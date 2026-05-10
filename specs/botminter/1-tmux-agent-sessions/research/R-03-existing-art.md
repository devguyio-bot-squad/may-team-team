# R-03: Existing Art — Multiplexer Patterns for Process Observability

## Overmind (Most Directly Relevant)

Go-based Procfile process manager using tmux as backend.

**Key patterns:**
- **Socket isolation:** `tmux -L overmind-<title>-<nanoid>` — unique socket per instance, never collides with user's tmux
- **Window-per-process:** Each Procfile entry gets its own named tmux window
- **Name sanitization:** Process names cleaned via regex before use as window names
- **Custom config passthrough:** `--tmux-config` flag for custom status bars/theming
- **IPC via Unix socket:** `.overmind.sock` for CLI-to-manager communication (start, stop, restart, connect)
- **Individual process control:** Restart/stop single processes without affecting others

**UX pitfall:** Nested tmux sessions (running `overmind connect` from inside tmux) cause double-prefix confusion.

## AI Agent Ecosystem

No major frameworks (CrewAI, AutoGen, LangGraph) use tmux. Their observability is trace-based (LangSmith, AgentOps). However, the Claude Code ecosystem has produced tmux-based tools:

### amux (Agent Multiplexer)
- Python, sessions with human-readable names
- Parses ANSI-stripped tmux output for status detection
- Watchdog: monitors context window usage, auto-sends `/compact`, detects stuck agents

### Agent Deck
- **Dedicated tmux socket** (`agent-deck`) — same isolation pattern as Overmind
- Polling-based status detection: Running (green), Waiting (yellow), Idle (gray), Error (red)
- Status bar shows all sessions with attention indicators
- Transition notifier daemon for status changes

## Synthesized Patterns

| Pattern | Description | Used By |
|---------|-------------|---------|
| **Socket isolation** | Dedicated `-L` socket per app | Overmind, Agent Deck |
| **Window-per-process** | Named window = named process | All tmux-based tools |
| **Status detection via output** | Parse pane output, don't instrument agents | amux, Agent Deck |
| **Status bar as notification surface** | Show process states in tmux status bar | Agent Deck |
| **tmux for observability, not supervision** | Separate lifecycle management from visual access | systemd+tmux pattern |
| **Custom config per session** | Branded theming without touching user config | Overmind |

## Anti-Patterns to Avoid

1. **Nesting:** Don't encourage attaching from inside another tmux — causes double-prefix confusion
2. **tmux as supervisor:** Don't rely on tmux for restart/health logic — use a proper supervisor
3. **Session managers as deps:** tmuxinator/tmuxp add Ruby/Python deps for functionality trivially achievable with raw CLI
4. **`kill-server` blast radius:** Without socket isolation, `kill-server` destroys all sessions including user's personal ones

## Key Takeaway

The pattern is well-validated: dedicated tmux socket + one window per agent + custom config for branding + proper supervisor for lifecycle. tmux provides the "attach and see what's happening" layer, not the process management layer.

## Sources

- [Overmind GitHub](https://github.com/DarthSim/overmind)
- [amux GitHub](https://github.com/mixpeek/amux)
- [Agent Deck GitHub](https://github.com/asheshgoplani/agent-deck)
- [Process Compose GitHub](https://github.com/F1bonacc1/process-compose)
