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

### sysadmin

See `profile/.gemini/agents/sysadmin.md`. Key points:

- Linux system administration specialist for this machine.
- Full user-level system access; privileged commands go through `sudo`
  and are gated by the policy engine (which will prompt for
  confirmation on destructive or privileged operations).
- Investigate-first workflow: detects the distro/init/package stack,
  inspects current state, plans, acts, verifies.
- Backs up any file edited in `/etc/` with a timestamped `.bak-*`
  copy before modifying it.
- Prefers dry-run flags where available (`apt --simulate`,
  `systemctl --dry-run`, `nft -c`, `sshd -t`, `nginx -t`, `visudo -c`).
- Scope: services, packages, users, filesystems, networking, logs,
  kernel, security, boot, hardware, cron. Out of scope: Python
  scripting (→ python-runner), application development, remote hosts
  unless explicitly authorized.
- Returns only a concise summary including any `.bak-*` paths created.

## Tuning

If a subagent is called too often or too rarely, the lever is the `description`
field. Tighter wording narrows the delegation; broader wording widens it.
