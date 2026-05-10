# R-01: tmux Capabilities for Agent Orchestration

## Prerequisites

- Detect with `command -v tmux` + `tmux -V`
- Version string format: `tmux X.Y` or `tmux X.Ya`
- **Minimum version: 3.0+** for `remain-on-exit failed` and modern style syntax

## Programmatic Control API

All tmux commands return exit code 0 on success, 1 on failure. Key commands:

| Command | Purpose |
|---------|---------|
| `has-session -t <name>` | Check if session exists (exit 0/1) |
| `new-session -d -s <session> -n <window>` | Create detached session with named window |
| `new-window -t <session> -n <name> '<cmd>'` | Add named window running a command |
| `kill-window -t <session>:<window>` | Kill a specific window |
| `kill-session -t <session>` | Kill entire session |
| `attach-session -t <session>` | Attach operator to session |
| `list-windows -t <session> -F '<fmt>'` | List windows with custom format |
| `display-message -t <target> -p '#{pane_dead}'` | Check if process exited |
| `capture-pane -t <target> -p -S -100` | Read scrollback |
| `send-keys -t <target> C-c` | Send interrupt |
| `respawn-window -t <target>` | Re-run command in dead window |

Target syntax: `session:window.pane` (e.g., `bm-team:bob.0`)

## Server Isolation via `-L`

The `-L` flag creates a **separate tmux server** with its own socket:

```bash
tmux -f /path/to/config -L botminter new-session -d -s bm-team -n bob
tmux -L botminter list-sessions
tmux -L botminter attach-session -t bm-team
```

This gives complete isolation from the user's personal tmux sessions — different server process, different config, no interference. All subsequent commands must use the same `-L` name.

## Custom Configuration

- `-f <config>` replaces user's `~/.tmux.conf` (system `/etc/tmux.conf` still loads)
- **`-f` is per-server, not per-session** — only read when server first starts
- Combined with `-L`, gives fully isolated config

## Status Bar Theming

Key options: `status-left`, `status-right`, `status-style`, `status-left-length`, `status-right-length`, `window-status-format`, `window-status-current-format`.

Inline style markers: `#[fg=colour46,bold]`. Colors: named, `colour0-255`, `#hex`. Attributes: `bold`, `dim`, `italics`, `reverse`.

Status bar is single-line — branding limited to text and Unicode characters.

## Window Naming

- Set via `-n` flag on creation
- Prevent rename: `set -wg automatic-rename off` + `set -wg allow-rename off`
- `-n` on creation auto-disables `automatic-rename` for that window

## Process Lifecycle — `remain-on-exit`

- `set -wg remain-on-exit on` — keeps window after process exits, shows "Pane is dead (status N, timestamp)"
- `remain-on-exit failed` (tmux 3.0+) — only keeps on non-zero exit
- Dead pane detection: `#{pane_dead}` returns "1", `#{pane_dead_status}` gives exit code
- Full scrollback preserved in dead windows
- `respawn-window` re-runs the command

## Scrollback Buffer

- Default: 10,000 lines
- Recommended for agent observability: 50,000
- Set via `set -g history-limit 50000` — applies only to new windows
- Read programmatically: `capture-pane -p -S -100` (last 100 lines) or `-S -` (full history)

## Rust Integration

- `tmux_interface` crate on crates.io — typed wrappers around CLI commands
- Alternative: shell out to `tmux` via `std::process::Command` — simpler, zero deps
- No official tmux Rust library; CLI is the stable interface

## Environment Variables

`new-session` and `new-window` support `-e 'KEY=value'` for passing env vars (repeatable).

## Sources

- tmux man page
- [tmux_interface crate](https://github.com/AntonGepting/tmux-interface-rs)
