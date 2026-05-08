#!/usr/bin/env python3
"""tools/download_models.py — fetch the 8 LLCBench benchmark LLMs.

Models are downloaded from the Hugging Face Hub via ``huggingface_hub``.
Each model is stored in ``--output_dir/<dataset_id>/`` and the
``--single_file`` flag (default) extracts the largest model weight file
(``*.safetensors`` / ``*.bin``) so that compressors can operate on a single
binary blob (which is the protocol used in the paper).

Example:

    python tools/download_models.py --output_dir ./models
    python tools/download_models.py --output_dir ./models --models D3,D7

Note: gated models may require ``huggingface-cli login`` first.
"""
from __future__ import annotations

import argparse
import os
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

try:
    from huggingface_hub import snapshot_download
except ImportError as e:
    sys.stderr.write("huggingface_hub is required: pip install huggingface_hub\n")
    raise


@dataclass(frozen=True)
class ModelSpec:
    dataset_id: str
    repo_id: str
    description: str


# The list of benchmark models. Repo IDs are the most popular HF mirrors that
# match the description used in the paper (Table 2). Users may override the
# `repo_id` mapping by editing this file.
MODELS: tuple[ModelSpec, ...] = (
    ModelSpec("D0", "lvwerra/gpt2-imdb",                 "Fine-tuned biomedical text generation (GPT-2 medium proxy)"),
    ModelSpec("D1", "dslim/bert-large-NER",              "BERT-large fine-tuned for NER"),
    ModelSpec("D2", "liswei/Taiwan-ELM-270M-Instruct",   "Taiwanese instruction model"),
    ModelSpec("D3", "Qwen/Qwen2.5-0.5B-Instruct",        "Qwen 2.5 0.5B instruction"),
    ModelSpec("D4", "microsoft/git-base",                "GIT base (vision-language)"),
    ModelSpec("D5", "HuggingFaceTB/SmolLM-135M",         "SmolLM 135M (German fine-tune proxy)"),
    ModelSpec("D6", "KoalaAI/Text-Moderation",           "Comment moderation classifier"),
    ModelSpec("D7", "facebook/dinov2-small",             "DINO-v2 small image classifier"),
)


def _largest_blob(directory: Path) -> Path | None:
    candidates = list(directory.rglob("*.safetensors")) + list(directory.rglob("*.bin"))
    if not candidates:
        return None
    return max(candidates, key=lambda p: p.stat().st_size)


def download(model: ModelSpec, output_dir: Path, single_file: bool) -> Path | None:
    target = output_dir / model.dataset_id
    target.mkdir(parents=True, exist_ok=True)

    print(f"[{model.dataset_id}] downloading {model.repo_id} -> {target}")
    snapshot_path = Path(
        snapshot_download(
            repo_id=model.repo_id,
            local_dir=target,
            local_dir_use_symlinks=False,
            allow_patterns=[
                "*.json", "*.txt",
                "*.safetensors", "*.bin", "*.model", "tokenizer*",
            ],
        )
    )

    if single_file:
        blob = _largest_blob(snapshot_path)
        if blob is None:
            print(f"[{model.dataset_id}] WARN: no .safetensors / .bin found", file=sys.stderr)
            return None
        dest = output_dir / f"{model.dataset_id}.bin"
        if dest.exists():
            dest.unlink()
        shutil.copy(blob, dest)
        print(f"[{model.dataset_id}] kept primary blob -> {dest}")
        return dest
    return snapshot_path


def main(argv: Iterable[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Download LLCBench benchmark LLMs")
    parser.add_argument("--output_dir", required=True, help="Where to store models")
    parser.add_argument(
        "--models",
        default="ALL",
        help="Comma-separated dataset IDs (D0..D7), or 'ALL' (default)",
    )
    parser.add_argument(
        "--single_file",
        action="store_true",
        default=True,
        help="Extract the primary weight blob for benchmarking (default: True)",
    )
    parser.add_argument(
        "--keep_full_repo",
        action="store_true",
        help="Skip extraction; keep the entire HF repo on disk",
    )
    args = parser.parse_args(argv)

    output_dir = Path(args.output_dir).expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    requested = (
        {m.dataset_id for m in MODELS}
        if args.models.upper() == "ALL"
        else {m.strip().upper() for m in args.models.split(",") if m.strip()}
    )

    for spec in MODELS:
        if spec.dataset_id not in requested:
            continue
        try:
            download(spec, output_dir, single_file=not args.keep_full_repo)
        except Exception as exc:  # pragma: no cover
            print(f"[{spec.dataset_id}] FAILED: {exc}", file=sys.stderr)


if __name__ == "__main__":
    main()
