# Gemini Agent: backup and restore

This file documents why `gemini-agent` exists, what it consists of, and how to
back it up and restore it across a system reinstall (Ubuntu, Debian, or Fedora).

---

## 1. Why this setup exists

We have two independent Gemini CLI profiles on the same machine:

- `gemini` (default): original setup, used for coding.
  Lives in `~/.gemini/`. Untouched by this setup.
- `gemini-agent`: a second profile used as a general-purpose autonomous agent.
  Uses Python scripting from a dedicated workspace.

The goal was to avoid polluting the clean coding setup with skills, MCP servers,
or agentic tooling. Profiles are isolated via `GEMINI_CLI_HOME`, and the
agentic system prompt is injected via `GEMINI_SYSTEM_MD`.

## 2. Architecture

```
~/.gemini/                      original profile, coding (not modified)
~/.gemini-agent/                agentic profile
  .gemini/
    settings.json               enables skills + subagents
    GEMINI.md                   context, conventions for agent
    skills/                     user skills for this profile
    agents/                     subagent definitions (python-runner, ...)
    oauth_creds.json            auth token (may need re-auth after restore)
    trustedFolders.json         trusted workspaces
    projects.json               project mapping
  system.md                     system prompt override for the agent
  backup/                       this folder
~/.local/bin/gemini-agent       launcher (sets GEMINI_CLI_HOME + GEMINI_SYSTEM_MD)
~/gemini-agent-workspace/       Python workspace used by the agent
  venv/                         dedicated venv (rebuildable)
  scripts/<name>/               reusable scripts, one folder per script
  scripts.md                    index of registered scripts
  tasks/                        scratch area per task
  data/                         outputs
  logs/                         logs
  requirements.txt              Python deps (source of truth)
  README.md                     workspace description
```

Invocation flow:

1. `gemini-agent` launcher exports `GEMINI_CLI_HOME=~/.gemini-agent`
   and `GEMINI_SYSTEM_MD=~/.gemini-agent/system.md`, then runs `gemini`.
2. Gemini CLI loads settings from `~/.gemini-agent/.gemini/`.
3. Gemini CLI uses `system.md` instead of the built-in system prompt.
4. The agent follows workspace conventions from `GEMINI.md`.

## 3. Prerequisites after a reinstall

Before restoring, on the fresh system:

1. Install Gemini CLI. Typical install on Ubuntu/Debian:
   ```
   # one of:
   npm install -g @google/gemini-cli
   # or use your preferred install method
   ```
2. Make sure `gemini` is on PATH and works:
   ```
   gemini --version
   ```
3. Make sure `~/.local/bin` is on PATH. On Ubuntu/Debian this is usually
   auto-handled in `~/.profile`. Verify:
   ```
   echo $PATH | tr ':' '\n' | grep -F "$HOME/.local/bin"
   ```
4. Install Python 3 with venv support:
   ```
   sudo apt install -y python3 python3-venv python3-pip
   ```

## 4. Backup procedure

### Automatic (recommended)

Run the backup helper before reinstalling:

```
bash ~/.gemini-agent/backup/backup.sh
```

This creates a single tarball at:

```
~/gemini-agent-backup-YYYYMMDD-HHMMSS.tar.gz
```

It includes:

- `~/.gemini-agent/` (everything except `backup/*.tar.gz`)
- `~/.local/bin/gemini-agent` launcher
- `~/gemini-agent-workspace/` excluding `venv/`, `__pycache__/`, and empty
  `logs/` / `tasks/` by default

It does NOT include:

- `~/.gemini/` (original coding profile). If you also want that, back it up
  separately: `tar czf ~/.gemini-backup.tar.gz -C ~ .gemini`.

After the tarball is created, copy it to safe storage (external disk, NAS,
cloud, etc.) BEFORE reinstalling.

### Manual alternative

If you prefer full manual control:

```
tar czf ~/gemini-agent-backup.tar.gz \
  -C "$HOME" \
  --exclude='.gemini-agent/backup/*.tar.gz' \
  --exclude='gemini-agent-workspace/venv' \
  --exclude='gemini-agent-workspace/**/__pycache__' \
  .gemini-agent \
  .local/bin/gemini-agent \
  gemini-agent-workspace
```

