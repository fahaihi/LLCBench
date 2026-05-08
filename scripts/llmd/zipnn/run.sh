#!/usr/bin/env bash
# scripts/llmd/zipnn/run.sh — ZipNN (https://github.com/zipnn/zipnn).
#
# Uses the official Python API directly, which is the same path the upstream
# `zipnn_compress_file.py` / `zipnn_decompress_file.py` scripts take.
# Requirements: pip install zipnn

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"

ALGO="zipnn"
PY="${PY:-python3}"

if [[ "${1-}" == "-d" ]]; then
    direction="decompress"; shift
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run "${PY}" - "${in_file}" "${out_file}" <<'PY'
import sys
from zipnn import ZipNN
src, dst = sys.argv[1], sys.argv[2]
zpn = ZipNN(input_format="byte", bytearray_dtype="float32")
with open(src, "rb") as fh:
    out = zpn.decompress(fh.read())
with open(dst, "wb") as fh:
    fh.write(out)
PY
)
else
    direction="compress"
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run "${PY}" - "${in_file}" "${out_file}" <<'PY'
import sys
from zipnn import ZipNN
src, dst = sys.argv[1], sys.argv[2]
zpn = ZipNN(input_format="byte", bytearray_dtype="float32")
with open(src, "rb") as fh:
    out = zpn.compress(fh.read())
with open(dst, "wb") as fh:
    fh.write(out)
PY
)
fi

wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
