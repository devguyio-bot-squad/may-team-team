# Tasks — STORY-04: Add operator UX — bm attach, bm status tmux info, prerequisites, E2E tests

**Parent Story:** [#8 — STORY-04: Add operator UX — bm attach, bm status tmux info, prerequisites, E2E tests](https://github.com/devguyio-bot-squad/may-team-team/issues/8)
**Parent Epic:** [#1 — Tmux agent sessions](https://github.com/devguyio-bot-squad/may-team-team/issues/1)
**Design Doc:** team/specs/botminter/1-tmux-agent-sessions/design.md
**Requirements Doc:** team/specs/botminter/1-tmux-agent-sessions/requirements.md

## Decisions

1. **Task granularity (4 tasks):** The story decomposes into four tasks: prerequisites check (Task 01), `bm attach` implementation (Task 02), `bm status` tmux info (Task 03), and E2E/exploratory test updates with branding verification (Task 04). Each maps to a distinct area of the codebase and is independently demoable.

2. **Attach and status are parallel:** Tasks 02 and 03 are independent — `bm attach` modifies the `Formation::shell()` trait and `commands/attach.rs`, while `bm status` tmux info modifies `state/dashboard.rs` and `commands/status.rs`. No shared code changes, so they can be implemented in parallel after Task 01.

3. **Tests grouped in Task 04:** E2E and exploratory test updates are grouped into a single final task because they verify all three features together (prerequisites, attach, status). This matches the story's "split risk" guidance — if test updates prove difficult, Task 04 can be deferred without blocking the core UX features.

4. **Codebase verification finding:** The `TmuxSession` struct and `formation/local/tmux/` module do not exist in the current codebase. STORY-01/02/03 must be implemented first. All tasks list this as a dependency. The verification confirmed that the design's claims about `Formation::shell()`, `check_prerequisites()`, `StatusInfo`, `commands/attach.rs`, and existing E2E tests are accurate.

5. **No scope escalation signals:** The story has a clear bounded objective (three CLI features + test coverage), all technologies are established, and 4 tasks is within expected range.

## Task Catalog

| # | Title | Status | Requirements | Acceptance Criteria | Complexity |
|---|-------|--------|--------------|---------------------|------------|
| 01 | Add tmux prerequisite check to `check_prerequisites()` | pending | TMUX-02 | AC-01 | Low |
| 02 | Implement `bm attach` with tmux session attachment | pending | UX-01 | AC-10, AC-10b, AC-14, AC-19 | Medium |
| 03 | Add tmux session info to `bm status` | pending | UX-02, UX-03 | AC-11 | Medium |
| 04 | Verify branded config and update E2E/exploratory tests | pending | BRAND-01, BRAND-02, BRAND-03 | AC-12, AC-13 | Medium |

## Task Sequence

```
Task 01 ──┬──► Task 02 ──┐
          └──► Task 03 ──┤
                         └──► Task 04
```

- **Task 01** is the foundation — adds tmux to the prerequisite check. Small, focused change with clear acceptance criteria.
- **Task 02** depends on Task 01 — implements `bm attach` including the `Formation::shell()` trait signature change (breaking change across all implementors), CLI argument addition, cheat sheet, and nested-session detection.
- **Task 03** depends on Task 01 — adds `TmuxStatusInfo` to `StatusInfo`, updates `gather_status()` and the status display. Independent of Task 02.
- **Task 04** depends on Tasks 02 and 03 — updates E2E and exploratory tests to verify all three features together, plus branded config rendering verification.

## Traceability

All STORY-04 requirements and acceptance criteria are covered:

| Requirement | Covered By |
|-------------|------------|
| TMUX-02 | Task 01 |
| UX-01 | Task 02 |
| UX-02 | Task 03 |
| UX-03 | Task 03 |
| BRAND-01 | Task 04 |
| BRAND-02 | Task 04 |
| BRAND-03 | Task 04 |

| Acceptance Criteria | Covered By |
|--------------------|------------|
| AC-01 | Task 01 |
| AC-10 | Task 02 |
| AC-10b | Task 02 |
| AC-11 | Task 03 |
| AC-12 | Task 04 |
| AC-13 | Task 04 |
| AC-14 | Task 02 |
| AC-19 | Task 02 |
