#!/usr/bin/env bash
# scripts/llc/pac/run.sh — PAC compressor (DAC 2023).
# Upstream: https://github.com/mynotwo/Faster-and-Stronger-Lossless-Compression-with-Optimized-Autoregressive-Framework
#
# NOTE: the URL referenced in the LLCBench paper
# (https://github.com/mynotwo/compressor_via_simple_and_scalable_parameterization)
# is an empty placeholder. The real PAC implementation lives at the URL above
# (also referenced in MSDZip's acknowledgements).
#
# The CLI mirrors TRACE's layout (same author).

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"

ALGO="pac"
PY="${PY:-python3}"
PAC_DIR="${PAC_DIR:-${HERE}/PAC}"
GPU_ID="${PAC_GPU_ID:-0}"
BATCH_SIZE="${PAC_BATCH_SIZE:-512}"
SEQ_LEN="${PAC_SEQ_LEN:-32}"
HIDDEN_DIM="${PAC_HIDDEN_DIM:-256}"
FFN_DIM="${PAC_FFN_DIM:-4096}"
VOCAB_DIM="${PAC_VOCAB_DIM:-64}"
LR="${PAC_LR:-1e-3}"

if [[ "${1-}" == "-d" ]]; then
    echo "PAC upstream does not ship a separate decompressor entry-point." >&2
    exit 2
fi

direction="compress"
in_file="$1"; out_file="$2"
prefix="$(basename "${in_file}")"

metrics=$(llcb_time_run "${PY}" "${PAC_DIR}/compressor.py" \
    --input_dir "${in_file}" \
    --prefix "${prefix}" \
    --batch_size "${BATCH_SIZE}" \
    --seq_len "${SEQ_LEN}" \
    --hidden_dim "${HIDDEN_DIM}" \
    --ffn_dim "${FFN_DIM}" \
    --vocab_dim "${VOCAB_DIM}" \
    --learning_rate "${LR}" \
    --gpu_id "${GPU_ID}")

if compgen -G "${PAC_DIR}/${prefix}_*.compress.combined" >/dev/null; then
    mv "${PAC_DIR}/${prefix}_"*.compress.combined "${out_file}"
fi

wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
