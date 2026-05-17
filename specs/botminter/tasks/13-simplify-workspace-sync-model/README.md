# Tasks — Simplify workspace sync model: eliminate member branches and fix doc contradictions

**Parent Story:** #13
**Project:** botminter

## Decisions

### Decomposition rationale

Split into 2 tasks by change type: code changes (Task 01) and documentation fixes (Task 02). This separation ensures:
- Code changes can be tested independently with the full test suite
- Doc changes don't create merge conflicts with code changes
- Code review can focus on behavior changes vs documentation accuracy separately

### Task 01 scope

Grouped all code-related ACs (AC-01, AC-02, AC-06, AC-07, AC-08) into one task because they're tightly coupled — removing `checkout_member_branch()` requires updating its call sites, adding migration logic, fixing error handling, and updating tests in the same files. Splitting these would create artificial dependencies.

Scope explicitly covers both `sync.rs` (function + call sites) and `repo.rs` (inline branch creation logic at lines 269-271 and 292-293) since they have independent implementations of member branch checkout. Also covers `commands/teams/sync.rs` for SyncEvent display handler updates.

### Task 02 scope

Grouped all documentation ACs (AC-03, AC-04, AC-05) together. Extended scope to include:
- Profile template source files (`profiles/agentic-sdlc-planning/context.md`, `profiles/scrum/context.md`) because they are the root cause of the doc contradictions
- MkDocs docs (`docs/content/concepts/workspace-model.md`, `docs/content/reference/cli.md`, `docs/content/how-to/launch-members.md`) that describe member branches as current behavior
- Project CLAUDE.md (`projects/botminter/CLAUDE.md`) workspace model section

Explicitly constrained: do NOT rename profile template files from `context.md` — only fix content claims. The extraction code handles the rename via `context_file` config.

### Migration approach

Chose in-place migration during `sync_workspace()` rather than a separate migration command because:
- All workspaces already run `bm teams sync` regularly
- Migration is a one-time operation per workspace that naturally fits the sync flow
- No operator action needed beyond running the existing sync command
- A dedicated migration command would be throwaway code

Migration uses `git branch -d` (safe delete, not `-D` force). If the old branch has unmerged commits, a warning is logged and the branch is preserved — operator can investigate.

### Error handling design principle

- `SyncEvent` variants for normal operational events the operator should know about (migration happened, project provisioned)
- `eprintln!` for warnings about failures that don't block the operation (submodule update failed)
- Both `.ok()` sites (sync.rs:106 for team submodule, sync.rs:126 for project submodules) must be fixed — the original task missed the second site

### Codebase verification results

All claims in issue #13 verified against the current codebase:
- `checkout_member_branch()` at sync.rs:269-294 — confirmed, no tracking setup
- Inline branch creation in `create_workspace_repo()` at repo.rs:269-271 and 292-293 — confirmed separate implementation
- `fs::copy()` at repo.rs:370-384 — confirmed copies, NOT symlinks
- `.ok()` at sync.rs:106 AND sync.rs:126 — confirmed TWO silent error swallowing sites
- Profile templates use `context.md` filename, not `CLAUDE.md` — confirmed
- Team CLAUDE.md claims "symlinks" and "Auto" propagation — confirmed incorrect
- SKILL.md Rule 2 describes CLAUDE.md → CLAUDE.md (no-op) — confirmed incorrect
- MkDocs docs reference "member branches" in 3 files — confirmed, must be updated

## Adversarial Review

### Round 1 — 3 reviewers, all returned REVISE

Issues addressed:
1. **[HIGH]** Both `.ok()` sites (106 AND 126) now explicitly listed — Staff Engineer + QE Engineer overlap
2. **[HIGH]** `commands/teams/sync.rs` added to files to modify for display handler — UX Engineer
3. **[HIGH]** Missing doc files added to Task 02 (workspace-model.md, cli.md, launch-members.md, projects/botminter/CLAUDE.md) — UX Engineer
4. **[MEDIUM]** Dead SyncEvent variants cleanup specified — UX + QE overlap
5. **[MEDIUM]** repo.rs inline branch creation explicitly scoped — Staff Engineer
6. **[MEDIUM]** Migration edge cases specified (main doesn't exist, unmerged commits, `-d` vs `-D`) — Staff + QE
7. **[MEDIUM]** Dedicated migration test cases added — QE Engineer
8. **[MEDIUM]** Migration events unconditional (not gated on verbose) — UX Engineer
9. **[MEDIUM]** Test enumeration categorized (update/add/unchanged) — Staff Engineer
10. **[LOW]** Line numbers replaced with content search patterns in Task 02 — QE + UX overlap

Issues acknowledged but not addressed (severity too low or out of scope):
- Staff Engineer suggested separating migration into a subtask — rejected because migration and removal are tightly coupled (you can't remove `checkout_member_branch` without either migrating or breaking existing workspaces)
- QE Engineer noted E2E AC-08 is a regression gate not behavioral verification — accepted as-is since E2E tests should be updated to verify `main` branch as part of AC-08

## Task Catalog

| # | Title | Status | Acceptance Criteria | Complexity |
|---|-------|--------|---------------------|------------|
| 01 | Eliminate member branches and fix error handling | pending | AC-01, AC-02, AC-06, AC-07, AC-08 | Medium |
| 02 | Fix documentation contradictions | pending | AC-03, AC-04, AC-05 | Low |

## Task Sequence

1. **Task 01** (code changes) — must come first because:
   - Tests validate the new behavior (main branch, no member branches)
   - Migration logic must be tested
   - Error handling changes must not break existing functionality
2. **Task 02** (doc fixes) — must run after Task 01 because:
   - Doc changes reference the new behavior (no member branches)
   - MkDocs docs must be updated to reflect removed member branch concept
   - Profile templates are documentation-only fixes (no code changes)
