#!/usr/bin/env bash
# scripts/fpmd/spdp/run.sh — SPDP (Single Precision Double Precision) compressor.
#
# Reference: https://userweb.cs.txstate.edu/~burtscher/research/SPDPcompressor/
# Hyper-parameters (paper): level=10, threads=2.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"

ALGO="spdp"
SPDP_BIN="${SPDP_BIN:-${HERE}/spdp}"

if [[ "${1-}" == "-d" ]]; then
    direction="decompress"; shift
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run "${SPDP_BIN}" 10 "${in_file}" "${out_file}" 2)
else
    direction="compress"
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run "${SPDP_BIN}" 10 "${in_file}" "${out_file}" 2)
fi

wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
