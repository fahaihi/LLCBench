#!/usr/bin/env bash
# scripts/llc/deepzip/run.sh — DeepZip (DCC 2019).
# Upstream: https://github.com/mohit1997/DeepZip
#
# DeepZip ships an end-to-end experiment driver, not a per-file CLI.
# Workflow per upstream README:
#   1. Place the file under  <DEEPZIP_DIR>/data/files_to_be_compressed/<file>
#   2. cd <DEEPZIP_DIR>/data && ./run_parser.sh
#   3. cd <DEEPZIP_DIR>/src  && ./run_experiments.sh <model> <gpu_id>
#
# The driver writes the compressed artefact under <DEEPZIP_DIR>/src/Outputs/.
# This wrapper automates those three steps.
#
# Requirements: Python 2/3, TensorFlow 1.8, Keras 2.2.2, NVIDIA GPU.

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../_common.sh
source "${HERE}/../../_common.sh"

ALGO="deepzip"
DEEPZIP_DIR="${DEEPZIP_DIR:-${HERE}/DeepZip}"
DEEPZIP_MODEL="${DEEPZIP_MODEL:-biLSTM}"  # see DeepZip/src/models.py
DEEPZIP_GPU="${DEEPZIP_GPU:-0}"

if [[ "${1-}" == "-d" ]]; then
    echo "DeepZip upstream does not expose a standalone decompression CLI." >&2
    echo "Re-run run_experiments.sh under the same setup to verify round-trip." >&2
    exit 2
fi

direction="compress"
in_file="$1"; out_file="$2"
base="$(basename "${in_file}")"

# Stage the input where DeepZip's driver expects it.
mkdir -p "${DEEPZIP_DIR}/data/files_to_be_compressed"
cp "${in_file}" "${DEEPZIP_DIR}/data/files_to_be_compressed/${base}"

metrics=$(llcb_time_run bash -c "
    set -e
    cd '${DEEPZIP_DIR}/data' && bash run_parser.sh
    cd '${DEEPZIP_DIR}/src'  && bash run_experiments.sh '${DEEPZIP_MODEL}' '${DEEPZIP_GPU}'
")

# Locate the produced artefact (Outputs/<base>.deepzip or similar).
produced="$(find "${DEEPZIP_DIR}/src/Outputs" -maxdepth 2 -type f -name "${base}*" 2>/dev/null | head -n 1 || true)"
if [[ -n "${produced}" ]]; then
    cp "${produced}" "${out_file}"
fi

wall=${metrics%,*}; rss=${metrics#*,}
llcb_emit "${ALGO}" "${direction}" "${in_file}" "${out_file}" "${wall}" "${rss}"
