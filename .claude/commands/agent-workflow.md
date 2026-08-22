---
description: "Activate the full agent workflow with specialized roles (Planner, Architect, Developer, Reviewer, etc.)"
---

# Agent Workflow

This file defines the **agent workflow** for this repository — the flow, routing, and workflow-level rules. The role definitions themselves live in the agent files and are not repeated here.

**Note:** All agent transitions require human interaction. There are no automatic handoffs - the user must explicitly invoke each agent or approve to continue.

> **CRITICAL INSTRUCTION:** When you adopt a role (e.g., Planner, Developer), you **MUST** first read the corresponding definition file in `.claude/agents/workflow-{RoleName}.md` — substitute the lower-case role identifier for `{RoleName}`. That file is the sole source of truth for the role's Entry, Responsibilities, Output Format, Behavioral Rules, and Exit. You are strictly bound by it.

---

## Source of Truth

| Document | Purpose |
|----------|---------|
| `.github/CONTRIBUTING.md` | Broad, cross-cutting engineering and quality principles |
| `.github/skills/INDEX.md` | Skill routing and library references |
| `.claude/agents/workflow-*.md` | Role definitions and behaviors |
| `.claude/rules/*.md` | Technology- and artifact-specific implementation conventions |

When a technology or artifact scope applies, load every matching instruction from `.claude/rules/`;
each matching instruction is authoritative for its implementation-specific conventions.

---

## Workflow Diagram

```
User Request
      │
      ▼
┌─────────┐
│ Planner │
└─────┬───┘
      ▼
┌───────────┐
│ Architect │◄──── APPROVAL ───────────────┐
└─────┬─────┘                              │
      ├                       ┌──────────┐ │
      ├─── If UI involved ──► │ Designer ├─┤
      │                       └──────────┘ │
      │                       ┌─────────┐  │
      ├─── If DB changes ───► │   DBA   ├──┘
      │                       └─────────┘
      │                       ┌────────────┐
      ├─ If RFC/DD needed ──► │ Documenter │
      │                       └─────┬──────┘
      │◄────────────────────────────┘
      │                       ┌──────────────────────┐
      ├─── If tests needed ──►│ Tester (Phase 1)     │
      │                       │  Draft Test Cases    │
      │                       │  → build contract    │
      │                       └──────────┬───────────┘
      │◄─────────────────────────────────┘
      ▼
┌───────────┐
│ Developer │◄────┐
└─────┬─────┘     │
      ▼           │
┌──────────┐ FAIL │
│ Reviewer ├──────┘
└─────┬────┘
      │ PASS
      │                       ┌──────────────────────┐
      ├─── If tests needed ──►│ Tester (Phase 2)     │◄──────┐
      │                       │  Implement tests     │       │
      │                       │  from Phase 1 TCs    │       │
      │                       └──────────┬───────────┘       │
      │                                  ▼                   │
      │                            ┌──────────┐ FAIL         │
      │                            │ Reviewer ├──────────────┘
      │                            └─────┬────┘
      │                                  │ PASS
      │◄─────────────────────────────────┘
      │                       ┌────────────┐
      ├─── If docs needed ───►│ Documenter │
      │    (README, ADR,      └─────┬──────┘
      │     Runbook, SOP,           │
      │     Glossary, Tech Stack,   │
      │     Business Case)          │
      │◄────────────────────────────┘
      ▼
   Complete
```

---

## Roles Summary

| Role | Agent File | When Invoked | Produces | Special Approval |
|------|-----------|--------------|----------|------------------|
| Planner | `workflow-planner` | Always | Plan with acceptance criteria | - |
| Architect | `workflow-architect` | Always | Technical design, observability requirements | Approves Designer/DBA output |
| Designer | `workflow-designer` | If UI involved | HTML mockups | Architect approves |
| DBA | `workflow-dba` | If DB changes | Schema design, migrations, index strategy | Architect approves |
| Documenter (proposal) | `workflow-documenter` | If RFC needed (pre-impl) | RFC from Architect's design | - |
| Documenter (design) | `workflow-documenter` | If Design Doc needed (post-RFC) | Design Doc — build-ready detail | - |
| Tester (Phase 1) | `workflow-tester` | If tests needed (pre-impl) | Test Cases document — build contract for Developer, mapped 1:1 to acceptance criteria | Goes straight to Developer, no Reviewer |
| Developer | `workflow-developer` | Always | Code, Docker, K8s, dashboards, runbook drafts | - |
| Reviewer | `workflow-reviewer` | Always (1-2x) | PASS/FAIL verdict | 3 FAILs → escalate |
| Tester (Phase 2) | `workflow-tester` | If tests needed (post-impl) | Executable unit/integration tests implementing Phase 1 Test Cases | - |
| Documenter (record) | `workflow-documenter` | If docs needed (post-impl) | README, ADRs, runbooks, SOPs, glossary, tech stack, business case | - |

**Note:** Every role outputs and stops. User decides when to proceed to next agent. Tester is optional — the Planner decides whether tests are needed (new features, complex logic, critical paths).

---

## Definition of Done

A change is done only when:

1. Acceptance criteria satisfied
2. `.github/CONTRIBUTING.md` and every applicable specialized instruction fully complied with
3. Applicable skills applied
4. Test Cases drafted pre-implementation and every AC mapped (if Tester invoked)
5. Reviewer returned PASS for implementation
6. Every Phase 1 Test Case has at least one executable test (if Tester invoked)
7. Reviewer returned PASS for tests (if Tester Phase 2 invoked)
8. Documentation updated (if applicable)
9. Optional improvements either implemented (with approval) or explicitly declined
