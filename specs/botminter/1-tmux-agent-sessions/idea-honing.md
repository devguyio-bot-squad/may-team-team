# Idea Honing — Tmux Agent Sessions

## Q-01: Should each member get its own tmux window within a single shared session, or its own separate tmux session?

A single session with named windows means one `tmux attach` shows all members as tabs. Separate sessions means `tmux ls` lists them individually and you attach to each one separately.

**Answer:** Single tmux session per team, with each agent/member running in its own named window within that session.

## Q-02: What should the tmux session and window naming convention be?

For example: Session: `bm-<team>` (e.g., `bm-may-team`), Windows: `<member>` (e.g., `bob`, `sentinel`, `cos`). Or a different preference?

**Answer:** Session named `bm-<team>` (e.g., `bm-may-team`), windows named `<member>` (e.g., `bob`, `sentinel`, `cos`).

## Q-03: Should tmux be required, or should it fall back to the current bare-process mode if tmux is not installed?

Options: (a) Required — error if tmux not found, (b) Preferred with fallback — use tmux if available, warn and fall back to background process otherwise, (c) Opt-in flag — background by default, `--tmux` to enable.

**Answer:** Required. `bm start` should error out if tmux is not installed.

## Q-04: What should happen when `bm stop` is called — should it kill the tmux windows/session, or just stop the agent processes and leave the tmux session intact for post-mortem inspection?

**Answer:** Stop the agent processes but leave the tmux session and windows intact, so the operator can attach and inspect scrollback / post-mortem.

## Q-05: Should agent stdout/stderr go directly to the tmux pane (live output visible when attached), or still be redirected to log files with the tmux window just showing a status/tail?

**Answer:** Directly to the tmux pane — live output visible when attached.

## Q-06: When `bm start` is called and a tmux session `bm-<team>` already exists (e.g., from a previous run), what should happen?

Options: (a) Reuse it — add new windows, skip members that already have a window, (b) Kill and recreate — destroy old session and start fresh, (c) Error out — tell operator to clean up first.

**Answer:** Kill and recreate — destroy the old session and start fresh.

## Q-07: The daemon also spawns members (via webhook/poll events and `/api/members/start`). Should daemon-triggered launches also go into tmux, or only the `bm start` CLI path?

**Answer:** All local formation member launches go through tmux — both CLI-initiated (`bm start`) and daemon-triggered (webhook/poll). This is a formation-level concern per ADR-0008, not a command-level concern.

## Q-08: Should `bm status` reflect tmux session info — e.g., showing the session name and whether the operator is currently attached?

**Answer:** Yes, `bm status` should show the tmux session name and list the windows. Attached/detached state isn't important. It should also show the `tmux attach` command so the operator knows how to connect.

## Q-09: Should the daemon itself also run inside a tmux window (e.g., a dedicated `daemon` window in the same session), or should it remain a background process as it is today?

**Answer:** No. The daemon stays as a background process. It's infrastructure. Only the coding agents (Ralph orchestrator TUI / brain processes) go into tmux windows — those are the observable workloads.

## Q-10: Should there be a convenience command to attach to the tmux session (e.g., reuse `bm attach` or a new subcommand), or is showing `tmux attach -t bm-<team>` in `bm status` output sufficient?

**Answer:** Yes — `bm attach` should attach to the tmux session. The local formation's `attach` implementation becomes "attach to the tmux session." This fits the Formation trait naturally — Lima formation attaches to the VM, local formation attaches to tmux.

## Q-11: When starting a single member (`bm start bob`), should it create the tmux session if it doesn't exist yet, or require the full team to have been started first?

**Answer:** Create the tmux session with just that one window. When starting another single member later, add a window to the existing session. Session creation is lazy/incremental — no need for a full team start first.

## Q-12: Should `bm stop bob` (single member) just kill that member's process in its window, or also remove the window from the session?

**Answer:** Keep the window. `bm stop` (all or single member) kills the agent process but leaves the tmux window intact for post-mortem inspection. Consistent behavior regardless of whether stopping one member or all.

## Q-13: Should BotMinter ship with a custom tmux configuration (theme, status bar, keybinding hints)?

**Answer:** Yes. BotMinter should use a custom `tmux.conf` that includes:
- A branded theme/status bar with BotMinter identity (ASCII art or branding)
- Status bar hints showing how to switch windows and detach (operator onboarding UX)
- Visual distinction so it's immediately clear this is a BotMinter-managed session, not a regular tmux
