#!/usr/bin/env python3
"""tools/run_benchmark.py — unified benchmark runner for LLCBench.

For every (algorithm, model) pair this script:

  1. Calls ``scripts/<class>/<algo>/run.sh <model> <out>`` for compression.
  2. Calls ``scripts/<class>/<algo>/run.sh -d <out> <restored>`` for
     decompression (when supported).
  3. Verifies the round-trip is *bit-for-bit* identical to the original.
  4. Records the canonical metrics line emitted by every wrapper.

The aggregated raw metrics are written to ``<output_dir>/raw_results.csv``,
which is later consumed by ``compute_metrics.py``.

Examples
--------

    # Run all algorithms on all models
    python tools/run_benchmark.py \\
        --models_dir ./models --algorithms all --output_dir ./results/run_local

    # Pick a subset
    python tools/run_benchmark.py \\
        --models_dir ./models \\
        --algorithms zipnn,zstd,lzma \\
        --output_dir ./results/run_subset
"""
from __future__ import annotations

import argparse
import csv
import filecmp
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parent.parent


@dataclass
class AlgoSpec:
    name: str
    category: str           # fpmd | llmd | llc | tlc
    suffix: str             # the file extension produced by compression
    extra_env: dict = field(default_factory=dict)
    skip_decompress: bool = False
    requires_gpu: bool = False

    @property
    def script(self) -> Path:
        return ROOT / "scripts" / self.category / self.name / "run.sh"


# Master registry. Adding a new compressor only requires extending this list.
ALGO_REGISTRY: list[AlgoSpec] = [
    # FPMD
    AlgoSpec("spdp",   "fpmd", ".spdp"),
    AlgoSpec("fpzip",  "fpmd", ".fpz"),
    AlgoSpec("mpc",    "fpmd", ".mpc"),
    # LLMD
    AlgoSpec("zipnn",  "llmd", ".znn"),
    AlgoSpec("fmdelta","llmd", ".fmd"),  # needs REFERENCE_FILE env var
    # LLC
    AlgoSpec("msdzip",  "llc", ".mz",     requires_gpu=True),
    AlgoSpec("trace",   "llc", ".trace",  requires_gpu=True),
    AlgoSpec("pac",     "llc", ".pac",    requires_gpu=True),
    AlgoSpec("deepzip", "llc", ".deepzip", requires_gpu=True),
    AlgoSpec("dzip",    "llc", ".dzip",   requires_gpu=True),
    # TLC
    AlgoSpec("lzma",    "tlc", ".7z"),
    AlgoSpec("lzma2",   "tlc", ".7z"),
    AlgoSpec("ppmd",    "tlc", ".7z"),
    AlgoSpec("lzop",    "tlc", ".lzop"),
    AlgoSpec("bzip2",   "tlc", ".bz2"),
    AlgoSpec("pbzip2",  "tlc", ".bz2"),
    AlgoSpec("lizard",  "tlc", ".lizard"),
    AlgoSpec("bsc",     "tlc", ".bsc"),
    AlgoSpec("brotli",  "tlc", ".brotli"),
    AlgoSpec("lzo",     "tlc", ".lzo"),
    AlgoSpec("pigz",    "tlc", ".pigz"),
    AlgoSpec("snzip",   "tlc", ".snz"),
    AlgoSpec("zstd",    "tlc", ".zstd"),
    AlgoSpec("zpaq",    "tlc", ".zpaq"),
]


def _run(cmd: list[str], env: dict | None = None) -> str:
    """Run *cmd* and return its stdout (one metrics line)."""
    proc = subprocess.run(
        cmd,
        check=False,
        env={**os.environ, **(env or {})},
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"command {shlex.join(cmd)} failed (rc={proc.returncode})\n"
            f"stdout: {proc.stdout}\nstderr: {proc.stderr}"
        )
    # last non-empty line is the metrics line
    last = [ln for ln in proc.stdout.strip().splitlines() if ln.strip()][-1]
    return last


def _list_models(models_dir: Path, dataset_filter: set[str] | None) -> list[Path]:
    candidates = sorted(p for p in models_dir.iterdir() if p.is_file())
    if dataset_filter:
        candidates = [
            p for p in candidates
            if p.stem in dataset_filter or p.name in dataset_filter
        ]
    return candidates