## 5. Restore procedure

### Automatic (recommended)

After reinstall, with the tarball placed at `~/gemini-agent-backup.tar.gz`
(rename yours to this, or pass a custom path):

```
tar xzf ~/gemini-agent-backup.tar.gz -C "$HOME"
bash ~/.gemini-agent/backup/restore.sh
```

`restore.sh` will:

- make `~/.local/bin/gemini-agent` executable
- recreate `~/gemini-agent-workspace/venv`
- install from `requirements.txt` if present
- run the `hello-env` sanity script
- print next steps

### Manual alternative

```
tar xzf ~/gemini-agent-backup.tar.gz -C "$HOME"
chmod +x ~/.local/bin/gemini-agent

python3 -m venv ~/gemini-agent-workspace/venv
~/gemini-agent-workspace/venv/bin/pip install --upgrade pip
~/gemini-agent-workspace/venv/bin/pip install -r ~/gemini-agent-workspace/requirements.txt
~/gemini-agent-workspace/venv/bin/python ~/gemini-agent-workspace/scripts/hello-env/main.py
```

## 6. Post-restore checks

- `gemini --version` works.
- `gemini-agent --version` works.
- `hello-env` script prints the expected paths.
- Start a session: `gemini-agent`. If `oauth_creds.json` is stale, authenticate
  again when prompted. Tokens can be revoked or tied to the previous device;
  re-auth is normal.
- Check that the system prompt is loaded: inside the session run `/memory show`
  (for context files) and confirm `GEMINI.md` from `~/.gemini-agent/.gemini/` is
  active. The system prompt override is silent; trust that it loaded if
  `gemini-agent` started without errors.

## 7. Troubleshooting

- `gemini-agent: command not found`
  - Check `ls ~/.local/bin/gemini-agent` and its exec bit.
  - Check that `~/.local/bin` is on PATH.
- `missing system prompt file` error
  - The file `~/.gemini-agent/system.md` is missing. Restore from backup.
- Scripts in venv fail to run
  - Recreate the venv; it contains absolute paths and may break after OS
    reinstall:
    ```
    rm -rf ~/gemini-agent-workspace/venv
    python3 -m venv ~/gemini-agent-workspace/venv
    ~/gemini-agent-workspace/venv/bin/pip install -r ~/gemini-agent-workspace/requirements.txt
    ```
- Authentication errors
  - Delete `~/.gemini-agent/.gemini/oauth_creds.json` and re-run
    `gemini-agent` to trigger a fresh login.

## 8. Maintenance notes

- Keep `requirements.txt` honest. When the agent installs a new package in the
  venv, record it. Otherwise restore cannot rebuild the environment.
- Keep `scripts.md` in sync: one entry per reusable script under
  `scripts/<slug>/` with name, description, inputs, outputs, location.
- Re-run `backup.sh` periodically, not only before reinstall.
- The `backup/` folder itself is also backed up so future-you has the docs
  and the scripts included in the tarball.

## 9. Subagents

Subagents are stored as Markdown files with YAML frontmatter under:

```
~/.gemini-agent/.gemini/agents/*.md
```

Currently defined:

- `python-runner`
  - Isolated Python automation using the workspace venv.
  - Full user-level system access (not sandboxed to workspace).
  - Called autonomously by the main agent for multi-step scripting tasks.
  - Can be invoked explicitly with `@python-runner <task>`.
  - Inherits all tools via `tools: ["*"]`.
  - Settings: `temperature: 0.2`, `max_turns: 40`, `timeout_mins: 15`.

Subagent files are plain text and travel inside the backup tarball with the
rest of `~/.gemini-agent/`. No special handling is required for restore.

To add a new subagent later: create a new `.md` file in the `agents/` folder
with frontmatter (`name`, `description`, `kind`, `tools`, etc.) and a body
that acts as that agent's system prompt. Then rebuild the tarball.
