# Summary — Tmux Agent Sessions

## Artifacts

| Artifact | Location | ID Count |
|----------|----------|----------|
| Rough idea | `rough-idea.md` | — |
| Idea honing | `idea-honing.md` | 13 questions (Q-01 through Q-13) |
| Requirements | `requirements.md` | 18 requirements across 5 categories: TMUX (4), SESS (4), LIFE (4), UX (3), BRAND (3) |
| Research | `research/` | 3 topics: R-01 (tmux capabilities), R-02 (alternatives), R-03 (existing art) |
| Design | `design.md` | 21 acceptance criteria (AC-01 through AC-19, plus AC-07a/07b/10b), 9 design decisions (D-01 through D-09) |
| Implementation plan | `plan.md` | 4 stories (STORY-01 through STORY-04) |

## Adversarial Review Summary

### Design Document (3 reviewers, 2 rounds)

| Reviewer | Round 1 | Round 2 |
|----------|---------|---------|
| Staff Engineer | PASS (7 issues: 1 major, 6 minor) | PASS (4 minor) |
| UX Engineer | REVISE (10 issues: 3 major, 7 minor) | PASS (2 minor) |
| QE Engineer | REVISE (14 issues: 6 major, 8 minor) | PASS (3 minor) |

Key improvements from review:
- All 13 original ACs rewritten in strict Given-When-Then format with explicit And clauses
- 8 new ACs added: nested tmux detection (AC-14), TMUX_TMPDIR security (AC-15), credential leakage (AC-16), config permissions (AC-17), dead-window cleanup (AC-18), no-session attach (AC-19), per-member attach (AC-10b), AC-07 split into AC-07a/07b
- PID validation after `#{pane_pid}` query (race condition fix)
- Pre-attach cheat sheet and scroll hint in status bar (onboarding)
- `bm attach [member]` for direct window targeting
- Explicit skip message for live-window collision
- Failure-path and timing-sensitive test guidance added to testing strategy
- D-05 added to explicitly defer BRAND-03 ASCII art

### Story Breakdown (2 reviewers, 1 round)

| Reviewer | Round 1 |
|----------|---------|
| Staff Engineer | PASS (7 minor) |
| Delivery/PM | PASS (1 major, 3 minor) |

Key improvements from review:
- STORY-03 size risk acknowledged with concrete split strategy
- AC references clarified across all stories (partial vs. primitive-only)
- Duplicate AC-17 test removed from STORY-04 (covered by STORY-01)
- `Formation::shell()` cross-cutting trait change flagged
- CI prerequisite made explicit as STORY-01 precondition
- STORY-04 split risk noted (UX vs. E2E test infrastructure)

## Design Overview

The feature adds tmux-based terminal multiplexing to BotMinter's local formation. Each coding agent runs in a named tmux window within a single team session (`bm-<team>`), on an isolated tmux server socket (`-L botminter`). The daemon stays as a background process.

Key design decisions:
- **D-01:** Dedicated tmux socket for complete isolation from user's personal tmux
- **D-02:** Embedded tmux.conf with branded status bar, written with `0600` permissions
- **D-03:** tmux module at `formation/local/tmux/` (formation concern per ADR-0008)
- **D-04:** `remain-on-exit on` for post-mortem window retention
- **D-05:** BRAND-03 ASCII art deferred; satisfied by status bar branding text
- **D-06:** Shell out to tmux CLI, no external crate dependency
- **D-07:** No state.json schema changes — tmux info derived from team name
- **D-08:** No trait abstraction — concrete TmuxSession, tested via real tmux
- **D-09:** Unset TMUX_TMPDIR for socket security

## Implementation Plan Overview

4 incremental stories, each demoable:

1. **STORY-01:** tmux module foundation — config file management, session lifecycle, version detection, name validation
2. **STORY-02:** Window management — create/query/remove windows, dead pane detection, PID tracking
3. **STORY-03:** Core integration — modify launch functions and start/stop orchestration atomically (largest story — split strategy documented if it runs long)
4. **STORY-04:** Operator UX — `bm attach [member]`, `bm status` tmux info, prerequisites, E2E/exploratory tests

## Areas for Future Refinement

- **Trait abstraction:** If tmux needs to be swapped for Zellij or another multiplexer, extract a `SessionManager` trait from `TmuxSession` (documented in D-08)
- **Per-window configuration:** Currently all windows share the global tmux config. A `WindowConfig` struct could support per-member settings if needed
- **systemd service support:** Current design assumes daemon and CLI share the same `/tmp` namespace. Needs revisiting if daemon runs as a systemd service with `PrivateTmp=yes`
- **ASCII art splash:** BRAND-03 deferred per D-05 — could add a welcome banner on initial attach in a future iteration

## Next Steps

1. Review and merge the spec PR on the team repo
2. Create story issues from the plan (STORY-01 through STORY-04)
3. Decompose each story into implementation tasks via the code-task-generator skill
4. Begin implementation starting with STORY-01
