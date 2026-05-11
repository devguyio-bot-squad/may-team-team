# Tasks — STORY-02: Implement window lifecycle in `TmuxSession` — create, query, and manage windows

**Parent Story:** [#6 — STORY-02: Implement window lifecycle in TmuxSession](https://github.com/devguyio-bot-squad/may-team-team/issues/6)
**Parent Epic:** [#1 — Tmux agent sessions](https://github.com/devguyio-bot-squad/may-team-team/issues/1)
**Design Doc:** team/specs/botminter/1-tmux-agent-sessions/design.md
**Requirements Doc:** team/specs/botminter/1-tmux-agent-sessions/requirements.md

## Decisions

1. **Task granularity (3 tasks):** The story decomposes into three sequential tasks along functional boundaries: window creation (Task 01), window querying (Task 02), window removal + attach + integration tests (Task 03). Each is independently testable. Task 01 is the most complex (env var security, PID validation); Task 02 is pure querying; Task 03 ties everything together with the full lifecycle integration test.

2. **No STORY-01 module exists yet:** Verification confirmed the tmux module from STORY-01 doesn't exist in the codebase yet (expected — stories are sequential). Tasks are written against the STORY-01 API as defined in the design doc. No discrepancies found.

3. **`attach()` uses blocking `.status()` not `exec`:** The design says `attach()` "execs" into tmux, but Rust's `Command::status()` blocks until the child exits (user detaches), which achieves the same effect without replacing the process. This is simpler and matches how `shell()` callers work. The `exec` approach (via `std::os::unix::process::CommandExt::exec()`) could be used instead but would prevent any cleanup code after detach.

## Task Catalog

| # | Title | Status | Requirements | Acceptance Criteria | Complexity |
|---|-------|--------|--------------|---------------------|------------|
| 01 | Implement `create_window()` with env var passing and PID retrieval | pending | SESS-02, SESS-03 | AC-04 (partial) | Medium |
| 02 | Implement window query methods — `window_exists()`, `is_pane_dead()`, `pane_pid()`, `list_windows()` | pending | SESS-02, LIFE-03 | AC-08 (partial) | Medium |
| 03 | Implement `kill_window_process()`, window removal, `session_info()`, `attach()`, and integration tests | pending | SESS-02, LIFE-03 | AC-04 (partial), AC-08 (partial) | Medium |

## Task Sequence

```
Task 01 ──► Task 02 ──► Task 03
```

- **Task 01** creates windows — the primitive all other methods operate on. Must be complete before querying or removing windows.
- **Task 02** adds query methods — `window_exists()`, `is_pane_dead()`, `pane_pid()`, `list_windows()`. These are consumed by Task 03's `remove_dead_window()` and `session_info()`.
- **Task 03** completes the lifecycle: removal, session aggregation, attach, and full integration tests covering the entire window lifecycle end-to-end.

## Traceability

All STORY-02 requirements and acceptance criteria are covered:

| Requirement | Covered By |
|-------------|------------|
| SESS-02 | Task 01, Task 02, Task 03 |
| SESS-03 | Task 01 |
| LIFE-03 | Task 02, Task 03 |

| Acceptance Criteria | Covered By |
|--------------------|------------|
| AC-04 (partial) | Task 01, Task 03 |
| AC-08 (partial) | Task 02, Task 03 |
