#!/usr/bin/env bash
# scripts/tlc/lzo/run.sh — Standalone LZO via the lzop tool's -F format.
#
# Note: the original LZO library does not ship a CLI; the paper measures the
# minilzo `lzo` reference tool. We forward to lzop with --format=lzo for
# convenience; ensure your LZO_BIN points to the right binary if you have one.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"
ALGO="lzo"
LZO_BIN="${LZO_BIN:-lzop}"

if [[ "${1-}" == "-d" ]]; then
    direction="decompress"; shift
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run "${LZO_BIN}" -df --format=lzo1x_999 "${in_file}" -o "${out_file}" 2>/dev/null \
              || llcb_time_run "${LZO_BIN}" -df "${in_file}" -o "${out_file}")
else
    direction="compress"
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run "${LZO_BIN}" -9 -f --format=lzo1x_999 "${in_file}" -o "${out_file}" 2>/dev/null \
              || llcb_time_run "${LZO_BIN}" -9 -f "${in_file}" -o "${out_file}")
fi
wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
