# sysadmin (Advisor & Planner)

The `sysadmin` subagent is a specialized Linux system administration investigator. It follows the **Advisor Pattern**: it performs read-only diagnostics to understand the system state and returns a structured execution plan for the parent agent to run.

## Why the Advisor Pattern?

Gemini CLI subagents run non-interactively. This means that if a command triggers a policy engine prompt (like `sudo` or `systemctl`), the subagent cannot show you the prompt and will be automatically denied.

By separating **Investigation** (subagent) from **Execution** (parent), we ensure that:
1.  The subagent can freely explore the system using read-only shell commands.
2.  The parent agent handles the privileged commands in the main terminal, where you can see and approve them.

## Capabilities

`sysadmin` can investigate:
- **Services**: `systemd` units, status, and configurations.
- **Logs**: `journalctl`, `/var/log/`, and `dmesg`.
- **Networking**: IP addresses, routing, open ports (`ss`), and DNS.
- **Packages**: `apt`, `dnf`, `rpm`, `pacman`, `snap`, and `flatpak`.
- **Hardware**: CPU, disks, PCI/USB devices, and smart status.
- **Kernel**: Modules, sysctl parameters, and version info.

## The Execution Plan

When `sysadmin` finishes its investigation, it returns a plan with:
- **Findings**: What was observed during the "recon" phase.
- **Steps**: Numbered list with Intent, Command, Verification, and Rollback for every change.
- **Backups**: Specific files that should be backed up before proceeding.
- **Risks**: Potential side effects (e.g., "This will restart the network interface").

## Usage

You don't usually need to call `sysadmin` manually. If you ask the main agent a system question (e.g., *"Why is my Nginx failing?"*), it will automatically delegate the investigation to `@sysadmin`.

## Universal Access

Because `sysadmin` uses shell commands (`run_shell_command`), it is not restricted by the "Workspace Sandbox." It can see any part of the system that your Linux user has permission to read.
