<div align="center">
  <img src="docs/github-wide-logo.png" alt="LLCBench — LLM Lossless Compression Benchmark" width="100%"/>

# LLCBench

**LLMs Lossless Compression Benchmark — A Comprehensive Review and Benchmark of Lossless Compression for Large Language Models**

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/python-3.10%2B-blue.svg)](https://www.python.org/)
[![PyTorch](https://img.shields.io/badge/PyTorch-1.4%20%7C%201.7%20%7C%202.x-ee4c2c.svg)](https://pytorch.org/)
[![Hugging Face](https://img.shields.io/badge/🤗-models-yellow.svg)](https://huggingface.co/models)

</div>

> 📄 *Paper:* "**The State of Lossless Compression for Large Language Models:
> Methods, Benchmarks, and Future Directions**".

---

## 🎯 What this repository is

A **reproducible** benchmark for lossless compression of LLM weights. It does
**not** re-implement the 24 baselines — instead, it:

1. **Clones the official upstream repository of every baseline** (real code).
2. **Wraps each into a uniform CLI** so they can all be driven by one Python
   runner (`tools/run_benchmark.py`).
3. **Measures** compressed size, wall time, peak CPU/GPU memory, then
   aggregates them into the 10 paper metrics (AvgCR / WAvgCR / SSP / CRP
   / TotalCT / TotalDT / AvgCPM / AvgDPM / AvgGPM).
4. **Verifies** every (compressor, model) pair is bit-for-bit lossless via a
   round-trip check.

```
┌──────────────────┐  HF Hub   ┌─────────────────┐
│ download_models  │──────────▶│   ./models/*.bin │
└──────────────────┘           └────────┬────────┘
                                        │
                                        ▼
┌──────────────────┐  upstream ┌─────────────────┐  ┌──────────────┐
│ setup_baselines  │──────────▶│ scripts/<algo>/ │─▶│ run_benchmark │
└──────────────────┘  git clone└─────────────────┘  └──────┬───────┘
                                                            │ raw_results.csv
                                                            ▼
                                                  ┌──────────────────┐
                                                  │ compute_metrics  │  → overall.csv
                                                  │ plot_results     │  → 4 PNGs
                                                  └──────────────────┘
```

---

## ⚡ TL;DR — one-shot reproduction

```bash
git clone https://github.com/Fluorite-Eyes/LLCBench.git
cd LLCBench

# Reproduce the entire TLC + LLMD section on CPU (no GPU required, ~minutes):
bash envs/create_env.sh tlc_env
conda activate tlc_env
bash reproduce.sh tlc

# To reproduce the GPU-heavy LLC section (PyTorch 1.7 + CUDA 11.1, hours):
bash envs/create_env.sh trace_env
conda activate trace_env
bash reproduce.sh llc
```

`reproduce.sh` is just a thin orchestrator over the 5 individual steps in
the [Detailed workflow](#-detailed-workflow) section below.

---

## 🏆 Benchmark Results (from the paper)

| Method     |  AvgCR | WAvgCR | AvgSSP | WAvgSSP |   CRP  | TotalCT (h) | TotalDT (h) | AvgCPM (GB) | AvgDPM (GB) |
|------------|:------:|:------:|:------:|:-------:|:------:|:-----------:|:-----------:|:-----------:|:-----------:|
| **FM-Delta** 🥇 | **2.038** | **1.571** | **32.789** | **27.240** | 88.936 | 0.031 | 0.032 | 0.690 | 0.846 |
| MSDZip 🥈 | 1.494 | 1.420 | 26.466 | 24.630 | 40.681 | 115.142 | 114.258 | 13.413 | 14.215 |
| PAC 🥉    | 1.494 | 1.420 | 26.448 | 24.615 | 40.689 | 57.104  | 71.617  | 13.405 | 14.110 |
| ZPAQ      | 1.489 | 1.415 | 26.185 | 24.362 | 40.694 | 0.808   | 0.819   | 8.286  | 7.697  |
| TRACE     | 1.488 | 1.414 | 26.173 | 24.336 | 40.579 | 46.786  | 70.071  | 13.405 | 14.110 |
| DZip      | 1.449 | 1.395 | 24.346 | 23.688 | 39.638 | 232.644 | 81.540  | 15.008 | 8.848  |
| DeepZip   | 1.449 | 1.395 | 24.342 | 23.685 | 39.637 | 169.898 | 23.369  | 51.028 | 8.484  |
| BSC       | 1.434 | 1.361 | 22.711 | 20.862 | 42.677 | 0.029   | 0.020   | 4.479  | 2.561  |
| PPMD      | 1.378 | 1.307 | 19.305 | 17.329 | 43.456 | 1.051   | 1.118   | 0.257  | 0.256  |
| LZMA      | 1.373 | 1.306 | 19.827 | 17.952 | 40.969 | 0.671   | 0.061   | 0.667  | 0.069  |
| LZMA2     | 1.368 | 1.301 | 19.648 | 17.735 | 40.566 | 0.233   | 0.021   | 3.264  | 1.412  |
| Brotli    | 1.346 | 1.281 | 18.555 | 16.572 | 39.901 | 4.943   | 0.021   | 0.215  | 0.019  |
| ZipNN     | 1.314 | 1.276 | 19.901 | 18.528 | 27.155 | 0.008   | 0.006   | 3.164  | 1.799  |
| BZip2     | 1.343 | 1.272 | 16.650 | 14.586 | 45.006 | 0.193   | 0.102   | 0.007  | 0.005  |
| PBZip2    | 1.343 | 1.272 | 16.644 | 14.580 | 45.001 | 0.015   | 0.010   | 0.133  | 0.110  |
| MPC       | 1.292 | 1.244 | 17.933 | 16.205 | 30.803 | 0.004   | 0.004   | 1.506  | 1.506  |
| ZSTD      | 1.302 | 1.243 | 16.907 | 14.914 | 36.518 | 0.641   | 0.004   | 0.256  | 0.012  |
| PIGZ      | 1.256 | 1.208 | 15.539 | 13.662 | 30.702 | 0.017   | 0.010   | 0.014  | 0.002  |
| FPZip     | 1.124 | 1.130 | 10.761 | 11.125 | **6.163** | 0.040 | 0.036 | 0.897  | 0.879  |
| Lizard    | 1.176 | 1.118 |  8.025 |  5.522 | 37.262 | 0.368   | 0.004   | 0.170  | 0.040  |
| LZOP      | 1.136 | 1.095 |  7.513 |  5.487 | 27.904 | 0.237   | 0.004   | 0.002  | 0.002  |
| LZO       | 1.135 | 1.094 |  7.488 |  5.472 | 27.696 | 0.219   | 0.004   | 0.002  | 0.002  |
| SPDP      | 1.120 | 1.078 |  6.139 |  3.987 | 28.283 | 0.010   | 0.011   | 0.018  | 0.018  |
| SnZip     | 1.055 | 1.036 |  3.851 |  2.524 | 13.798 | 0.005   | 0.003   | 0.003  | 0.003  |

Per-algorithm breakdowns from the paper appendix (Tables B.7 – B.30) are
available in [`results/per_algorithm/`](results/per_algorithm).

---

## 🔬 Algorithms — wrappers around real upstream code

| Category | Compressor | Upstream repository | What env to use |
|----------|------------|---------------------|-----------------|
| FPMD | **MPC**     | [hpdps-group/FCBench](https://github.com/hpdps-group/FCBench) (`code/MPC`) | `fpmd_env` + `nvcc` |
| FPMD | **FPZip**   | [llnl/fpzip](https://github.com/llnl/fpzip) | `fpmd_env` |
| FPMD | **SPDP**    | [SPDP_11.c](https://userweb.cs.txstate.edu/~burtscher/research/SPDPcompressor/SPDP_11.c) | `fpmd_env` |
| LLMD | **FM-Delta**| [ningwanyi/FM-Delta](https://github.com/ningwanyi/FM-Delta) | `llmd_env` |
| LLMD | **ZipNN**   | [zipnn/zipnn](https://github.com/zipnn/zipnn) | `tlc_env` or `llmd_env` |
| LLC  | **MSDZip**  | [huidong-ma/MSDZip](https://github.com/huidong-ma/MSDZip) | `trace_env` |
| LLC  | **TRACE**   | [mynotwo/A-Fast-Transformer-…](https://github.com/mynotwo/A-Fast-Transformer-based-General-Purpose-LosslessCompressor) | `trace_env` |
| LLC  | **PAC**     | [mynotwo/Faster-and-Stronger-…](https://github.com/mynotwo/Faster-and-Stronger-Lossless-Compression-with-Optimized-Autoregressive-Framework) ⚠ ¹ | `trace_env` |
| LLC  | **DeepZip** | [mohit1997/DeepZip](https://github.com/mohit1997/DeepZip) | `deepzip_env` |
| LLC  | **DZip**    | [mohit1997/Dzip-torch](https://github.com/mohit1997/Dzip-torch) | `dzip_env` |
| TLC  | LZMA / LZMA2 / PPMD | 7-Zip CLI (`7zz`)                          | `tlc_env` |
| TLC  | LZOP        | [lzop.org](https://www.lzop.org/)                       | `tlc_env` |
| TLC  | BZip2 / PBZip2 | bzip2 + pbzip2                                       | `tlc_env` |
| TLC  | Lizard      | [inikep/lizard](https://github.com/inikep/lizard)       | `tlc_env` |
| TLC  | BSC         | [IlyaGrebnov/libbsc](https://github.com/IlyaGrebnov/libbsc) | `tlc_env` |
| TLC  | Brotli      | [google/brotli](https://github.com/google/brotli)       | `tlc_env` |
| TLC  | LZO         | [oberhumer.com](https://www.oberhumer.com/opensource/lzo/) | `tlc_env` |
| TLC  | PIGZ        | pigz                                                    | `tlc_env` |
| TLC  | SnZip       | [kubo/snzip](https://github.com/kubo/snzip)             | `tlc_env` |
| TLC  | ZSTD        | [facebook/zstd](https://github.com/facebook/zstd)       | `tlc_env` |
| TLC  | ZPAQ        | [mattmahoney.net/dc/zpaq](https://mattmahoney.net/dc/zpaq.html) | `tlc_env` |

> ¹ The URL referenced in the LLCBench paper for PAC
> (`mynotwo/compressor_via_simple_and_scalable_parameterization`) turned
> out to be a placeholder containing only "aaa". The DAC 2023 repo above is
> the real implementation (also referenced in MSDZip's acknowledgements).

---

## 📚 Detailed workflow

### 1. Clone every upstream baseline

```bash
bash tools/setup_baselines.sh
```

The cloned trees land under `scripts/<class>/<algo>/<UpstreamName>/` (each
wrapper picks them up via env vars — see the wrapper headers).

### 2. Build native binaries

```bash
bash tools/build_native.sh
```

Builds:
- **SPDP** (single-file C compile)
- **FPZip CLI** (CMake build under `scripts/fpmd/fpzip/upstream/build`)
- **MPC** via `nvcc` (`-arch=sm_75` by default — set `CUDA_ARCH=sm_89` for
  RTX 40 series).
- **FM-Delta** Cython extension via `python setup.py install --user`.

### 3. Download benchmark LLMs

```bash
python tools/download_models.py --output_dir ./models
```

Pulls 8 LLMs from Hugging Face and extracts the primary weight blob to
`./models/<id>.bin` so the compressors can operate on a single binary file
(matching the protocol used in the paper). See [`tools/download_models.py`](tools/download_models.py) for the URL list.

### 4. Run a benchmark

```bash
# All algorithms, all models
python tools/run_benchmark.py \
    --models_dir ./models \
    --algorithms all \
    --output_dir ./results/run_paper

# A subset
python tools/run_benchmark.py \
    --models_dir ./models \
    --algorithms zstd,lzma,zipnn,bzip2 \
    --output_dir ./results/run_quick
```

The runner emits `raw_results.csv` plus one row per (algorithm, model,
direction). Round-trip identity is verified (use `--no_verify` to skip).

### 5. Aggregate metrics & plot

```bash
python tools/compute_metrics.py --result_dir ./results/run_paper
python tools/plot_results.py    --result_dir ./results/run_paper
```

Produces:
- `overall.csv` — paper Table 3 reproduction
- `per_algorithm/<algo>.csv` — paper appendix Tables B.7–B.30
- `cr_bar.png`, `ssp_bar.png`, `scatter_cr_time.png`, `scatter_cr_mem.png`

---

## 📦 Conda environments

Several baselines pin **mutually incompatible** versions (DZip needs PyTorch
1.4 / Python 3.6.8; TRACE needs PyTorch 1.7 / CUDA 11.1; DeepZip needs
TF 1.x). We split things into 6 conda envs — see [`envs/README.md`](envs/README.md)
for the full matrix. Switch envs when running different algorithm families.

---

## 📐 Metrics

\[
\mathrm{AvgCR} = \tfrac{1}{n}\sum_{i=0}^{n-1}\frac{F^b_i}{F^a_i},
\quad
\mathrm{WAvgCR} = \sum_{i}\frac{F^b_i}{\sum_j F^b_j}\cdot\frac{F^b_i}{F^a_i}
\]
\[
\mathrm{SSP} = \left(1 - \frac{F^a_i}{F^b_i}\right)\times100\%,
\quad
\mathrm{CRP} = \frac{\sqrt{\sum_i (CR_i - CR_u)^2}}{\sqrt{n}\cdot CR_u}\times100\%
\]

Implemented in [`tools/compute_metrics.py`](tools/compute_metrics.py).

---

## 📦 Benchmark Datasets

| ID | Model | Size (B) | Description |
|----|-------|---------:|-------------|
| D0 | gpt2-medium-pubmed       | 1,418,253,632 | Biomedical text generation |
| D1 | bert-large-finetuned-ner | 1,337,252,416 | Token classification (NER) |
| D2 | Taiwan-ELM-270M-Instruct | 1,236,873,728 | Taiwanese instruction model |
| D3 | Qwen2.5-0.5B-Instruct    |   987,748,864 | Causal LM |
| D4 | git-base-fashion         |   706,479,488 | Vision–language (fashion) |
| D5 | SmolLM-135M-de           |   538,990,848 | German fine-tuned SLM |
| D6 | Comment-Moderation       |   267,641,344 | Moderation classifier |
| D7 | dinov2-small-finetuned   |    88,306,432 | Image classification |

---

## 🧪 Tested status

| Component | Status |
|-----------|--------|
| `tools/run_benchmark.py` round-trip on TLC `bzip2` | ✅ verified locally |
| `tools/compute_metrics.py` Table-3 metrics | ✅ matches paper to 3 d.p. |
| `tools/plot_results.py` (CR bar / SSP bar / scatters) | ✅ generates 4 PNGs |
| 24 algorithm wrappers (`bash -n` syntax) | ✅ |
| `tools/setup_baselines.sh` clone of all 9 git repos + SPDP | ✅ URLs verified live |
| LLC family on GPU | ⚠ requires `trace_env` / `dzip_env` (we cannot run them on macOS dev box) |

---

## 🤝 Contributing

1. Add a wrapper at `scripts/<class>/<algo>/run.sh` honouring the contract
   in [`scripts/_common.sh`](scripts/_common.sh):
   - `run.sh <input> <output>` for compression
   - `run.sh -d <input> <output>` for decompression
   - emit one CSV line: `algo,direction,in_bytes,out_bytes,wall_s,peak_rss_mb`
2. Register it in `tools/run_benchmark.py::ALGO_REGISTRY`.
3. Append the hyper-params to `params.txt`.
4. Open a PR with your overall.csv numbers.

---

## 📚 Citation

```bibtex
@article{sun2025llcbench,
  title  = {The State of Lossless Compression for Large Language Models:
            Methods, Benchmarks, and Future Directions},
  author = {Sun, Hui and Chen, Jiashun and Ma, Huidong and Xie, Haonan
            and Zhong, Cheng and Wang, Gang and Liu, Xiaoguang and Cai, Wentong},
  journal= {Knowledge-Based Systems},
  year   = {2025}
}
```

---

## 📄 License

Apache-2.0 — see [LICENSE](LICENSE). Each upstream baseline retains its own
license; LLCBench only ships *wrappers*, not their source code.
