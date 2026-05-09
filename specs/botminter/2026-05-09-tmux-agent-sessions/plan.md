# Implementation Plan — Tmux Agent Sessions

## Checklist

- [ ] STEP-01: Create tmux module with config and session lifecycle
- [ ] STEP-02: Add tmux window management
- [ ] STEP-03: Integrate tmux into member launch functions
- [ ] STEP-04: Wire tmux into start/stop orchestration
- [ ] STEP-05: Add operator UX — attach, status, prerequisites
- [ ] STEP-06: Update E2E and exploratory test coverage

---

## STEP-01: Create tmux module with config and session lifecycle

**Title:** Add `formation/local/tmux/` module with config management and session lifecycle

**Objective:** Establish the foundational tmux module as a directory module under `formation/local/`. Implement the `TmuxConfig` struct (embedded config content, atomic file writing with `0600` permissions) and the core `TmuxSession` struct (session creation, destruction, existence checks, tmux version detection, name validation).

**Implementation Guidance:**
- Create `formation/local/tmux/mod.rs` with `TmuxSession` struct and public API
- Create `formation/local/tmux/config.rs` with `TmuxConfig` struct and the embedded tmux.conf content as a `const &str`
- `TmuxSession::new()` validates team name against `[a-zA-Z0-9_-]`, constructs `socket_name = "botminter"` and `session_name = "bm-{team}"`
- `check_tmux_available()` runs `tmux -V`, parses version string, returns error if < 3.0
- All `Command::new("tmux")` invocations unset `TMUX_TMPDIR` via `.env_remove("TMUX_TMPDIR")`
- `TmuxConfig::ensure_written()` uses atomic write (temp file + rename) with `0600` permissions, same pattern as `state.json`
- Register the module in `formation/local/mod.rs`

**Test Requirements:**
- Unit tests: name validation accepts `my-team`, `team_1`, rejects `my;team`, `team:name`, `team name`
- Unit tests: `TmuxConfig::config_content()` is non-empty and contains expected directives
- Integration tests: `check_tmux_available()` returns a version on systems with tmux
- Integration tests: session create → exists returns true → destroy → exists returns false
- Integration tests: config file written with correct permissions (stat check)

**Integration:** This step establishes the module structure that all subsequent steps build on. No existing code is modified — this is purely additive.

**Demo:** Run the integration tests showing a tmux session being created and destroyed programmatically. Show `~/.botminter/tmux.conf` written with correct content and `0600` permissions.

**Requirements:** TMUX-01, TMUX-03, TMUX-04, BRAND-01
**Acceptance Criteria:** AC-01 (partial — version check), AC-02 (version error)
**Dependencies:** —

---

## STEP-02: Add tmux window management

**Title:** Implement window lifecycle in `TmuxSession` — create, query, and manage windows

**Objective:** Add window management methods to `TmuxSession`: creating named windows that run commands with environment variables via the `-e` flag, querying window state (list, PID, dead pane detection), and removing dead windows.

**Implementation Guidance:**
- `create_window(name, cmd, cwd, envs)` constructs `tmux -L botminter new-window -t <session> -n <name> -c <cwd> -e K1=V1 -e K2=V2 -- <cmd> <args...>`, then queries `#{pane_pid}` to return the process PID
- Window name validated against `[a-zA-Z0-9_-]`
- `window_exists()` uses `tmux list-windows -F '#{window_name}'` and checks for the name
- `is_pane_dead()` uses `tmux display-message -t <target> -p '#{pane_dead}'`
- `pane_pid()` uses `tmux display-message -t <target> -p '#{pane_pid}'`
- `list_windows()` returns `Vec<TmuxWindow>` parsed from `tmux list-windows -F` output
- `remove_window()` calls `tmux kill-window -t <target>`
- `remove_dead_window()` checks `is_pane_dead()` before removing
- `session_info()` returns `SessionInfo` with window list and attach command string
- `attach()` execs `tmux -L botminter attach-session -t <session>`

