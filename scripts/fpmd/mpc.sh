#!/bin/bash

# 启用错误检查，如果命令失败则退出
set -e

# 设置模型路径（原始模型）
MODEL_PATH="/home/chenjiashun/models/dinov2-small-finetuned-galaxy10-decals/model.safetensors"
MODEL_NAME=$(basename "$MODEL_PATH")
CSV_FILE="result.csv"

# 进入脚本所在目录
cd "$(dirname "$0")"

# CSV表头初始化（新增 GPU 监控列）
if [ ! -f "$CSV_FILE" ]; then
  echo "Data,SourceSize (B),CompressedSize (B),CR (bits/base),CT (s),CM (KB),CM_GPU (KB),DT (s),DM (KB),DM_GPU (KB),Is_Same" > "$CSV_FILE"
fi

# 拷贝模型到当前目录
echo "拷贝模型 $MODEL_PATH 到当前目录..."
cp "$MODEL_PATH" "./$MODEL_NAME"
echo "拷贝完成。"

# 检查是否需要8字节对齐
echo "检查是否需要进行8字节补齐..."
FILE_SIZE=$(stat -c %s "$MODEL_NAME")
PADDING=$(( (8 - (FILE_SIZE % 8)) % 8 ))

if (( PADDING > 0 )); then
  echo "当前文件大小: $FILE_SIZE 字节，追加 $PADDING 字节..."
  dd if=/dev/zero bs=1 count=$PADDING >> "$MODEL_NAME"
else
  echo "文件已对齐，无需补齐。"
fi

# GPU监控函数（使用 nvidia-smi）
start_gpu_monitor() {
  GPU_LOG_FILE="$1"
  GPU_PID_FILE="$2"
  GPU_ID=${3:-0}
  echo 0 > "$GPU_LOG_FILE"
  (
    while true; do
      usage=$(nvidia-smi --id=$GPU_ID --query-gpu=memory.used --format=csv,noheader,nounits)
      echo "$usage" >> "$GPU_LOG_FILE"
      sleep 0.001
    done
  ) &
  echo $! > "$GPU_PID_FILE"
}

stop_gpu_monitor() {
  GPU_LOG_FILE="$1"
  GPU_PID_FILE="$2"
  kill "$(cat "$GPU_PID_FILE")" 2>/dev/null
  sleep 0.2
  PEAK=$(awk 'BEGIN{max=0} {if($1+0>max) max=$1} END{print max}' "$GPU_LOG_FILE")
  echo "$PEAK"
}

# 临时文件
MEM_OUTPUT_COMPRESS="mem_compress.tmp"
MEM_OUTPUT_DECOMPRESS="mem_decompress.tmp"

# --- 压缩 ---
echo "运行 ./MPC_double 进行压缩..."
start_gpu_monitor "gpu_compress.log" "gpu_compress.pid"

start_ns_compress=$(date +%s%N)
/usr/bin/time -o "$MEM_OUTPUT_COMPRESS" -f "%M" ./MPC_double "$MODEL_NAME" 1 > compress.log 2>&1
end_ns_compress=$(date +%s%N)

CM_GPU=$(stop_gpu_monitor "gpu_compress.log" "gpu_compress.pid")

duration_ns_compress=$((end_ns_compress - start_ns_compress))
CT_s=$(echo "scale=3; $duration_ns_compress / 1000000000" | bc)
[[ ${CT_s:0:1} == "." ]] && CT_s="0${CT_s}"
CM=$(cat "$MEM_OUTPUT_COMPRESS")

COMPRESSED_FILE="${MODEL_NAME}.mpc"
SourceSize=$(stat -c %s "$MODEL_NAME")
CompressedSize=$(stat -c %s "$COMPRESSED_FILE")
CR=$(echo "$SourceSize $CompressedSize" | awk '{if ($1 > 0) printf("%.3f", 8*$2/$1); else print "0.000"}')

echo "压缩完成: 原始大小=$SourceSize, 压缩后=$CompressedSize, 压缩率=$CR, 时间=$CT_s s, 内存=$CM KB, GPU内存=$CM_GPU KB"

# --- 解压 ---
echo "运行 ./MPC_double 进行解压..."
start_gpu_monitor "gpu_decompress.log" "gpu_decompress.pid"

DECOMPRESSED_MODEL_NAME="${COMPRESSED_FILE}.org"
start_ns_decompress=$(date +%s%N)
/usr/bin/time -o "$MEM_OUTPUT_DECOMPRESS" -f "%M" ./MPC_double "$COMPRESSED_FILE" > decompress.log 2>&1
end_ns_decompress=$(date +%s%N)

DM_GPU=$(stop_gpu_monitor "gpu_decompress.log" "gpu_decompress.pid")

duration_ns_decompress=$((end_ns_decompress - start_ns_decompress))
DT_s=$(echo "scale=3; $duration_ns_decompress / 1000000000" | bc)
[[ ${DT_s:0:1} == "." ]] && DT_s="0${DT_s}"
DM=$(cat "$MEM_OUTPUT_DECOMPRESS")

echo "解压完成: 时间=$DT_s s, 内存=$DM KB, GPU内存=$DM_GPU KB"

# --- 验证数据一致性 ---
echo "验证数据一致性: $MODEL_NAME vs $DECOMPRESSED_MODEL_NAME"
IS_SAME=$(python3 -c "
import numpy as np, sys
try:
    a = np.fromfile(sys.argv[1], dtype=np.uint8)
    b = np.fromfile(sys.argv[2], dtype=np.uint8)
    a = np.where(a == 13, 10, a)
    b = np.where(b == 13, 10, b)
    print(a.shape == b.shape and np.array_equal(a, b))
except Exception: print('False'); sys.exit(1)
" "$MODEL_NAME" "$DECOMPRESSED_MODEL_NAME")

echo "数据一致性: $IS_SAME"

# --- 写入CSV ---
echo "$MODEL_NAME,$SourceSize,$CompressedSize,$CR,$CT_s,$CM,$CM_GPU,$DT_s,$DM,$DM_GPU,$IS_SAME" >> "$CSV_FILE"
echo "已写入结果到 $CSV_FILE"

# --- 清理 ---
echo "清理临时文件..."
rm -f "$MODEL_NAME" "$COMPRESSED_FILE" "$DECOMPRESSED_MODEL_NAME" \
      "$MEM_OUTPUT_COMPRESS" "$MEM_OUTPUT_DECOMPRESS" \
      gpu_compress.log gpu_decompress.log \
      gpu_compress.pid gpu_decompress.pid
echo "清理完成。"

# --- 移动结果 ---
MODEL_PARENT_DIR_NAME=$(basename "$(dirname "$MODEL_PATH")")
TARGET_DIR="./${MODEL_PARENT_DIR_NAME}_results"
mkdir -p "$TARGET_DIR"
mv compress.log decompress.log "$CSV_FILE" "$TARGET_DIR/"

echo "✅ 所有结果已移动到: $TARGET_DIR"
echo "脚本执行完毕。"
