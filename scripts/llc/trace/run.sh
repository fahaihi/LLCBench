#!/usr/bin/env bash
# scripts/llc/trace/run.sh — TRACE compressor (WWW 2022).
# Upstream: https://github.com/mynotwo/A-Fast-Transformer-based-General-Purpose-LosslessCompressor
#
# IMPORTANT: TRACE is an *adaptive* per-file compressor. The upstream README
# uses these arguments:
#
#   python compressor.py \
#       --input_dir <FILE>  --prefix <name> \
#       --batch_size 512 --seq_len 8 \
#       --hidden_dim 256 --ffn_dim 4096 --vocab_dim 64 \
#       --learning_rate 1e-3 --gpu_id 0
#
# It writes <name>_<vocab>_<hidden>_<ffn>_bs<bs>_random_seq32.compress.combined
# beside the input.  This wrapper renames that file to the requested output.
#
# Decompression is *not* supported by upstream TRACE as a separate command;
# the model + arithmetic-coded stream is round-trip-decodable inside
# ``compressor.py`` only when the same hyper-params are passed.  We expose
# `-d` for completeness; if upstream lacks decompression, the wrapper exits
# with code 2.
#
# Requirements: PyTorch 1.7.0, CUDA 11.1, 1x NVIDIA GPU.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"

ALGO="trace"
PY="${PY:-python3}"
TRACE_DIR="${TRACE_DIR:-${HERE}/TRACE}"
GPU_ID="${TRACE_GPU_ID:-0}"
BATCH_SIZE="${TRACE_BATCH_SIZE:-512}"
SEQ_LEN="${TRACE_SEQ_LEN:-8}"
HIDDEN_DIM="${TRACE_HIDDEN_DIM:-256}"
FFN_DIM="${TRACE_FFN_DIM:-4096}"
VOCAB_DIM="${TRACE_VOCAB_DIM:-64}"
LR="${TRACE_LR:-1e-3}"

if [[ "${1-}" == "-d" ]]; then
    echo "TRACE upstream does not ship a separate decompressor entry-point." >&2
    echo "Re-run the same compressor.py command to verify round-trip." >&2
    exit 2
fi

direction="compress"
in_file="$1"; out_file="$2"
prefix="$(basename "${in_file}")"

# TRACE writes its output next to the input under a deterministic name.
expected_out="${TRACE_DIR}/${prefix}_${VOCAB_DIM}_${HIDDEN_DIM}_${FFN_DIM}_bs${BATCH_SIZE}_random_seq32.compress.combined"

metrics=$(llcb_time_run "${PY}" "${TRACE_DIR}/compressor.py" \
    --input_dir "${in_file}" \
    --prefix "${prefix}" \
    --batch_size "${BATCH_SIZE}" \
    --seq_len "${SEQ_LEN}" \
    --hidden_dim "${HIDDEN_DIM}" \
    --ffn_dim "${FFN_DIM}" \
    --vocab_dim "${VOCAB_DIM}" \
    --learning_rate "${LR}" \
    --gpu_id "${GPU_ID}")

# Move the output file into the requested location.
if [[ -f "${expected_out}" ]]; then
    mv "${expected_out}" "${out_file}"
elif compgen -G "${TRACE_DIR}/${prefix}_*.compress.combined" >/dev/null; then
    mv "${TRACE_DIR}/${prefix}_"*.compress.combined "${out_file}"
fi

wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
