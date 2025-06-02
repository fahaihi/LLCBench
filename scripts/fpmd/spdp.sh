#!/bin/bash

# 启用错误检查，如果命令失败则退出
set -e

# 设置模型路径（原始模型）
MODEL_PATH="/home/chenjiashun/models/gpt2-medium-pubmed/model.safetensors"
MODEL_NAME=$(basename "$MODEL_PATH")  # 例如: model.safetensors
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
echo "运行 ./spdp 进行压缩..."

start_ns_compress=$(date +%s%N)
/usr/bin/time -o "$MEM_OUTPUT_COMPRESS" -f "%M" ./spdp 10 < "$MODEL_NAME" > "$MODEL_NAME.spdp" 2> compress.log
end_ns_compress=$(date +%s%N)

duration_ns_compress=$((end_ns_compress - start_ns_compress))
if (( duration_ns_compress < 0 )); then duration_ns_compress=0; fi
CT_s=$(echo "scale=3; $duration_ns_compress / 1000000000" | bc)
[[ ${CT_s:0:1} == "." ]] && CT_s="0${CT_s}"
CM=$(cat "$MEM_OUTPUT_COMPRESS")

COMPRESSED_FILE="${MODEL_NAME}.spdp"
SourceSize=$(stat -c %s "$MODEL_NAME")
CompressedSize=$(stat -c %s "$COMPRESSED_FILE")
CR=$(echo "$SourceSize $CompressedSize" | awk '{if ($1 > 0) printf("%.3f", 8*$2/$1); else print "0.000"}')

echo "原始大小: $SourceSize B, 压缩后大小: $CompressedSize B"
echo "压缩率 (bits/base): $CR"
echo "压缩时间 (CT): $CT_s s"
echo "压缩内存 (CM): $CM KB"

# --- 解压 ---
echo "运行 ./spdp 进行解压..."
DECOMPRESSED_MODEL_NAME="${MODEL_NAME}.spdpout"  # 例：model.safetensors.spdpout

start_ns_decompress=$(date +%s%N)
/usr/bin/time -o "$MEM_OUTPUT_DECOMPRESS" -f "%M" ./spdp 10 < "$COMPRESSED_FILE" > "$DECOMPRESSED_MODEL_NAME" 2> decompress.log
end_ns_decompress=$(date +%s%N)

duration_ns_decompress=$((end_ns_decompress - start_ns_decompress))
if (( duration_ns_decompress < 0 )); then duration_ns_decompress=0; fi
DT_s=$(echo "scale=3; $duration_ns_decompress / 1000000000" | bc)
[[ ${DT_s:0:1} == "." ]] && DT_s="0${DT_s}"
DM=$(cat "$MEM_OUTPUT_DECOMPRESS")

echo "解压时间 (DT): $DT_s s"
echo "解压内存 (DM): $DM KB"

# 数据一致性验证
echo "验证数据一致性: $MODEL_NAME vs $DECOMPRESSED_MODEL_NAME"
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
    sys.exit(1)
except Exception as e:
    print(f'Error during comparison: {e}', file=sys.stderr)
    print('False')
    sys.exit(1)
" "$MODEL_NAME" "$DECOMPRESSED_MODEL_NAME")

echo "数据一致性 (Is_Same): $IS_SAME"

# 写入结果到CSV文件
echo "$MODEL_NAME,$SourceSize,$CompressedSize,$CR,$CT_s,$CM,$DT_s,$DM,$IS_SAME" >> "$CSV_FILE"
echo "结果已写入 $CSV_FILE"

# 清理临时文件
echo "清理临时文件..."
rm -f "$MODEL_NAME" "$COMPRESSED_FILE" "$DECOMPRESSED_MODEL_NAME" \
      "$MEM_OUTPUT_COMPRESS" "$MEM_OUTPUT_DECOMPRESS"
echo "清理完成。"

# 创建结果目录并移动日志
MODEL_PARENT_DIR_NAME=$(basename "$(dirname "$MODEL_PATH")")
TARGET_DIR="./${MODEL_PARENT_DIR_NAME}_results"
mkdir -p "$TARGET_DIR"
mv compress.log decompress.log "$CSV_FILE" "$TARGET_DIR/"

echo "✅ 所有文件已移动到: $TARGET_DIR"
echo "脚本执行完毕。"
