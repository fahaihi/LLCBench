#!/bin/bash
#source activate pt2
# Running benchmark template!
echo "1 设置实验参数，为了避免错误，使用绝对路径."
source "$(dirname "$(dirname "$(dirname "$(realpath "$0")")")")/params.txt"
AlgorithmPath=$CompressorDir"/traditional/lzo-2.10/temp"
Algorithm="lzo"

# 将时间戳转换为秒的函数
function timer_reans() {
    if [[ $1 == *"."* ]]; then
        local min=$(echo "$1" | cut -d ':' -f 1)
        local sec=$(echo "$1" | cut -d ':' -f 2 | cut -d '.' -f 1)
        local ms=$(echo "$1" | cut -d '.' -f 2)
        local result=$(echo $min $sec $ms | awk '{printf ("%.3f\n", 60*$1+$2+$3/1000+1)}')
        echo $result
    else
        local hour=$(echo "$1" | cut -d ':' -f 1)
        local min=$(echo "$1" | cut -d ':' -f 2)
        local sec=$(echo "$1" | cut -d ':' -f 3)
        local result=$(echo $hour $min $sec | awk '{printf ("%.3f\n",3600*$1+60*$2+$3+1.001)}')
        echo $result
    fi
}

echo "2 创建算法存储及工作目录"
mkresdir=${ResultDir}/${Algorithm}
if [ ! -d "$mkresdir" ]; then
    mkdir -p "$mkresdir"
    echo "Created directory: $directory"
else
    echo "Directory already exists: $directory"
fi
echo "Data,SourceSize (B),CompressedSize (B),CR (bits/base),CT (S),CM (KB),DT (S),DM (KB),Is_Same" > ${mkresdir}/${Algorithm}_${Threads}.csv

echo "3 执行算法压缩及解压缩操作"
for SourceDataDir in ${Datasets[@]}; do
    echo "-------------------------------------------------------------------------------------------"
    echo "SourceDataDir : ${SourceDataDir}"
    FileBaseName=$(basename ${SourceDataDir})   # data name
    echo $FileBaseName

    echo "3.1 将数据拷贝至工作目录下" # 避免脏数据
    cp ${SourceDataDir} ${AlgorithmPath}/${FileBaseName}.${Suffix} # 到算法源目录去执行

    echo "3.2 调用${Algorithm}进行文件压缩操作"
    echo "compression..."
    cd ${AlgorithmPath}
    (/bin/time -v -p lzo -9 ${FileBaseName}.${Suffix} ${FileBaseName}.lzo) >${mkresdir}/${FileBaseName}_${Threads}_com.log 2>&1

    echo "统计压缩信息"
    CompressedFileSize=$(ls -lah --block-size=1 ${FileBaseName}.lzo | awk '/^[-d]/ {print $5}')
    CompressionTime=$(cat ${mkresdir}/${FileBaseName}_${Threads}_com.log | grep -o 'Elapsed (wall clock) time (h:mm:ss or m:ss):.*' | awk '{print $8}')
    CompressionMemory=$(cat ${mkresdir}/${FileBaseName}_${Threads}_com.log | grep -o 'Maximum resident set size.*' | grep -o '[0-9]*')
    SourceFileSize=$(ls -lah --block-size=1 ${FileBaseName}.${Suffix} | awk '/^[-d]/ {print $5}')

    CompressionRatio=$(echo $CompressedFileSize $SourceFileSize | awk '{printf ("%.3f\n", 8*$1/$2)}')
    echo "CompressedFileSize : ${CompressedFileSize} B"
    echo "CompressionTime : ${CompressionTime} h:mm:ss or m:ss"
    echo "CompressionTime : $(timer_reans $CompressionTime) S"
    echo "CompressionMemory : ${CompressionMemory} KB"
    echo "SourceFileSize : ${SourceFileSize} B"
    echo "CompressionRatio : ${CompressionRatio} bits/base"

    echo "3.3 调用${Algorithm}进行文件解压缩操作"
    echo "de-compression..."
    (/bin/time -v -p lzo -d ${FileBaseName}.lzo ${FileBaseName}.lzo.${Suffix}) >${mkresdir}/${FileBaseName}_${Threads}_decom.log 2>&1
    echo "统计压缩信息"
    DeCompressionTime=$(cat ${mkresdir}/${FileBaseName}_${Threads}_decom.log | grep -o 'Elapsed (wall clock) time (h:mm:ss or m:ss):.*' | awk '{print $8}')
    DeCompressionMemory=$(cat ${mkresdir}/${FileBaseName}_${Threads}_decom.log | grep -o 'Maximum resident set size.*' | grep -o '[0-9]*')
    echo "DeCompressionTime : ${DeCompressionTime} h:mm:ss or m:ss"
    echo "DeCompressionTime : $(timer_reans $DeCompressionTime) S"
    echo "DeCompressionMemory : ${DeCompressionMemory} KB"

    echo "3.4 将结果存储在一个新的文件"
    echo "CompressedFileSize (B)  : ${CompressedFileSize}" >${mkresdir}/${FileBaseName}_${Threads}.log
    echo "CompressionRatio (bits/base): ${CompressionRatio}" >>${mkresdir}/${FileBaseName}_${Threads}.log
    echo "CompressionTime (S)     : $(timer_reans $CompressionTime)" >>${mkresdir}/${FileBaseName}_${Threads}.log
    echo "CompressionMemory (KB)  : ${CompressionMemory}" >>${mkresdir}/${FileBaseName}_${Threads}.log
    echo "DeCompressionTime (S)   : $(timer_reans $DeCompressionTime)" >>${mkresdir}/${FileBaseName}_${Threads}.log
    echo "DeCompressionMemory (KB): ${DeCompressionMemory}" >>${mkresdir}/${FileBaseName}_${Threads}.log

    echo "3.5 判断解压前后数据一致性"
    is_same=$(python ${ToolPath} cmp ${FileBaseName}.${Suffix} ${FileBaseName}.lzo.${Suffix})
    echo ${is_same}

    rm -rf ${FileBaseName}.${Suffix}
    rm -rf ${FileBaseName}.lzo
    rm -rf ${FileBaseName}.lzo.${Suffix}

    echo "3.6 将结果存储在CSV文件"
    echo "${FileBaseName},${SourceFileSize},${CompressedFileSize},${CompressionRatio},$(timer_reans $CompressionTime),${CompressionMemory},$(timer_reans $DeCompressionTime),${DeCompressionMemory},${is_same}" >> ${mkresdir}/${Algorithm}_${Threads}.csv
done
