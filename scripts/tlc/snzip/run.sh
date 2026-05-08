#!/usr/bin/env bash
# scripts/tlc/snzip/run.sh
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"
ALGO="snzip"

if [[ "${1-}" == "-d" ]]; then
    direction="decompress"; shift
    in_file="$1"; out_file="$2"
    workdir="$(mktemp -d)"
    cp "${in_file}" "${workdir}/$(basename "${in_file}")"
    pushd "${workdir}" >/dev/null
    metrics=$(llcb_time_run snzip -kd -t snzip "$(basename "${in_file}")")
    popd >/dev/null
    base="$(basename "${in_file}")"
    mv "${workdir}/${base%.snz}" "${out_file}"
    rm -rf "${workdir}"
else
    direction="compress"
    in_file="$1"; out_file="$2"
    workdir="$(mktemp -d)"
    cp "${in_file}" "${workdir}/$(basename "${in_file}")"
    pushd "${workdir}" >/dev/null
    metrics=$(llcb_time_run snzip -k -t snzip "$(basename "${in_file}")")
    popd >/dev/null
    mv "${workdir}/$(basename "${in_file}").snz" "${out_file}"
    rm -rf "${workdir}"
fi
wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
