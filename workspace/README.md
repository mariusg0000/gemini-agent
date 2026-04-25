# Gemini Agent Workspace

Home for the `gemini-agent` profile. Holds its Python environment, reusable
scripts, task scratch space, and logs. Scripts run from here but can read and
write anywhere the user has permission.

## Layout

```
~/gemini-agent-workspace/
  venv/            Dedicated Python environment for the agent
  scripts/         Reusable scripts, one folder per script
  tasks/           Scratch space, one folder per task (YYYY-MM-DD-slug)
  data/            Agent-produced or agent-curated data
  logs/            Execution logs
  requirements.txt Pinned dependencies for the venv
  scripts.md       Index of all registered scripts
```

## Python environment

- Interpreter: `~/gemini-agent-workspace/venv/bin/python`
- Pip:         `~/gemini-agent-workspace/venv/bin/pip`
- Never use system Python for agent work.
- Install new deps with pip, then record in `requirements.txt`.

## Conventions

- A reusable script lives in its own folder under `scripts/<name>/`.
- Each script folder contains `main.py` and `SCRIPT.md`.
- Inputs/outputs are passed via CLI args or stdin/stdout, not hardcoded paths.
- Logs go to `logs/<script-or-task>.log`.
- Task scratch goes under `tasks/<YYYY-MM-DD-slug>/`.
- Every new reusable script is registered in `scripts.md`.

## Isolation note

The venv isolates Python packages only. Scripts run with full user privileges
and can access the whole filesystem. That is the intended behavior. For risky
actions, the agent must ask for confirmation.
