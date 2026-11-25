# CLAUDE.md

Read and follow all project rules, architecture standards, coding conventions, and documentation requirements in [`AGENTS.md`](AGENTS.md).

## Quick Reminders for Claude Code
- Always start every `.luau` file with `--!strict`.
- Place shared contracts/configs in `src/shared/`, authoritative logic in `src/server/Services/`, and client camera/input/UI in `src/client/Controllers/`.
- Keep changes scoped to the assigned domain/branch to avoid merge conflicts with other developers and AI agents (Antigravity, Codex).
- Update `docs/ARCHITECTURE.md` and `docs/CHANGELOG.md` whenever you add or change a Service, Controller, Config, or Remote.
- Run `stylua --check src` and `selene src` before concluding a task (if installed in the environment).
