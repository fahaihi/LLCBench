#!/usr/bin/env bash
# scripts/tlc/ppmd/run.sh — PPMD via 7-Zip.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"
ALGO="ppmd"
SEVENZIP_BIN="${SEVENZIP_BIN:-7zz}"

if [[ "${1-}" == "-d" ]]; then
    direction="decompress"; shift
    in_file="$1"; out_file="$2"
    workdir="$(mktemp -d)"
    metrics=$(llcb_time_run "${SEVENZIP_BIN}" x -y "-mmt16" "-o${workdir}" "${in_file}")
    extracted="$(find "${workdir}" -type f | head -n 1)"
    mv "${extracted}" "${out_file}"
    rm -rf "${workdir}"
else
    direction="compress"
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run "${SEVENZIP_BIN}" a "-m0=ppmd" "-mx9" "-mmt16" "${out_file}" "${in_file}")
fi

wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
