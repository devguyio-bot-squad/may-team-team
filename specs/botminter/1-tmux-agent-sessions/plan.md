# Implementation Plan — Tmux Agent Sessions

## Checklist

- [ ] STEP-01: Create tmux module with config and session lifecycle
- [ ] STEP-02: Add tmux window management
- [ ] STEP-03: Integrate tmux into launch and start/stop orchestration
- [ ] STEP-04: Add operator UX — attach, status, prerequisites, E2E and exploratory tests

## CI Prerequisite

tmux 3.0+ must be installed in CI environments that run integration and E2E tests. This is consistent with the project's test philosophy (CI already requires real GitHub tokens, `podman`, and `gnome-keyring-daemon`). Add `apt install -y tmux` (or equivalent) to CI setup. Integration tests that require tmux should be documented in the test module — they naturally fail with an actionable error if tmux is missing.

---

## STEP-01: Create tmux module with config and session lifecycle

**Title:** Add `formation/local/tmux/` module with config management and session lifecycle

**Objective:** Establish the foundational tmux module as a directory module under `formation/local/`. Implement the `TmuxConfig` struct (embedded config content, atomic file writing with `0600` permissions) and the core `TmuxSession` struct (session creation, destruction, existence checks, tmux version detection, name validation).

**Implementation Guidance:**
- Create `formation/local/tmux/mod.rs` with `TmuxSession` struct and public API. All public types must be defined with at least complete signatures so the module compiles when registered.
- Create `formation/local/tmux/config.rs` with `TmuxConfig` struct and the embedded tmux.conf content as a `const &str`
- `TmuxSession::new()` validates team name against `[a-zA-Z0-9_-]`, constructs `socket_name = "botminter"` and `session_name = "bm-{team}"`
- `check_tmux_available()` runs `tmux -V`, parses version string (extract first two numeric components, ignore suffixes like `a`, `-rc`, `next-`), returns error if < 3.0. Add unit test cases for known format variants: `tmux 3.3a`, `tmux 3.4`, `tmux next-3.4`.
- All `Command::new("tmux")` invocations unset `TMUX_TMPDIR` via `.env_remove("TMUX_TMPDIR")`
- `TmuxConfig::ensure_written()` verifies `~/.botminter/` directory exists (creating if needed, same as `config::config_dir()`), then uses atomic write (temp file + rename) with `0600` permissions
- Register the module in `formation/local/mod.rs`

**Test Requirements:**
- Unit tests: name validation accepts `my-team`, `team_1`, rejects `my;team`, `team:name`, `team name`
- Unit tests: `TmuxConfig::config_content()` is non-empty and contains expected directives
- Unit tests: version parsing for `tmux 3.3a`, `tmux 3.4`, `tmux next-3.4`, `tmux 3.2-rc`
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
- `create_window(name, cmd, cwd, envs)` constructs `tmux -L botminter new-window -t <session> -n <name> -c <cwd> -e K1=V1 -e K2=V2 -- <cmd> <args...>`, then queries `#{pane_pid}` to return the process PID. After retrieving the PID, validate with `kill(pid, 0)` — if the process exited between window creation and PID query, return an error with context.
- Window name validated against `[a-zA-Z0-9_-]`
- `window_exists()` uses `tmux list-windows -F '#{window_name}'` and checks for the name
- `is_pane_dead()` uses `tmux display-message -t <target> -p '#{pane_dead}'`
- `pane_pid()` uses `tmux display-message -t <target> -p '#{pane_pid}'`
- `list_windows()` returns `Vec<TmuxWindow>` parsed from `tmux list-windows -F` output
- `remove_window()` calls `tmux kill-window -t <target>`
- `remove_dead_window()` checks `is_pane_dead()` before removing
- `session_info()` returns `SessionInfo` with window list and attach command string
- `attach()` execs `tmux -L botminter attach-session -t <session>`. Note: this call blocks until the user detaches — all callers of `Formation::shell()` must tolerate this.

**Test Requirements:**
- Integration tests: create window running `sleep 300` → `pane_pid()` returns a valid PID → `is_pane_dead()` returns false
- Integration tests: create window running `true` (exits immediately) → after brief sleep, `is_pane_dead()` returns true (with `remain-on-exit on`)
- Integration tests: `remove_dead_window()` removes dead window, leaves live window untouched
- Integration tests: `list_windows()` returns correct window names and indices
- Integration tests: window name validation rejects invalid characters

**Integration:** Builds on STEP-01's session lifecycle. These methods are consumed by STEP-03 (launch + orchestration integration).

**Demo:** Run integration tests showing: create a session, add two windows (one long-running, one that exits), list windows showing both, detect the dead pane, remove only the dead window.

**Requirements:** SESS-02, SESS-03, LIFE-03
**Acceptance Criteria:** AC-04 (partial — output visible in pane), AC-08 (partial — dead pane detection)
**Dependencies:** STEP-01

---

## STEP-03: Integrate tmux into launch and start/stop orchestration

**Title:** Wire tmux into `launch_ralph()`, `launch_brain()`, and `start_local_members()` in a single atomic step

