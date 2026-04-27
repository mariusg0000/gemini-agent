# Subagents

Subagents are specialized specialists exposed to the main agent as tools. They run in an isolated conversation with their own system prompt, tool allowlist, and limits.

## Shipped Subagents

The `gemini-agent` profile includes three pre-configured subagents:

### 🧠 [brain (High-Reasoning Specialist)](agents/brain.md)
Specialized in complex logic, deep codebase analysis, and mathematical problem-solving. Uses the high-capacity `gemini-3.1-pro-preview` model and a mandatory context-summary workflow.

### 🐍 [python-runner (Automation Specialist)](agents/python-runner.md)
Isolated Python execution in a dedicated workspace. Use for multi-step scripting, data processing, and creating reusable automation tools.

### 🛠️ [sysadmin (Advisor & Planner)](agents/sysadmin.md)
Linux system administration investigator. Uses the **Advisor Pattern** to perform read-only diagnostics and return structured execution plans for the main agent.

---

## File Format

Each subagent is a single Markdown file with YAML frontmatter:
- **Location**: `~/.gemini-agent/.gemini/agents/*.md`
- **Fields**: `name`, `description`, `tools`, `model`, `temperature`, `max_turns`.

## Invocation

- **Implicit**: The main agent decides when to delegate based on the subagent's `description`.
- **Explicit**: Use `@agent-name <task>` to force delegation.
