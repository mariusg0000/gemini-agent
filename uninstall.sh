#!/usr/bin/env bash
# Uninstall the gemini-agent profile, launcher, and (optionally) workspace.
#
# Usage:
#   ./uninstall.sh                 # interactive
#   ./uninstall.sh --yes           # non-interactive, removes all three targets
#   ./uninstall.sh --keep-workspace # keep ~/gemini-agent-workspace intact
#
# Never touches ~/.gemini (the default Gemini CLI profile).
set -euo pipefail

YES=0
KEEP_WS=0
for arg in "$@"; do
  case "$arg" in
    --yes) YES=1 ;;
    --keep-workspace) KEEP_WS=1 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

AGENT_HOME="$HOME/.gemini-agent"
LAUNCHER="$HOME/.local/bin/gemini-agent"
WORKSPACE="$HOME/gemini-agent-workspace"

confirm() {
  if [ "$YES" -eq 1 ]; then
    return 0
  fi
  read -r -p "$1 [y/N] " ans
  case "$ans" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

if [ -e "$LAUNCHER" ]; then
  if confirm "Remove launcher $LAUNCHER?"; then
    rm -f "$LAUNCHER"
    echo "Removed $LAUNCHER"
  fi
fi

if [ -d "$AGENT_HOME" ]; then
  if confirm "Remove profile $AGENT_HOME (includes settings, skills, agents, oauth_creds)?"; then
    rm -rf "$AGENT_HOME"
    echo "Removed $AGENT_HOME"
  fi
fi

if [ "$KEEP_WS" -eq 1 ]; then
  echo "Keeping workspace at $WORKSPACE."
elif [ -d "$WORKSPACE" ]; then
  if confirm "Remove workspace $WORKSPACE (includes your scripts, venv, logs, tasks)?"; then
    rm -rf "$WORKSPACE"
    echo "Removed $WORKSPACE"
  fi
fi

echo "Uninstall done. The default ~/.gemini profile was not touched."
