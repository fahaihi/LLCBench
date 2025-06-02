#!/bin/bash

# 启用错误检查，如果命令失败则退出
set -e

# 设置：模型路径（原始模型）
MODEL_PATH="/home/chenjiashun/models/gpt2-medium-pubmed/model.safetensors"

MODEL_NAME=$(basename "$MODEL_PATH")  # 例如: model.safetensors
ORIGINAL_MODEL_NAME_NO_EXT="${MODEL_NAME%.*}" # 例如: model

SUFFIX="bak"  # 用于重命名源文件的后缀
CSV_FILE="result.csv"

# 进入脚本所在目录
cd "$(dirname "$0")"

# 如果CSV不存在，写入表头
if [ ! -f "$CSV_FILE" ]; then
  echo "Data,SourceSize (B),CompressedSize (B),CR (bits/base),CT (s),CM (KB),DT (s),DM (KB),Is_Same" > "$CSV_FILE"
fi

# 拷贝模型到当前目录
echo "拷贝模型 $MODEL_PATH 到当前目录..."
cp "$MODEL_PATH" "./$MODEL_NAME"
echo "拷贝完成。"

# 临时文件用于存储 time 命令的内存输出
MEM_OUTPUT_COMPRESS="mem_compress.tmp"
MEM_OUTPUT_DECOMPRESS="mem_decompress.tmp"

# --- 压缩 ---
echo "运行 zipnn_compress_file.py..."

# 捕获开始时间 (纳秒)
start_ns_compress=$(date +%s%N)

# 运行Python脚本，仅使用 /usr/bin/time 获取内存 (%M)
# Python脚本的标准输出和错误输出重定向到 compress.log
/usr/bin/time -o "$MEM_OUTPUT_COMPRESS" -f "%M" python zipnn_compress_file.py "$MODEL_NAME" > compress.log 2>&1

# 捕获结束时间 (纳秒)
end_ns_compress=$(date +%s%N)
echo "压缩脚本执行完毕。"

# 计算耗时 (纳秒)
duration_ns_compress=$((end_ns_compress - start_ns_compress))
# 基本的健全性检查，防止时间倒流或极小值导致负数
if (( duration_ns_compress < 0 )); then duration_ns_compress=0; fi

# 使用 bc 将纳秒转换为秒，并保留3位小数
CT_s=$(echo "scale=3; $duration_ns_compress / 1000000000" | bc)
# 如果结果是 ".xxx"，则在前面补 "0"
if [[ ${CT_s:0:1} == "." ]]; then
    CT_s="0${CT_s}"
fi

# 获取压缩使用的最大内存 (KB)
CM=$(cat "$MEM_OUTPUT_COMPRESS")


# 压缩后文件名
COMPRESSED_FILE="${MODEL_NAME}.znn"

# 获取压缩信息
SourceSize=$(stat -c %s "$MODEL_NAME")
CompressedSize=$(stat -c %s "$COMPRESSED_FILE")
CR=$(echo "$SourceSize $CompressedSize" | awk '{if ($1 > 0) printf("%.3f", 8*$2/$1); else print "0.000"}') # 避免除以0

echo "原始大小: $SourceSize B, 压缩后大小: $CompressedSize B"
echo "压缩率 (bits/base): $CR"
echo "压缩时间 (CT): $CT_s s"
echo "压缩内存 (CM): $CM KB"

# 将源文件重命名为 model.safetensors.bak
RENAMED_MODEL_NAME="${MODEL_NAME}.${SUFFIX}"
echo "重命名 $MODEL_NAME 为 $RENAMED_MODEL_NAME"
mv "$MODEL_NAME" "$RENAMED_MODEL_NAME"

# --- 解压 ---
echo "运行 zipnn_decompress_file.py..."
# 解压后文件名应与原始 MODEL_NAME 相同
DECOMPRESSED_MODEL_NAME="$MODEL_NAME"

# 捕获开始时间 (纳秒)
start_ns_decompress=$(date +%s%N)

# 运行Python脚本，仅使用 /usr/bin/time 获取内存 (%M)
/usr/bin/time -o "$MEM_OUTPUT_DECOMPRESS" -f "%M" python zipnn_decompress_file.py "$COMPRESSED_FILE" > decompress.log 2>&1

# 捕获结束时间 (纳秒)
end_ns_decompress=$(date +%s%N)
echo "解压脚本执行完毕。"

# 计算耗时 (纳秒)
duration_ns_decompress=$((end_ns_decompress - start_ns_decompress))
if (( duration_ns_decompress < 0 )); then duration_ns_decompress=0; fi

# 使用 bc 将纳秒转换为秒，并保留3位小数
DT_s=$(echo "scale=3; $duration_ns_decompress / 1000000000" | bc)
# 如果结果是 ".xxx"，则在前面补 "0"
if [[ ${DT_s:0:1} == "." ]]; then
    DT_s="0${DT_s}"
fi

# 获取解压使用的最大内存 (KB)
DM=$(cat "$MEM_OUTPUT_DECOMPRESS")

echo "解压时间 (DT): $DT_s s"
echo "解压内存 (DM): $DM KB"

# 数据一致性验证
echo "验证数据一致性: $RENAMED_MODEL_NAME vs $DECOMPRESSED_MODEL_NAME"
IS_SAME=$(python3 -c "
import numpy as np
import sys

file1_path = sys.argv[1]
file2_path = sys.argv[2]

try:
    series1 = np.fromfile(file1_path, dtype=np.uint8)
    series2 = np.fromfile(file2_path, dtype=np.uint8)

    series1 = np.where(series1 == 13, 10, series1)
    series2 = np.where(series2 == 13, 10, series2)

    are_same = series1.shape == series2.shape and np.array_equal(series1, series2)
    print(are_same)
except FileNotFoundError:
    print('False')
    sys.exit(1) # Indicate error if a file is not found
except Exception as e: # Catch other potential numpy errors
    print(f'Error during comparison: {e}', file=sys.stderr)
    print('False')
    sys.exit(1)
" "$RENAMED_MODEL_NAME" "$DECOMPRESSED_MODEL_NAME")

echo "数据一致性 (Is_Same): $IS_SAME"

# 写入结果到CSV文件
echo "$MODEL_NAME,$SourceSize,$CompressedSize,$CR,$CT_s,$CM,$DT_s,$DM,$IS_SAME" >> "$CSV_FILE"
echo "结果已写入 $CSV_FILE"

# 清理文件
echo "清理临时文件..."
rm -f "$DECOMPRESSED_MODEL_NAME" "$COMPRESSED_FILE" "$RENAMED_MODEL_NAME" \
      "$MEM_OUTPUT_COMPRESS" "$MEM_OUTPUT_DECOMPRESS"
echo "清理完成。"

# 获取模型所在目录的最后一级名称
MODEL_PARENT_DIR_NAME=$(basename "$(dirname "$MODEL_PATH")")

# 创建目标文件夹 (如果不存在)
TARGET_DIR="./${MODEL_PARENT_DIR_NAME}_results"
mkdir -p "$TARGET_DIR"
echo "创建/确认结果目录: $TARGET_DIR"

# 移动日志和 CSV 文件进去
echo "移动日志和CSV文件到 $TARGET_DIR"
mv compress.log decompress.log "$CSV_FILE" "$TARGET_DIR/"

echo "✅ 所有文件已移动到: $TARGET_DIR"
echo "脚本执行完毕。"
