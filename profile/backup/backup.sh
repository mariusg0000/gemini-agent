#!/usr/bin/env bash
# Back up the gemini-agent profile, launcher, and workspace into a single
# tarball placed in the user's home directory.
#
# Usage:
#   bash ~/.gemini-agent/backup/backup.sh [output-path]
set -euo pipefail

TS="$(date +%Y%m%d-%H%M%S)"
OUT="${1:-$HOME/gemini-agent-backup-$TS.tar.gz}"

AGENT_HOME="$HOME/.gemini-agent"
LAUNCHER="$HOME/.local/bin/gemini-agent"
WORKSPACE="$HOME/gemini-agent-workspace"

missing=0
for p in "$AGENT_HOME" "$LAUNCHER" "$WORKSPACE"; do
  if [ ! -e "$p" ]; then
    echo "WARN: missing $p" >&2
    missing=1
  fi
done
if [ "$missing" -ne 0 ]; then
  echo "Proceeding anyway with what exists..." >&2
fi

echo "Creating backup: $OUT"

tar czf "$OUT" \
  -C "$HOME" \
  --exclude='.gemini-agent/backup/*.tar.gz' \
  --exclude='gemini-agent-workspace/venv' \
  --exclude='gemini-agent-workspace/**/__pycache__' \
  --exclude='gemini-agent-workspace/**/*.pyc' \
  $( [ -d "$AGENT_HOME" ]  && echo ".gemini-agent" ) \
  $( [ -f "$LAUNCHER" ]    && echo ".local/bin/gemini-agent" ) \
  $( [ -d "$WORKSPACE" ]   && echo "gemini-agent-workspace" )

ls -lh "$OUT"

cat <<'EOF'

Backup done.

Next steps:
  1. Copy the tarball to safe storage (external disk, NAS, cloud).
  2. After a system reinstall, see:
     ~/.gemini-agent/backup/README.md
     or run: bash ~/.gemini-agent/backup/restore.sh
EOF
