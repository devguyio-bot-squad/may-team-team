# Summary — Tmux Agent Sessions

## Artifacts

| Artifact | Location | ID Count |
|----------|----------|----------|
| Rough idea | `rough-idea.md` | — |
| Idea honing | `idea-honing.md` | 13 questions (Q-01 through Q-13) |
| Requirements | `requirements.md` | 18 requirements across 5 categories: TMUX (4), SESS (4), LIFE (4), UX (3), BRAND (3) |
| Research | `research/` | 3 topics: R-01 (tmux capabilities), R-02 (alternatives), R-03 (existing art) |
| Design | `design.md` | 13 acceptance criteria (AC-01 through AC-13), 8 design decisions (D-01 through D-08) |
| Implementation plan | `plan.md` | 4 implementation steps (STEP-01 through STEP-04) |

## Design Overview

The feature adds tmux-based terminal multiplexing to BotMinter's local formation. Each coding agent runs in a named tmux window within a single team session (`bm-<team>`), on an isolated tmux server socket (`-L botminter`). The daemon stays as a background process.

Key design decisions:
- **D-01:** Dedicated tmux socket for complete isolation from user's personal tmux
- **D-02:** Embedded tmux.conf with branded status bar, written with `0600` permissions
- **D-03:** tmux module at `formation/local/tmux/` (formation concern per ADR-0008)
- **D-04:** `remain-on-exit on` for post-mortem window retention
- **D-05:** Shell out to tmux CLI, no external crate dependency
- **D-06:** No state.json schema changes — tmux info derived from team name
- **D-07:** No trait abstraction — concrete TmuxSession, tested via real tmux
- **D-08:** Unset TMUX_TMPDIR for socket security

## Implementation Plan Overview

4 incremental steps, each demoable:

1. **STEP-01:** tmux module foundation — config file management, session lifecycle, version detection, name validation
2. **STEP-02:** Window management — create/query/remove windows, dead pane detection, PID tracking
3. **STEP-03:** Core integration — modify launch functions and start/stop orchestration atomically
4. **STEP-04:** Operator UX — `bm attach`, `bm status` tmux info, prerequisites, E2E/exploratory tests

## Areas for Future Refinement

- **Trait abstraction:** If tmux needs to be swapped for Zellij or another multiplexer, extract a `SessionManager` trait from `TmuxSession` (documented in D-07)
- **Per-window configuration:** Currently all windows share the global tmux config. A `WindowConfig` struct could support per-member settings if needed
- **systemd service support:** Current design assumes daemon and CLI share the same `/tmp` namespace. Needs revisiting if daemon runs as a systemd service with `PrivateTmp=yes`
