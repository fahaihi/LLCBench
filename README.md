<!-- LOGO -->
<br />
<h1 align="center">
  <img src="https://github.com/Fluorite-Eyes/LLCBench/blob/main/logo.png" alt="Logo" width="821" height="350">
</h1>

# LLCBench

# LLMs Lossless Compression Benchmark - a Comprehensive Review and Benchmark of Lossless Compression for Large Language Models

## Overview

LLCBench is a benchmark and review suite dedicated to lossless compression of Large Language Models (LLMs). We systematically evaluate and categorize existing approaches—including 4 types: Floating-Point-Driven, LLM-Driven, Learning-based, and Traditional compressors. Our benchmark assesses Y lossless compressors on X real-world LLMs using 10 key performance metrics, such as compression ratio, throughput, and resource consumption. LLCBench aims to support research, sharing, and persistent storage of LLMs by offering a standardized and continuously updated evaluation platform.

## Benchmark Results
Performance comparison of different universal lossless compression tools on benchmark dataset.

| **Algorithm** | ***WavgCR*** | ***AvgCR*** | ***WavgSSP*** | ***AvgSSP*** | ***CRP***  | ***TotalCT*** | ***TotalDT*** | ***AvgCPM*** | ***AvgDPM*** |
|:-------------:|:------------:|:-----------:|:-------------:|:------------:|:----------:|:-------------:|:-------------:|:------------:|:------------:|
|               | (bits/base)  | (bits/base) | (\%)          | (\%)         | (\%)       | (Hour)        | (Hour)        | (GB)         | (GB)         |
| NNCP          | **4.183**    | **2.521**   | **47.713**    | **68.476**   | 13.084     | 942.928       | 926.049       | 0.111        | 0.111        |
| PAC           | **4.327**    | **2.638**   | **45.912**    | **67.019**   | 12.720     | 74.398        | 116.868       | 6.102        | 6.295        |
| TRACE         | **4.411**    | 2.718       | **44.867**    | 66.032       | 12.486     | 69.128        | 131.110       | 6.106        | 6.449        |
| DZip          | 4.494        | **2.516**   | 43.819        | **68.545**   | 14.272     | 332.787       | 148.374       | 10.113       | 4.790        |
| DZip*         | 4.562        | 3.802       | 42.971        | 52.476       | 11.158     | 332.787       | 148.374       | 10.113       | 4.790        |
| Lstm-compress | 5.395        | 2.786       | 32.563        | 65.168       | 14.543     | 492.869       | 474.498       | **0.009**    | **0.009**    |
| DeepZip*      | 16.835       | 7.045       | -110.434      | 11.933       | 18.504     | 250.714       | 52.449        | 13.708       | 4.292        |
| DeepZip       | 16.865       | 5.760       | -110.811      | 28.003       | 24.092     | 250.714       | 52.449        | 13.708       | 4.292        |
| BSC           | 4.826        | 2.928       | 39.677        | 63.394       | 13.045     | 0.353         | 0.300         | 0.121        | 0.116        |
| Lzma2         | 4.912        | 3.122       | 38.590        | 60.967       | 12.289     | 0.584         | 0.030         | 1.264        | 0.427        |
| XZ            | 4.923        | 3.118       | 38.463        | 61.021       | 12.365     | 0.879         | 0.040         | 1.612        | 0.504        |
| PPMD          | 4.960        | 3.025       | 38.001        | 62.181       | 12.934     | 0.893         | 0.953         | 0.226        | 0.225        |
| PBzip2        | 5.052        | 3.275       | 36.845        | 59.062       | 11.798     | **0.024**     | **0.016**     | 0.115        | 0.084        |
| Gzip          | 5.351        | 3.862       | 33.113        | 51.728       | **10.342** | 0.451         | 0.026         | **0.002**    | **0.002**    |
| LZ4-multi     | 5.618        | 4.280       | 29.770        | 46.501       | **9.656**  | **0.064**     | **0.009**     | 0.116        | 0.025        |
| SnZip         | 5.981        | 5.100       | 25.235        | 36.244       | **7.473**  | **0.031**     | **0.021**     | **0.003**    | **0.003**    |

**Notes.** "*" : Consideration of NN Model Size; 
"Avg/WavgCR (bits/base)" : Average OR Weighted Average Compression Ratio; 
"TotalCT/DT (Hours)" : Total Compression OR Decompression Time;
"AvgCPM/DPM (GB)" : Average Compression OR Decompression Peak Memory;
"Avg/WavgSSP (%)" : Average OR Weighted Average Storage Saving Percentage;
"CRP (%)" : Compression Robust Performance (%).

