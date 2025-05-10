# LLCBench

# A Comprehensive Review and Benchmark of Lossless Compression for Large Language Models

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

We benchmark on 28 widely studied datasets. 

These datasets contain various types of text, images, audio, genomic data, etc.
Please refer to our paper for detailed information about the data, and the details of how to obtain each dataset are given below.
The detailed link address of the benchmark datasets are as follows:

|ID|Name|Data Type|Size (Bytes)|Description|
|:---:|:---:|:---:|:---:|:---:|
|D1|[xml](https://sun.aei.polsl.pl//~sdeor/corpus/silesia.zip)|text|5345280 |Files in xml format|
|D2|[ooffice](https://sun.aei.polsl.pl//~sdeor/corpus/silesia.zip)|heterogeneous|6152192 |Files consisting of Office programs|
|D3|[reymont](https://sun.aei.polsl.pl//~sdeor/corpus/silesia.zip)|text|6627202 |A pdf file with the contents of Reymont's book|
|D4|[sao](https://sun.aei.polsl.pl//~sdeor/corpus/silesia.zip)|homogeneous|7251944 |Files containing information of 258,996 stars|
|D5|[x-ray](https://sun.aei.polsl.pl//~sdeor/corpus/silesia.zip)|image|8474240 |12-bit grayscale scaled x-ray medical image of a child's hand|
|D6|[mr](https://sun.aei.polsl.pl//~sdeor/corpus/silesia.zip)|image|9970564 |A magnetic resonance medical image of the head|
|D7|[osdb](https://sun.aei.polsl.pl//~sdeor/corpus/silesia.zip)|heterogeneous|10085684 |Open source database files for testing|
|D8|[dickens](https://sun.aei.polsl.pl//~sdeor/corpus/silesia.zip)|text|10192446 |Text file consisting of multiple novels by Dickens|

