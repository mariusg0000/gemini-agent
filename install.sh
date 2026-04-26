#!/usr/bin/env bash
# Install the gemini-agent profile, launcher, and workspace on this machine.
#
# Usage:
#   ./install.sh                 # safe install, never overwrites existing files
#   ./install.sh --force         # overwrite profile and workspace templates
#
# What it does:
#   - Verifies prerequisites (gemini, python3, python3-venv, ~/.local/bin in PATH).
#   - Copies `profile/` to ~/.gemini-agent/.
#   - Installs `bin/gemini-agent` to ~/.local/bin/gemini-agent.
#   - Copies `workspace/` to ~/gemini-agent-workspace/.
#   - Creates the Python venv and installs requirements.txt.
#   - Runs the `hello-env` sanity script.
#
# It NEVER touches ~/.gemini (the default Gemini CLI profile).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE=0
if [ "${1:-}" = "--force" ]; then
  FORCE=1
fi

msg() { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

msg "Checking prerequisites"

command -v gemini >/dev/null 2>&1 || die "gemini CLI not found on PATH. Install it first."
command -v python3 >/dev/null 2>&1 || die "python3 not found."
python3 -c "import venv" >/dev/null 2>&1 || die "python3 venv module not available. On Debian/Ubuntu: sudo apt install python3-venv. On Fedora: sudo dnf install python3 python3-pip"

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) warn "$HOME/.local/bin is not on PATH. Add it to your shell rc file." ;;
esac

AGENT_HOME="$HOME/.gemini-agent"
LAUNCHER="$HOME/.local/bin/gemini-agent"
WORKSPACE="$HOME/gemini-agent-workspace"

copy_tree() {
  local src="$1"
  local dst="$2"
  if [ -e "$dst" ] && [ "$FORCE" -eq 0 ]; then
    warn "Skipping $dst (already exists). Use --force to overwrite."
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  if [ "$FORCE" -eq 1 ] && [ -e "$dst" ]; then
    rm -rf "$dst"
  fi
  cp -R "$src" "$dst"
}

msg "Installing profile to $AGENT_HOME"
copy_tree "$REPO_DIR/profile" "$AGENT_HOME"

msg "Installing launcher to $LAUNCHER"
mkdir -p "$(dirname "$LAUNCHER")"
if [ -e "$LAUNCHER" ] && [ "$FORCE" -eq 0 ]; then
  warn "Skipping $LAUNCHER (already exists). Use --force to overwrite."
else
  cp "$REPO_DIR/bin/gemini-agent" "$LAUNCHER"
  chmod +x "$LAUNCHER"
fi

msg "Installing workspace to $WORKSPACE"
copy_tree "$REPO_DIR/workspace" "$WORKSPACE"

msg "Creating Python venv at $WORKSPACE/venv"
if [ ! -d "$WORKSPACE/venv" ]; then
  python3 -m venv "$WORKSPACE/venv"
fi

msg "Upgrading pip / setuptools / wheel"
"$WORKSPACE/venv/bin/pip" install --upgrade pip setuptools wheel >/dev/null

if [ -s "$WORKSPACE/requirements.txt" ] && grep -v '^\s*#' "$WORKSPACE/requirements.txt" | grep -q '[^[:space:]]'; then
  msg "Installing requirements"
  "$WORKSPACE/venv/bin/pip" install -r "$WORKSPACE/requirements.txt"
else
  msg "No requirements to install"
fi

msg "Running sanity check"
if [ -f "$WORKSPACE/scripts/hello-env/main.py" ]; then
  "$WORKSPACE/venv/bin/python" "$WORKSPACE/scripts/hello-env/main.py"
fi

cat <<'EOF'

Install complete.

Next steps:
  1. Open a new shell or ensure ~/.local/bin is on PATH.
  2. Run:        gemini-agent
     Authenticate when prompted. The default Gemini CLI (`gemini`) is untouched.
  3. Customize:
       ~/.gemini-agent/system.md
       ~/.gemini-agent/.gemini/GEMINI.md
       ~/.gemini-agent/.gemini/settings.json
       ~/.gemini-agent/.gemini/agents/*.md
       ~/gemini-agent-workspace/scripts.md
EOF
