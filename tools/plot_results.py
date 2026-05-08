#!/usr/bin/env python3
"""tools/plot_results.py — turn ``overall.csv`` into figures.

Generates four PNGs under ``--result_dir``:

  * cr_bar.png            – AvgCR / WAvgCR bar chart
  * ssp_bar.png           – AvgSSP / WAvgSSP bar chart
  * scatter_cr_time.png   – Compression ratio vs total compression time
  * scatter_cr_mem.png    – Compression ratio vs CPU peak memory

The code only depends on pandas + matplotlib so it runs in any environment.
"""
from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd


def _bar(df: pd.DataFrame, cols: list[str], title: str, ylabel: str, out: Path) -> None:
    fig, ax = plt.subplots(figsize=(13, 5))
    df.plot(x="Method", y=cols, kind="bar", ax=ax)
    ax.set_title(title)
    ax.set_ylabel(ylabel)
    ax.set_xlabel("")
    ax.grid(axis="y", linestyle=":", alpha=0.4)
    plt.xticks(rotation=45, ha="right")
    plt.tight_layout()
    plt.savefig(out, dpi=150)
    plt.close(fig)


def _scatter(df: pd.DataFrame, x: str, y: str, title: str, xlabel: str, ylabel: str,
             out: Path, log_x: bool = False) -> None:
    fig, ax = plt.subplots(figsize=(8, 6))
    ax.scatter(df[x], df[y], s=60, alpha=0.8)
    for _, row in df.iterrows():
        ax.annotate(row["Method"], (row[x], row[y]),
                    textcoords="offset points", xytext=(5, 5), fontsize=8)
    if log_x:
        ax.set_xscale("symlog", linthresh=1e-3)
    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.grid(linestyle=":", alpha=0.4)
    plt.tight_layout()
    plt.savefig(out, dpi=150)
    plt.close(fig)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--result_dir", required=True)
    args = parser.parse_args()

    result_dir = Path(args.result_dir).expanduser().resolve()
    overall_csv = result_dir / "overall.csv"
    if not overall_csv.exists():
        raise SystemExit(f"overall.csv not found in {result_dir}; "
                         "run compute_metrics.py first")

    df = pd.read_csv(overall_csv)
    df = df.sort_values("AvgCR", ascending=False).reset_index(drop=True)

    _bar(df, ["AvgCR", "WAvgCR"], "Compression Ratio (higher is better)",
         "Ratio", result_dir / "cr_bar.png")
    _bar(df, ["AvgSSP", "WAvgSSP"], "Storage Saving Percentage (higher is better)",
         "Saving (%)", result_dir / "ssp_bar.png")
    # Accept both naming variants used by compute_metrics (TotalCT/AvgCPM)
    # and the canned paper CSV (TotalCT_h/AvgCPM_GB).
    ct_col = "TotalCT" if "TotalCT" in df.columns else "TotalCT_h"
    mem_col = "AvgCPM" if "AvgCPM" in df.columns else "AvgCPM_GB"
    _scatter(df, ct_col, "AvgCR",
             "Compression Ratio vs Total Compression Time",
             "Total Compression Time (hours)", "AvgCR",
             result_dir / "scatter_cr_time.png", log_x=True)
    _scatter(df, mem_col, "AvgCR",
             "Compression Ratio vs Avg Peak CPU Memory",
             "Avg CPU Peak Memory (GB)", "AvgCR",
             result_dir / "scatter_cr_mem.png", log_x=True)
    print(f"Figures written to {result_dir}")


if __name__ == "__main__":
    main()
