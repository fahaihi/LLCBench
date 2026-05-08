# Per-Algorithm Conda Environments

LLCBench reproduces 24 baselines, several of which pin **mutually
incompatible** versions of PyTorch / TensorFlow. To keep things sane each
algorithm family lives in its own conda env:

| Env | What runs in it | Key pins |
|-----|-----------------|----------|
| `tlc_env`     | All 14 TLC compressors **and** ZipNN | Python 3.10, generic |
| `fpmd_env`    | FPZip (Python bindings), SPDP & MPC build toolchain | Python 3.10, cmake, cython |
| `llmd_env`    | ZipNN + FM-Delta build deps          | Python 3.10, cython |
| `trace_env`   | TRACE, PAC, MSDZip                   | **PyTorch 1.7 + CUDA 11.1** |
| `deepzip_env` | DeepZip                              | TensorFlow 1.15 + Keras 2.2 |
| `dzip_env`    | DZip-torch                           | **Python 3.6.8 + PyTorch 1.4** |

## Quick start

```bash
# Install conda (or mamba) first if you don't have it.

bash envs/create_env.sh tlc_env
conda activate tlc_env
python tools/run_benchmark.py --models_dir ./models \
    --algorithms bzip2,zstd,lzma,brotli,zipnn \
    --output_dir ./results/run_tlc

# Switch envs to run the GPU-heavy LLCs
conda deactivate
bash envs/create_env.sh trace_env
conda activate trace_env
python tools/run_benchmark.py --models_dir ./models \
    --algorithms trace,pac,msdzip \
    --output_dir ./results/run_llc
```

## Notes / caveats

- **MPC** (FPMD) needs an NVIDIA GPU with `nvcc`. We default to `sm_75`
  (RTX 20-series). Set `CUDA_ARCH=sm_86` (RTX 30-series) or `sm_89`
  (RTX 40-series) before running `tools/build_native.sh` if needed.
- **DeepZip / DZip** were authored against very old toolchains (TF 1.8,
  PyTorch 1.4); we use the closest still-installable versions. If a
  compressor reports "operation not implemented" on a modern GPU, run it
  on CPU by setting `CUDA_VISIBLE_DEVICES=`.
- **FM-Delta** is a Cython package — `tools/build_native.sh` will build &
  install it into the active env.

## Why no single mega-env?

Because:
* TF 1.x and TF 2.x cannot coexist.
* PyTorch 1.4 (Python ≤3.6.8) cannot coexist with PyTorch 1.7 (≥3.7).
* DZip's authors hard-pin `numpy<1.18` while TRACE wants `numpy==1.18.5`.

Splitting things by env is the only sustainable way; this is also what the
LLCBench paper authors do internally.
