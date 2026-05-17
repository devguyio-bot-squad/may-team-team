# Tasks — bm teams sync: broken surfacing

**Parent Story:** [#39](https://github.com/devguyio-bot-squad/may-team-team/issues/39)
**Parent Epic:** None (standalone bug)

## Decisions

**Bug 1 (dirty workspace blocks sync) is already fixed.** Issue #13 ("Simplify workspace sync model") removed `checkout_member_branch()` and replaced it with `migrate_to_main()` which handles errors gracefully (warnings + continue). The original symptom ("Cannot switch to branch 'engineer-bob': working tree has uncommitted changes") was caused by the branch checkout that no longer exists. No further work needed for Bug 1.

**Content comparison over hashing.** For Bug 2, chose `fs::read()` byte equality over blake3/sha256 hashing. The synced files (ralph.yml, CLAUDE.md, PROMPT.md, settings.local.json) are small config files (< 50KB). Simple byte comparison is sufficient, requires no new dependencies, and is easier to reason about. Hashing would only be justified for large files where you'd want to avoid reading one file if hashes differ early — not applicable here.

**Match pattern over result mapping.** For Bug 3, chose `match` + `continue` over `.unwrap_or_else()` or `.map_err()` because it mirrors the existing `create_workspace_repo` error handling at `team_sync.rs:154-167`, keeping the codebase consistent.

## Task Catalog

| # | Title | Status | Acceptance Criteria | Complexity |
|---|-------|--------|---------------------|------------|
| 01 | Replace mtime comparison with content comparison in copy_if_newer | pending | AC-01, AC-02, AC-03, AC-04 | Low |
| 02 | Make sync failure non-fatal in multi-workspace loop | pending | AC-05, AC-06, AC-07, AC-08 | Low |

## Adversarial Review

All 3 reviewers returned **PASS** (round 1, no iteration needed):
- **Staff Engineer:** PASS — minor suggestions: add file-length fast-path before content read (incorporated), check if `filetime` can be removed from Cargo.toml (incorporated)
- **UX Engineer:** PASS — minor suggestion: consider "Skipped (unchanged)" wording over "Skipped (up-to-date)" (cosmetic, not incorporated — current wording becomes correct after fix)
- **QE Engineer:** PASS — minor suggestions: add integration test for AC-03 (incorporated), specify failure injection mechanism for Task 02 tests (incorporated)

## Task Sequence

Task 01 and Task 02 are independent — they modify different files and address different bugs. They can be implemented in either order. Task 01 is sequenced first because it is the "most impactful fix" (per the issue description) and affects the core sync mechanism.

## Acceptance Criteria Summary

| ID | Criterion | Task |
|----|-----------|------|
| AC-01 | Identical content, older source mtime → file NOT copied | 01 |
| AC-02 | Different content, older source mtime → file IS copied (critical mtime bug fix) | 01 |
| AC-03 | After submodule update with content change but older mtime, workspace has new content | 01 |
| AC-04 | `cargo test -p bm` passes, renamed tests pass, filetime usage removable from affected test modules | 01 |
| AC-05 | Push failure for one workspace does not abort remaining workspaces | 02 |
| AC-06 | `WorkspaceSyncFailed` event emitted with member name and error message | 02 |
| AC-07 | Sync failures displayed unconditionally (not gated on `--verbose`) | 02 |
| AC-08 | `cargo test -p bm` passes, no regressions, new resilience tests pass | 02 |