## Benchmark Datasets

We benchmark on 8 widely used large-scale models. These models cover a range of tasks including text generation, named entity recognition, instruction-following, vision-language understanding, multilingual language modeling, comment moderation, and image classification.

All models are publicly available on [Hugging Face](https://huggingface.co/).  
Please refer to our paper for more details about the datasets used in our benchmark, which include various types of text, images, audio, and genomic data. The specific links and acquisition methods for each dataset are provided below.

| ID  | Model Name                   | Model Size (B) | Short Description                              |
|-----|------------------------------|----------------|------------------------------------------------|
| D0  | Gpt2-medium-pubmed           | 1,418,253,632  | A finetuned biomedical text generation model   |
| D1  | Bert-large-finetuned-ner     | 1,337,252,416  | A finetuned token classification (NER) model   |
| D2  | Taiwan-ELM-270M-Instruct     | 1,236,873,728  | A collection of Taiwanese instruction models   |
| D3  | Qwen2.5-0.5B-Instruct        |   987,748,864  | A causal language model                        |
| D4  | Git-base-fashion             |   706,479,488  | A fashion vision-language model                |
| D5  | SmolLM-135M-de               |   538,990,848  | A finetuned language model for German          |
| D6  | Comment-Moderation           |   267,641,344  | A comment moderation model                     |
| D7  | Dinov2-small-finetuned       |    88,306,432  | A well-finetuned image classification model    |

## Algorithms Details

In our comparison examinations, we benchmarked 24 state-of-the-art lossless methods for LLMs compression, including FPMD-based MPC, FPZip, and SPDP; LLMD-based FM-Delta and ZipNN; LLC-based MSDZip, DeepZip, DZip, PAC and TRACE; as well as TLC-based LZMA, LZMA2, PPMD, LZOP, BZip2, PBZip2, Lizard, BSC, Brotli, LZO, PIGZ, SnZip, ZSTD, and ZPAQ.

All experiments were performed on a Ubuntu 20.04.6 LTS server featuring 2 Intel(R) Xeon(R) Gold 6248 CPUs (2.50GHz, 40 cores combined), 6 NVIDIA GeForce RTX 4090 GPUs(16,384 CUDA cores and 24GB memory each),and 314GB of DDR4 RAM.

## Algorithms details and commands

## Floating-Point-Number-Driven Method

### SPDP

**SPDP** ([https://userweb.cs.txstate.edu/\~burtscher/research/SPDPcompressor/](https://userweb.cs.txstate.edu/~burtscher/research/SPDPcompressor/)) (Single Precision Double Precision) is a dictionary-based lossless compression algorithm designed for both precision formats. It functions as either an HDF5 filter or an independent compression tool. The execution commands of SPSP are as follows:

```
# compression
./spdp 10 file file.spdp 2
# decompression
./spdp 10 file.spdp file.out 2
```

### FPZip

**FPZip** ([https://github.com/llnl/fpzip](https://github.com/llnl/fpzip)) is a versatile library and command-line tool designed for lossless and optionally lossy compression of 2D and 3D floating-point arrays. It is optimized for spatially correlated scalar data, such as regularly sampled continuous functions, but is not ideal for compressing unstructured floating-point data streams. The FPZip compression and decompression commands in this manuscript are as follows:

```
# compression and decompression
python fpzip.py
```

### MPC

**MPC** algorithm is a high-speed, lossless compression method optimized for GPUs and other parallel computing systems. Designed with minimal internal state, MPC achieves exceptional compression ratios across various datasets while significantly outperforming traditional CPU-based algorithms in throughput. Its innovative approach enables efficient real-time data compression, making it ideal for large-scale computing environments. The items reproduce MPC using algorithm scripts from **FCBench** ([https://github.com/hpdps-group/FCBench](https://github.com/hpdps-group/FCBench)). The execution commands are as follows:

```
# compression
./MPC_double file 1
# decompression
./MPC_double file.mpc
```

-----

## Large-Language-Models-Drive Method

### ZipNN

**ZipNN** ([https://github.com/zipnn/zipnn](https://github.com/zipnn/zipnn)) was proposed by Hershcovitch and Wood et al. in 2024. It is an open-source, CPU-based, lossless compressor for AI model tensors that applies type-aware optimizations. The working script and hyperparameters of ZipNN are as follows:

```
# compression
python zipnn_compress_file.py file
# decompression
python zipnn_decompress_file.py file.znn
```

### FM-Delta

**FM-Delta** ([https://github.com/ningwanyi/FM-Delta](https://github.com/ningwanyi/FM-Delta)) is a reference-based lossless compressor specifically designed for large model parameters, published at the NIPS 2024 conference. The working script and hyperparameters are as follows:

```
# compression and decompression
python fmdela.py
```

-----

## Learning-based Lossless Compression Method

### MSDZip

**MSDZip** ([https://github.com/mhuidong/MSDZip](https://github.com/mhuidong/MSDZip)) is the latest neural network-based multimodal data compressor, published at the WWW 2025 conference. Its execution script is as follows:

```
# compression
python compress.py file file.mz --prefix file --gpu 
# decompression
python decompress.py file.mz file.mz.out --prefix file --gpu
```

### TRACE

**TRACE** ([https://github.com/mynotwo/A-Fast-Transformer-based-General-Purpose-LosslessCompressor](https://github.com/mynotwo/A-Fast-Transformer-based-General-Purpose-LosslessCompressor)) is a lossless multimodal data compression algorithm built on the Transformer architecture, demonstrating strong performance in recompressing Large Language Models. The execution script of TRACE is as follows:

```
# compression
python compressor.py --source file --comp file.trace
# decompression
python compressor.py --comp file.trace --decomp file.trace.out
```

### PAC

**PAC** ([https://github.com/mynotwo/compressor\_via\_simple\_and\_scalable\_parameterization](https://www.google.com/search?q=https://github.com/mynotwo/compressor_via_simple_and_scalable_parameterization)) is a lossless multimodal data compression algorithm proposed by Mao et al., developed by the same team behind TRACE. It utilizes a context-based modeling approach, with its prediction component built upon a multilayer perceptron (MLP). The execution commands for PAC are as follows:

```
# compression
python compressor.py --source file --comp file.pac
# decompression
python compressor.py --comp file.pac --decomp file.pac.out
```

### DeepZip

**DeepZip** ([https://github.com/mohit1997/DeepZip](https://github.com/mohit1997/DeepZip)) is a static compression algorithm introduced by Goyal et al. in 2019, built upon an RNN-based architecture. Its compression process necessitates storing the trained model within the final output file. The execution script for DeepZip is as follows:

```
#compression
sh./compress.sh file file.deepzip bs model
#decompression
sh./decompress.sh file.deepzip file.deepzip.out bs model
```

### DZip

**DZip** ([https://github.com/mohit1997/Dzip-torch](https://github.com/mohit1997/Dzip-torch)), developed by the same team behind DeepZip, is an integrated compression solution based on BiGRU and MLP. In this work, DZip introduces a pioneering semi-adaptive lossless compression framework. The execution commands for DZip are as follows:

```
# compression
sh ./compress.sh file file.dzip com model
# decompression
sh ./decompress.sh file.dzip file.dzip.out com model
```

-----

## Traditional Lossless Compression Method

### LZMA

**LZMA** ([https://www.7-zip.org/sdk.html](https://www.7-zip.org/sdk.html)) (Lempel-Ziv-Markov chain algorithm) is an efficient data compression algorithm, originally developed by Igor Pavlov and implemented in the 7-Zip compression tool. It uses a dictionary coding mechanism, similar to the LZ77 algorithm, but generally achieves a higher compression ratio than Bzip2. The working script and hyperparameters of LZMA are as follows:

```
# compression
lzma a -m0=lzma -mx9 -mmt16 file.7z file
# decompression
lzma x -y -mx9 -mmt file.7z
```

### LZMA2

**LZMA2** Algorithm improves the multi-threading capability and performance of the LZMA algorithm and better handles incompressible data, so the compression performance is slightly improved. We also used the built-in Lzma2 algorithm in the 7-Zip application.

```
# compression
7zz a -m0=lzma2 -mx9 -mmt16 file.7z file
# decompression
7zz x -y -mx9 -mmt16 file.7z
```

### PPMD

**PPMD** is a context-based compression method, built upon the Partial Matching Prediction (PPM) algorithm introduced by Cleary and Witten. PPM employs statistical modeling by analyzing prior symbols in the input sequence to predict the next symbol, thereby reducing the entropy of the output data. Unlike dictionary-based compression, which encodes symbols by locating them within a predefined dictionary, PPM focuses on probabilistically predicting upcoming symbols. In our implementation, we utilize PPMD within 7-Zip to perform data compression.

```
# Compression
7zz a -m0=ppmd -mx9 -mmt16 file.7z file
# Decompression
7zz x -y -mx9 -mmt16 file.7z
```

### LZOP

**LZOP** ([https://www.lzop.org/](https://www.lzop.org/)) is a file compression tool that closely resembles GZip. It relies on the LZO data compression library to perform compression, offering significantly faster compression and decompression speeds compared to gzip, though with a slight trade-off in compression ratio.

```
# Compression
lzop -9 -f file -o file.lzop
# Decompression
lzop -df file.lzop -o file.lzop.out
```

### BZip2

**Bzip2** ([https://sourceware.org/bzip2/](https://sourceware.org/bzip2/)) is an open-source, patent-free data compression tool known for its high efficiency. It generally achieves file compression rates within 10% to 15% of the most advanced statistical compressors from the PPM family while offering approximately twice the compression speed and six times the decompression speed.

```
# Compression
bzip2 -kzfc9 file > file.bz2
# Decompression
bzip2 -cdf file.bz2 > file.bz2.out
```

### PBzip2

**PBzip2** ([https://linux.die.net/man/1/pbzip2](https://linux.die.net/man/1/pbzip2)) is a parallelized variant of the BZip2 block-sorting compression algorithm, designed to leverage pthreads for near-linear speedup on SMP systems.

```
# Compression
pbzip2 -9 -m2000 -p16 -c file > file.bz2
# Decompression
pbzip2 -dc -9 -p16 -m2000 file.bz2
```

### Lizard

**Lizard** ([https://github.com/inikep/lizard](https://github.com/inikep/lizard)) is a high-performance compression tool designed for rapid decompression. At low to medium compression levels, it delivers a compression ratio comparable to Zip/Zlib and Zstd/Brotli while maintaining exceptional decompression speed.

```
# Compression
lizard -49 -f file file.lizard -BD
# Decompression
lizard -df  file.lizard file.lizard.out
```

### BSC

**BSC** ([https://github.com/IlyaGrebnov/libbsc](https://github.com/IlyaGrebnov/libbsc)) is a high-performance file compressor utilizing a lossless block-ordered data compression algorithm. This manuscript employs BSC V3.3.2 for both compression and decompression tasks.

```
# Compression
bsc e file file.bsc -e2
# Decompression
bsc d file.bsc file.bsc.out
```

### Brotli

**Brotli** ([https://github.com/google/brotli](https://github.com/google/brotli)) is a versatile, lossless compression algorithm that integrates an advanced variant of LZ77, Huffman coding, and second-order context modeling. It delivers a compression ratio comparable to top-tier general-purpose methods while maintaining a speed similar to deflate but achieving more compact compression.

```
# Compression
brotli file -o file.brotli
# Decompression
brotli -d file.brotli -o file.brotli.out
```

### LZO

**LZO** ([https://www.oberhumer.com/opensource/lzo/](https://www.oberhumer.com/opensource/lzo/)) is a portable lossless data compression library written in ANSI C. LZO Offers pretty fast compression and extremely fast decompression.

```
# Compression
lzo -9 file file.lzo
# Decompression
lzo -d file.lzo file.lzo.out
```

### PIGZ

**PIGZ** ([https://linux.die.net/man/1/pigz](https://linux.die.net/man/1/pigz)) leverages multithreading to efficiently utilize multiple processors and cores for compression. It divides the input into 128 KB chunks, compressing each in parallel while simultaneously calculating individual check values. The compressed data is then sequentially written to the output, with a final combined check value derived from the individual calculations.

```
# Compression
pigz -cf -9 -p16 file > file.pigz
# Decompression
pigz -dfc -p16 file.pigz > file.pigz.out
```

### SnZip

**SnZip** ([https://github.com/kubo/snzip](https://github.com/kubo/snzip)) is a general-purpose, lossless compression algorithm built on snappy. It supports multiple file formats, including framing-format and old framing-format, with framing-format set as the default. The following command lines demonstrate how to use SnZip for compression and decompression.

```
# compression
snzip -k -t snzip file
# decompression
snzip -kd -t snzip file.snz
```

### ZSTD

**ZSTD** ([https://github.com/facebook/zstd](https://github.com/facebook/zstd)) is a high-speed, lossless compression algorithm designed for real-time applications, offering compression ratios that surpass zlib-level efficiency. It leverages an advanced entropy stage powered by Huff0 and the FSE library to enhance performance.

```
# Compression
zstd -19 -f file -o file.zstd
# Decompression
zstd -df file.zstd -o file.zstd.out
```

### ZPAQ

**ZPAQ** ([https://mattmahoney.net/dc/zpaq.html](https://mattmahoney.net/dc/zpaq.html)) is a free, open-source command-line archiver designed for Windows, Linux, and macOS. It supports incremental backups, meaning only files that have changed since the last backup are added, optimizing storage and backup speed. Additionally, its journaling feature ensures that previous versions remain accessible, allowing rollback to earlier states when needed.
