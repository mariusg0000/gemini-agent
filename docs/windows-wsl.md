# Running gemini-agent on Windows via WSL

`gemini-agent` is Linux-first: the launcher, the policy rules, and the
`sysadmin` subagent all assume a POSIX shell (bash), POSIX tools
(`systemctl`, `apt`, `mount`, etc.), and Linux paths. On Windows the
supported path is WSL (Windows Subsystem for Linux). Inside WSL you
get a real Ubuntu/Debian userland and everything in this repo works
unchanged.

This tutorial walks you through the full setup from a blank Windows 10
or Windows 11 machine to a working `gemini-agent` command.

## What you end up with

- A WSL2 Ubuntu instance, kept separate from your Windows system.
- Node.js, Python, and `git` installed inside that Ubuntu.
- The `gemini` CLI installed inside WSL.
- The `gemini-agent` profile and workspace installed inside WSL.
- A `gemini-agent` command you launch from a WSL terminal (Windows
  Terminal, VS Code integrated terminal, or `wsl` from PowerShell).

The native Windows side is untouched.

## Prerequisites

- Windows 10 version 2004 (build 19041) or later, or any Windows 11.
- Virtualization enabled in BIOS/UEFI (most machines have this on by
  default). If WSL install fails, this is the first thing to check.
- An administrator PowerShell for the initial install only.
- ~5 GB of free disk space for the Ubuntu image and dependencies.

## Step 1 — Install WSL2 and Ubuntu

Open **PowerShell as Administrator** and run:

```powershell
wsl --install -d Ubuntu
```

This single command does everything:

- Enables the WSL and Virtual Machine Platform Windows features.
- Installs the WSL2 kernel.
- Downloads and registers the latest Ubuntu LTS as the default
  distribution.
- Sets WSL2 as the default version.

Reboot when Windows asks.

After the reboot, Ubuntu will finish setting itself up on first launch
(either automatically or when you click the new "Ubuntu" Start menu
entry). It will ask you to create:

- A **username** (keep it simple, lowercase, no spaces — this is your
  Linux user, unrelated to your Windows account).
- A **password** (used for `sudo`; there is no password-less option by
  default).

You now have a working Ubuntu terminal. Verify:

```bash
lsb_release -a
uname -r
```

You should see Ubuntu X.Y and a kernel with `-WSL2-` in the name.

## Step 2 — Update the base system

Fresh Ubuntu images are rarely up to date. Inside the WSL terminal:

```bash
sudo apt update
sudo apt -y upgrade
```

## Step 3 — Install core dependencies

You need `git`, Python 3 with venv, and Node.js 20+ (Gemini CLI
requires a recent Node).

```bash
sudo apt install -y git curl python3 python3-venv python3-pip ca-certificates
```

Install Node.js 20 via NodeSource (Ubuntu's default Node is usually
too old for Gemini CLI):

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node --version    # should print v20.x
npm --version
```

Confirm `~/.local/bin` is on your `PATH` (it usually is on Ubuntu):

```bash
echo "$PATH" | tr ':' '\n' | grep -F "$HOME/.local/bin" || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && \
  source ~/.bashrc
```

## Step 4 — Install Gemini CLI

Install the upstream CLI globally for your WSL user. Use `npm`'s
user-level prefix so `sudo` isn't needed:

```bash
mkdir -p "$HOME/.npm-global"
npm config set prefix "$HOME/.npm-global"
echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

