#!/usr/bin/env bash
# scripts/tlc/pbzip2/run.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"
ALGO="pbzip2"

if [[ "${1-}" == "-d" ]]; then
    direction="decompress"; shift
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run bash -c "pbzip2 -dc -p16 -m2000 '$1' > '$2'" _ "${in_file}" "${out_file}")
else
    direction="compress"
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run bash -c "pbzip2 -9 -m2000 -p16 -c '$1' > '$2'" _ "${in_file}" "${out_file}")
fi
wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
