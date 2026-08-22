---
applyTo: "**"
---

> [!TIP]
> Cross-cutting engineering principles live in `.github/CONTRIBUTING.md`. For a technology or artifact scope,
> load every matching `.github/instructions/*.instructions.md`; those files own the specialized implementation
> rules for their scope. Use `.github/skills/INDEX.md` to route reusable workflows. Resolve physical placement,
> project names, and filenames through `.github/skills/solution-structure/SKILL.md`.
> If two applicable authorities conflict, stop and reconcile the source documents instead of silently choosing one.

# Authored Guidance DRY Gate

Before editing any authored guidance under `.github/`:

1. Search authored `.github/` sources for every concept being changed.
2. Identify exactly one normative owner for each concept before writing.
3. Extend the owner; consumers must link to its exact complete section.
4. Consumers may contain workflow-specific instructions or executable examples, but must not redefine paths,
   filenames, tokens, naming formulas, applicability conditions, policy tables, or verification checklists.
5. If no owner exists, establish one explicitly before updating consumers.
6. If authorities overlap or conflict, stop and reconcile them before implementation.
7. Before completion, rescan the changed guidance against its parent commit and confirm that every new rule has
   one owner.
8. Audit authored `.github/` only. Do not manually update generated mirrors or run platform synchronization.

# Workflow Orchestration

## 1. Plan Node Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately – don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

## 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

## 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

## 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

## 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes – don't over-engineer
- Challenge your own work before presenting it

## 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests – then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management
1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

## Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
