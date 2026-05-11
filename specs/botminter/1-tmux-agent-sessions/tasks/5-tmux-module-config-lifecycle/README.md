# Tasks — STORY-01: Add `formation/local/tmux/` module with config management and session lifecycle

**Parent Story:** [#5 — STORY-01: Add formation/local/tmux/ module with config management and session lifecycle](https://github.com/devguyio-bot-squad/may-team-team/issues/5)
**Parent Epic:** [#1 — Tmux agent sessions](https://github.com/devguyio-bot-squad/may-team-team/issues/1)
**Design Doc:** team/specs/botminter/1-tmux-agent-sessions/design.md
**Requirements Doc:** team/specs/botminter/1-tmux-agent-sessions/requirements.md

## Decisions

1. **Config file location:** tmux.conf is written to `~/.config/botminter/tmux.conf` (user config home), not `~/.botminter/tmux.conf` (agent runtime). This follows the existing codebase convention where `~/.config/botminter/` holds user configuration (profiles, minty config, VM templates) and `~/.botminter/` holds runtime state (`config.yml`, `state.json`, credentials). Resolved via `dirs::config_dir().join("botminter")`, matching `profile::profiles_dir()`.

2. **Config content storage:** The tmux.conf content is stored as an actual file in the repo at `crates/bm/src/formation/local/tmux/tmux.conf` and loaded via `include_str!()` at compile time. This keeps the config readable and editable as a standalone file rather than buried in a Rust const string, while still shipping it embedded in the binary.

3. **Task granularity (3 tasks):** The story decomposes into three sequential tasks: module structure + config (Task 01), version detection (Task 02), session lifecycle (Task 03). Each is independently testable and builds on the previous. Version detection is separated because it has a clean boundary (pure parsing logic + single integration test) and establishes the `tmux_cmd()` helper reused by session lifecycle.

4. **No scope escalation signals:** The story has a clear single objective, no technology unknowns, and maps directly to the design doc. Three tasks is within the expected range. No epic-scope signals detected.

## Task Catalog

| # | Title | Status | Requirements | Acceptance Criteria | Complexity |
|---|-------|--------|--------------|---------------------|------------|
| 01 | Create tmux module structure with TmuxConfig and TmuxSession::new() | pending | TMUX-04, BRAND-01 | AC-17 | Medium |
| 02 | Implement tmux version detection and parsing | pending | TMUX-03 | AC-02 (partial) | Low |
| 03 | Implement session lifecycle methods with integration tests | pending | TMUX-01, TMUX-04 | AC-02 (partial), AC-17 | Medium |

## Task Sequence

```
Task 01 ──► Task 02 ──► Task 03
```

- **Task 01** is the foundation — creates the module structure, `TmuxConfig`, and `TmuxSession::new()`. No tmux binary needed for unit tests.
- **Task 02** depends on Task 01 — adds `check_tmux_available()` and establishes the `tmux_cmd()` helper that all subsequent tmux invocations use.
- **Task 03** depends on Task 02 — implements session lifecycle methods using the `tmux_cmd()` helper and `TmuxConfig` from prior tasks. Completes the story with full integration tests.

## Traceability

All STORY-01 requirements and acceptance criteria are covered:

| Requirement | Covered By |
|-------------|------------|
| TMUX-01 | Task 03 |
| TMUX-03 | Task 02 |
| TMUX-04 | Task 01, Task 03 |
| BRAND-01 | Task 01 |

| Acceptance Criteria | Covered By |
|--------------------|------------|
| AC-02 (partial) | Task 02, Task 03 |
| AC-17 | Task 01, Task 03 |
