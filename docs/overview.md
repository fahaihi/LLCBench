# LLCBench — Methodology & Metrics

This document complements the project README by describing **how** LLCBench
classifies compressors, **what** metrics it measures and **why** each metric
matters for Large Language Model storage and distribution.

---

## 1. Compressor Taxonomy

LLCBench groups every method into one of four orthogonal classes:

| Class | Idea | Pros | Cons | Examples |
|-------|------|------|------|----------|
| **FPMD**  | Operate directly on FP32 / BF16 / FP16 binary layout, exploiting bit-level redundancy in the *fraction*, *exponent*, *sign* fields. | Very fast, low memory. | Limited compression ratio. | FPZip, MPC, SPDP, BUFF |
| **LLMD**  | Tailored to LLM tensors. Two variants: *reference-based* (delta against a foundation model) and *non-reference-based* (type-aware grouping + entropy coding). | Highest compression ratio for fine-tuned models. | Reference-based methods need a base model; less flexible for from-scratch models. | FM-Delta, ZipNN, DFloat11, NeuZip |
| **LLC**   | Neural-network probability modelling + arithmetic coding. Static, dynamic and semi-adaptive variants. | Excellent compression ratio. | Compute and memory intensive. | DeepZip, DZip, PAC, TRACE, MSDZip |
| **TLC**   | General-purpose dictionary / transform / statistical coders. | Robust, well-tested, very fast on CPUs. | Plateaus on highly redundant model weights. | LZMA(2), ZSTD, ZPAQ, BSC, BZip2, PBZip2, Brotli, LZO(P), PIGZ, Lizard, SnZip, PPMD |

Concrete bibliography for every entry is in the paper (see Sec. 3).

---

## 2. Metrics

For each compressor and each model we record both **compressed size** and
**throughput / resource** statistics. From these primitives we compute:

* **AvgCR / WAvgCR** – arithmetic / weighted-mean compression ratio.
* **AvgSSP / WAvgSSP** – storage saving percentage.
* **CRP** – compression robustness, i.e. the coefficient of variation of
  per-model compression ratios. Lower is better.
* **TotalCT / TotalDT** – cumulative compression / decompression wall time.
* **AvgCPM / AvgDPM** – peak CPU memory of compression / decompression
  averaged over the 8 datasets.
* **AvgGPM** – peak GPU memory of compression for GPU-accelerated baselines.

The mathematical formulae are implemented (and documented) in
[`tools/compute_metrics.py`](../tools/compute_metrics.py).

---

## 3. Reproducibility Workflow

```text
    ┌──────────────────────┐
    │ download_models.py   │  pulls 8 LLMs from Hugging Face into ./models
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │ run_benchmark.py     │  picks each algorithm wrapper, calls compress
    │                      │  & decompress, writes raw_results.csv
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │ compute_metrics.py   │  AvgCR / WAvgCR / SSP / CRP / TotalCT / DT ...
    └──────────┬───────────┘
               │
               ▼
    ┌──────────────────────┐
    │ plot_results.py      │  emits radar / bar / scatter PNGs
    └──────────────────────┘
```

Each `run.sh` wrapper under `scripts/` follows the same I/O contract:

```
run.sh <input_file> <output_file>      # compression
run.sh -d <input_file.X> <output_file> # decompression
```

so that a new compressor can plug into the runner with zero code change.

---

## 4. Result Files

The `results/` folder contains the *exact* numbers reported in the paper:

```
results/
├── overall.csv              # Table 3 – aggregated metrics for all algorithms
├── gpu_memory.csv           # Table 5 – GPU peak memory of GPU baselines
└── per_algorithm/           # Tables B.7 – B.30 – per-algorithm breakdowns
    ├── deepzip.csv
    ├── dzip.csv
    ├── pac.csv
    └── ...
```

`per_algorithm/<algo>.csv` is keyed on dataset ID (D0-D7 / D9), with columns
`CS, CR, SSP, CT, CPM, DT, DPM`.

---

## 5. Hardware

The numbers in the paper were collected on the following machine:

* **OS** – Ubuntu 20.04.6 LTS
* **CPU** – 2 × Intel(R) Xeon(R) Gold 6248 @ 2.50 GHz (40 cores total)
* **GPU** – 6 × NVIDIA GeForce RTX 4090 24 GB
* **RAM** – 314 GB DDR4

Any modern Linux server should reproduce the FPMD / TLC / LLMD entries. GPU
is required for the LLC family.