def benchmark_one(algo: AlgoSpec, model_path: Path, workdir: Path,
                  verify: bool) -> list[dict]:
    """Benchmark a single (algorithm, model) pair. Return rows for raw_results."""
    if not algo.script.exists():
        raise FileNotFoundError(algo.script)
    rows: list[dict] = []

    compressed = workdir / f"{model_path.stem}_{algo.name}{algo.suffix}"
    restored   = workdir / f"{model_path.stem}_{algo.name}.restored"

    # 1) compression
    line = _run(["bash", str(algo.script), str(model_path), str(compressed)],
                env=algo.extra_env)
    rows.append(_metrics_to_row(algo, model_path, line))

    if algo.skip_decompress:
        return rows

    # 2) decompression
    line = _run(["bash", str(algo.script), "-d", str(compressed), str(restored)],
                env=algo.extra_env)
    rows.append(_metrics_to_row(algo, model_path, line))

    # 3) round-trip verification
    if verify and not filecmp.cmp(model_path, restored, shallow=False):
        raise RuntimeError(f"{algo.name} round-trip mismatch on {model_path.name}")
    return rows


def _metrics_to_row(algo: AlgoSpec, model_path: Path, line: str) -> dict:
    parts = line.strip().split(",")
    if len(parts) != 6:
        raise ValueError(f"Bad metrics line for {algo.name}: {line!r}")
    return {
        "algorithm": parts[0],
        "model_id":  model_path.stem,
        "model":     model_path.name,
        "direction": parts[1],
        "input_bytes":  int(parts[2]),
        "output_bytes": int(parts[3]),
        "wall_seconds": float(parts[4]),
        "peak_rss_mb":  float(parts[5]),
    }


def main(argv: Iterable[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="LLCBench unified benchmark runner")
    parser.add_argument("--models_dir", required=True, help="Folder of LLM blobs")
    parser.add_argument("--algorithms", default="all",
                        help="Comma-separated algorithm names or 'all'")
    parser.add_argument("--datasets", default="all",
                        help="Comma-separated dataset stems (D0..D7) or 'all'")
    parser.add_argument("--output_dir", required=True, help="Where to write CSV results")
    parser.add_argument("--no_verify", action="store_true",
                        help="Skip round-trip verification (saves disk + time)")
    parser.add_argument("--continue_on_error", action="store_true",
                        help="Don't abort the whole run on a single algo failure")
    args = parser.parse_args(argv)

    output_dir = Path(args.output_dir).expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    raw_csv = output_dir / "raw_results.csv"

    # Resolve algorithm subset
    if args.algorithms.lower() == "all":
        algos = list(ALGO_REGISTRY)
    else:
        wanted = {x.strip().lower() for x in args.algorithms.split(",")}
        algos = [a for a in ALGO_REGISTRY if a.name.lower() in wanted]
        unknown = wanted - {a.name.lower() for a in algos}
        if unknown:
            print(f"WARN: unknown algorithms ignored: {sorted(unknown)}", file=sys.stderr)

    dataset_filter = None
    if args.datasets.lower() != "all":
        dataset_filter = {x.strip() for x in args.datasets.split(",") if x.strip()}

    models = _list_models(Path(args.models_dir).expanduser().resolve(), dataset_filter)
    if not models:
        sys.exit(f"No model files found in {args.models_dir}")

    write_header = not raw_csv.exists()
    with raw_csv.open("a", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=[
            "algorithm", "model_id", "model", "direction",
            "input_bytes", "output_bytes", "wall_seconds", "peak_rss_mb",
        ])
        if write_header:
            writer.writeheader()

        for algo in algos:
            for model_path in models:
                t0 = time.time()
                with tempfile.TemporaryDirectory(prefix=f"llcb_{algo.name}_") as tmp:
                    try:
                        rows = benchmark_one(
                            algo, model_path, Path(tmp), verify=not args.no_verify,
                        )
                    except Exception as exc:
                        print(f"[{algo.name} / {model_path.name}] FAILED: {exc}",
                              file=sys.stderr)
                        if not args.continue_on_error:
                            raise
                        continue
                for row in rows:
                    writer.writerow(row)
                fh.flush()
                print(f"[{algo.name} / {model_path.name}] done in {time.time()-t0:.1f}s")

    print(f"raw results -> {raw_csv}")


if __name__ == "__main__":
    main()
