# Contributing

See [`README.md`](./README.md) for local tool installation and pre-commit setup.

Repository conventions, per-chart commands, release boundaries, and what must pass before
a change is considered done all live in [`AGENTS.md`](./AGENTS.md). It is written for AI
coding agents, but it is equally the reference for human contributors — read it before
your first change.

## AI agent instructions

[`AGENTS.md`](./AGENTS.md) is the **single source of truth** for agent instructions — with one
documented exception, described below. Cursor and Codex read it directly from the repo root;
harnesses that look elsewhere are pointed at it rather than handed a second copy.

Copilot is the awkward one. It reads root `AGENTS.md` only for code review on GitHub.com and
for the coding agent — **not** for Copilot Chat in any IDE — while it reads
`.github/copilot-instructions.md` nearly everywhere, and ranks that file *above* `AGENTS.md`
when the two disagree. So the review triggers in that file intentionally restate `AGENTS.md`
rules; when you change a rule, change it in both.

The full set of agent configuration files:

| File | Role |
| --- | --- |
| `AGENTS.md` | All shared instructions |
| `CLAUDE.md` | `@AGENTS.md` import, because Claude Code reads `CLAUDE.md` |
| `.github/copilot-instructions.md` | Review-specific triggers; the only one Copilot reads on every surface |

**Changes go in `AGENTS.md`** unless the instruction is genuinely specific to one harness and
cannot live there. The one deliberate exception is `.github/copilot-instructions.md`, whose
review triggers mirror `AGENTS.md` rules because Copilot needs them in that file to honour
them. Keep the two in step: where they disagree, Copilot follows the Copilot file, so stale
text there silently overrides `AGENTS.md`.
