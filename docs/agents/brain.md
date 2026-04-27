# brain (High-Reasoning Specialist)

The `brain` subagent is a specialized reasoning specialist designed for deep codebase analysis, complex logical problem solving, and intricate planning.

## Configuration

- **Model**: `gemini-3.1-pro-preview`
- **Temperature**: 0.1 (Optimized for precision and deterministic logic)
- **Tools**: Full access (`*`)
- **Max Turns**: 40

## Workflow: The @brain Loop

The `brain` agent follows a strict **Orchestrator -> specialist** delegation pattern to ensure it has the highest quality context before it begins thinking.

1.  **Request**: The user invokes the agent via `@brain` or "use brain".
2.  **Context Gathering**: The main agent (orchestrator) reads relevant files, extracts code snippets, and identifies constraints.
3.  **Disclosure**: The main agent displays a **"Summary for @brain"** to the user, showing exactly what is being sent to the subagent.
4.  **Delegation**: The structured summary is sent to the `brain` tool.
5.  **Reasoning**: `brain` analyzes the summary, uses tools to fill any gaps, and formulates a solution.
6.  **Response**: `brain` returns a comprehensive answer including a mandatory **"Tools & Process Log"** for full transparency.

## Use Cases

- **Logic Audits**: Auditing business rules spread across multiple files (e.g., checkout logic vs. security policy).
- **Architecture Planning**: Designing a new module or refactoring existing complex logic.
- **Root Cause Analysis**: Investigating subtle bugs that require tracing data through multiple layers.
- **Compliance Checks**: Ensuring implementation details match documented requirements.

## Transparency & Observability

`brain` is designed to be the most "observable" agent in the profile.
- **Input Visibility**: You see the prompt before it goes in.
- **Process Visibility**: You see the "Tools & Process Log" at the end, listing exactly which files were read and which shell commands were run during the reasoning phase.
