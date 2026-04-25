"""Template script for the Gemini Agent workspace.

Copy this folder to `scripts/<new-name>/`, rename, implement `run()`, and
register the script in `~/gemini-agent-workspace/scripts.md`.
"""
from __future__ import annotations

import argparse
import json
import sys


def run(args: argparse.Namespace) -> int:
    result = {"ok": True, "message": "replace me"}
    json.dump(result, sys.stdout)
    sys.stdout.write("\n")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Template script.")
    return parser


if __name__ == "__main__":
    sys.exit(run(build_parser().parse_args()))
