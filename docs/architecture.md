# Architecture

The goal is to run two independent Gemini CLI profiles on the same machine
without interfering with each other.

## Two profiles

- `gemini` uses the default configuration root at `~/.gemini/`.
- `gemini-agent` uses a separate configuration root at `~/.gemini-agent/`.

The switch is done via the `GEMINI_CLI_HOME` environment variable. Setting it
makes Gemini CLI treat that path as the user-level config root. The launcher
`~/.local/bin/gemini-agent` sets `GEMINI_CLI_HOME=$HOME/.gemini-agent` and then
runs the regular `gemini` binary.

## Launcher: HOME guard

Gemini CLI uses a tiered discovery model (workspace > user > extension) for
skills, settings, and policies. When the current working directory is `$HOME`,
Gemini picks up `$HOME/.gemini/` (the default coding profile) as the
**workspace** tier for the `gemini-agent` session, which bleeds skills and
settings from the coding profile into the agent profile and can trigger
"skill conflict" warnings.

The launcher avoids this by switching to the agent's dedicated workspace
(`~/gemini-agent-workspace/`) whenever it is invoked from `$HOME`. Any other
CWD is honored unchanged, so launching from a project directory still uses
that project as the workspace.

## System prompt override

The agentic behavior is installed as a full override of Gemini CLI's built-in
system prompt. The launcher also sets `GEMINI_SYSTEM_MD=$HOME/.gemini-agent/system.md`.

- `system.md` is the non-negotiable "firmware": working loop, safety rules,
  output style, delegation rules.
- `GEMINI.md` is the project/profile context file: stable conventions and
  lightweight guidance that Gemini CLI concatenates into every prompt.

## Skills and subagents

- Skills: `~/.gemini-agent/.gemini/skills/<name>/SKILL.md`
  On-demand procedural expertise. Gemini autonomously activates a skill when
  the task matches its description.
- Subagents: `~/.gemini-agent/.gemini/agents/<name>.md`
  Isolated agents exposed as tools to the main agent. Each has its own system
  prompt, tool allowlist, context, and limits.

## Approval model and policy engine

Default approval mode is `yolo`. Ordinary tool calls execute without a UI
prompt so the agent is fluid and autonomous.

The safety net is Gemini CLI's policy engine:

- Rules live in `~/.gemini-agent/.gemini/policies/*.toml`.
- `deny` rules hard-block catastrophic commands (e.g. `rm -rf /`,
  `mkfs`, `dd` to a block device).
- `ask_user` rules intercept destructive or privileged commands
  (sudo, package managers, service/power control, force-push,
  curl|bash, firewall/user/mount changes) and force a UI confirmation
  even in YOLO mode.
- Rules apply globally to `gemini-agent` and to every subagent it
  spawns. Subagents cannot bypass the policy.

See `docs/safety-policy.md` for the full rule set and rationale.

## Python workspace

Long-running automation work happens through a dedicated Python workspace at
`~/gemini-agent-workspace/`:

- `venv/` is the Python environment used by all agent scripting.
- `scripts/<name>/` holds reusable scripts; each script has a folder with
  `main.py` and `SCRIPT.md`.
- `scripts.md` is a catalog the agent consults before writing new scripts.
- `tasks/<YYYY-MM-DD-slug>/` holds one-off scratch work per task.
- `logs/`, `data/` hold transient outputs.
- `requirements.txt` is the source of truth for dependencies.

## File ownership boundaries

- The repo ships **templates** only. No secrets.
- The profile holds **personal state**: oauth token, trusted folders, project
  mapping, session history.
- The workspace holds **scripts and scratch**: reusable code, task outputs,
  logs, the venv.
- Backups cover profile + workspace, never the venv.

## Why not just edit `~/.gemini/`?

Because the default profile must stay clean for coding. Mixing skills, MCP
servers, and an agentic system prompt into the default profile contaminates
coding sessions and is harder to reason about. Two profiles with clear purposes
beat one profile with flags.
