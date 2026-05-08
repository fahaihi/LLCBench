#!/usr/bin/env python3
"""tools/compute_metrics.py — Aggregate raw run results into the metrics
reported in the LLCBench paper.

Input
-----
A ``raw_results.csv`` file produced by :mod:`run_benchmark`. Required columns:

    algorithm, model_id, direction, input_bytes, output_bytes,
    wall_seconds, peak_rss_mb

Outputs (written next to the input)
-----------------------------------
* ``per_algorithm/<algo>.csv`` – per-model breakdown
  (CS, CR, SSP, CT, CPM, DT, DPM)
* ``overall.csv``              – AvgCR, WAvgCR, AvgSSP, WAvgSSP, CRP,
                                  TotalCT, TotalDT, AvgCPM, AvgDPM
"""
from __future__ import annotations

import argparse
import math
from pathlib import Path

import pandas as pd


def _per_algorithm_table(raw: pd.DataFrame) -> pd.DataFrame:
    """Transform raw rows into one row per (algorithm, model)."""
    comp = raw[raw["direction"] == "compress"].copy()
    deco = raw[raw["direction"] == "decompress"].copy()

    comp.rename(columns={
        "output_bytes": "compressed_bytes",
        "input_bytes":  "original_bytes",
        "wall_seconds": "ct_seconds",
        "peak_rss_mb":  "cpm_mb",
    }, inplace=True)
    deco.rename(columns={
        "wall_seconds": "dt_seconds",
        "peak_rss_mb":  "dpm_mb",
    }, inplace=True)

    merged = comp.merge(
        deco[["algorithm", "model_id", "dt_seconds", "dpm_mb"]],
        on=["algorithm", "model_id"], how="left",
    )
    merged["CS_MB"] = merged["compressed_bytes"] / (1024 * 1024)
    merged["CR"]    = merged["original_bytes"] / merged["compressed_bytes"]
    merged["SSP"]   = (1 - merged["compressed_bytes"] / merged["original_bytes"]) * 100
    merged["CT_h"]  = merged["ct_seconds"] / 3600
    merged["DT_h"]  = merged["dt_seconds"] / 3600
    return merged


def _overall_table(per_algo: pd.DataFrame) -> pd.DataFrame:
    """Compute aggregate metrics per algorithm (matches paper's Table 3)."""
    rows = []
    for algo, df in per_algo.groupby("algorithm"):
        n = len(df)
        weights = df["original_bytes"] / df["original_bytes"].sum()
        avg_cr   = df["CR"].mean()
        wavg_cr  = (weights * df["CR"]).sum()
        avg_ssp  = df["SSP"].mean()
        wavg_ssp = (weights * df["SSP"]).sum()
        # CRP = std(CR) / (sqrt(n) * mean(CR)) * 100
        crp = math.sqrt(((df["CR"] - avg_cr) ** 2).sum()) / (math.sqrt(n) * avg_cr) * 100
        rows.append({
            "Method":   algo,
            "AvgCR":    round(avg_cr, 3),
            "WAvgCR":   round(wavg_cr, 3),
            "AvgSSP":   round(avg_ssp, 3),
            "WAvgSSP":  round(wavg_ssp, 3),
            "CRP":      round(crp, 3),
            "TotalCT":  round(df["CT_h"].sum(), 3),
            "TotalDT":  round(df["DT_h"].sum(), 3),
            "AvgCPM":   round(df["cpm_mb"].mean() / 1024, 3),  # GB
            "AvgDPM":   round(df["dpm_mb"].mean() / 1024, 3),  # GB
        })
    return pd.DataFrame(rows).sort_values("AvgCR", ascending=False).reset_index(drop=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--result_dir", required=True,
                        help="Directory that contains raw_results.csv")
    args = parser.parse_args()

    result_dir = Path(args.result_dir).expanduser().resolve()
    raw_path = result_dir / "raw_results.csv"
    if not raw_path.exists():
        raise SystemExit(f"raw_results.csv not found under {result_dir}")

    raw = pd.read_csv(raw_path)
    per_algo = _per_algorithm_table(raw)

    per_dir = result_dir / "per_algorithm"
    per_dir.mkdir(exist_ok=True)
    for algo, df in per_algo.groupby("algorithm"):
        df_out = df[["model_id", "CS_MB", "CR", "SSP", "CT_h", "cpm_mb", "DT_h", "dpm_mb"]].copy()
        df_out.columns = ["ID", "CS(MB)", "CR", "SSP(%)", "CT(h)", "CPM(MB)", "DT(h)", "DPM(MB)"]
        df_out.to_csv(per_dir / f"{algo}.csv", index=False, float_format="%.4f")

    overall = _overall_table(per_algo)
    overall.to_csv(result_dir / "overall.csv", index=False)
    print(overall.to_string(index=False))
    print(f"\nPer-algorithm breakdown -> {per_dir}")
    print(f"Overall summary         -> {result_dir / 'overall.csv'}")


if __name__ == "__main__":
    main()
