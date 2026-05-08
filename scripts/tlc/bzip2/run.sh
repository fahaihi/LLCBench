#!/usr/bin/env bash
# scripts/tlc/bzip2/run.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"
ALGO="bzip2"

if [[ "${1-}" == "-d" ]]; then
    direction="decompress"; shift
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run bash -c "bzip2 -cdf '$1' > '$2'" _ "${in_file}" "${out_file}")
else
    direction="compress"
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run bash -c "bzip2 -kzfc9 '$1' > '$2'" _ "${in_file}" "${out_file}")
fi
wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
