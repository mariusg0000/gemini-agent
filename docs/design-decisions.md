# Design decisions

## Why two profiles instead of one with flags

Flags encourage mixing. Two profiles give hard separation:

- `gemini` is tuned for coding, nothing more.
- `gemini-agent` is tuned for open-ended, agentic, automation work.

A hard boundary is easier to reason about than "skills enabled or not this
session." Nothing in the agentic profile leaks into coding sessions, and
nothing in coding sessions constrains the agent.

## Why `GEMINI_CLI_HOME` instead of project-level settings

`GEMINI_CLI_HOME` is the cleanest way to fully reroute Gemini CLI to a second
user-level root. Project-level settings merge with the user profile rather than
replacing it, which would not give clean separation. The launcher exports the
variable only for its own process, so the default `gemini` command keeps using
`~/.gemini/`.

## Why `GEMINI_SYSTEM_MD` for the system prompt

System prompt overrides via `GEMINI_SYSTEM_MD` replace the built-in prompt
entirely. This gives total control over the agent's working loop, safety rules,
and delegation behavior. Keeping this override scoped to the `gemini-agent`
launcher ensures the default `gemini` still gets the upstream system prompt.

## Why a dedicated Python workspace

Running Python automation inside the user's project folders pollutes those
projects with venvs, logs, and scratch files. A dedicated workspace:

- avoids polluting projects,
- centralizes reusable scripts so they compound,
- allows a stable pinned dependency set, and
- gives a single auditable location for agent-produced artifacts.

## Why "one folder per script"

A flat `scripts/` folder invites entropy. Each script getting its own folder:

- makes room for `SCRIPT.md`, example data, tests, and assets,
- keeps diffs tidy,
- lets each script evolve into a small tool if needed.

`scripts.md` at the workspace root is the canonical index.

## Why `python-runner` has full system access

The goal is a practical general-purpose agent, not a sandboxed coding
assistant. Restricting it to the workspace would defeat its purpose (file
operations, sysadmin-like tasks, media, etc.). Safety comes from:

- explicit safety rules in the subagent's system prompt,
- the policy engine that intercepts dangerous shell commands
  (see `docs/safety-policy.md`),
- user-level OS permissions.

If you want tighter isolation, narrow the `tools` list in
`profile/.gemini/agents/python-runner.md`, or run Gemini CLI inside a sandbox
profile. That is a conscious trade-off, not a default.

## Why YOLO + policy engine instead of default approval

Three options were considered:

1. **Default approval.** Every tool call shows a UI prompt. Safe but
   makes autonomous work painful; the user becomes a bottleneck for
   trivial operations.
2. **Full YOLO.** Every tool call runs, no prompt. Fast but unsafe:
   a single misreading of the goal could `rm -rf` the home folder.
3. **YOLO + policy engine.** Tool calls run by default, but the policy
   engine transparently intercepts destructive or privileged commands
   and forces a prompt (or a hard block) on them.

Option 3 is the chosen default. It gives autonomy for the 95% of
operations that are safe (reads, file writes inside the workspace,
running scripts, computing things, using APIs) and keeps the 5% that
are truly dangerous behind an explicit confirmation. Rules live in
`profile/.gemini/policies/safety.toml` and are version-controlled, so
safety behavior is reviewable and shareable.

## Why the repo ships templates, not user state

Templates can be version-controlled, diffed, and shared. User state (oauth
tokens, trusted folders, project mappings, private scripts) cannot, safely.
The repo's install flow only populates templates. Personal state is created by
first-time use and is covered by the workspace backup scripts, which live on
the user's machine only.
