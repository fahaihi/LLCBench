#!/usr/bin/env bash
# scripts/llc/msdzip/run.sh — MSDZip (https://github.com/huidong-ma/MSDZip)
#
# Upstream usage (from the README):
#   python compress.py   <file>     <file>.mz   --prefix <prefix>
#   python decompress.py <file>.mz  <file>.mz.out --prefix <prefix>
#
# The 'stepwise-parallel' variant is also supported via env-vars:
#   MSDZIP_PARALLEL=2 ./run.sh <in> <out>
# which switches to sp-compress.sh / sp-decompress.sh.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"

ALGO="msdzip"
PY="${PY:-python3}"
MSDZIP_DIR="${MSDZIP_DIR:-${HERE}/MSDZip}"
PARALLEL="${MSDZIP_PARALLEL:-}"

prefix="$(basename "${1#-d}" .mz)"

if [[ "${1-}" == "-d" ]]; then
    direction="decompress"; shift
    in_file="$1"; out_file="$2"
    if [[ -n "${PARALLEL}" ]]; then
        metrics=$(llcb_time_run bash "${MSDZIP_DIR}/sp-decompress.sh" \
            "${in_file}" "${out_file}" "${prefix}" "${PARALLEL}")
    else
        metrics=$(llcb_time_run "${PY}" "${MSDZIP_DIR}/decompress.py" \
            "${in_file}" "${out_file}" --prefix "${prefix}")
    fi
else
    direction="compress"
    in_file="$1"; out_file="$2"
    if [[ -n "${PARALLEL}" ]]; then
        metrics=$(llcb_time_run bash "${MSDZIP_DIR}/sp-compress.sh" \
            "${in_file}" "${out_file}" "${prefix}" "${PARALLEL}")
    else
        metrics=$(llcb_time_run "${PY}" "${MSDZIP_DIR}/compress.py" \
            "${in_file}" "${out_file}" --prefix "${prefix}")
    fi
fi

wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
