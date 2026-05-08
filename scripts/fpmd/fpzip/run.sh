#!/usr/bin/env bash
# scripts/fpmd/fpzip/run.sh — wrapper-of-wrapper for the Python CLI.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="${PY:-python3}"

if [[ "${1-}" == "-d" ]]; then
    shift
    exec "${PY}" "${HERE}/fpzip.py" decompress "$1" "$2"
else
    exec "${PY}" "${HERE}/fpzip.py" compress "$1" "$2"
fi
