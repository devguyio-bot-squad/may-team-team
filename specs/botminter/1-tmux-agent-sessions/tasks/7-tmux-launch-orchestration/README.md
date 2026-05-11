# Tasks — STORY-03: Wire tmux into launch functions and start/stop orchestration

**Parent Story:** [#7 — STORY-03: Wire tmux into launch functions and start/stop orchestration](https://github.com/devguyio-bot-squad/may-team-team/issues/7)
**Parent Epic:** [#1 — Tmux agent sessions](https://github.com/devguyio-bot-squad/may-team-team/issues/1)
**Design Doc:** team/specs/botminter/1-tmux-agent-sessions/design.md
**Requirements Doc:** team/specs/botminter/1-tmux-agent-sessions/requirements.md

## Decisions

1. **3-task split follows the plan's suggested sub-split:** The plan notes this is the largest story and suggests splitting into (a) launch rewrite with simple session lifecycle and (b) smart orchestration. Task 01 covers the launch rewrite, Task 02 covers the full-start session lifecycle, and Task 03 covers the single-start orchestration (skip-if-live, dead-window cleanup). Each task is independently demoable.

2. **No stop_members.rs changes:** Verified against the codebase — `stop_local_members()` uses `libc::kill(pid, SIGTERM)` which works correctly because `create_window()` returns the actual process PID inside the pane. `remain-on-exit on` keeps windows alive after the kill. No tmux-specific stop logic needed.

3. **2-second sleep can be simplified:** `start_members.rs:219` sleeps 2 seconds after launch then checks `is_alive()`. Since `create_window()` already validates the PID is alive (catches immediate exits), this sleep is redundant for the normal path. Task 02 notes this can be simplified or removed.

4. **Brain stderr tee approach:** The design says brain stderr should go to both the pane and `brain-stderr.log`. Task 01 specifies using shell redirection (`cmd 2> >(tee brain-stderr.log >&2)`) or having the brain binary log independently. The implementer can choose the simpler approach.

## Task Catalog

| # | Title | Status | Requirements | Acceptance Criteria | Complexity |
|---|-------|--------|--------------|---------------------|------------|
| 01 | Rewrite `launch_ralph()` and `launch_brain()` to use tmux windows | pending | TMUX-01, TMUX-04, SESS-02, SESS-03, SESS-04 | AC-04, AC-05, AC-15, AC-16 | High |
| 02 | Wire tmux session lifecycle into `start_local_members()` — full start path | pending | SESS-01, LIFE-01, LIFE-04 | AC-03, AC-06, AC-09 | Medium |
| 03 | Add single-start orchestration — skip-if-live, dead-window cleanup | pending | TMUX-02, LIFE-02, LIFE-03 | AC-01 (partial), AC-07a, AC-07b, AC-08, AC-18 | Medium |

## Task Sequence

```
Task 01 ──► Task 02 ──► Task 03
```

- **Task 01** rewrites the launch primitives — after this, `launch_ralph()` and `launch_brain()` accept `&TmuxSession` and create windows. But nothing calls them with tmux yet.
- **Task 02** wires tmux into `start_local_members()` for the full-start path — after this, `bm start` creates a tmux session with all member windows. The simple destroy-and-create lifecycle works end-to-end.
- **Task 03** adds the smart single-start orchestration — after this, `bm start bob` handles all edge cases (no session, add to existing, skip live, replace dead).

## Traceability

| Requirement | Covered By |
|-------------|------------|
| TMUX-01 | Task 01 |
| TMUX-02 | Task 03 |
| TMUX-04 | Task 01 |
| SESS-01 | Task 02 |
| SESS-02 | Task 01 |
| SESS-03 | Task 01 |
| SESS-04 | Task 01 |
| LIFE-01 | Task 02 |
| LIFE-02 | Task 03 |
| LIFE-03 | Task 03 |
| LIFE-04 | Task 02 |

| Acceptance Criteria | Covered By |
|--------------------|------------|
| AC-01 (partial) | Task 03 |
| AC-03 | Task 02 |
| AC-04 | Task 01 |
| AC-05 | Task 01 |
| AC-06 | Task 02 |
| AC-07a | Task 03 |
| AC-07b | Task 03 |
| AC-08 | Task 03 |
| AC-09 | Task 02 |
| AC-15 | Task 01 |
| AC-16 | Task 01 |
| AC-18 | Task 03 |
