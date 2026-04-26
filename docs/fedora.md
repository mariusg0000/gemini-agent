# Using gemini-agent on Fedora

The `gemini-agent` profile and its system diagnostics (`sysadmin` subagent) are fully compatible with Fedora and RHEL-based distributions. The agent understands `dnf` for package management, `systemctl` for services, and `journalctl` for logs.

## Native Fedora Installation

1. Install the prerequisite Python packages:
   ```bash
   sudo dnf install python3 python3-pip
   ```
   *(Note: Fedora includes the `venv` module in its core `python3` package by default, so there is no separate `python3-venv` package to install).*

2. Clone and install `gemini-agent`:
   ```bash
   git clone <repo-url> gemini-agent
   cd gemini-agent
   ./install.sh
   ```

3. Add `~/.local/bin` to your `PATH` if it is not already present, then run the agent:
   ```bash
   gemini-agent
   ```

## Fedora on Windows (WSL2)

While the default WSL2 experience installs Ubuntu, you can install a Fedora userland in WSL to use `gemini-agent` with Fedora's tools.

1. **Option A: Fedora Remix for WSL**
   The easiest way to get Fedora on WSL is to install **Fedora Remix for WSL** from the Microsoft Store or via `winget`:
   ```powershell
   winget install "Fedora Remix for WSL"
   ```

2. **Option B: Importing a Rootfs**
   Alternatively, you can download a Fedora rootfs tarball and import it into WSL:
   ```powershell
   wsl --import Fedora-39 C:\wsl\Fedora-39 path\to\fedora-rootfs.tar.xz
   ```

Once inside your Fedora WSL instance, follow the native Fedora installation instructions above.

## Agent Behavior Differences

- The `sysadmin` subagent will automatically detect that it is running on a Fedora system by inspecting `/etc/os-release`.
- When diagnosing package issues, the `sysadmin` subagent will propose `dnf` or `rpm` commands instead of `apt` or `dpkg`.
- The built-in safety policy (`profile/.gemini/policies/safety.toml`) already includes explicit intercept rules for `dnf`, `yum`, and `rpm`, ensuring that any destructive or privileged package management commands require user confirmation.
