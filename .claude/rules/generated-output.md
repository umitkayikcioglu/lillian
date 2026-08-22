---
paths:
  - ".agents/**"
  - ".claude/**"
  - "plugins/**"
  - ".ai/**"
---

# Generated and Vendored Output

`.agents/`, `.claude/`, `plugins/` and `.ai/` are never authored in place.

**Never edit, stage, or commit anything inside them.** If a search lands you in one, treat the
hit as a build artifact: trace it back to its source and edit there instead.

Where that source is depends on which repository you are in.

## The source repository

You are here if `tools/sync-ai-platforms.ps1` exists at the repository root.

Source-of-truth lives under `.github/`, and these folders are generated from it by a git
pre-commit hook. Direct edits are overwritten on the next hook run and desync from source.

To change a skill, instruction, agent, prompt, or plugin behavior, edit the source under
`.github/` — `.github/skills/{SkillName}/`, `.claude/rules/`, `.github/agents/`,
`.github/prompts/` — and let the hook regenerate the rest. `{SkillName}` is the registered lower-case skill
identifier.

## A consuming repository

You are here otherwise. The source repository is vendored at `.ai/`, and these folders are
symlinks into it.

Editing through them modifies the vendored checkout, not this repository. The change will not
appear in this repo's diff, and it is lost the next time `.ai/` is updated.

- **Shared behavior** — change it upstream in the source repository, then pull `.ai/`.
- **Behavior for this repository alone** — create a real file outside the symlinked paths.
