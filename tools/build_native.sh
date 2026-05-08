#!/usr/bin/env bash
# tools/build_native.sh — build SPDP / FPZip / MPC binaries from cloned source.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
S="${REPO_ROOT}/scripts"

# --- SPDP (single C file) ---
if [[ -f "${S}/fpmd/spdp/SPDP_11.c" && ! -x "${S}/fpmd/spdp/spdp" ]]; then
    echo "→ building SPDP"
    cc -O3 -o "${S}/fpmd/spdp/spdp" "${S}/fpmd/spdp/SPDP_11.c"
fi

# --- FPZip CLI (CMake) ---
if [[ -d "${S}/fpmd/fpzip/upstream" && ! -x "${S}/fpmd/fpzip/upstream/build/utils/fpzip" ]]; then
    echo "→ building FPZip CLI"
    cmake -S "${S}/fpmd/fpzip/upstream" -B "${S}/fpmd/fpzip/upstream/build" \
          -DBUILD_TESTING=OFF -DBUILD_UTILITIES=ON >/dev/null
    cmake --build "${S}/fpmd/fpzip/upstream/build" -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)"
fi

# --- MPC (CUDA) ---
MPC_SRC_DIR="${S}/fpmd/mpc/FCBench/code/MPC"
if [[ -d "${MPC_SRC_DIR}" && ! -x "${S}/fpmd/mpc/MPC_double" ]]; then
    if command -v nvcc >/dev/null; then
        echo "→ building MPC_double via nvcc"
        ARCH="${CUDA_ARCH:-sm_75}"
        nvcc -O3 -arch="${ARCH}" \
             "${MPC_SRC_DIR}/MPC_double_12.cu" \
             -o "${S}/fpmd/mpc/MPC_double"
        nvcc -O3 -arch="${ARCH}" \
             "${MPC_SRC_DIR}/MPC_float_12.cu" \
             -o "${S}/fpmd/mpc/MPC_float" || true
    else
        echo "⚠ nvcc not found; skipping MPC build (it's GPU-only)."
    fi
fi

# --- FM-Delta (Cython + C++) ---
if [[ -d "${S}/llmd/fmdelta/FM-Delta" ]]; then
    cd "${S}/llmd/fmdelta/FM-Delta"
    if ! python3 -c "import fmd" 2>/dev/null; then
        echo "→ building FM-Delta (Cython + setup.py)"
        pip install -r requirements.txt
        cython -3 --fast-fail --cplus ./fmd.pyx
        python3 setup.py install --user
    fi
fi

echo "✓ native builds complete."
