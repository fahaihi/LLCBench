#!/usr/bin/env python3
"""scripts/llmd/fmdelta/fmdela.py — Driver around the upstream `fmd` package.

The upstream FM-Delta package (built from
https://github.com/ningwanyi/FM-Delta) installs a Python module named ``fmd``
exposing four core functions::

    fmd.compress_param(base_array,  finetuned_array, order='C')   -> bytes
    fmd.decompress_param(bytes_blob, base_array,    order='C')    -> array

We treat each model as a **flat float32 stream** (the format produced by
``tools/download_models.py``) and call the per-parameter API on the whole
file. This is identical to how the LLCBench paper measures FM-Delta on a
single contiguous binary blob.

CLI:

    python fmdela.py compress   --target <ft.bin>   --reference <base.bin> --output <delta>
    python fmdela.py decompress --delta  <delta>    --reference <base.bin> --output <restored>
"""
from __future__ import annotations

import argparse
import os
import resource
import sys
import time

import numpy as np


def _peak_rss_mb() -> float:
    rss = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    return rss / (1024 * 1024) if sys.platform == "darwin" else rss / 1024.0


def _import_fmd():
    try:
        import fmd  # type: ignore
    except ImportError:
        sys.stderr.write(
            "The 'fmd' module is required.\n"
            "Build & install it via:\n"
            "    cd scripts/llmd/fmdelta/FM-Delta\n"
            "    pip install -r requirements.txt\n"
            "    cython -3 --cplus ./fmd.pyx\n"
            "    python setup.py install\n"
        )
        raise
    return fmd


def _load_floats(path: str) -> np.ndarray:
    with open(path, "rb") as fh:
        data = fh.read()
    return np.frombuffer(data, dtype=np.float32)


def cmd_compress(args: argparse.Namespace) -> tuple[int, int, float]:
    fmd = _import_fmd()
    base = _load_floats(args.reference)
    target = _load_floats(args.target)
    if base.size != target.size:
        # Pad the shorter one so compress_param can still run; the wrapper
        # records the shape in the first 8 bytes for the decoder.
        n = max(base.size, target.size)
        base = np.pad(base,   (0, n - base.size))
        target = np.pad(target, (0, n - target.size))
    t0 = time.perf_counter()
    blob = fmd.compress_param(base, target, order="C")
    wall = time.perf_counter() - t0
    with open(args.output, "wb") as fh:
        fh.write(np.uint64(target.size).tobytes())
        fh.write(blob)
    return os.path.getsize(args.target), os.path.getsize(args.output), wall


def cmd_decompress(args: argparse.Namespace) -> tuple[int, int, float]:
    fmd = _import_fmd()
    base = _load_floats(args.reference)
    with open(args.delta, "rb") as fh:
        n = int(np.frombuffer(fh.read(8), dtype=np.uint64)[0])
        blob = fh.read()
    if base.size < n:
        base = np.pad(base, (0, n - base.size))
    base = base[:n]
    t0 = time.perf_counter()
    arr = fmd.decompress_param(blob, base, order="C").astype(np.float32)
    wall = time.perf_counter() - t0
    with open(args.output, "wb") as fh:
        fh.write(arr.tobytes())
    return os.path.getsize(args.delta), os.path.getsize(args.output), wall


def main() -> None:
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)

    pc = sub.add_parser("compress")
    pc.add_argument("--target", required=True)
    pc.add_argument("--reference", required=True)
    pc.add_argument("--output", required=True)

    pd = sub.add_parser("decompress")
    pd.add_argument("--delta", required=True)
    pd.add_argument("--reference", required=True)
    pd.add_argument("--output", required=True)

    args = p.parse_args()
    in_sz, out_sz, wall = (cmd_compress if args.cmd == "compress" else cmd_decompress)(args)
    print(f"fmdelta,{args.cmd},{in_sz},{out_sz},{wall:.3f},{_peak_rss_mb():.2f}")


if __name__ == "__main__":
    main()
