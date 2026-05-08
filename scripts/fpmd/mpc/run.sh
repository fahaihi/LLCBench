#!/usr/bin/env bash
# scripts/fpmd/mpc/run.sh — Massively Parallel Compressor (MPC).
#
# Reference: FCBench MPC (https://github.com/hpdps-group/FCBench)
# Compression : ./MPC_double <file> 1
# Decompression: ./MPC_double <file.mpc>

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"

ALGO="mpc"
MPC_BIN="${MPC_BIN:-${HERE}/MPC_double}"

if [[ "${1-}" == "-d" ]]; then
    direction="decompress"; shift
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run "${MPC_BIN}" "${in_file}")
    # MPC_double writes alongside the input by convention; relocate.
    if [[ -f "${in_file%.mpc}" ]]; then mv "${in_file%.mpc}" "${out_file}"; fi
else
    direction="compress"
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run "${MPC_BIN}" "${in_file}" 1)
    if [[ -f "${in_file}.mpc" ]]; then mv "${in_file}.mpc" "${out_file}"; fi
fi

wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
