#!/usr/bin/env python3
"""scripts/fpmd/fpzip/fpzip.py — FPZip wrapper.

FPZip (https://github.com/llnl/fpzip) is a Lorenzo-predictor based
floating-point compressor.  We use the official PyPI bindings:

    pip install fpzip

CLI:

    python fpzip.py compress   <input>  <output>
    python fpzip.py decompress <input>  <output>

Emits one CSV-formatted metrics line on stdout:

    fpzip,<direction>,<input_size>,<output_size>,<wall_seconds>,<peak_rss_mb>
"""
from __future__ import annotations

import argparse
import os
import resource
import struct
import sys
import time

import numpy as np

try:
    import fpzip
except ImportError as e:  # pragma: no cover - imported only when used
    sys.stderr.write("fpzip is required: pip install fpzip\n")
    raise


def _peak_rss_mb() -> float:
    rss_kb = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    # On Linux ru_maxrss is in KB, on macOS it is in bytes. Normalise to MB.
    if sys.platform == "darwin":
        return rss_kb / (1024 * 1024)
    return rss_kb / 1024.0


def _read_floats(path: str, dtype=np.float32) -> np.ndarray:
    with open(path, "rb") as fh:
        data = fh.read()
    n = len(data) // np.dtype(dtype).itemsize
    return np.frombuffer(data, dtype=dtype, count=n).reshape(1, 1, n)


def compress(src: str, dst: str) -> None:
    arr = _read_floats(src, dtype=np.float32)
    blob = fpzip.compress(arr, precision=0, order="C")  # lossless
    with open(dst, "wb") as fh:
        fh.write(struct.pack("<Q", arr.size))            # store length
        fh.write(blob)


def decompress(src: str, dst: str) -> None:
    with open(src, "rb") as fh:
        length = struct.unpack("<Q", fh.read(8))[0]
        blob = fh.read()
    arr = fpzip.decompress(blob, order="C").astype(np.float32)
    arr = arr.reshape(-1)[:length]
    with open(dst, "wb") as fh:
        fh.write(arr.tobytes())


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("direction", choices=["compress", "decompress"])
    parser.add_argument("src")
    parser.add_argument("dst")
    args = parser.parse_args()

    t0 = time.perf_counter()
    if args.direction == "compress":
        compress(args.src, args.dst)
    else:
        decompress(args.src, args.dst)
    wall = time.perf_counter() - t0
    rss = _peak_rss_mb()

    in_sz = os.path.getsize(args.src)
    out_sz = os.path.getsize(args.dst)
    print(f"fpzip,{args.direction},{in_sz},{out_sz},{wall:.3f},{rss:.2f}")


if __name__ == "__main__":
    main()