npm install -g @google/gemini-cli
gemini --version
```

First `gemini` run will prompt you to authenticate (OAuth personal or
API key — follow the upstream instructions).

## Step 5 — Clone and install gemini-agent

Clone the repo **inside the WSL home**, not into `/mnt/c/...`. WSL's
native filesystem is much faster than the mounted Windows drives, and
some tools misbehave with Windows line endings.

```bash
cd ~
git clone https://github.com/mariusg0000/gemini-agent.git
cd gemini-agent
./install.sh
```

The installer:

- Copies `profile/` to `~/.gemini-agent/`.
- Installs the launcher to `~/.local/bin/gemini-agent`.
- Copies `workspace/` to `~/gemini-agent-workspace/`.
- Creates the Python venv and installs `requirements.txt`.
- Runs a sanity check script.

## Step 6 — First run

Open a **new** WSL terminal (so `PATH` is re-read) and run:

```bash
gemini-agent
```

If `gemini` was not yet authenticated in this WSL instance, sign in
when prompted. From this point on, the agent behaves exactly as
described in the main README and in `docs/architecture.md`.

## Daily workflow tips

### Launching from Windows Terminal

If you use [Windows Terminal](https://aka.ms/terminal), it picks up
your WSL distro automatically and shows it in the dropdown. Pin an
Ubuntu tab. From any such tab, `gemini-agent` just works.

### Launching from PowerShell or cmd

You can invoke the agent from Windows:

```powershell
wsl -- gemini-agent
```

or with a specific starting directory:

```powershell
wsl --cd /home/<you>/some/project -- gemini-agent
```

This opens a WSL session, runs the agent inside it, and shares stdout
with your Windows terminal.

### Working on files that live on Windows

WSL mounts your Windows drives at `/mnt/c/`, `/mnt/d/`, etc. You can
`cd` there and run `gemini-agent`:

```bash
cd /mnt/c/Users/<you>/Projects/my-thing
gemini-agent
```

Two caveats:

- Filesystem performance is significantly slower on `/mnt/*` than on
  `~`. For heavy agent work, clone the project to `~` instead.
- Git line endings: configure `core.autocrlf` appropriately if you
  edit the same repo from both sides.

### Accessing WSL files from Windows

All your WSL files are visible from Windows at:

```
\\wsl$\Ubuntu\home\<you>\
```

You can paste that into File Explorer, or into VS Code with the
**WSL** extension (recommended: `code .` from inside WSL).

### Updating

```bash
cd ~/gemini-agent
git pull
./install.sh --force
```

`--force` overwrites profile and workspace templates with the latest
from the repo. Your personal state (oauth token, skills you added,
scripts you wrote, logs) is not in those templates and is preserved
by the regular `backup.sh` / `restore.sh` flow — run a backup before
a `--force` install if you want extra safety.

## What doesn't work (even under WSL)

These are Windows-only things the Linux-first `sysadmin` subagent
cannot do from inside WSL:

- Controlling Windows services (`Get-Service`, `Stop-Service`).
- Managing Windows Firewall or Windows user accounts.
- Installing Windows packages via `winget`, `choco`, or `scoop`.
- Modifying the Windows registry.

WSL is Linux. It administers the Linux userland, not Windows. If you
want the agent to drive Windows-side administration, that would need a
separate PowerShell-based subagent and a separate policy file — see
the note in the main README.

## Troubleshooting

- **`wsl --install` says the feature is not available**: your Windows
  is too old. Upgrade to at least Windows 10 2004 / build 19041.
- **Ubuntu won't start after install**: virtualization is disabled in
  BIOS/UEFI. Enable Intel VT-x / AMD-V / "SVM Mode".
- **`npm install -g` asks for sudo**: re-do the `npm config set prefix`
  step and make sure your `PATH` points to the user-local bin first.
- **`gemini` works but `gemini-agent` does nothing**: check
  `~/.local/bin` is on `PATH` (`echo $PATH`) and that
  `~/.local/bin/gemini-agent` is executable
  (`ls -l ~/.local/bin/gemini-agent`).
- **"Skill conflict" warning on startup**: this is the `$HOME` vs.
  workspace issue described in `docs/architecture.md`. The launcher
  already guards against it by switching to `~/gemini-agent-workspace`
  when launched from `$HOME`. If you still see it, verify the launcher
  is the current version: `head -1 ~/.local/bin/gemini-agent`.
