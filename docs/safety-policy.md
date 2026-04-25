# Safety policy

`gemini-agent` defaults to `yolo` approval mode: ordinary tool calls run
without a UI confirmation prompt, so the agent is fluid and autonomous.

## How YOLO is set

YOLO mode is only enablable via CLI flag (`general.defaultApprovalMode`
in `settings.json` does not accept `yolo`, it is restricted to
`default | auto_edit | plan`). The launcher therefore appends
`--approval-mode=yolo` unless the user has already passed an approval
flag.

The launcher also sets `GEMINI_SANDBOX=false` (unless the user
overrides it). Gemini CLI auto-enables sandboxing when YOLO is on; for
this profile we explicitly want full system access (the `python-runner`
and future `sysadmin` subagents depend on it), so we turn the sandbox
off and rely on the policy engine for safety instead.

## Decisions

The policy engine inspects every tool call (especially
`run_shell_command`) and returns one of three decisions:

| Decision   | Effect                                                   |
| ---------- | -------------------------------------------------------- |
| `allow`    | Tool runs, no prompt. (This is what YOLO gives us.)      |
| `ask_user` | UI prompt, user approves or rejects. Overrides YOLO.     |
| `deny`     | Tool call is blocked entirely; the model cannot use it.  |

## Where the rules live

Profile path:

```
~/.gemini-agent/.gemini/policies/safety.toml
```

Repo path:

```
profile/.gemini/policies/safety.toml
```

Any `.toml` file in that directory is loaded and merged. Higher
`priority` wins within a tier; user-tier rules (this file) override
built-in defaults like "YOLO allow-all".

## What is blocked (`deny`)

Things that are catastrophic and essentially unrecoverable:

- `rm -rf /` and variants targeting the root filesystem
- `dd ... of=/dev/<disk>` (raw writes to a block device)
- `mkfs.*` (filesystem creation)
- Partitioning tools: `fdisk`, `sfdisk`, `parted`, `gdisk`, `wipefs`
- `shred` on `/dev/*`

## What requires confirmation (`ask_user`)

Destructive, privileged, or hard-to-reverse operations:

- Privilege escalation: `sudo`, `doas`, `pkexec`, `su`
- Power / session: `reboot`, `shutdown`, `halt`, `poweroff`,
  `systemctl reboot|poweroff|suspend|hibernate`, `loginctl terminate-user`
- Service management: `systemctl {stop|start|restart|enable|disable|mask|unmask|kill|reload|daemon-reload}`,
  `service`, `rc-service`
- Package managers: `apt`, `apt-get`, `aptitude`, `dnf`, `yum`,
  `pacman`, `snap`, `flatpak`, `dpkg`, `rpm`
- Global language-package installs: `pip install` without an explicit
  venv, `npm install -g`
- Recursive filesystem ops: `rm -r`, `chown -R`, `chgrp -R`, `chmod -R`
- In-place truncation: `: > /...`, `truncate -s 0`
- Mass signalling: `killall`, `pkill`, `kill -9`, `kill -KILL`, `kill -TERM`
- Download-and-execute: `curl|wget|fetch ... | sh|bash|python|ruby|perl|node`,
  `bash <(curl ...)`
- Containers: `docker`/`podman` `system prune`, `volume rm`, `network rm`,
  `rm -f`, `rmi -f`, `*_prune`
- VM management: `virsh destroy`, `VBoxManage unregistervm`, etc.
- Git history rewrites: `git push --force`, `--force-with-lease`,
  `git reset --hard`, `git clean -fd`, `filter-branch`, `filter-repo`
- Scheduling / persistence: `crontab -r|-e`, user-unit `systemctl` changes
- Network and firewall: `ufw`, `iptables`, `nft`, `firewall-cmd`,
  `ip route`, `ip link`
- User / group management: `useradd`, `userdel`, `usermod`, `groupadd`,
  `passwd`, `gpasswd`, `adduser`, `deluser`
- Mount / swap: `mount`, `umount`, `swapon`, `swapoff`, `mkswap`,
  `cryptsetup`

## Writing a new rule

Use `commandPrefix` for literal prefixes (safest) and `commandRegex`
when you need alternation or character classes. Do not use `^` or `$`
anchors: they apply to the full JSON argument string, not to the
command. The engine already anchors the match at the start of the
command.

Gemini CLI also runs a ReDoS safety check on every regex. Avoid:

- Nested quantifiers in groups, e.g. `(X+)?`, `(X*)*`, `(X+)*`.
- Overlapping `*`-quantified character classes around a literal whose
  characters are also in the class, e.g. `[a-zA-Z]*r[a-zA-Z]*` — this
  can trigger polynomial backtracking.

Prefer restricted character classes that don't overlap with neighboring
literals. For example, to match an `rm` flag cluster that contains
either `r` or `R`:

```toml
commandRegex = 'rm[[:space:]]+-[fivIVF]*[rR][fivIVF]*'
```

`[fivIVF]` shares no characters with `[rR]`, so the regex is linear.

```toml
[[rule]]
toolName = "run_shell_command"
commandPrefix = ["rsync "]
decision = "ask_user"
priority = 100
```

Priorities: user rules in the 100-200 band are the sweet spot.
Catastrophic `deny` rules use 200. Privilege-escalation and
download-and-execute use 150-160. Everything else uses 100-120.

## Testing the policy

Inside `gemini-agent`, run:

```
/policies list
```

to see which rules are loaded. To dry-run without risk, use a shell
command that matches the pattern but is harmless, e.g. `sudo --help`
should still trigger the `sudo ` prefix rule and show the
confirmation UI.

## Design notes

- `deny` is used very sparingly. The policy must not lock the user
  out of their own machine; it only blocks things that are almost
  always a mistake.
- `ask_user` is preferred over `deny` for anything recoverable, so the
  user retains full control.
- Rules apply to every subagent (including `python-runner` and, in the
  future, `sysadmin`). Subagents cannot escape the policy.
