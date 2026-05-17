# Merge Gate — botminter

## Test Commands

Always use `just` recipes from the project root (`projects/botminter/`). Never use raw `cargo` commands — `just` handles feature flags, env vars, and profile staging.

| Command | What it runs | Requires credentials |
|---------|-------------|---------------------|
| `just build` | `cargo build -p bm` | No |
| `just unit` | Unit tests only | No |
| `just clippy` | Lint with `-D warnings` | No |
| `just conformance` | Bridge conformance tests | No |
| `just e2e` | E2E tests against real GitHub | Yes |
| `just test` | All of the above | Yes |

## Gate Workflow

1. Check out the PR branch: `gh pr checkout <number>`
2. Run fast tests first (no credentials needed):
   ```bash
   just build && just clippy && just unit && just conformance
   ```
3. Run e2e tests (requires credentials in environment):
   ```bash
   just e2e
   ```
4. **All pass** — merge with `gh pr merge <number> --merge`, add sentinel comment
5. **Any failure** — do NOT merge, report which tests failed

## Pass/Fail Thresholds

- Unit tests: all must pass
- Clippy: zero warnings (enforced by `-D warnings`)
- Conformance: all must pass
- E2E: all scenarios must pass
- No partial passes — any single failure means reject

## Required Environment Variables

E2E tests need these env vars. Values are provisioned via `.envrc.d/botminter.sh` in the workspace root (see `team/projects/botminter/envrc.example` for the template).

| Variable | Purpose |
|----------|---------|
| `TESTS_GH_TOKEN` | GitHub token for API calls (member's own token works) |
| `TESTS_GH_ORG` | GitHub org where test repos are created/deleted |
| `TESTS_APP_ID` | Test GitHub App — numeric ID |
| `TESTS_APP_CLIENT_ID` | Test GitHub App — client ID string |
| `TESTS_APP_INSTALLATION_ID` | Test GitHub App — installation ID |
| `TESTS_APP_PRIVATE_KEY_FILE` | Absolute path to test app `.pem` private key |

If any variable is missing, e2e tests fail immediately with "No GitHub token found."

## Comment Format

All merge gate comments use:

```
### 🛡️ sentinel — $(date -u +%Y-%m-%dT%H:%M:%SZ)
```
