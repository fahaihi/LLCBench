#!/usr/bin/env bash
# envs/create_env.sh — create the per-algorithm conda environment that matches
# the upstream paper's official version pins. Each env is independent so that
# (e.g.) DeepZip's TF1.8 doesn't conflict with TRACE's PyTorch 1.7.
#
# Usage:   bash envs/create_env.sh <env_name>
#
# Available envs:
#   tlc_env       — pandas + plotting (TLC + LLMD ZipNN)
#   fpmd_env      — pandas + fpzip python bindings
#   llmd_env      — zipnn + fm_delta build deps
#   trace_env     — TRACE / PAC / MSDZip (PyTorch 1.7, CUDA 11.1)
#   deepzip_env   — DeepZip (TF 1.8, Keras 2.2.2, Python 3.6)
#   dzip_env      — DZip-torch (PyTorch 1.4, Python 3.6.8, CUDA 9.0+)
#
# Requires: conda (or mamba). For environments pinning Python 3.6, we use
# conda-forge so the build still resolves on modern Linux.

set -euo pipefail
ENV_NAME="${1:?usage: $0 <env_name>}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPEC_FILE="${HERE}/${ENV_NAME}.yml"

if [[ ! -f "${SPEC_FILE}" ]]; then
    echo "❌ unknown env: ${ENV_NAME}. Available specs:"
    ls "${HERE}"/*.yml | xargs -n1 basename | sed 's/.yml$//' | sed 's/^/    /'
    exit 1
fi

if conda env list | awk '{print $1}' | grep -qx "${ENV_NAME}"; then
    echo "✓ env '${ENV_NAME}' already exists. Activate via:  conda activate ${ENV_NAME}"
    exit 0
fi

echo "→ creating conda env from ${SPEC_FILE}"
conda env create -f "${SPEC_FILE}"
echo "✓ created. Activate with:   conda activate ${ENV_NAME}"
