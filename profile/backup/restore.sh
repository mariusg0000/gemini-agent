#!/usr/bin/env bash
# Restore the gemini-agent setup after a fresh OS install.
#
# Assumes the backup tarball has already been extracted into $HOME, so that
# these paths exist:
#   ~/.gemini-agent
#   ~/.local/bin/gemini-agent
#   ~/gemini-agent-workspace
#
# Usage:
#   bash ~/.gemini-agent/backup/restore.sh
set -euo pipefail

AGENT_HOME="$HOME/.gemini-agent"
LAUNCHER="$HOME/.local/bin/gemini-agent"
WORKSPACE="$HOME/gemini-agent-workspace"

echo "Checking restored paths..."
for p in "$AGENT_HOME" "$LAUNCHER" "$WORKSPACE"; do
  if [ ! -e "$p" ]; then
    echo "ERROR: missing $p" >&2
    echo "Extract the backup tarball into \$HOME first." >&2
    exit 1
  fi
done

echo "Ensuring launcher is executable..."
chmod +x "$LAUNCHER"

echo "Rebuilding Python venv at $WORKSPACE/venv ..."
if [ -d "$WORKSPACE/venv" ]; then
  rm -rf "$WORKSPACE/venv"
fi
python3 -m venv "$WORKSPACE/venv"

echo "Upgrading pip..."
"$WORKSPACE/venv/bin/pip" install --upgrade pip setuptools wheel

if [ -s "$WORKSPACE/requirements.txt" ] && grep -v '^\s*#' "$WORKSPACE/requirements.txt" | grep -q '[^[:space:]]'; then
  echo "Installing requirements..."
  "$WORKSPACE/venv/bin/pip" install -r "$WORKSPACE/requirements.txt"
else
  echo "No requirements to install."
fi

echo "Running sanity script hello-env..."
if [ -f "$WORKSPACE/scripts/hello-env/main.py" ]; then
  "$WORKSPACE/venv/bin/python" "$WORKSPACE/scripts/hello-env/main.py"
else
  echo "WARN: hello-env not found; skipping sanity run." >&2
fi

cat <<'EOF'

Restore complete.

Checks to run manually:
  gemini --version
  gemini-agent --version
  gemini-agent            # start a session; reauthenticate if prompted

If authentication fails, delete:
  ~/.gemini-agent/.gemini/oauth_creds.json
and run gemini-agent again.
EOF
