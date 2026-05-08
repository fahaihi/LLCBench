#!/usr/bin/env bash
# scripts/llc/dzip/run.sh — DZip-torch (DCC 2021).
# Upstream: https://github.com/mohit1997/Dzip-torch
#
# Upstream usage (from coding-gpu/):
#   bash compress.sh   <input>      <output>     <com|bs> <model_path>
#   bash decompress.sh <compressed> <restored>   <com|bs> <model_path>
#   bash compare.sh    <original>   <restored>           # round-trip check
#
# `com` = combined model (default, higher CR), `bs` = bootstrap-only.
# Requirements: Python ≤3.6.8, PyTorch 1.4, CUDA 9.0+.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"

ALGO="dzip"
DZIP_DIR="${DZIP_DIR:-${HERE}/Dzip-torch}"
WORK_DIR="${DZIP_DIR}/coding-gpu"
DZIP_MODE="${DZIP_MODE:-com}"      # com | bs
DZIP_MODEL_PATH="${DZIP_MODEL_PATH:-${WORK_DIR}/bootstrap_model}"

if [[ "${1-}" == "-d" ]]; then
    direction="decompress"; shift
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run bash -c "
        cd '${WORK_DIR}' && \
        bash decompress.sh '$0' '$1' '${DZIP_MODE}' '${DZIP_MODEL_PATH}'
    " "${in_file}" "${out_file}")
else
    direction="compress"
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run bash -c "
        cd '${WORK_DIR}' && \
        bash compress.sh '$0' '$1' '${DZIP_MODE}' '${DZIP_MODEL_PATH}'
    " "${in_file}" "${out_file}")
fi

wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
