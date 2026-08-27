# Contributing

See [`README.md`](./README.md) for local tool installation and pre-commit setup.

Repository conventions, per-chart commands, release boundaries, and what must pass before
a change is considered done all live in [`AGENTS.md`](./AGENTS.md). It is written for AI
coding agents, but it is equally the reference for human contributors — read it before
your first change.

## AI agent instructions

[`AGENTS.md`](./AGENTS.md) is the **single source of truth** for agent instructions. It is
the file Cursor, GitHub Copilot, Codex, and other harnesses read from the repo root.

Every other agent configuration file is a thin pointer to it:

| File | Role |
| --- | --- |
| `AGENTS.md` | All shared instructions |
| `CLAUDE.md` | `@AGENTS.md` import, because Claude Code reads `CLAUDE.md` |
| `.github/copilot-instructions.md` | Only guidance specific to *reviewing* a diff |

**Changes go in `AGENTS.md`** unless the instruction is genuinely specific to one harness
and cannot live there. No instruction should appear in two files: duplicated guidance
drifts apart, and agents then get contradictory instructions.
