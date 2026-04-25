# Scripts Index

Registry of reusable scripts in `~/gemini-agent-workspace/scripts/`.
The agent must keep this file up to date: every new reusable script is added
here; deprecated scripts are marked or removed.

## Format

Each entry:

- Name: short slug
- Description: one line, what it does
- Input: CLI args / stdin / files it reads
- Output: stdout / files it writes
- Location: absolute path

## Entries

### hello-env

- Description: Prints Python version, venv path, and workspace path. Sanity check.
- Input: none
- Output: stdout (key: value lines)
- Location: `~/gemini-agent-workspace/scripts/hello-env/main.py`
