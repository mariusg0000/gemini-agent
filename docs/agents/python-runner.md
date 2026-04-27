# python-runner (Automation Specialist)

The `python-runner` subagent is an isolated specialist designed to write, adapt, and execute Python scripts for automation, data processing, and iterative development.

## Isolated Workspace

To keep your main system clean and prevent dependency conflicts, `python-runner` operates inside a dedicated workspace:
- **Root**: `~/gemini-agent-workspace/`
- **Venv**: Uses the private virtual environment at `~/gemini-agent-workspace/venv/`.
- **Interpreter**: Always uses `~/gemini-agent-workspace/venv/bin/python`.

## Capabilities

`python-runner` is ideal for:
- **Multi-step Scripting**: Writing a script, running it, seeing an error, and fixing it in a loop.
- **Data Processing**: Curating large datasets, converting file formats, or performing complex calculations.
- **Automation**: Creating reusable tools for your PC that you can invoke later.
- **API Integration**: Writing scripts to fetch data from external services.

## Script Management

The agent maintains a permanent "toolbox" of your automation:
- **`scripts.md`**: A catalog of every reusable script the agent has created for you.
- **`scripts/`**: Individual folders for each script, containing `main.py` and a `SCRIPT.md` documentation file.
- **`tasks/`**: One-off "scratch" scripts for temporary tasks.

## Usage

Delegate to `@python-runner` when you need logic that is too complex for a one-line shell command or requires external Python libraries.

```bash
# Example
@python-runner "Write a script to find all duplicate images in ~/Pictures and move them to a 'duplicates' folder."
```

## Safety

While `python-runner` has full user-level access to the filesystem, it is instructed to use **Dry-Runs** and **Previews** before making wide-scope changes. It will always use the workspace `venv` to avoid polluting your system-wide Python installation.