**Objective:** Replace bare background process spawning with tmux window creation in the launch functions, and wire tmux session lifecycle into `start_local_members()`. This step is atomic — launch signature changes and caller updates happen together so the codebase compiles at every commit.

**Implementation Guidance:**

*Launch function changes (`formation/launch.rs`):*
- Add `tmux: &TmuxSession` parameter to both `launch_ralph()` and `launch_brain()`
- Build the command as `&[&str]` (e.g., `&["ralph", "run", "-p", "PROMPT.md"]`) — NOT a shell string
- Collect env vars as `Vec<(&str, &str)>` from the existing bridge/credential logic
- Call `tmux.create_window(member_name, cmd, workspace, &envs)` instead of `Command::new().spawn()`
- Remove `Stdio::null()` redirections (tmux pane captures output natively)
- Keep brain stderr log file redirect (`brain-stderr.log`) as a secondary diagnostic capture alongside tmux pane output. The command run inside the tmux window should tee stderr to the log file while still showing it in the pane (e.g., via shell redirection `cmd 2> >(tee brain-stderr.log >&2)` or by configuring the command to log stderr independently). This provides a persistent log file even after the tmux session is destroyed.
- Remove `reap_child()` calls for member launches (tmux manages the process). Retain `reap_child()` for daemon spawning.
- The returned PID (from `#{pane_pid}`) is recorded in `state.json` as before

*Start orchestration changes (`formation/start_members.rs`):*
- Call `TmuxSession::check_tmux_available()?` and `TmuxConfig::ensure_written()?` at the top
- Construct `TmuxSession::new(&team.name)?`
- Full start (`member_filter.is_none()`): `tmux.destroy_if_exists()` then `tmux.create()`. Log "Destroying previous session bm-<team>" when an existing session is found.
- Single start: `if !tmux.exists() { tmux.create()? }`
- Before each member launch: if `tmux.window_exists(&member) && tmux.is_pane_dead(&member)?`, call `tmux.remove_dead_window(&member)?`. This handles the case where `bm stop` removed the PID from state.json but `remain-on-exit on` left the dead tmux window.
- Pass `&tmux` to `launch_ralph()` / `launch_brain()`

*Stop behavior:*
- No tmux-specific changes needed — existing PID-based `kill(pid, SIGTERM)` works because the PID is the actual process inside the pane. `remain-on-exit on` keeps the window.

*Daemon path:*
- The daemon calls `start_local_members()` which now handles tmux internally. The daemon inherits `PATH` (including tmux) from the operator's environment at startup and can access the tmux socket at `/tmp/tmux-<uid>/botminter` since it runs on the same host as the same user.

*Assumption:* The daemon and CLI share the same `/tmp` namespace. This is true for direct process spawning but would need revisiting if the daemon is ever run as a systemd service with `PrivateTmp=yes`.

**Test Requirements:**
- Integration test: `launch_ralph(&tmux, ...)` with a stub command → window exists with correct name → PID matches a running process
- Integration test: verify `brain-stderr.log` is written alongside tmux pane output for brain launches
- Integration test: env vars passed via `-e` are accessible inside the window
- Integration test: full start creates session + windows → stop kills processes → windows show "Pane is dead" → second full start destroys old session and creates fresh one
- Integration test: single member start creates session with one window → second single member adds window to existing session
- Integration test: stop member → start same member → dead window removed, new window created with live process

**Integration:** This is the core integration step. It modifies `launch.rs` and `start_members.rs` atomically — both signature changes and caller updates in the same commit. After this, `bm start` and `bm stop` work with tmux end-to-end.

**Demo:** Run `bm start` → `tmux -L botminter list-windows -t bm-<team>` shows all member windows → `bm stop` → windows remain with dead panes → `bm start bob` → dead window replaced with live window.

**Requirements:** TMUX-01, TMUX-02, TMUX-04, SESS-01, SESS-02, SESS-03, SESS-04, LIFE-01, LIFE-02, LIFE-03, LIFE-04
**Acceptance Criteria:** AC-03, AC-04, AC-05, AC-06, AC-07, AC-08, AC-09
**Dependencies:** STEP-02

---

## STEP-04: Add operator UX — attach, status, prerequisites, and test coverage

**Title:** Implement `bm attach`, tmux info in `bm status`, prerequisites error messages, branded config verification, and E2E/exploratory test updates

**Objective:** Complete the operator-facing UX and test coverage. `bm attach` attaches to the tmux session (with nested-session warning), `bm status` shows tmux session info and attach hint, `check_prerequisites()` includes tmux with actionable error messages. Update E2E and exploratory tests to verify tmux behavior.

**Implementation Guidance:**
- `LinuxLocalFormation::shell()`: change from error to `TmuxSession::new(&self.team_name)?.attach()`. Note: `attach()` blocks until the user detaches — this is correct for `shell()` semantics (the existing Lima implementation also blocks via `lima.exec_shell()`). Before attaching, check `$TMUX` env var — if set, print warning about nested sessions and `C-b d` to detach.
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

**Integration:** This is the final step — after this, the full operator journey works end-to-end.

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
**Dependencies:** STEP-03
