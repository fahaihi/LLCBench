# LLCBench — Per-Algorithm Install & Run Guide

This document collects the install and execute commands for every compressor
benchmarked in LLCBench. The command set comes directly from the paper's
Appendix A and is mirrored 1:1 in [`scripts/`](../scripts).

> **Wrapper contract.** Every `run.sh` accepts either:
> ```
> run.sh <input_file> <output_file>          # compression (default)
> run.sh -d <compressed_file> <output_file>  # decompression
> ```
> Wrappers print a single line of metrics to stdout in the form
> `algo,direction,input_size,output_size,wall_time_seconds,peak_rss_mb`.

---

## Floating-Point-Number-Driven (FPMD)

### SPDP

[Homepage](https://userweb.cs.txstate.edu/~burtscher/research/SPDPcompressor/)
— dictionary-based codec for FP32/FP64.

```bash
# Compression
./spdp 10 file file.spdp 2
# Decompression
./spdp 10 file.spdp file.out 2
```

### FPZip

[GitHub](https://github.com/llnl/fpzip) — Lorenzo-predictor based
floating-point compressor.

```bash
python scripts/fpmd/fpzip/fpzip.py compress   <file>  <file.fpz>
python scripts/fpmd/fpzip/fpzip.py decompress <file.fpz> <file.out>
```

### MPC

[FCBench MPC](https://github.com/hpdps-group/FCBench) — high-throughput
parallel compressor for FP data.

```bash
./MPC_double file 1        # compression
./MPC_double file.mpc      # decompression
```

---

## Large-Language-Model-Driven (LLMD)

### ZipNN

[GitHub](https://github.com/zipnn/zipnn) — type-aware lossless compressor
for AI tensors (Hershcovitch *et al.*, 2024).

```bash
python zipnn_compress_file.py   file
python zipnn_decompress_file.py file.znn
```

### FM-Delta

[GitHub](https://github.com/ningwanyi/FM-Delta) — reference-based delta
compression for fine-tuned LLMs (NeurIPS 2024).

```bash
python fmdela.py            # configurable; see fmdela.py --help
```

---

## Learning-Based Lossless Compression (LLC)

### MSDZip

[GitHub](https://github.com/huidong-ma/MSDZip) — neural multimodal compressor
(WWW 2025).

```bash
# Regular mode
python compress.py   <file>     <file>.mz       --prefix <prefix>
python decompress.py <file>.mz  <file>.mz.out   --prefix <prefix>

# Stepwise-parallel mode (faster on multi-core CPUs / multi-GPU)
bash sp-compress.sh   <file>    <file>.mz       <prefix> <parallel>
bash sp-decompress.sh <file>.mz <file>.mz.out   <prefix> <parallel>
```

### TRACE

[GitHub](https://github.com/mynotwo/A-Fast-Transformer-based-General-Purpose-LosslessCompressor)

```bash
python compressor.py --source file --comp file.trace
python compressor.py --comp file.trace --decomp file.trace.out
```

### PAC

[GitHub](https://github.com/mynotwo/compressor_via_simple_and_scalable_parameterization)

```bash
python compressor.py --source file --comp file.pac
python compressor.py --comp file.pac --decomp file.pac.out
```

### DeepZip

[GitHub](https://github.com/mohit1997/DeepZip) — RNN-based static compressor.

```bash
sh compress.sh   file        file.deepzip          bs model
sh decompress.sh file.deepzip file.deepzip.out      bs model
```

### DZip

[GitHub](https://github.com/mohit1997/Dzip-torch) — BiGRU+MLP semi-adaptive
compressor.

```bash
sh compress.sh   file        file.dzip          com model
sh decompress.sh file.dzip   file.dzip.out      com model
```

---

## Traditional Lossless Compression (TLC)

### LZMA / LZMA2 / PPMD (via 7-Zip)

```bash
# LZMA
lzma a -m0=lzma  -mx9 -mmt16 file.7z file
lzma x -y -mx9 -mmt          file.7z

# LZMA2
7zz a -m0=lzma2 -mx9 -mmt16 file.7z file
7zz x -y -mx9 -mmt16        file.7z

# PPMD
7zz a -m0=ppmd  -mx9 -mmt16 file.7z file
7zz x -y -mx9 -mmt16        file.7z
```

### LZOP

```bash
lzop -9 -f file -o file.lzop
lzop -df file.lzop -o file.lzop.out
```

### BZip2 / PBZip2

```bash
# BZip2
bzip2 -kzfc9 file > file.bz2
bzip2 -cdf  file.bz2 > file.bz2.out

# PBZip2 (parallel)
pbzip2 -9 -m2000 -p16 -c file > file.bz2
pbzip2 -dc -9 -p16 -m2000 file.bz2
```

### Lizard

```bash
lizard -49 -f file file.lizard -BD
lizard -df file.lizard file.lizard.out
```

### BSC

```bash
bsc e file file.bsc -e2
bsc d file.bsc file.bsc.out
```

### Brotli

```bash
brotli file -o file.brotli
brotli -d file.brotli -o file.brotli.out
```

### LZO

```bash
lzo -9  file file.lzo
lzo -d  file.lzo file.lzo.out
```

### PIGZ

```bash
pigz -cf -9 -p16 file        > file.pigz
pigz -dfc      -p16 file.pigz > file.pigz.out
```

### SnZip

```bash
snzip -k -t snzip file
snzip -kd -t snzip file.snz
```

### ZSTD

```bash
zstd -19 -f file        -o file.zstd
zstd -df file.zstd      -o file.zstd.out
```

### ZPAQ

```bash
zpaq a file.zpaq file -t16 -method 5
zpaq x file.zpaq      -method 5 -t 16
```

---

## Adding a new compressor

1. Drop a wrapper into `scripts/<class>/<myalgo>/run.sh` honouring the
   two-arg contract above.
2. Register the entry in `tools/run_benchmark.py::ALGO_REGISTRY`.
3. Append default hyper-parameters to `params.txt`.
4. Run `python tools/run_benchmark.py --algorithms myalgo` and submit a PR.
