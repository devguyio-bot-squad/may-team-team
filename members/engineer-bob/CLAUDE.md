# Engineer — Team Member Context

This file provides context for operating as the engineer team member. Read `team/CLAUDE.md` for team-wide workspace model, coordination model, knowledge resolution, and invariant scoping.

## A. Project Context

Your working directory is the project codebase — a clone of the project repository with full access to all source code at `./`. The team repo is cloned into `team/` within the project workspace.

[When a real project is assigned, this section will contain project-specific information: build commands, test commands, architecture notes, deployment procedures, etc.]

## B. Team Member Skills & Capabilities

### Available Hats

Fifteen specialized hats are available for different phases of work. Board scanning is handled by an auto-inject skill, not a hat.

| Hat | Purpose |
|-----|---------|
| **po_gate** | Handles all human:po:* statuses — triage, backlog, plan-review, accept |
| **lead_plan-create** | Creates planning artifacts — PDD for epics, code-task-generator for stories |
| **lead_plan-review** | Zero-trust adversarial quality gate for planning artifacts |
| **lead_breakdown** | Externalizes approved plans — story issues from epics, task issues from stories |
| **lead_monitor** | Monitors epic progress, advances to acceptance when all stories done |
| **dev_implement-red** | TDD red phase — writes failing tests for the current task |
| **dev_implement-green** | TDD green phase — implements minimum code to pass tests |
| **dev_implement-refactor** | TDD refactor phase — cleans up while keeping tests green |
| **dev_implement-review** | Code reviewer — reviews implementation quality |
| **qe_verify** | Verifies implementation against acceptance criteria |
| **qe_investigate** | Investigates bugs, determines simple vs complex, creates linked Story |
| **qe_monitor** | Monitors linked Story completion for bugs |
| **sre_setup** | Sets up test infrastructure |
| **cw_write** | Writes documentation for documentation stories |
| **cw_review** | Reviews documentation quality |

### Workspace Layout

```
project-repo-engineer/               # Project repo clone (CWD)
  team/                           # Team repo clone
    knowledge/, invariants/             # Team-level
    members/engineer-bob/                    # Member config
    projects/<project>/                 # Project-specific
  PROMPT.md → team/members/engineer-bob/PROMPT.md
  CLAUDE.md → team/members/engineer-bob/CLAUDE.md
  ralph.yml                             # Copy
  poll-log.txt                          # Board scan audit log
```

### Knowledge Resolution

Knowledge is resolved by specificity (most general to most specific):

| Level | Path |
|-------|------|
| Team knowledge | `team/knowledge/` |
| Project knowledge | `team/projects/<project>/knowledge/` |
| Member knowledge | `team/members/engineer-bob/knowledge/` |
| Member-project knowledge | `team/members/engineer-bob/projects/<project>/knowledge/` |
| Hat knowledge (various) | `team/members/engineer-bob/hats/<hat>/knowledge/` |

More specific knowledge takes precedence.

### Invariant Compliance

All applicable invariants MUST be satisfied:

| Level | Path |
|-------|------|
| Team invariants | `team/invariants/` |
| Project invariants | `team/projects/<project>/invariants/` |
| Member invariants | `team/members/engineer-bob/invariants/` |

Critical member invariant: `team/members/engineer-bob/invariants/design-quality.md`

### Coordination Conventions

See `team/PROCESS.md` for:
- Issue types and workflow conventions
- Status transition patterns
- Comment attribution format (emoji headers with ISO timestamps)
- Milestone and PR conventions

### GitHub Access

**NEVER use `gh` CLI directly.** All GitHub operations MUST go through the `github-project` skill scripts:
- Issue queries and mutations
- Project board operations
- Status transitions
- Pull request operations
- Milestone management
- Comments and labels

If a script doesn't exist for an operation, create one or extend an existing script. Do NOT fall back to raw `gh` commands. Bypassing the skill corrupts the board state cache and wastes API quota.

The team repo is auto-detected from `team/`'s git remote.

### Operating Mode

**Supervised mode (GitHub comment-based)** — human gates at three decision points:
- `human:po:design-review` — design doc approval
- `human:po:plan-review` — story breakdown approval
- `human:po:accept` — epic acceptance

At these gates, the system checks for human response comments containing approval or rejection. All other transitions auto-advance.

**Three-member model** — the team has three roles:
- **Engineer** (you) — handles all development lifecycle phases
- **Chief of staff** — the operator's AI assistant, handles operational tasks and drives improvements
- **Sentinel** — handles PR merge gating and orphaned PR triage

### Reference Files

- Team context: `team/CLAUDE.md`
- Process conventions: `team/PROCESS.md`
- Work objective: see `PROMPT.md`
