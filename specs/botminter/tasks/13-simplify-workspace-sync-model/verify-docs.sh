#!/usr/bin/env bash
set -euo pipefail

TEAM_DIR="${1:?Usage: verify-docs.sh <team-dir>}"
PROJECT_DIR="${2:?Usage: verify-docs.sh <team-dir> <botminter-project-dir>}"

FAILURES=0
PASSES=0

fail() { echo "FAIL: $1"; FAILURES=$((FAILURES + 1)); }
pass() { echo "PASS: $1"; PASSES=$((PASSES + 1)); }

# --- AC-03: Propagation model says "copies" not "symlinks" ---

if grep -q "symlinks into" "$TEAM_DIR/CLAUDE.md"; then
  fail "AC-03: team/CLAUDE.md still contains 'symlinks into' in propagation model"
else
  pass "AC-03: team/CLAUDE.md propagation model no longer claims symlinks"
fi

if grep "Member PROMPT.md, CLAUDE.md" "$TEAM_DIR/CLAUDE.md" | grep -q "Manual"; then
  pass "AC-03: team/CLAUDE.md propagation model says Manual for PROMPT.md/CLAUDE.md"
else
  fail "AC-03: team/CLAUDE.md PROMPT.md/CLAUDE.md row missing Manual sync requirement"
fi

# --- AC-04: Workspace model diagram uses copy notation, not arrows ---

if grep -qP "^\s+(PROMPT|CLAUDE)\.md\s+→\s+team/members/" "$TEAM_DIR/CLAUDE.md"; then
  fail "AC-04: team/CLAUDE.md workspace model diagram still uses arrow notation"
else
  pass "AC-04: team/CLAUDE.md workspace model diagram no longer uses arrow notation"
fi

# --- AC-05: SKILL.md Rule 2 says context.md → CLAUDE.md ---

SKILL_FILE="$TEAM_DIR/members/chief-of-staff-kevin/coding-agent/skills/workspace-sync/SKILL.md"

if grep -q "CLAUDE\.md → CLAUDE\.md Rename" "$SKILL_FILE"; then
  fail "AC-05: SKILL.md Rule 2 heading still says 'CLAUDE.md → CLAUDE.md Rename'"
else
  pass "AC-05: SKILL.md Rule 2 heading no longer says no-op rename"
fi

if grep -q "context\.md → CLAUDE\.md Rename" "$SKILL_FILE"; then
  pass "AC-05: SKILL.md Rule 2 heading correctly says 'context.md → CLAUDE.md Rename'"
else
  fail "AC-05: SKILL.md Rule 2 heading missing 'context.md → CLAUDE.md Rename'"
fi

# --- No "member branch" references in MkDocs docs ---

DOCS_DIR="$PROJECT_DIR/docs/content"
for doc in concepts/workspace-model.md reference/cli.md how-to/launch-members.md; do
  if grep -qi "member branch" "$DOCS_DIR/$doc"; then
    fail "No member-branch refs: $doc still contains 'member branch'"
  else
    pass "No member-branch refs: $doc clean"
  fi
done

# --- Profile templates: 3 files with both "symlinks into" AND arrow notation ---

PROFILES_DIR="$PROJECT_DIR/profiles"
BOTH_FILES=(
  "agentic-sdlc-planning/context.md"
  "scrum/context.md"
  "agentic-sdlc-minimal/context.md"
)
for f in "${BOTH_FILES[@]}"; do
  if grep -q "symlinks into" "$PROFILES_DIR/$f"; then
    fail "Profile $f still contains 'symlinks into'"
  else
    pass "Profile $f no longer contains 'symlinks into'"
  fi
  if grep -qP "^\s+(PROMPT|context)\.md\s+→\s+team/members/" "$PROFILES_DIR/$f"; then
    fail "Profile $f still uses arrow notation in workspace diagram"
  else
    pass "Profile $f no longer uses arrow notation"
  fi
done

# --- Profile templates: 6 files with arrow notation only ---

ARROW_ONLY_FILES=(
  "scrum/roles/human-assistant/context.md"
  "scrum/roles/architect/context.md"
  "agentic-sdlc-planning/roles/engineer/context.md"
  "agentic-sdlc-planning/roles/sentinel/context.md"
  "agentic-sdlc-minimal/roles/engineer/context.md"
  "agentic-sdlc-minimal/roles/sentinel/context.md"
)
for f in "${ARROW_ONLY_FILES[@]}"; do
  if grep -qP "^\s+(PROMPT|context)\.md\s+→\s+team/members/" "$PROFILES_DIR/$f"; then
    fail "Profile $f still uses arrow notation in workspace diagram"
  else
    pass "Profile $f no longer uses arrow notation"
  fi
done

# --- Summary ---

TOTAL=$((PASSES + FAILURES))
echo ""
echo "=== Documentation Verification: $PASSES/$TOTAL passed, $FAILURES failed ==="

if [ "$FAILURES" -gt 0 ]; then
  exit 1
fi
