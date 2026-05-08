#!/usr/bin/env bash
# scripts/_common.sh — shared helpers for every LLCBench wrapper.
#
# Wrappers expose a uniform CLI:
#   run.sh <input> <output>       # compression (default)
#   run.sh -d <input> <output>    # decompression
#
# They emit one line of metrics to stdout:
#   algo,direction,input_size,output_size,wall_time_seconds,peak_rss_mb

set -euo pipefail

# Run a command, measuring wall time and peak RSS.
#
# Strategy (in order):
#   1) GNU `time` (Linux / `gtime` on macOS via brew) — exact wall + RSS.
#   2) Pure Python `resource.RUSAGE_CHILDREN` — works on every Unix.
#
# BSD `time` (default on macOS) does NOT support `-f`, so we deliberately
# avoid it.  Echoes "<wall_seconds>,<peak_rss_mb>" to stdout.
llcb_time_run() {
    local _gnu_time=""
    if command -v gtime >/dev/null 2>&1; then
        _gnu_time="gtime"
    elif /usr/bin/time --help 2>&1 | head -n 1 | grep -q -- '-f'; then
        _gnu_time="/usr/bin/time"
    fi

    if [[ -n "${_gnu_time}" ]]; then
        local _tmp; _tmp="$(mktemp)"
        "${_gnu_time}" -f "%e %M" -o "${_tmp}" "$@"
        local _wall _rss; read -r _wall _rss < "${_tmp}"
        rm -f "${_tmp}"
        local _rss_mb; _rss_mb=$(awk -v k="${_rss}" 'BEGIN{printf "%.2f", k/1024.0}')
        echo "${_wall},${_rss_mb}"
        return
    fi

    # Portable fallback: Python wraps the child and reports its peak RSS.
    python3 - "$@" <<'PY'
import os, resource, subprocess, sys, time
cmd = sys.argv[1:]
t0 = time.perf_counter()
proc = subprocess.run(cmd)
wall = time.perf_counter() - t0
ru = resource.getrusage(resource.RUSAGE_CHILDREN)
# ru_maxrss is KB on Linux, bytes on macOS
rss_mb = ru.ru_maxrss / (1024 * 1024) if sys.platform == "darwin" else ru.ru_maxrss / 1024
sys.stdout.write(f"{wall:.3f},{rss_mb:.2f}\n")
sys.exit(proc.returncode)
PY
}

llcb_filesize() {
    if stat -c %s "$1" >/dev/null 2>&1; then
        stat -c %s "$1"
    else
        # macOS / BSD
        stat -f %z "$1"
    fi
}

# Print the canonical metrics line.
# Usage: llcb_emit <algo> <direction> <in_path> <out_path> <wall_s> <rss_mb>
llcb_emit() {
    local algo="$1" dir="$2" in_path="$3" out_path="$4" wall="$5" rss="$6"
    local in_sz out_sz
    in_sz=$(llcb_filesize "${in_path}")
    out_sz=$(llcb_filesize "${out_path}")
    echo "${algo},${dir},${in_sz},${out_sz},${wall},${rss}"
}
