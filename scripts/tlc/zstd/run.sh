#!/usr/bin/env bash
# scripts/tlc/zstd/run.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"
ALGO="zstd"

if [[ "${1-}" == "-d" ]]; then
    direction="decompress"; shift
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run zstd -df "${in_file}" -o "${out_file}")
else
    direction="compress"
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run zstd -19 -f "${in_file}" -o "${out_file}")
fi
wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
