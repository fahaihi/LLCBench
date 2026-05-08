#!/usr/bin/env python3
"""tools/tool.py — legacy helper kept from the original LLCBench repository.

This module historically contained a one-off plotting / data-massaging
utility shipped with the very first public version of LLCBench. It has been
superseded by ``compute_metrics.py`` + ``plot_results.py`` but is preserved
here for backward compatibility with users who depended on it.

Usage:

    python tools/tool.py --help
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import pandas as pd


def cmd_summarize(args: argparse.Namespace) -> None:
    """Prints a quick aggregate from a raw_results.csv file."""
    raw = pd.read_csv(args.input)
    comp = raw[raw["direction"] == "compress"]
    summary = comp.groupby("algorithm").agg(
        files=("model_id", "count"),
        avg_ratio=("input_bytes",
                   lambda s: (s / comp.loc[s.index, "output_bytes"]).mean()),
        total_seconds=("wall_seconds", "sum"),
    ).round(3)
    print(summary.sort_values("avg_ratio", ascending=False))


def cmd_filesize(args: argparse.Namespace) -> None:
    """Reports byte sizes of every file under a directory (sanity check)."""
    base = Path(args.path).expanduser().resolve()
    for p in sorted(base.rglob("*")):
        if p.is_file():
            print(f"{p.stat().st_size:>16}  {p}")


def main() -> None:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_sum = sub.add_parser("summarize", help="Print a summary of raw_results.csv")
    p_sum.add_argument("--input", required=True)
    p_sum.set_defaults(fn=cmd_summarize)

    p_ls = sub.add_parser("filesize", help="List file sizes under a directory")
    p_ls.add_argument("--path", required=True)
    p_ls.set_defaults(fn=cmd_filesize)

    args = parser.parse_args()
    args.fn(args)


if __name__ == "__main__":
    sys.exit(main())
