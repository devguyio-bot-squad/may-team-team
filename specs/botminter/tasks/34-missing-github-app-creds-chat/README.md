# Tasks — bm chat/meetings missing GitHub App credentials

**Parent Story:** [#34 — bm chat and bm meetings do not inject GitHub App credentials](https://github.com/devguyio-bot-squad/may-team-team/issues/34)
**Parent Epic:** N/A (standalone bug)
**Design Doc:** N/A

## Decisions

- **Single-task decomposition:** This bug has a single root cause (missing credential injection in `launch_session()`) with a straightforward fix. A single task covers the implementation and tests. No multi-task decomposition is needed.
- **Environment variable injection approach:** Set env vars on the current process (`std::env::set_var` / `std::env::remove_var`) before launching the coding agent, rather than modifying the `Formation::exec_in()` trait to support env vars. Rationale: `bm chat` and `bm meetings` are one-shot commands — env pollution is not a concern. Both execution paths (formation `exec_in` child process and direct `Command::exec()`) inherit parent env, so a single injection point covers both. Known coupling: this approach depends on `exec_in` inheriting parent env without sanitization. If `exec_in` is changed to use explicit env maps (e.g., for container formations per ADR-0008), credential injection must move to the `exec_in` call site.
- **Credential detection via filesystem:** Check for `workspace/.config/gh/hosts.yml` file existence (not just the directory) rather than querying the keyring. Rationale: the directory is created by the daemon during `bm start`. Validating `hosts.yml` existence prevents setting a broken `GH_CONFIG_DIR` when the directory exists but is empty or corrupted. This avoids adding keyring dependencies to the chat flow.
- **Extract injection to standalone function:** The credential detection and env mutation logic is extracted into `inject_app_credentials()` for independent unit testability. This mirrors the pattern in `formation/launch.rs` where `collect_bridge_env_vars()` and `vars_to_unset()` are standalone functions.
- **Operator feedback:** Emit `eprintln!` messages indicating which identity is in use. This was flagged by all three adversarial reviewers as a significant gap — operators had no way to know which GitHub identity a chat session would use.

## Task Catalog

| # | Title | Status | Requirements | Acceptance Criteria | Complexity |
|---|-------|--------|--------------|---------------------|------------|
| 01 | Inject GitHub App credentials into chat and meeting sessions | pending | CRED-01, CRED-02, CRED-03 | AC-01, AC-02, AC-03, AC-04, AC-05, AC-06 | Low |

## Task Sequence

Single task — no dependencies or sequencing needed. The fix is localized to `crates/bm/src/chat/mod.rs:launch_session()`.

## Requirements

| ID | Requirement |
|----|-------------|
| CRED-01 | `bm chat` and `bm meetings` must inject `GH_CONFIG_DIR` pointing to the member's App credential path when App credentials are available |
| CRED-02 | `bm chat` and `bm meetings` must unset `GH_TOKEN` and `GITHUB_TOKEN` when injecting `GH_CONFIG_DIR` to prevent override |
| CRED-03 | `bm chat` and `bm meetings` must emit operator-visible feedback indicating which GitHub identity is in use |

## Acceptance Criteria

| ID | Criterion |
|----|-----------|
| AC-01 | Given a workspace with `.config/gh/` directory present, when `launch_session()` is called, then `GH_CONFIG_DIR` is set to that path |
| AC-02 | Given `GH_TOKEN`/`GITHUB_TOKEN` are set and App credentials exist, when `launch_session()` runs, then those vars are removed |
| AC-03 | Given a workspace without `.config/gh/`, when `launch_session()` is called, then no `GH_CONFIG_DIR` is set and existing tokens are preserved |
| AC-04 | Given credential injection runs before execution branching, when either `exec_in` or `Command::exec()` path is taken, then the coding agent inherits the injected credentials |
| AC-05 | Given App credentials are found (or not), when `launch_session()` runs, then a message is emitted to stderr indicating which GitHub identity will be used |
| AC-06 | Given `.config/gh/` directory exists but `hosts.yml` is missing, when `launch_session()` is called, then `GH_CONFIG_DIR` is NOT set and a warning is emitted |
