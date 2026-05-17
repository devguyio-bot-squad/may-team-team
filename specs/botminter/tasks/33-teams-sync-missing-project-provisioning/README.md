# Tasks — bm teams sync missing new project provisioning

**Parent Bug:** [#33 — bm teams sync does not provision new projects into member workspaces](https://github.com/devguyio-bot-squad/may-team-team/issues/33)
**Parent Epic:** N/A (standalone bug)
**Design Doc:** N/A

## Decisions

- **Single-task decomposition:** This bug has a single root cause (missing new-project provisioning in `sync_workspace()`) with a localized fix. The implementation touches two files (`sync.rs` and `team_sync.rs`) plus a signature update in `mod.rs`, but the change is cohesive — splitting it would create unnecessary coupling between tasks. A single task covers the implementation and tests.
- **Parameter threading approach:** Pass the manifest's project list as `&[(&str, &str)]` directly to `sync_workspace()` rather than having `sync_workspace()` read the manifest itself. Rationale: `sync_workspace()` is a low-level function that operates on a single workspace — it should not know about the manifest. The caller (`sync_team_workspaces()`) already has the project list built at line 91-96 as `project_refs`. This follows the existing pattern: `create_workspace_repo()` receives `projects: &[(&str, &str)]` the same way.
- **Reuse existing primitives:** The fix calls `git_submodule_add()` and `checkout_member_branch()` — both already exist and are well-tested. `git_submodule_add()` is idempotent (checks for existing submodule before adding). No new helper functions are needed.
- **Provisioning placement:** New project provisioning goes after the existing submodule update loop (lines 110-131) and before context file re-copy (line 133). This ordering ensures: (1) existing projects are updated first, (2) new projects are added, (3) context injection and agent dir assembly see all projects (they run later and discover from filesystem).
- **SyncEvent for feedback:** Add a `ProjectProvisioned(String)` variant to `SyncEvent` so the command layer can distinguish new-project provisioning from routine submodule updates. The command layer renders this event unconditionally (not only in verbose mode) — the original bug was a silent failure, and replacing it with a silent success would undermine operator trust.
- **Partial-failure resilience:** If provisioning fails for one project (e.g., unreachable fork URL), continue attempting remaining projects. Collect failures and report them after all projects are attempted. Errors are wrapped with `.with_context()` including the project name and fork URL, following the pattern at `repo.rs:281-288`. Re-running `bm teams sync` recovers from transient failures due to `git_submodule_add()` idempotency.

## Verification Results

- `sync_workspace()` at `sync.rs:83` — verified: takes 7 params, no projects param currently
- `sync_team_workspaces()` at `team_sync.rs:63` — verified: builds `project_refs` at line 91-96 but only passes to `create_workspace_repo()` (line 145)
- `git_submodule_add()` at `util.rs:209` — verified: idempotent, checks `git submodule status` before adding
- `checkout_member_branch()` at `sync.rs:234` — verified: handles existing branch checkout and new branch creation
- `create_workspace_repo()` at `repo.rs:172` — verified: project provisioning pattern at lines 274-296 is the reference implementation
- `project_names` discovery at `sync.rs:176-189` — verified: reads from filesystem, so newly-added submodules are automatically included
- No other callers of `sync_workspace()` besides `team_sync.rs` and test code in `sync.rs`

## Task Catalog

| # | Title | Status | Requirements | Acceptance Criteria | Complexity |
|---|-------|--------|--------------|---------------------|------------|
| 01 | Provision new project submodules during workspace sync | pending | SYNC-01, SYNC-02, SYNC-03, SYNC-04 | AC-01, AC-02, AC-03, AC-04, AC-05, AC-06, AC-07, AC-08 | Low |

## Task Sequence

Single task — no dependencies or sequencing needed. The fix spans `sync.rs` (primary), `team_sync.rs` (call site), and `mod.rs` (re-export), but these changes are cohesive and must be applied together.

## Requirements

| ID | Requirement |
|----|-------------|
| SYNC-01 | `bm teams sync` must detect projects in the manifest that are missing from existing workspace `projects/` directories and provision them as git submodules |
| SYNC-02 | Newly-provisioned project submodules must have the member's branch checked out (not detached HEAD) |
| SYNC-03 | Newly-provisioned projects must be included in downstream workspace operations: context injection (CLAUDE.md workspace context) and agent directory assembly (symlinks) |
| SYNC-04 | Provisioning failures for individual projects must not abort the entire sync; errors must include the project name and fork URL for actionable diagnosis |

## Acceptance Criteria

| ID | Criterion |
|----|-----------|
| AC-01 | Given a workspace with no projects and a manifest with one project, when `sync_workspace()` is called with the project list, then the project is provisioned as a git submodule in `projects/<name>/` |
| AC-02 | Given a new project submodule provisioned during sync, when provisioning completes, then the submodule is on the member's branch (not detached HEAD) |
| AC-03 | Given a workspace with existing projects and a manifest with the same projects, when `sync_workspace()` is called, then existing projects are updated normally with no errors |
| AC-04 | Given a project was already provisioned in a prior sync, when `sync_workspace()` is called again with the same manifest, then no duplicate or error occurs (idempotent) |
| AC-05 | Given a new project is provisioned, when context injection and agent dir assembly run, then the new project appears in CLAUDE.md context and agent directory |
| AC-06 | Given any run mode and a new project provisioned, when sync completes, then a `SyncEvent::ProjectProvisioned` event is emitted and rendered unconditionally (not only in verbose mode) |
| AC-07 | Given a manifest with two new projects where the second has an unreachable fork URL, when `sync_workspace()` runs, then the first project is provisioned, the second fails with an actionable error, and the sync reports the failure |
| AC-08 | Given a project with an invalid fork URL, when provisioning fails, then the error includes the project name and fork URL (following `.with_context()` pattern from `repo.rs:281-288`) |
