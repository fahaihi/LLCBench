#!/usr/bin/env bash
# reproduce.sh — end-to-end reproduction driver for the LLCBench paper.
#
# What it does (in order):
#   1. Clone every upstream baseline repository (tools/setup_baselines.sh).
#   2. Build native binaries:    SPDP, FPZip CLI, MPC (CUDA), FM-Delta (Cython).
#   3. Download benchmark LLMs from Hugging Face into ./models.
#   4. Run the requested algorithm subset with `tools/run_benchmark.py`.
#   5. Compute aggregate metrics & emit overall.csv + figures.
#
# Usage:
#   bash reproduce.sh                        # full reproduction (requires GPU env)
#   bash reproduce.sh tlc                    # only TLC + ZipNN  (CPU-only, fast)
#   bash reproduce.sh fpmd                   # FPZip / MPC / SPDP
#   bash reproduce.sh llmd                   # ZipNN + FM-Delta
#   bash reproduce.sh llc                    # MSDZip / TRACE / PAC / DeepZip / DZip
#   bash reproduce.sh "bzip2 zstd lzma"      # explicit space-separated algo list
#
# Environment variables:
#   MODELS_DIR=./models              where benchmark LLMs are stored
#   OUTPUT_DIR=./results/repro       where raw + aggregated results are written
#   SKIP_DOWNLOAD=1                  reuse existing models in $MODELS_DIR
#   SKIP_SETUP=1                     reuse cloned baselines

set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${HERE}"

MODELS_DIR="${MODELS_DIR:-${HERE}/models}"
OUTPUT_DIR="${OUTPUT_DIR:-${HERE}/results/repro}"
SUBSET="${1:-all}"

ALGOS_TLC="lzma lzma2 ppmd lzop bzip2 pbzip2 lizard bsc brotli lzo pigz snzip zstd zpaq"
ALGOS_FPMD="spdp fpzip mpc"
ALGOS_LLMD="zipnn fmdelta"
ALGOS_LLC="msdzip trace pac deepzip dzip"

case "${SUBSET}" in
    all)  ALGOS="${ALGOS_FPMD} ${ALGOS_LLMD} ${ALGOS_LLC} ${ALGOS_TLC}" ;;
    tlc)  ALGOS="${ALGOS_TLC} zipnn" ;;
    fpmd) ALGOS="${ALGOS_FPMD}" ;;
    llmd) ALGOS="${ALGOS_LLMD}" ;;
    llc)  ALGOS="${ALGOS_LLC}" ;;
    *)    ALGOS="${SUBSET}" ;;
esac

# ── 1. clone upstream baselines ────────────────────────────────────────────
if [[ -z "${SKIP_SETUP:-}" ]]; then
    echo "── (1/5) cloning upstream baselines"
    bash tools/setup_baselines.sh
fi

# ── 2. build native binaries ────────────────────────────────────────────────
echo "── (2/5) building native binaries (SPDP / FPZip / MPC / FM-Delta)"
bash tools/build_native.sh || echo "⚠ some builds skipped (e.g. no nvcc) — continuing"

# ── 3. download benchmark LLMs ──────────────────────────────────────────────
if [[ -z "${SKIP_DOWNLOAD:-}" ]]; then
    echo "── (3/5) downloading benchmark LLMs into ${MODELS_DIR}"
    python3 tools/download_models.py --output_dir "${MODELS_DIR}"
fi

# Convert HF model snapshots to flat float32 blobs (D0.bin … D7.bin).
ls "${MODELS_DIR}"/*.bin >/dev/null 2>&1 || {
    echo "❌ ${MODELS_DIR} contains no <id>.bin files — did the download succeed?"
    exit 1
}

# ── 4. run benchmark ────────────────────────────────────────────────────────
ALGO_CSV="$(echo ${ALGOS} | tr ' ' ',')"
echo "── (4/5) running benchmark for: ${ALGO_CSV}"
mkdir -p "${OUTPUT_DIR}"
python3 tools/run_benchmark.py \
    --models_dir "${MODELS_DIR}" \
    --algorithms "${ALGO_CSV}" \
    --output_dir "${OUTPUT_DIR}" \
    --continue_on_error

# ── 5. aggregate + plot ─────────────────────────────────────────────────────
echo "── (5/5) computing metrics & plotting figures"
python3 tools/compute_metrics.py --result_dir "${OUTPUT_DIR}"
python3 tools/plot_results.py    --result_dir "${OUTPUT_DIR}"

echo "✓ done. Open ${OUTPUT_DIR}/overall.csv and the *.png figures."
