#!/bin/bash
#source activate pt2
echo "1 设置实验参数，为了避免错误，使用绝对路径."
source "$(dirname "$(dirname "$(dirname "$(realpath "$0")")")")/params.txt"
deepzip=$CompressorDir"/dl-based/deepzip"
dzip=$CompressorDir"/dl-based/dzip/"
GPU=0

# 将时间戳转换为秒
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

mkresdir=${ResultDir}/deepzip
# mk deepzip
if [ ! -d "$mkresdir" ]; then
    mkdir -p "$mkresdir"
    echo "Created directory: $directory"
else
    echo "Directory already exists: $directory"
fi
echo "Data,SourceSize (B),CompressedSize (B),CR (bits/base),CT (S),CM (KB),DT (S),DM (KB),Is_Same,ModelSize (B)" > ${mkresdir}/deepzip_${Threads}.csv

mkresdir=${ResultDir}/dzip
# mk dzip
if [ ! -d "$mkresdir" ]; then
    mkdir -p "$mkresdir"
    echo "Created directory: $directory"
else
    echo "Directory already exists: $directory"
fi
echo "Data,SourceSize (B),CompressedSize (B),CR (bits/base),CT (S),CM (KB),DT (S),DM (KB),Is_Same,ModelSize (B)" > ${mkresdir}/dzip_${Threads}.csv


echo "2 创建算法存储及工作目录"
# 创建一个写入记录的VCF文件
echo "3 执行算法压缩及解压缩操作"
for SourceDataDir in ${Datasets[@]}; do
    FileBaseName=$(basename ${SourceDataDir})
    # ======================================== DeepZip =======================================
    cp ${SourceDataDir} ${deepzip}/${FileBaseName}.${Suffix} # 到算法源目录去执行
    cd ${deepzip}
    algorithm="deepzip"
    mkresdir=${ResultDir}/${algorithm}

    echo "Copy dataset ${FileBaseName}"
    echo "Running ${algorithm}"
    echo "Compressing"
    (/bin/time -v -p sh ./compress.sh ${FileBaseName}.${Suffix} ${FileBaseName}.${algorithm} bs ${FileBaseName} ${GPU} ${FileBaseName}_temp) >${mkresdir}/${FileBaseName}_${Threads}_com.log 2>&1
    echo "统计压缩信息"
    CompressedFileSize=$(ls -lah --block-size=1 ${FileBaseName}.${algorithm}.combined | awk '/^[-d]/ {print $5}')
    ModelSize=$(stat -c %s ${FileBaseName})
    CompressedFileSize=$((CompressedFileSize + ModelSize))
    TrainingTime=$(cat ${FileBaseName}.${Suffix}.trainingtime)
    CompressionTime=$(cat ${mkresdir}/${FileBaseName}_${Threads}_com.log | grep -o 'Elapsed (wall clock) time (h:mm:ss or m:ss):.*' | awk '{print $8}')
    CompressionMemory=$(cat ${mkresdir}/${FileBaseName}_${Threads}_com.log | grep -o 'Maximum resident set size.*' | grep -o '[0-9]*')
    SourceFileSize=$(ls -lah --block-size=1 ${FileBaseName}.${Suffix} | awk '/^[-d]/ {print $5}') #以字节为单位显示原始文件大小
    CompressionRatio=$(echo $CompressedFileSize $SourceFileSize | awk '{printf ("%.3f\n", 8*$1/$2)}')

    echo "CompressedFileSize : ${CompressedFileSize} B"
    echo "CompressionTime : ${CompressionTime} h:mm:ss or m:ss"
    echo "CompressionTime : $(timer_reans $CompressionTime) S"
    echo "CompressionMemory : ${CompressionMemory} KB"
    echo "SourceFileSize : ${SourceFileSize} B"
    echo "CompressionRatio : ${CompressionRatio} bits/base"
    echo "ModelSize: ${ModelSize} B"

    echo "Decompressing"
    (/bin/time -v -p sh ./decompress.sh ${FileBaseName}.${algorithm} ${FileBaseName}.${algorithm}.${Suffix} bs ${FileBaseName} ${GPU} ${FileBaseName}_temp) >${mkresdir}/${FileBaseName}_${Threads}_decom.log 2>&1
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

    echo "3.5 判断解压前后数据一致性"
    is_same=$(python ${ToolPath} cmp ${FileBaseName}.${Suffix} ${FileBaseName}.${algorithm}.${Suffix})
    echo "${is_same}"
    rm -rf ${FileBaseName}.${Suffix}
