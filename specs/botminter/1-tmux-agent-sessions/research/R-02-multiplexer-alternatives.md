# R-02: Terminal Multiplexer Alternatives

## Comparison Matrix

| Criterion | tmux | Zellij | GNU Screen | cmux | Byobu |
|-----------|------|--------|------------|------|-------|
| Rust library | `tmux_interface` | `zjctl` (3rd-party) | None | None | tmux passthrough |
| Programmatic CLI | Excellent | Good | Limited | Socket API (macOS) | tmux passthrough |
| Custom status bar | Excellent | Good (zjstatus plugin) | Basic | GUI native | tmux + monitoring |
| Availability | Universal | Excellent | Universal | macOS only | Good |
| Maturity | 15+ years | ~4 years | 30+ years | Months | Mature (wrapper) |
| Post-mortem | `remain-on-exit` | Partial (command panes) | `zombie` command | N/A | tmux |
| Headless/server | Yes | Yes | Yes | No (GUI) | Yes |

## Zellij (Rust-based)

- Production-ready (v0.41-0.44), active development
- KDL-based config, WASM plugin system, session resurrection
- Programmatic CLI via `zellij action` commands
- **Weakness:** No clean equivalent to `remain-on-exit` — issue #707 tracks this
- **Weakness:** `zjctl` Rust crate is 3rd-party, less mature than `tmux_interface`
- Worth revisiting in 12-18 months

## GNU Screen

- Universal availability, pre-installed on many systems
- `zombie` command for post-mortem, but API is primitive
- No Rust library, limited programmatic control
- Splits lost on detach — not suitable

## cmux

- Real product — native macOS app built on Ghostty's rendering engine
- Socket API for programmatic control, pane border status indicators
- **Not suitable:** GUI-only, macOS-only, cannot run headlessly

## Byobu

- Wrapper around tmux with enhanced defaults (F-keys, system indicators)
- No incremental value for programmatic control — adds unnecessary abstraction

## Process Managers (Overmind, Foreman, Hivemind)

- Overmind uses tmux under the hood — validates the window-per-process pattern
- Foreman/Hivemind are stdout multiplexers, no interactive access
- Process managers solve a different problem (Procfile runners, not arbitrary sessions)

## Recommendation

**tmux is the clear choice.** Reasons:
1. Best Rust integration (`tmux_interface` or direct CLI)
2. `remain-on-exit` is the cleanest post-mortem solution
3. `-L` socket flag for complete isolation
4. Universal availability on Linux servers
5. 15+ years of battle-tested stability
6. Most complete programmatic command API

## Sources

- [Zellij GitHub](https://github.com/zellij-org/zellij)
- [tmux_interface crate](https://github.com/AntonGepting/tmux-interface-rs)
- [Overmind GitHub](https://github.com/DarthSim/overmind)
- [cmux official site](https://cmux.com/)
