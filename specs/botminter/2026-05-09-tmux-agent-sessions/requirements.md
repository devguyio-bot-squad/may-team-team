# Requirements — Tmux Agent Sessions

## tmux Dependency (TMUX)

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| TMUX-01 | The system MUST use tmux as the terminal multiplexer for running agents | must-have | Q-13, R-02 |
| TMUX-02 | The system MUST require tmux to be installed; `bm start` MUST error with an actionable message if tmux is not found | must-have | Q-03 |
| TMUX-03 | The system MUST require tmux version 3.0 or later | must-have | R-01 |
| TMUX-04 | The system MUST use a dedicated tmux server socket (`-L`) to isolate BotMinter sessions from the user's personal tmux | must-have | R-01, R-03 |

## Session Topology (SESS)

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| SESS-01 | The system MUST create one tmux session per team, named `bm-<team>` | must-have | Q-01, Q-02 |
| SESS-02 | Each agent member MUST run in its own named tmux window within the team session, named `<member>` | must-have | Q-01, Q-02 |
| SESS-03 | Agent stdout and stderr MUST go directly to the tmux pane (no redirection to null or log files) | must-have | Q-05 |
| SESS-04 | The daemon MUST remain a background process and MUST NOT run inside a tmux window | must-have | Q-09 |

## Lifecycle (LIFE)

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| LIFE-01 | `bm start` (all members) MUST kill any existing `bm-<team>` tmux session and create a fresh one | must-have | Q-06 |
| LIFE-02 | `bm start <member>` MUST create the tmux session if it does not exist, or add a window to the existing session | must-have | Q-11 |
| LIFE-03 | `bm stop` (all or single member) MUST stop the agent process but MUST leave the tmux window intact for post-mortem inspection | must-have | Q-04, Q-12 |
| LIFE-04 | All local formation member launches MUST go through tmux — both CLI-initiated and daemon-triggered | must-have | Q-07 |

## Operator UX (UX)

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| UX-01 | `bm attach` MUST attach the operator to the team's tmux session | must-have | Q-10 |
| UX-02 | `bm status` MUST display the tmux session name and list of windows | must-have | Q-08 |
| UX-03 | `bm status` MUST show the command to attach (e.g., `bm attach` or `tmux -L botminter attach -t bm-<team>`) | must-have | Q-08 |

## Branding (BRAND)

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| BRAND-01 | The system MUST ship a custom `tmux.conf` loaded via `-f` that provides a branded BotMinter theme | must-have | Q-13 |
| BRAND-02 | The status bar MUST include keybinding hints showing how to switch windows and detach | must-have | Q-13 |
| BRAND-03 | The session SHOULD display BotMinter ASCII art or branding on initial attach or in the status bar | should-have | Q-13 |

## Traceability Matrix

| Requirement | Acceptance Criteria | Implementation Step | Status |
|-------------|--------------------|--------------------|--------|
| TMUX-01 | — | — | Pending |
| TMUX-02 | — | — | Pending |
| TMUX-03 | — | — | Pending |
| TMUX-04 | — | — | Pending |
| SESS-01 | — | — | Pending |
| SESS-02 | — | — | Pending |
| SESS-03 | — | — | Pending |
| SESS-04 | — | — | Pending |
| LIFE-01 | — | — | Pending |
| LIFE-02 | — | — | Pending |
| LIFE-03 | — | — | Pending |
| LIFE-04 | — | — | Pending |
| UX-01 | — | — | Pending |
| UX-02 | — | — | Pending |
| UX-03 | — | — | Pending |
| BRAND-01 | — | — | Pending |
| BRAND-02 | — | — | Pending |
| BRAND-03 | — | — | Pending |