#    rm -rf ${FileBaseName}.${algorithm}.combined
    rm -rf ${FileBaseName}.${algorithm}.${Suffix}
    rm -rf ${FileBaseName}.${algorithm}.params
    rm -rf ${FileBaseName}.${Suffix}.trainingtime
    echo "3.6 将结果存储在CSV文件"
    echo "${FileBaseName},${SourceFileSize},${CompressedFileSize},${CompressionRatio},$(timer_reans $CompressionTime),${CompressionMemory},$(timer_reans $DeCompressionTime),${DeCompressionMemory},${is_same},${ModelSize}" >> ${mkresdir}/${algorithm}_${Threads}.csv

    # ======================================== DZip =======================================
    cp ${SourceDataDir} ${dzip}/${FileBaseName}.${Suffix} # 到算法源目录去执行
    cp ${deepzip}/${FileBaseName} ${dzip}
    cp ${deepzip}/params_${FileBaseName} ${dzip}
    rm -rf ${FileBaseName}
    rm -rf params_${FileBaseName}
    cd ${dzip}
    algorithm="dzip"
    mkresdir=${ResultDir}/${algorithm}


    echo "Copy dataset ${FileBaseName}"
    echo "Running ${algorithm}"
    (/bin/time -v -p sh ./compress.sh ${FileBaseName}.${Suffix} ${FileBaseName}.${algorithm} com ${FileBaseName} ${GPU} ${FileBaseName}_temp) >${mkresdir}/${FileBaseName}_${Threads}_com.log 2>&1
    echo "统计压缩信息"
    CompressedFileSize=$(ls -lah --block-size=1 ${FileBaseName}.${algorithm}.combined | awk '/^[-d]/ {print $5}')
    CompressedFileSize=$((CompressedFileSize + ModelSize))
    CompressionTime=$(cat ${mkresdir}/${FileBaseName}_${Threads}_com.log | grep -o 'Elapsed (wall clock) time (h:mm:ss or m:ss):.*' | awk '{print $8}')
    CompressionTime=$(timer_reans $CompressionTime)
    CompressionTime=$(echo "scale=3; ($CompressionTime + $TrainingTime) / 1" | bc)
    CompressionMemory=$(cat ${mkresdir}/${FileBaseName}_${Threads}_com.log | grep -o 'Maximum resident set size.*' | grep -o '[0-9]*')
    SourceFileSize=$(ls -lah --block-size=1 ${FileBaseName}.${Suffix} | awk '/^[-d]/ {print $5}') #以字节为单位显示原始文件大小
    CompressionRatio=$(echo $CompressedFileSize $SourceFileSize | awk '{printf ("%.3f\n", 8*$1/$2)}')
    echo "CompressedFileSize : ${CompressedFileSize} B"
    echo "CompressionTime : ${CompressionTime} S"
    echo "CompressionMemory : ${CompressionMemory} KB"
    echo "SourceFileSize : ${SourceFileSize} B"
    echo "CompressionRatio : ${CompressionRatio} bits/base"

    echo "Decompressing"
    (/bin/time -v -p sh ./decompress.sh ${FileBaseName}.${algorithm} ${FileBaseName}.${algorithm}.${Suffix} com ${FileBaseName} ${GPU} ${FileBaseName}_temp) >${mkresdir}/${FileBaseName}_${Threads}_decom.log 2>&1
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

    echo "3.5 判断解压前后数据一致性"
    is_same=$(python ${ToolPath} cmp ${FileBaseName}.${Suffix} ${FileBaseName}.${algorithm}.${Suffix})

    rm -rf ${FileBaseName}
    rm -rf ${FileBaseName}.dzip.params
    rm -rf params_${FileBaseName}
    rm -rf ${FileBaseName}.${Suffix}
#    rm -rf ${FileBaseName}.${algorithm}.combined
    rm -rf ${FileBaseName}.${algorithm}.${Suffix}


    echo "3.6 将结果存储在CSV文件"
    echo "${FileBaseName},${SourceFileSize},${CompressedFileSize},${CompressionRatio},${CompressionTime},${CompressionMemory},$(timer_reans $DeCompressionTime),${DeCompressionMemory},${is_same},${ModelSize}" >> ${mkresdir}/${algorithm}_${Threads}.csv
done
