#!/usr/bin/env bash
# scripts/llmd/fmdelta/run.sh — FM-Delta (https://github.com/ningwanyi/FM-Delta).
#
# FM-Delta is *reference-based*: it needs a base model and a fine-tuned model.
# Build / install the upstream Cython package first:
#   cd scripts/llmd/fmdelta/FM-Delta && \
#       pip install -r requirements.txt && \
#       cython -3 --cplus ./fmd.pyx && python setup.py install
#
# Then call this wrapper with REFERENCE_FILE pointing to the base model file:
#   REFERENCE_FILE=./models/D2_base.bin run.sh    <fine_tuned> <delta>
#   REFERENCE_FILE=./models/D2_base.bin run.sh -d <delta>      <restored>
#
# We delegate to the small Python driver shipped in fmdela.py, which talks to
# the installed `fmd` Python module.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"

PY="${PY:-python3}"
ALGO="fmdelta"
: "${REFERENCE_FILE:?Set REFERENCE_FILE to the path of the base/reference model}"

if [[ "${1-}" == "-d" ]]; then
    direction="decompress"; shift
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run "${PY}" "${HERE}/fmdela.py" decompress \
        --delta "${in_file}" --reference "${REFERENCE_FILE}" --output "${out_file}")
else
    direction="compress"
    in_file="$1"; out_file="$2"
    metrics=$(llcb_time_run "${PY}" "${HERE}/fmdela.py" compress \
        --target "${in_file}" --reference "${REFERENCE_FILE}" --output "${out_file}")
fi

wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
