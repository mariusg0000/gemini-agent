"""Print basic environment info for the Gemini Agent workspace."""
from __future__ import annotations

import os
import sys
from pathlib import Path


def main() -> int:
    workspace = Path(__file__).resolve().parents[2]
    print(f"python_executable: {sys.executable}")
    print(f"python_version: {sys.version.split()[0]}")
    print(f"venv_path: {workspace / 'venv'}")
    print(f"workspace_path: {workspace}")
    print(f"cwd: {os.getcwd()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
