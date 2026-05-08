#!/usr/bin/env bash
# tools/setup_baselines.sh — clone every upstream baseline repository so the
# LLCBench wrappers under scripts/ have real implementations to call.
#
# Usage:   bash tools/setup_baselines.sh
#
# After running this script you should have, alongside scripts/<class>/<algo>/run.sh,
# the upstream source trees in scripts/<class>/<algo>/<UpstreamName>/.
# The wrappers discover them via well-known env vars (TRACE_DIR, PAC_DIR, …).
#
# Skips already-cloned repos. Network access required.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="${REPO_ROOT}/scripts"

clone() {
    local url="$1" dest="$2"
    if [[ -d "${dest}/.git" ]]; then
        echo "✓ already cloned: ${dest}"
        return
    fi
    echo "→ cloning ${url} -> ${dest}"
    git clone --depth=1 "${url}" "${dest}"
}

# === FPMD ===
clone https://github.com/llnl/fpzip.git           "${SCRIPTS}/fpmd/fpzip/upstream"
clone https://github.com/hpdps-group/FCBench.git  "${SCRIPTS}/fpmd/mpc/FCBench"
# SPDP is a single C file hosted on a faculty page.
if [[ ! -f "${SCRIPTS}/fpmd/spdp/SPDP_11.c" ]]; then
    echo "→ downloading SPDP_11.c"
    curl -fsSL "https://userweb.cs.txstate.edu/~burtscher/research/SPDPcompressor/SPDP_11.c" \
        -o "${SCRIPTS}/fpmd/spdp/SPDP_11.c"
fi

# === LLMD ===
clone https://github.com/zipnn/zipnn.git          "${SCRIPTS}/llmd/zipnn/upstream"
clone https://github.com/ningwanyi/FM-Delta.git   "${SCRIPTS}/llmd/fmdelta/FM-Delta"

# === LLC ===
clone https://github.com/huidong-ma/MSDZip.git    "${SCRIPTS}/llc/msdzip/MSDZip"
clone https://github.com/mynotwo/A-Fast-Transformer-based-General-Purpose-LosslessCompressor.git \
                                                  "${SCRIPTS}/llc/trace/TRACE"
# NOTE: the URL referenced in the LLCBench paper for PAC
# (mynotwo/compressor_via_simple_and_scalable_parameterization) is an empty
# placeholder. The actual implementation lives in the DAC 2023 repo.
clone https://github.com/mynotwo/Faster-and-Stronger-Lossless-Compression-with-Optimized-Autoregressive-Framework.git \
                                                  "${SCRIPTS}/llc/pac/PAC"
clone https://github.com/mohit1997/DeepZip.git    "${SCRIPTS}/llc/deepzip/DeepZip"
clone https://github.com/mohit1997/Dzip-torch.git "${SCRIPTS}/llc/dzip/Dzip-torch"

cat <<'EOF'

────────────────────────────────────────────────────────────────────────────
✓ All baselines cloned.

Next steps — see envs/README.md for per-algorithm conda environments:

    # Build the native compressors that need compilation
    bash tools/build_native.sh

    # Create per-algorithm conda envs (only the ones you plan to run)
    bash envs/create_env.sh tlc_env       # bzip2/zstd/lzma/...     (no GPU)
    bash envs/create_env.sh fpmd_env      # FPZip/MPC/SPDP          (CPU+CUDA)
    bash envs/create_env.sh llmd_env      # ZipNN, FM-Delta         (CPU)
    bash envs/create_env.sh trace_env     # TRACE / PAC / MSDZip    (PyTorch 1.7, CUDA 11.1)
    bash envs/create_env.sh deepzip_env   # DeepZip                 (TF 1.8, Keras 2.2.2)
    bash envs/create_env.sh dzip_env      # DZip-torch              (PyTorch 1.4, Python 3.6)
────────────────────────────────────────────────────────────────────────────
EOF