**Test Requirements:**
- Integration tests: create window running `sleep 300` → `pane_pid()` returns a valid PID → `is_pane_dead()` returns false
- Integration tests: create window running `true` (exits immediately) → `is_pane_dead()` returns true (with `remain-on-exit on`)
- Integration tests: `remove_dead_window()` removes dead window, leaves live window untouched
- Integration tests: `list_windows()` returns correct window names and indices
- Integration tests: window name validation rejects invalid characters

**Integration:** Builds on STEP-01's session lifecycle. These methods are consumed by STEP-03 (launch integration) and STEP-04 (orchestration).

**Demo:** Run integration tests showing: create a session, add two windows (one long-running, one that exits), list windows showing both, detect the dead pane, remove only the dead window.

**Requirements:** SESS-02, SESS-03, LIFE-03
**Acceptance Criteria:** AC-04 (partial — output visible in pane), AC-08 (partial — dead pane detection)
**Dependencies:** STEP-01

---

## STEP-03: Integrate tmux into member launch functions

**Title:** Modify `launch_ralph()` and `launch_brain()` to create tmux windows

**Objective:** Replace the bare background process spawning in `launch_ralph()` and `launch_brain()` with tmux window creation, so each agent member runs inside a named tmux window with stdout/stderr visible in the pane.

**Implementation Guidance:**
- Add `tmux: &TmuxSession` parameter to both `launch_ralph()` and `launch_brain()`
- Build the command as `&[&str]` (e.g., `&["ralph", "run", "-p", "PROMPT.md"]`) — NOT a shell string
- Collect env vars as `Vec<(&str, &str)>` from the existing bridge/credential logic
- Call `tmux.create_window(member_name, cmd, workspace, &envs)` instead of `Command::new().spawn()`
- Remove `Stdio::null()` redirections (tmux pane captures output natively)
- Remove brain stderr log file redirect (`brain-stderr.log`) — pane captures stderr
- Remove `reap_child()` calls for member launches (tmux manages the process)
- The returned PID (from `#{pane_pid}`) is recorded in `state.json` as before
- Retain `reap_child()` for daemon spawning (unchanged)

**Test Requirements:**
- Integration test: `launch_ralph(&tmux, ...)` with a stub command → window exists with correct name → PID matches a running process
- Integration test: verify no `brain-stderr.log` created for brain launches
- Integration test: env vars passed via `-e` are accessible inside the window (verify via `tmux show-environment`)

**Integration:** Modifies `formation/launch.rs`. Callers (`start_local_members()`) are updated in STEP-04. This step changes signatures but STEP-04 wires the callers.

**Demo:** Manually call `launch_ralph(&tmux, ...)` in a test, then `tmux -L botminter attach -t bm-test` to see the process running with visible output in the window.

**Requirements:** TMUX-01, SESS-02, SESS-03
**Acceptance Criteria:** AC-03 (partial — windows created), AC-04 (stdout/stderr in pane)
**Dependencies:** STEP-02

---

## STEP-04: Wire tmux into start/stop orchestration

**Title:** Integrate tmux session lifecycle into `start_local_members()` and stop behavior

**Objective:** Wire the tmux session management into the member start orchestration function. Handle session creation/destruction based on full vs. single-member start. Add dead window cleanup before member restarts. Ensure stop behavior works with `remain-on-exit on`.

**Implementation Guidance:**
- In `start_local_members()`:
  - Call `TmuxSession::check_tmux_available()?` and `TmuxConfig::ensure_written()?` at the top
  - Construct `TmuxSession::new(&team.name)?`
  - Full start (`member_filter.is_none()`): `tmux.destroy_if_exists()` then `tmux.create()`
  - Single start: `if !tmux.exists() { tmux.create()? }`
  - Before each member launch: if `tmux.window_exists(&member) && tmux.is_pane_dead(&member)?`, call `tmux.remove_dead_window(&member)?`
  - Pass `&tmux` to `launch_ralph()` / `launch_brain()`
- In stop logic: no tmux-specific changes needed — existing PID-based `kill(pid, SIGTERM)` works because the PID is the actual process inside the pane. `remain-on-exit on` in the config keeps the window.
- Daemon-mediated path: the daemon calls `start_local_members()` which now handles tmux internally. The daemon inherits `PATH` (including tmux) from the operator's environment at startup.

