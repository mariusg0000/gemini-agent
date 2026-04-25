# project-hub skill

`project-hub` is a shipped skill that gives `gemini-agent` a persistent,
per-project Obsidian-friendly memory layer. It mirrors the wiki-lite
structure used in the Hermes agent, ported to Gemini CLI.

## When it activates

The main agent loads the skill when the user mentions any of:

- `project-hub`, `project`
- `open project`, `resume project`, `init project`
- `inbox`, `add to inbox`, `process inbox`, `integrate notes`
- Romanian equivalents: `deschide project`, `reia project`,
  `proceseaza inbox`, `integreaza notite`, `adauga in inbox`, etc.

Passive-capture triggers (`I have an idea`, `note this`, `am o idee`,
`noteaza asta`, ...) append the whole user message to the current
project's inbox and return to the main task immediately.

## What it creates

For each managed project:

```
<project-root>/
  README.md
  project-hub/
    00-home.md        dashboard summary
    01-current.md     current focus, next step, blockers
    02-inbox.md       write-only raw capture
    03-plan.md        Active / Next / Later / Postponed / Canceled / Done
    04-knowledge.md   stable decisions, facts, conventions
    assets/           screenshots, PDFs, attachments
```

Project hubs live inside the user's actual project folders (wherever
they already are on disk), not inside `~/gemini-agent-workspace/`. The
workspace is for agent-produced Python scripts and task scratch; the
hub is for human-owned project memory.

## Registry

The registry of known projects is a single INI file at:

```
~/.gemini-agent/projects.ini
```

Format:

```ini
[angrytower]
path=/mnt/DATA/Work/AI/AngryTowers
desc=Godot port and multiplayer relay implementation
aliases=angry towers
status=active
```

- `path` is the project root (the folder that contains `project-hub/`).
- `aliases` is optional, comma-separated.
- Matching is case-insensitive against section names and aliases.
- The file is auto-created by the skill on first use.

## Why the registry lives outside the repo

`projects.ini` contains absolute paths that are personal machine
state, so it is gitignored (see `.gitignore`). The skill code ships
in the repo; the registry does not. Installing on a new machine
starts with an empty registry; running `open project-hub on <name>`
for the first time registers it.

## Interaction with the policy engine

Project-hub operations are file-level and do not trigger the policy
engine:

- Markdown writes and edits go through `write_file` / `edit_file`, not
  through the shell.
- Inbox appends use a short inline `python3 -c "..."`. `python3` is
  not on the policy list, so captures are silent.
- `mkdir -p` is not policy-guarded.

If a user ever asks the agent to create a hub inside a path that
requires `sudo`, the skill stops and reports. Project hubs belong in
user-writable folders.

## Safety rules built into the skill

- Inbox is write-only during normal work. It is read only when the
  user explicitly runs an integration.
- Each task exists in exactly one section of `03-plan.md` at a time;
  timestamps are preserved when tasks move to `Done`, `Postponed`,
  or `Canceled`.
- After writing any critical file, the skill reads it back and halts
  if content does not match.
- Ambiguous inbox notes stay in the inbox; the skill never empties
  the inbox wholesale.
- The skill does not fabricate content to fill empty sections.

## Related

- `docs/subagents.md` — the subagents (`python-runner`, `sysadmin`).
  Heavy batch integrations can be delegated to `python-runner` if an
  inbox grows large.
- `docs/safety-policy.md` — why file tools stay outside the policy
  engine while shell commands go through it.
