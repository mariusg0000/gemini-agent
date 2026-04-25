# Subagents

Subagents are specialized agents exposed to the main agent as tools. They run
in an isolated conversation with their own system prompt, own tool allowlist,
and own turn/time limits. When invoked, they work to completion and return
only a final summary. Their transcript does not bloat the main agent's context.

## Location

```
~/.gemini-agent/.gemini/agents/*.md
```

## File format

Each subagent is a single Markdown file with YAML frontmatter at the top and a
body that becomes the agent's system prompt.

```markdown
---
name: my-agent
description: >-
  One paragraph describing exactly when the main agent should delegate here.
  The main agent sees this text and uses it to decide.
kind: local
tools:
  - "*"              # or a specific list
temperature: 0.2
max_turns: 30
timeout_mins: 10
---

# my-agent

Body text: the agent's system prompt.
```

### Frontmatter fields

| Field          | Required | Notes                                                        |
| -------------- | -------- | ------------------------------------------------------------ |
| `name`         | yes      | Unique slug. Also becomes the tool name.                     |
| `description`  | yes      | Used by the main agent to decide when to delegate.           |
| `kind`         | no       | `local` (default) or `remote`.                               |
| `tools`        | no       | Array of tool names. Wildcards allowed: `*`, `mcp_*`.        |
| `mcpServers`   | no       | Inline MCP servers scoped to this agent only.                |
| `model`        | no       | Specific model to use. Defaults to inheriting the parent.    |
| `temperature`  | no       | 0.0 - 2.0. Lower is more deterministic.                      |
| `max_turns`    | no       | Cap on turns before the agent must return. Default 30.       |
| `timeout_mins` | no       | Execution timeout in minutes. Default 10.                    |

## Invocation

- Implicit: the main agent inspects the description and delegates when a task
  matches.
- Explicit: the user starts a prompt with `@agent-name <task>` to force
  delegation to a specific agent.

## Isolation

- Independent conversation history and tool calls.
- Isolated tool registry if `tools` is restricted.
- Cannot recursively call other subagents.

## Shipped subagents

### python-runner

See `profile/.gemini/agents/python-runner.md`. Key points:

- Full user-level system access (`tools: ["*"]`).
- Uses the dedicated venv at `~/gemini-agent-workspace/venv/bin/python`.
- Enforces workspace conventions: `scripts/<slug>/`, `scripts.md`,
  `requirements.txt`, `tasks/<YYYY-MM-DD-slug>/`.
- Returns only a concise summary to the parent.

### sysadmin (advisor pattern)

See `profile/.gemini/agents/sysadmin.md`. Key points:

- Linux system administration **investigator and planner** for this
  machine. It runs only read-only diagnostic commands and returns a
  structured execution plan; it does not execute state-changing or
  privileged commands itself.
- Why: Gemini CLI subagents run non-interactively. The policy engine
  (`~/.gemini-agent/.gemini/policies/safety.toml`) forces `ask_user`
  on privileged and destructive commands, and non-interactive mode
  converts `ask_user` to `deny`. A subagent that tried to run
  `sudo systemctl enable ...` would be silently denied and appear
  stuck. Upstream tracks this limitation (see
  [gemini-cli#18127](https://github.com/google-gemini/gemini-cli/issues/18127),
  [gemini-cli#14306](https://github.com/google-gemini/gemini-cli/issues/14306)).
  The advisor pattern sidesteps the problem: investigation happens
  in the subagent, execution happens in the interactive parent
  session where policy prompts work.
- Scope: services, packages, users, filesystems, networking, logs,
  kernel, security, boot, hardware. Out of scope: Python scripting
  (→ `python-runner`), application development, remote hosts.
- Allowed to run: read-only inspection (`systemctl status`,
  `journalctl`, `ss`, `ip`, `ps`, `df`, `dpkg -l`, `cat /etc/...`,
  etc.).
- Forbidden from running itself: anything with `sudo`/`doas`/`pkexec`,
  any `systemctl start|stop|enable|disable|mask|restart|...`,
  package state changes, firewall edits, user management, file
  writes to `/etc`, `rm -r`, `dd`, `mount`/`umount`, `reboot`,
  `git push --force`, `curl | sh`, etc. These go in the plan, not
  in an actual tool call.
- Returns a structured plan with: Goal, Environment, Findings,
  optional "Recon to run first", numbered Plan steps (Intent /
  Command / Verification / Rollback), Backups recommended, Risks
  and notes.

### How the parent consumes a sysadmin plan

1. Read the Risks and Backups sections before touching anything.
2. If the plan includes "Recon to run first", run those commands
   in the main session first. The user sees them in the UI.
3. For each numbered step:
   - Create any backups the plan recommends
     (`cp -a <file> <file>.bak-$(date +%Y%m%d-%H%M%S)`).
   - Run `Command`. The policy engine surfaces a prompt for
     destructive or privileged commands; honor the user's decision.
   - Run `Verification` and confirm expected output.
   - On failure, stop. Offer `Rollback` and ask before continuing.
4. Report: goal, steps executed, verification results, rollbacks
   used, follow-ups.

The parent does not forward the plan to the user as the final
answer. It executes the plan.

## Tuning

If a subagent is called too often or too rarely, the lever is the `description`
field. Tighter wording narrows the delegation; broader wording widens it.
