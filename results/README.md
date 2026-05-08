# LLCBench Results

This directory contains the **exact numbers** reported in the LLCBench
paper (Knowledge-Based Systems). They are committed alongside the code so
that downstream researchers can build on top of them without having to
re-run the entire benchmark (which takes >800 GPU-hours for the LLC family).

## Files

| File | Source | What it contains |
|------|--------|------------------|
| `overall.csv`           | Paper Table 3 | Aggregated 10-metric scores for 24 algorithms |
| `gpu_memory.csv`        | Paper Table 5 | Average peak GPU memory of GPU-accelerated baselines |
| `per_algorithm/<x>.csv` | Paper Tables B.7 – B.30 | Per-model breakdown for each algorithm |
| `cr_bar.png`            | Generated     | AvgCR / WAvgCR bar chart |
| `ssp_bar.png`           | Generated     | AvgSSP / WAvgSSP bar chart |
| `scatter_cr_time.png`   | Generated     | Compression ratio vs. total compression time |
| `scatter_cr_mem.png`    | Generated     | Compression ratio vs. peak CPU memory |

## Schema

`per_algorithm/<algo>.csv` rows are keyed by **dataset id** (D0..D9) and
contain:

| column     | unit | meaning                                |
|------------|------|----------------------------------------|
| `ID`       | –    | Dataset id (see paper Table 2)         |
| `CS(MB)`   | MB   | Compressed size                        |
| `CR`       | –    | Compression ratio (`original / compressed`) |
| `SSP(%)`   | %    | Storage saving percentage              |
| `CT(s)`    | s    | Compression wall time                  |
| `CT(h)`    | h    | Compression wall time (hours)          |
| `CPM(MB)`  | MB   | Peak CPU memory during compression     |
| `DT(s)`    | s    | Decompression wall time                |
| `DT(h)`    | h    | Decompression wall time (hours)        |
| `DPM(MB)`  | MB   | Peak CPU memory during decompression   |

## Reproducing the figures

```bash
python tools/plot_results.py --result_dir results/
```

## Reproducing the numbers from scratch

```bash
python tools/download_models.py --output_dir ./models
python tools/run_benchmark.py   --models_dir ./models --output_dir ./results/your_run
python tools/compute_metrics.py --result_dir ./results/your_run
python tools/plot_results.py    --result_dir ./results/your_run
```
