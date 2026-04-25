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
