# gemini-agent

A second, agentic profile for [Google Gemini CLI](https://github.com/google-gemini/gemini-cli)
that runs side-by-side with the default `gemini` command, without polluting it.

- `gemini`       stays clean, for coding.
- `gemini-agent` is an autonomous general-purpose profile with Python
  scripting, skills, subagents, and a dedicated workspace.

Isolation is achieved by setting `GEMINI_CLI_HOME` and `GEMINI_SYSTEM_MD` per
launcher. No fork of Gemini CLI, no patching - just configuration.

## What you get after install

- `~/.gemini-agent/`                  agentic profile (settings, GEMINI.md, system.md, skills, subagents)
- `~/.local/bin/gemini-agent`         launcher that exports `GEMINI_CLI_HOME` + `GEMINI_SYSTEM_MD`
- `~/gemini-agent-workspace/`         Python workspace: venv, scripts/, tasks/, data/, logs/, scripts.md
- `python-runner` subagent            isolated Python runner with full user-level system access
- YOLO mode + policy safety net       autonomous by default; destructive/privileged shell commands still prompt
- Backup scripts                      `~/.gemini-agent/backup/backup.sh` and `restore.sh`

Your existing `~/.gemini` profile is not touched.

## Requirements

- Gemini CLI installed and working (`gemini --version`)
- Python 3 with venv support: `sudo apt install python3 python3-venv python3-pip`
- `~/.local/bin` on your `PATH`

## Install

```
git clone <repo-url> gemini-agent
cd gemini-agent
./install.sh
```

First launch:

```
gemini-agent
```

Authenticate when prompted.

## Layout of the repo

```
.
├── bin/gemini-agent              launcher
├── profile/                      -> installed to ~/.gemini-agent/
│   ├── system.md
│   ├── backup/
│   └── .gemini/
│       ├── settings.json
│       ├── GEMINI.md
│       ├── agents/python-runner.md
│       ├── policies/safety.toml
│       └── skills/
├── workspace/                    -> installed to ~/gemini-agent-workspace/
│   ├── README.md
│   ├── requirements.txt
│   ├── scripts.md
│   └── scripts/
│       ├── _template/
│       └── hello-env/
├── install.sh
├── uninstall.sh
├── docs/
│   ├── architecture.md
│   ├── subagents.md
│   ├── safety-policy.md
│   ├── windows-wsl.md
│   └── design-decisions.md
├── LICENSE                       MIT
└── README.md
```

## Customize after install

- Edit behavior:       `~/.gemini-agent/system.md`, `~/.gemini-agent/.gemini/GEMINI.md`
- Add skills:          `~/.gemini-agent/.gemini/skills/<name>/SKILL.md`
- Add subagents:       `~/.gemini-agent/.gemini/agents/<name>.md`
- Safety rules:        `~/.gemini-agent/.gemini/policies/safety.toml` (see `docs/safety-policy.md`)
- Add scripts:         `~/gemini-agent-workspace/scripts/<name>/` and register in `scripts.md`
- Pin deps:            `~/gemini-agent-workspace/requirements.txt`

## Personal backup and restore

The repo installs templates. Your personal data (oauth token, trusted folders,
project mapping, the scripts you create, the logs you accumulate) stays on your
machine only. Two helper scripts handle backup and restore across a system
reinstall:

```
bash ~/.gemini-agent/backup/backup.sh
bash ~/.gemini-agent/backup/restore.sh
```

See `~/.gemini-agent/backup/README.md` for details.

## Safety notes

- `gemini-agent` defaults to `yolo` approval mode. Ordinary tool calls run
  without a UI confirmation so the agent is fluid and autonomous.
- The policy engine in `profile/.gemini/policies/safety.toml` is the
  safety net: it forces a UI confirmation for destructive or privileged
  shell commands (sudo, rm -r, package installers, service/power control,
  force-push, curl|bash, firewall and user/mount changes) and hard-blocks
  catastrophic ones (rm -rf /, mkfs, dd to a block device, partitioning,
  shred of a device). See `docs/safety-policy.md` for the full list.
- `python-runner` is configured with `tools: ["*"]` and full user-level access
  to the system. It can read and write anywhere the user can. Review its
  instructions in `profile/.gemini/agents/python-runner.md` before installing.
- OAuth credentials are never included in this repo. They live only in
  `~/.gemini-agent/.gemini/oauth_creds.json` after you sign in.

## Windows

`gemini-agent` is Linux-first. The launcher is bash, the policy rules
cover POSIX shell tooling (`sudo`, `apt`, `systemctl`, etc.), and the
`sysadmin` subagent is written for a systemd/Debian-style environment.
None of that runs natively on Windows.

The supported path on Windows is WSL2 (Windows Subsystem for Linux).
Inside a WSL Ubuntu you get a real Linux userland and everything in
this repo works unchanged. A step-by-step tutorial from a blank
Windows 10 / 11 to a working `gemini-agent` command is in:

[`docs/windows-wsl.md`](docs/windows-wsl.md)

## License

MIT. See `LICENSE`.
