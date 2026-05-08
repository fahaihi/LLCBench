#!/usr/bin/env bash
# scripts/tlc/zpaq/run.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"
ALGO="zpaq"

if [[ "${1-}" == "-d" ]]; then
    direction="decompress"; shift
    in_file="$1"; out_file="$2"
    workdir="$(mktemp -d)"
    metrics=$(llcb_time_run zpaq x "${in_file}" -to "${workdir}/" -t16 -method 5)
    extracted="$(find "${workdir}" -type f | head -n 1)"
    mv "${extracted}" "${out_file}"
    rm -rf "${workdir}"
else
    direction="compress"
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run zpaq a "${out_file}" "${in_file}" -t16 -method 5)
fi
wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
