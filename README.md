# gemini-agent

A second, agentic profile for [Google Gemini CLI](https://github.com/google-gemini/gemini-cli)
that turns the same binary you use for coding into a general-purpose autonomous
agent for your PC — filesystem, system administration, Python automation, web
research, project memory — without replacing your existing setup or moving to a
pay-per-token backend.

- `gemini` stays clean, for coding.
- `gemini-agent` is an autonomous profile with Python scripting, skills,
  subagents, a policy-engine safety net, and a dedicated workspace.

Isolation is achieved purely through configuration (`GEMINI_CLI_HOME`,
`GEMINI_SYSTEM_MD`, per-launcher env). No fork of Gemini CLI, no patching, no
daemon — just a layer of templates on top of the official binary.

## Why this instead of Hermes, OpenCode, Claude Code, or an OpenRouter-based agent

Open-source agent stacks are great, but most of them (Hermes, OpenCode,
Claude Code, OpenHands, the OpenRouter-based builds) share the same economic
model: you plug in an API key and pay per million input/output tokens, on a
metered bill. Agentic usage is the worst-case shape for that billing model —
the agent reads large files, scans directories, iterates on subagents, calls
tools, retries, thinks out loud — all of which *eats tokens*. A serious
automation session on a `claude-3.5-sonnet` or `gpt-4.1` budget can run into
single-digit dollars per conversation. "Let it run all day" is not a thing
you do, because the meter is running.

`gemini-agent` is built on Google Gemini CLI, which inverts that:

- **Subscription-native, not pay-per-token.** Sign in with a regular Google
  account and you get the free tier out of the box (generous daily quota on
  Gemini 2.5 models) at $0/month. Upgrade to AI Pro / AI Ultra and the quota
  scales up for a fixed monthly price. The model that runs your agent is the
  same model bundled into Gemini Advanced — no separate API plan, no top-ups.
- **Predictable cost.** You know your monthly spend before the month starts.
  An all-day autonomous session doesn't change the bill. This is the decisive
  difference for the *agentic* use case, which is exactly where pay-per-token
  stacks hurt.
- **1M-token context.** The agent can read an entire project tree, a full
  `journalctl` dump, or the output of `find /etc -type f` in a single turn
  without manual chunking. Most pay-per-token agents either can't do this
  (4k–200k windows) or don't do it because the cost per request is
  prohibitive.
- **Batteries included by Google.** Google Search grounding
  (`google_web_search`), URL fetch (`web_fetch`), and a full `browser_agent`
  subagent are built into Gemini CLI. No Serper/Brave/DDG API key, no extra
  Playwright wiring, no separate paid tier for search. In Hermes-style
  stacks you assemble these yourself and pay per search.
- **One binary, no infrastructure.** `gemini-agent` is not a daemon, not a
  server, not a Docker stack. It is a launcher + a config folder + a Python
  workspace. There is no "Hermes runtime" to keep alive, no channels, no
  cron, no memory DB to back up. When Google ships a new Gemini CLI version,
  you get it for free with `npm update -g @google/gemini-cli`.
- **First-class subagent and skill system.** Subagents are a supported
  Gemini CLI primitive with isolated context, tool allowlists, temperature,
  and turn limits. Skills are auto-discovered YAML-frontmatter Markdown
  files. You're not bolting on concepts — you're using primitives the
  upstream tool maintains and documents.
- **Real autonomy without a spray of confirmation prompts.** The default
  `yolo` approval mode lets the agent execute the 95% of operations that
  are safe (reads, writes inside the workspace, Python scripts, API calls)
  without prompting, while the policy engine
  (`profile/.gemini/policies/safety.toml`) still forces a UI prompt for
  `sudo`, `rm -r`, package managers, service/power control, firewall edits,
  and hard-blocks catastrophic ones (`rm -rf /`, `mkfs`, `dd` to a block
  device). You get Hermes-level fluidity with better safety, because the
  safety net is declarative and reviewable instead of a wall of per-tool
  confirmation dialogs.
- **Dual-profile isolation.** Your coding workflow (`gemini`) stays light,
  fast, and free of agent-specific skills/MCP servers. The agent
  (`gemini-agent`) gets a full workspace, subagents, and a broad policy
  rule set. One machine, two profiles, zero cross-contamination.
  Hermes-style monoliths don't give you this split.
- **Your data stays on your machine.** The repo ships only templates. OAuth
  tokens, trusted folder lists, project registry (`projects.ini`), scripts,
  logs, and the venv are created locally by first-run and by `install.sh`,
  never tracked in git. The backup/restore pair in `profile/backup/` moves
  exactly that personal layer across reinstalls, without ever uploading it.
- **Python-first automation, not shell-scripting-in-the-agent.** The agent
  writes, catalogues, and reuses real Python scripts inside
  `~/gemini-agent-workspace/`, backed by a dedicated venv that the launcher
  activates deterministically. Scripts accumulate across sessions as a
  personal toolbox (see `scripts.md`). Hermes-style setups tend to push
  everything through shell tools and lose that compounding value.
- **No vendor lock-in at the wrapper layer.** Because `gemini-agent` is
  *config on top of* Gemini CLI, not a fork or patch, you can uninstall it
  (`./uninstall.sh`) and your `gemini` command is untouched. If you ever
  want to switch the backend, the system.md prompt, policy file, skills,
  and Python scripts are plain text you can port.

**Where `gemini-agent` is not the right choice:**

- You need strict data-residency or on-prem inference. Gemini runs in
  Google's cloud. For air-gapped or compliance-locked environments, a
  local-model stack (Ollama + a Hermes-style wrapper) is the right pick.
- You want to mix and match frontier models per task (Claude for X, GPT
  for Y, Gemini for Z) in one agent. Gemini CLI is Gemini-only;
  OpenRouter-based stacks give you that flexibility at the cost of paying
  per token for all of them.
- You've already built a heavy Hermes or OpenCode customization and the
  migration cost exceeds the token-bill savings. For new setups, or when
  starting fresh after a reinstall, this is almost never the case.

## What you get after install

- `~/.gemini-agent/`                  agentic profile (settings, GEMINI.md, system.md, skills, subagents)
- `~/.local/bin/gemini-agent`         launcher that exports `GEMINI_CLI_HOME` + `GEMINI_SYSTEM_MD`
- `~/gemini-agent-workspace/`         Python workspace: venv, scripts/, tasks/, data/, logs/, scripts.md
- `python-runner` subagent            isolated Python runner with full user-level system access
- `sysadmin` advisor subagent         read-only Linux diagnostics that returns an execution plan to the parent
- `project-hub` skill                 per-project wiki-lite memory hub (inbox, plan, knowledge) for projects anywhere on disk
- YOLO mode + policy safety net       autonomous by default; destructive/privileged shell commands still prompt
- Backup scripts                      `~/.gemini-agent/backup/backup.sh` and `restore.sh`

Your existing `~/.gemini` profile is not touched.

## Requirements

- Gemini CLI installed and working (`gemini --version`)
- Python 3 with venv support:
  - Debian/Ubuntu: `sudo apt install python3 python3-venv python3-pip`
  - Fedora: `sudo dnf install python3 python3-pip`
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
│       ├── agents/sysadmin.md
│       ├── policies/safety.toml
│       └── skills/project-hub/SKILL.md
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
│   ├── project-hub.md
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

## Expanding Workspace Access

By default, Gemini CLI internal tools (like `ReadFile`, `ReadFolder`, `SearchText`) are
restricted to the current working directory for safety. If you want the agent
to have native, high-performance access to other folders (e.g., a data drive or
your entire home directory) without falling back to slower shell commands,
you must configure two files in your profile:

1.  **Add to Context (`~/.gemini-agent/.gemini/settings.json`)**:
    Add the paths to the `context.includeDirectories` array. This tells the
    agent that these folders are part of its potential workspace.
    ```json
    "context": {
      "includeDirectories": ["/mnt/DATA/Work/AI/", "~"],
      "loadMemoryFromIncludeDirectories": true
    }
    ```
2.  **Grant Trust (`~/.gemini-agent/.gemini/trustedFolders.json`)**:
    Internal tools will still block access unless the folder is "Trusted."
    You can trust a broad path by adding it to this JSON file:
    ```json
    {
      "/mnt/DATA/": "TRUST_FOLDER",
      "/home/marius/": "TRUST_FOLDER"
    }
    ```

**Note:** The `gemini-agent` launcher automatically detects your current
directory and passes it as the primary workspace via the `--workspace` flag.
This ensures that internal tools work natively on whatever project you are
currently in.

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
cover POSIX shell tooling (`sudo`, `apt`, `dnf`, `systemctl`, etc.), and the
`sysadmin` subagent is written for a systemd-based environment (Debian/Ubuntu, Fedora/RHEL).
None of that runs natively on Windows.

The supported path on Windows is WSL2 (Windows Subsystem for Linux).
Inside a WSL Ubuntu you get a real Linux userland and everything in
this repo works unchanged. A step-by-step tutorial from a blank
Windows 10 / 11 to a working `gemini-agent` command is in:

[`docs/windows-wsl.md`](docs/windows-wsl.md)

*(For using Fedora in WSL, see [`docs/fedora.md`](docs/fedora.md))*

## License

MIT. See `LICENSE`.