**Test Requirements:**
- Integration test: full start creates session + windows → stop kills processes → windows show "Pane is dead" → second full start destroys old session and creates fresh one
- Integration test: single member start creates session with one window → second single member adds window to existing session
- Integration test: stop member → start same member → dead window removed, new window created with live process

**Integration:** This is the core integration step — after this, `bm start` and `bm stop` work with tmux end-to-end. Previous steps provided the building blocks.

**Demo:** Run `bm start` → `tmux -L botminter list-windows -t bm-<team>` shows all member windows → `bm stop` → windows remain with dead panes → `bm start bob` → dead window replaced with live window.

**Requirements:** TMUX-02, TMUX-04, SESS-01, SESS-04, LIFE-01, LIFE-02, LIFE-03, LIFE-04
**Acceptance Criteria:** AC-03, AC-05, AC-06, AC-07, AC-08, AC-09
**Dependencies:** STEP-03

---

## STEP-05: Add operator UX — attach, status, prerequisites

**Title:** Implement `bm attach`, tmux info in `bm status`, prerequisites error messages, and branded config

**Objective:** Complete the operator-facing UX: `bm attach` attaches to the tmux session (with nested-session warning), `bm status` shows tmux session info and attach hint, and `check_prerequisites()` includes tmux with actionable error messages. Verify the branded status bar works end-to-end.

**Implementation Guidance:**
- `LinuxLocalFormation::shell()`: change from error to `TmuxSession::new(&self.team_name)?.attach()`. Before attaching, check `$TMUX` env var — if set, print warning about nested sessions and `C-b d` to detach.
- `LinuxLocalFormation::check_prerequisites()`: add tmux check via `TmuxSession::check_tmux_available()`. Error messages: "tmux is required but not found. Install with: apt install tmux / dnf install tmux" and "tmux 3.0+ is required (found X.Y). Please upgrade."
- `state/dashboard.rs`: add `tmux: Option<TmuxStatusInfo>` to `StatusInfo`. In `gather_status()`, construct `TmuxSession` and call `session_info()` if session exists.
- `commands/status.rs`: display tmux info after daemon info: `tmux: bm-may-team (3 windows)` and `attach: bm attach`.
- Verify branded tmux.conf renders correctly: status bar with "botminter", session name, window tabs, keybinding hints.

**Test Requirements:**
- Integration test: `check_prerequisites()` succeeds with tmux installed
- Integration test: `shell()` on a running session attaches (can test by immediately detaching via `send-keys C-b d`)
- E2E test updates: after `bm start`, verify `tmux -L botminter has-session -t bm-<team>` succeeds and `tmux -L botminter list-windows` returns expected windows
- E2E test updates: `bm status` output contains tmux session name and "bm attach"
- E2E test updates: after `bm stop`, verify windows still exist with dead panes
- Exploratory test updates: add tmux verification to relevant phases (session creation, window naming, post-mortem scrollback)

**Integration:** This is the final step — after this, the full operator journey works: `bm start` → `bm status` (shows tmux info) → `bm attach` (enters branded tmux session) → navigate windows → `C-b d` detach → `bm stop` → `bm attach` (see dead panes with scrollback).

**Demo:** Full operator journey:
1. `bm start` — members launch in tmux
2. `bm status` — shows `tmux: bm-may-team (3 windows)` and `attach: bm attach`
3. `bm attach` — enters tmux session with branded status bar showing "botminter | bm-may-team | 1:bob 2:cos 3:sentinel | C-b n:next C-b p:prev C-b d:detach | 14:23"
4. Navigate windows with `C-b n` — see live agent output
5. `C-b d` to detach
6. `bm stop` — processes die, windows remain
7. `bm attach` — see dead pane messages with scrollback intact

**Requirements:** TMUX-02, UX-01, UX-02, UX-03, BRAND-01, BRAND-02, BRAND-03
**Acceptance Criteria:** AC-01, AC-10, AC-11, AC-12, AC-13
**Dependencies:** STEP-04
