import argparse
import sys
import os
import numpy as np

def parseArgs(argv):
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(help='Tool Commands')
    # compare
    cmp_parser = subparsers.add_parser(name='cmp', help='Compare two files for consistency.')
    cmp_parser.add_argument('file1', type=str, help='File 1.')
    cmp_parser.add_argument('file2', type=str, help='File 2.')
    cmp_parser.set_defaults(func=cmp)
    # compression ratio
    cr_parser = subparsers.add_parser(name='cr', help='Compute compression ratio.')
    cr_parser.add_argument('file1', type=str, help='Source file.')
    cr_parser.add_argument('file2', type=str, help='Compressed file.')
    cr_parser.set_defaults(func=cr)
    # compare & cr
    p_parser = subparsers.add_parser(name='perform', help='Compare & Compute.')
    p_parser.add_argument('file1', type=str, help='Source file.')
    p_parser.add_argument('file2', type=str, help='Compressed file.')
    p_parser.add_argument('file3', type=str, help='Decompressed file.')
    p_parser.set_defaults(func=perform)
    # data
    p_parser = subparsers.add_parser(name='data', help='Generate data list in shell command.')
    p_parser.add_argument('dir', type=str, help='Source file dir.')
    p_parser.set_defaults(func=data)

    args = parser.parse_args(argv)
    args.func(args)
    return args

def compare(file1, file2):
    print(f"Comparing files: {file1} and {file2}")
    with open(file1, 'rb') as f:  # 一次一个byte = 8bit
        series1 = np.frombuffer(f.read(), dtype=np.uint8)
    f.close()
    with open(file2, 'rb') as f:  # 一次一个byte = 8bit
        series2 = np.frombuffer(f.read(), dtype=np.uint8)
    f.close()
    series1 = np.where(series1 == 13, 10, series1)
    series2 = np.where(series2 == 13, 10, series2)
    return np.array_equal(series1, series2)

def compute_cr(file1, file2):
    f1_size, f2_size = os.stat(file1).st_size, os.stat(file2).st_size
    return round(f2_size/f1_size*8, 5)

def cmp(args):      # 比较decompressed file与source file是否一直
    file1, file2 = args.file1, args.file2
    if compare(file1, file2):
        print('True')
    else:
        print('False')

def cr(args):       # 计算compressed file与source file之间的压缩率
    file1, file2 = args.file1, args.file2
    print('The compression ratio between <ori:{}> and <comp:{}> is {}.'.format(file1, file2, compute_cr(file1, file2)))

def perform(args):  # 比较source与decomp的一致性，计算source与comp的压缩率
    file1, file2, file3 = args.file1, args.file2, args.file3
    if compare(file1, file3):
        print('The file {} is the same as {}'.format(file1, file3))
    else:
        print('The file {} is different from {}'.format(file1, file3))
    print('The compression ratio between <ori:{}> and <comp:{}> is {}.'.format(file1, file2, compute_cr(file1, file2)))

def data(args):
    pwd = os.path.abspath(args.dir)
    file_info = list()
    for file in os.listdir(pwd):
        file_path = os.path.join(pwd, file)
        file_size = os.path.getsize(file_path)
        file_info.append((file_path, file_size))

    file_info.sort(key=lambda x:x[1])

    for i in range(len(file_info)):
        print(f'D{i+1}="{file_info[i][0]}"')
    print(' '.join([f'$D{i+1}' for i in range(len(file_info))]))

if __name__ == '__main__':
    parseArgs(sys.argv[1:])
