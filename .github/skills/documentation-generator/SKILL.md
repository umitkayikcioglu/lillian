---
name: documentation-generator
description: Document templates for ADRs, RFCs, design docs, runbooks, post-incident reviews, SOPs, handovers, business cases, test plans, test cases, role briefs, and more. Use when creating or updating any structured document such as an ADR, RFC, design doc, runbook, postmortem, SOP, handover, business case, brag document, project status update, retrospective, tech stack or architecture overview, data dictionary, performance improvement plan, test cases, test plan, role brief, or hiring/job ad.
type: guidance
applies_to:
  - Documenter
  - Planner
  - Architect
  - Developer
  - Tester
mandatory: conditional
mandatory_when:
  - Creating ADRs or RFCs
  - Writing design documents
  - Creating runbooks or SOPs
  - Creating handover documentation
  - Creating data dictionaries
triggers:
  - documentation
  - ADR
  - RFC
  - runbook
  - post incident review
  - postmortem
  - design doc
  - handover
  - SOP
  - business case
  - brag document
  - project status
  - retrospective
  - tech stack
  - architecture overview
  - data dictionary
  - performance improvement
  - test cases
  - test plan
  - role brief
  - job ad
  - hiring
  - recruiting
references:
  - ../solution-structure/SKILL.md
  - templates/architecture-decision-record.md
  - templates/request-for-comments.md
  - templates/design-doc.md
  - templates/runbook.md
  - templates/post-incident-review.md
  - templates/standard-operating-procedure.md
  - templates/takeover-handover.md
  - templates/data-dictionary.md
  - templates/business-glossary.md
  - templates/business-case.md
  - templates/business-case-financial-model.md
  - templates/brag-document.md
  - templates/performance-improvement-plan.md
  - templates/project-status-update.md
  - templates/retrospective.md
  - templates/tech-stack-overview.md
  - templates/architecture-overview.md
  - templates/test-cases.md
  - templates/test-plan.md
  - templates/role-brief.md
summary: Document templates for ADRs, RFCs, design docs, runbooks, post incident reviews, SOPs, handovers, business cases, test plans, test cases, role briefs, and more.
---

# Documentation Skill

Provides standardized templates for the structured document types listed below. Repository and service
`README.md` files are structural indexes/overviews rather than instances of these templates; their placement
and purpose come from `solution-structure` and their content is maintained with the owning repository or
service.

## Before you write: read the template file

**The section lists in this document are an index, not a substitute for the templates.** Every
document type below points at a file under `templates/`. Open that file and author from it.

Composing a document from the headings listed in this skill produces something that looks
conformant and is not. The sections it drops are usually the ones that matter most — Cross-Cutting
Concerns, Rollback, Verify Completion, Revision History — because those are the sections an author
does not think to invent. The result reads as complete while silently lacking exactly what a future
reader needs.

The order:

1. Identify the document type, then resolve its repository path and filename from
   [`Documentation Placement and Naming Rules`](../solution-structure/SKILL.md#documentation-placement-and-naming-rules).
2. **Read the selected `templates/[document-type].md` file in full** before writing a line.
3. Author using that file's headings, in that order.
4. Include sections you will leave thin. Where one genuinely does not apply, say so in a line —
   `Not applicable: single-operator system, no rotation` — rather than deleting the heading. An
   explicit absence is information; a missing heading is indistinguishable from an oversight.

**Existing documents are different.** Do not retrofit template sections into an already-accepted
ADR or a historical record by inventing content for them. Restructure and rename freely; author
new prose never. A missing section in an accepted decision is honest, whereas a fabricated
Assumptions or Risks section corrupts the record.

## When to Use

| Phase | Document Type | When to Use | Created By | Reviewed By |
|-------|---------------|-------------|------------|-------------|
| 2. Justification & Approval | Business Case | To secure support, funding, or prioritization. Scales: light usage = problem + reasons + scope + risks; heavy usage = full investment justification | PM, Product Lead, Architect | Leadership, Finance |
| 2. Justification & Approval | Business Case Financial Model | To evaluate financial impact of a project | PM, Product Lead | Leadership, Finance |
| 3. Knowledge Transfer (in) / 9. Closure | Takeover & Handover | Single template covering both directions of ownership transfer — Takeover when inheriting a system, Handover when transferring out | Receiving / Departing Engineer | Receiving Team / Architect |
| 4. Decide & Design | RFC | Proposed changes before implementing | Documenter | Peers, Architects |
| 4. Decide & Design | ADR | Architecture decisions | Architect, Documenter | Senior Devs |
| 4. Decide & Design | Design Doc (aka Tech Spec) | Before coding complex features | Engineer, Tech Lead | Dev Team, Product |
| 5. Build Contract | Test Plan | Cross-feature, release, or project-level test strategy; required in regulated contexts (FDA, IEC 62304, ISO 13485, ISO 26262) | Test Lead, Tester | QA Lead, Product Owner, Engineering Lead |
| 5. Build Contract | Test Cases | For QA verification of acceptance criteria | Tester | Reviewer, QA |
| 7. Operate | Runbook | For handling systems & failures | Developer, SRE | Platform, On-call |
| 7. Operate | SOP | For repetitive tasks, compliance | DevOps, SRE | Team Lead |
| 8. Report Progress | Project Status Update | Regular reporting to stakeholders | Project Manager | Leadership |
| 9. Closure | Retrospective | At project end, to capture outcomes and lessons | PM, Team Lead | Leadership, Team |
| 10. Always-Living Reference | Tech Stack Overview | To document current technologies | Engineer, Tech Lead | New team members |
| 10. Always-Living Reference | Architecture Overview | To explain how the existing product, module, component, service, or coherent area works (Diátaxis "Explanation") | Architect, Tech Lead | Dev Team, New team members |
| 10. Always-Living Reference | Data Dictionary | To define schema, fields, data types | Data Engineers, DBAs | Data Governance |
| 10. Always-Living Reference | Business Glossary | To define key business terms | Product, Domain Experts | Product Owners |
| Orthogonal A. Incident | Post Incident Review (aka Postmortem) | After incidents | On-call Engineer | SRE Lead, Manager |
| Orthogonal B. People & Recruiting | Role Brief | Tech-team intake brief handed to HR/recruiting describing the kind of person we want; HR translates into a public job posting | Engineering Manager, Tech Lead | Hiring Manager, HR Partner |
| Orthogonal B. People & Recruiting | Brag Document | Before reviews or promo cycles | Individual | Manager |
| Orthogonal B. People & Recruiting | Performance Improvement Plan | When performance needs formal guidance | Manager, HR | HR, Department Head |

> **Project intake** is *not* a template here — small ideas live as a **GitHub issue**. If an issue grows into a project, graduate it into a Business Case (light usage; financial sections skipped). Add a Business Case Financial Model only when a financial gate engages. Resolve both physical names and locations from `solution-structure`.

## Lifecycle Phases

Templates group into phases. The flow is the *default* path; each project picks the subset that fits.

```
PHASE                          ARTIFACTS
─────────────────────────────────────────────────────────────────
1. Discovery / Inception       GitHub issue (intake — not a template)
2. Justification & Approval    Business Case (light or heavy)
                               → Business Case Financial Model
                                 (only if material)
3. Knowledge Transfer (in)     Takeover (single template covers both
                                 incoming and outgoing transfers)
4. Decide & Design             RFC → ADR(s) → Design Doc
                               ADRs emerge across all three —
                               and during Implementation
5. Build Contract              Test Plan (optional; scope selected from
                                 the template; parallel to Design Doc)
                               Test Cases (living; per-feature, from
                                 acceptance criteria; pre-code)
6. Implementation              Code gated by Test Cases
7. Operate                     Runbook (living) + SOP (living)
8. Report Progress             Project Status Update (recurring)
9. Closure                     Handover (same template as Phase 3,
                                 used outgoing here)
                               Project Retrospective
10. Always-Living Reference    all four are living
                               Tech Stack Overview (updated when an
                                 ADR changes a tech choice)
                               Architecture Overview (updated when
                                 system behavior or structure shifts)
                               Data Dictionary (updated on any schema
                                 change — no ADR required)
                               Business Glossary (updated whenever
                                 terminology enters or shifts)
─── ORTHOGONAL FLOWS ─────────────────────────────────────────────
A. Incident (any time, system-lifetime)
   Post Incident Review (aka Postmortem)
B. People & Recruiting (HR-adjacent flow, not in repo)
   Role Brief, Brag Document, Performance Improvement Plan
```

### Phase notes

- **Phase 1 (Discovery / Inception)** lives in the issue tracker, *not* the repo. Only graduates to a doc if it becomes a project.
- **Phase 2 (Justification & Approval)** — the Business Case template scales: light usage covers project-brief intake (problem + reasons + scope + risks); heavy usage adds the financial sections; a separate Business Case Financial Model is produced only when the analysis is material.
- **Phase 4 (Decide & Design)** — RFC, ADR, and Design Doc are not strictly linear; see *Lifecycle Ordering* below for which subset to pick. **ADRs can crystallize during RFC, during Design Doc work, or after-the-fact during Implementation** when an emergent decision needs capture.
- **Phase 5 (Build Contract)** — Test Cases derive from the Planner's *acceptance criteria*, not from the Design Doc. They can be drafted **before or after** the DD: pre-DD when acceptance criteria are clear and the design is uncontroversial; post-DD when the design surfaces edge cases. Test Plan, when used, runs **parallel to the Design Doc** because it depends on architecture choices to define environments and integration strategy.
- **Phase 10 (Always-Living Reference)** — these docs are *never closed*, but their update triggers differ:
  - **Tech Stack Overview** — updated when an ADR changes a tech choice (new framework, swapped database, new observability stack, etc.).
  - **Architecture Overview** — updated when system behavior or structure shifts (new component, swapped data flow, removed integration). The Diátaxis *Explanation* doc — describes how the existing system works for someone with zero prior context. Defers *why* to ADRs, *what tools* to Tech Stack, *fields* to Data Dictionary.
  - **Data Dictionary** — updated on any schema change (new table, new field, type change, removal). No ADR required; a migration is enough.
  - **Business Glossary** — updated whenever new terminology enters the domain or an existing term's meaning shifts. No ADR or migration required.
- **Orthogonal Flow A (Incident)** — PIRs are **system-lifetime**, not project-bound. They accumulate against the running system over its whole life; a project can close while PIRs continue.
- **Orthogonal Flow B (People & Recruiting)** — HR-adjacent docs. **None live in the repo.**
  - **Role Brief** — tech team's intake brief handed to HR / recruiting when opening a requisition. HR owns the public job posting (comp, benefits, EEO, application process); this brief is the upstream input.
  - **Brag Document** — personal artifact for performance reviews and promotion cycles.
  - **Performance Improvement Plan** — HR artifact for formal performance guidance.

## Lifecycle Ordering: RFC, ADR, Design Doc

RFCs, ADRs, and Design Docs look similar at a glance but capture different things. They are **not strictly linear** — each change picks the subset that fits — but the default order is:

**RFC → ADR → Design Doc** *(propose → decide → design how)*

| Artifact | Question it answers | State | Shape |
|----------|--------------------|-------|-------|
| **RFC** | *Should we do this?* | Open while under discussion; closes with a decision | Problem, alternatives, trade-offs, recommendation |
| **ADR** | *We chose X because Y.* | Immutable record of one decision | Context, decision, consequences — single-focus |
| **Design Doc** | *Here's how we will build it.* | Lives through implementation | Components, APIs, data flow, edge cases |

### How they compose

- One RFC can produce **multiple ADRs** — each discrete decision in the RFC's "Decision" section becomes its own ADR so the choice stays discoverable without reading the full proposal.
- One Design Doc can **reference multiple ADRs** — the DD describes the how; the ADRs explain why each constrained choice was made.
- ADRs can also emerge **during** Design Doc work — decisions surface as the design is fleshed out and get captured as they crystallize.

### When to use which subset

| Situation | Artifacts needed |
|-----------|------------------|
| Small change, clear decision | **ADR** only |
| Contested or speculative proposal, no complex build | **RFC → ADR** |
| Large feature, controversial approach | **RFC → ADR(s) → Design Doc** |
| Large feature, uncontested approach | **Design Doc** (ADRs extracted as decisions surface) |
| Emergent architectural choice made during implementation | **ADR** written after the fact |
| Exploratory or google-style design culture | **RFC → Design Doc → ADR(s) extracted from DD** |

### Anti-patterns

- **RFC that reads like a Design Doc.** If you already know how to build it and there's nothing to debate, skip the RFC.
- **ADR that reads like an RFC.** An ADR records a decision — it does not propose one. If alternatives are still open, you want an RFC.
- **Design Doc with no ADRs for load-bearing choices.** Key technology or architecture picks should be extractable — future readers shouldn't have to re-read the whole DD to find them.
- **Writing all three for a trivial change.** Overhead is real; pick the smallest artifact set that captures the decision.

## Repository Placement and Naming Authority

[`Documentation Placement and Naming Rules`](../solution-structure/SKILL.md#documentation-placement-and-naming-rules)
is the sole source of truth for every in-repo documentation directory, filename, scoped placement, and
supporting-material location. Read that complete section before creating or moving an artifact. This skill does
not define parallel app, module, component, service, project, or release filename forms.

Choose the narrowest scope that still captures the right audience, then apply the one canonical form from
`solution-structure`. Scope changes audience and placement context only; it does not create different document
semantics, metadata, identifiers, or lifecycle rules.

Point-in-time records capture a proposal, decision, design, incident, coordinated test scope, or status at a
specific time. Living documents—such as runbooks, SOPs, architecture overviews, and test cases—are revised in
place as the system evolves. Singletons remain one-per-repository references. `solution-structure` expresses
those distinctions in their canonical physical names.

### Identifier schemes

- **Tickets** use `{TicketId}`, the complete external tracker identifier defined by `solution-structure`. Preserve its tracker prefix; for GitHub issue 42 the identifier is `GITHUB-42`, never `42` or an invented local alias.
- **Projects** use a sequential internal ID: `P1`, `P2`, `P3`, ...
- **Documents** use a timestamp-slug ID: `{DocumentTypeAbbreviation}-{yyyyMMddHHmm}-{slug}` where
  `{DocumentTypeAbbreviation}` is the established identifier for the selected document type (`ADR`, `RFC`,
  `PIR`, etc.), the timestamp follows .NET DateTime conventions (`yyyy`=year, `MM`=month, `dd`=day,
  `HH`=24-hour, `mm`=minute), and `slug` is the kebab-case title. In-document references use this full ID;
  resolve its physical name from `solution-structure`.
- **SOPs** are the one living document type with an ID of its own. Cross-references from runbooks, tickets, and other SOPs use `SOP-{slug}`. Living documents have no timestamp, so the slug is the stable handle; resolve the physical name from `solution-structure`.
- **ID placement inside a document:** the ID lives in the `## Metadata` block (e.g., `**ADR ID:** ADR-202603121430-adopt-event-sourcing-for-billing`), **not** in the `# H1 title`. The H1 is the human-readable title only — `# Architectural Decision Record: Adopt event sourcing for the billing module` — keeping the ID out of the title prevents repetition and keeps the heading scannable.

### Codenames vs functional names in prose

Repositories commonly use an internal **codename** that differs from the functional product name. Codenames
are developer-facing technical identifiers; product users, support staff, auditors, and onboarding readers may
not know what they mean.

**Rule:** in doc *prose*, prefer the **functional / product name**. Reserve the codename for places where it is a technical identifier that cannot be renamed.

| Context | Use |
|---|---|
| File paths, folder names | **canonical technical name resolved from `solution-structure`** |
| Git remotes, branch names, repository URLs | **existing technical identifier** |
| Package, namespace, and class names | **canonical technical name from the owning engineering convention** |
| Configuration keys, environment variables, image and container names | **existing technical identifier** |
| Headings and intro paragraphs | **functional product name** |
| User- or stakeholder-facing prose | **functional product name** |
| Business Case, Project Status Update, Retrospective | **functional product name**; these are read by leadership and finance |
| Architecture Overview, Runbook, SOP | **functional name** in prose; the resolved technical name in commands and paths |

**Why:** docs survive past their original audience. The engineer who wrote it knows what the codename refers to; the product manager onboarding two years later does not. Functional names age better and onboard faster, while codenames in technical identifiers stay stable through renames.

**Exception:** when a codename has become the de facto product name (used externally with customers, marketing, or sales), treat it as the functional name and use it everywhere.

### Placeholder conventions inside templates

- **Dates:** `[YYYYMMDD]` — compact, no dashes (e.g., `[20260425]`).
- **Times:** `[HH:MM]` (24-hour).
- **Generic placeholders:** square brackets — `[Name]`, `[Project Name]`, `[Title]`.
- **Format-string placeholders** (where the *shape* of the value is the placeholder): bare literal — `yyyyMMddHHmm`, `slug`, `[N]`, `[X.Y]`. No curly braces.

### Metadata field conventions

Rules that govern the `## Metadata` block at the top of every template. The templates themselves are the source of truth for which fields each doc carries — the rules below prevent drift.

**Field order** (by scanning priority, not alphabetical):

1. Identity — Doc ID, or for project-scoped docs `Project ID` + `Project Name`, or for HR/personal docs the subject identity (`Role`, `Employee Name`)
2. Version (when carried — see rule below)
3. Last Updated / Modified (when present)
4. Date / Created (when first written; SOP uses `Effective Date` here)
5. Status (only when present as a metadata field, not a separate `## Status` section)
6. Domain-specific descriptive fields — Severity, Scope, Reporting Period, Duration, etc.
7. Person fields — Authors, Owner, Reviewers, Approver, Manager, From/To

**Naming rules:**

- **Author / Owner**: `Authors` / `Author` for who **wrote** a per-instance doc; `Owner` for who **maintains** a living doc. Domain labels (`Manager` for PIP, `From`/`To` for Handover, `Project Manager` for PSU) where intrinsic to the doc type.
- **Version is rare**. For most docs, Git history + the `Status` field already capture revision and lifecycle — a manually-bumped Version adds bookkeeping without value. Templates default to **no `Version:`**. Two exceptions:
  - **Regulated SOPs** (ISO 9001 / FDA QSR / GxP) — auditors require an explicit Version stamp independent of Last Reviewed; the SOP template flags this as a regulated-context override.
  - **Takeover & Handover** — sign-off ceremony where both parties literally agree on a specific revision; Version is part of the legal feel of the doc.
- **Last Updated** is used by docs that are continuously edited: living docs (Runbook, Test Cases, Tech Stack, Glossary, Data Dictionary, Architecture Overview), and continuously-revised per-instance docs (Test Plan, SOP — which uses `Last Reviewed`).
- **Date semantics**: `Date` = creation; `Last Updated` = most recent edit; `Effective Date` + `Last Reviewed` + `Next Review` for SOP; `Incident Date` (event) vs `Date` (when written) for PIR.

**Metadata is data, not links.** Pointers to other docs go **only** in `## References` — never as `**RFC:**` / `**Business Case:**` / `**References:**` field inside Metadata. One canonical location per fact.

### Status vocabulary

Templates that track lifecycle carry a `## Status` section whose `<!-- Choose one: ... -->` comment lists the values valid for that document type. The shared vocabulary is defined once here — generated documents record only the chosen value, never a vocabulary table.

| Status | Description |
|--------|-------------|
| Draft | The document is being written and not yet agreed upon. Open for discussion. |
| In Review | The document is under active review by stakeholders. |
| Approved | Agreed upon by stakeholders; the official direction (execution or implementation can proceed). |
| Implemented | The proposal or design has been implemented and is live in production. |
| Rejected | Formally declined, with reasons documented. Kept to record what was considered. |
| Superseded by [Doc ID] | Replaced by a newer document (e.g., `Superseded by ADR-yyyyMMddHHmm-slug`). Creates a clear chain. |
| Archived | No longer relevant or in effect, but not directly replaced. Preserved for reference. For Test Plans specifically: the release shipped; the plan is preserved for reference. |
| Canceled | Intentionally abandoned or descoped before completion. No further work will be done. |

The Post Incident Review extends this with incident-specific statuses (Awaiting Root Cause, Pending Approval, Completed, Follow-up Required, Closed, Obsolete, Reopened) defined in its template.

### Supporting material

Non-markdown material—diagrams, screenshots, spreadsheets, raw data, benchmark output, and recordings—must
remain attributable to the document it supports. Resolve its physical location and name from
`solution-structure`; do not invent a parallel `assets` or CI-style `artifacts` convention.

- Link to supporting material with paths relative to the document.
- Create physical storage only when material exists; empty directories are clutter.
- Commit only shareable material. Personal scratch, raw recordings, and sensitive data belong elsewhere.

### Embedding diagrams in markdown

Different diagram formats render differently on GitHub:

- **Mermaid** — GitHub renders ` ```mermaid ` code fences natively. Inline directly in the markdown; reserve attachment storage for complex or reused diagrams.
- **PlantUML** — GitHub does **not** render `.puml` natively. A pre-commit git hook generates a sibling `.svg` from the `.puml` source. The doc embeds the SVG inside a collapsible `<details>` block that also points readers at the editable source.

**PlantUML embedding pattern:**

````markdown
<details>
<summary>The Auth Flow Diagram</summary>

> [!TIP]
> [Edit the PlantUML source](relative-link-to-plantuml-source) and render it with PlantUML. <!-- link-check-ignore -->

![The Auth Flow Diagram](relative-link-to-rendered-svg)
</details>
````

Why this shape:
- `<details>` keeps long diagrams collapsed by default so the doc body stays scannable.
- The `> [!TIP]` callout points contributors to the editable source — the `.svg` is generated, not hand-edited.
- Keep the `.puml` source and generated `.svg` together in the supporting-material location selected by `solution-structure`. Commit both: GitHub renders the SVG, while humans edit the PUML.

### Gotchas

- Takeover and Handover use the same template for incoming and outgoing transfer; resolve its physical output name from `solution-structure`.
- Runbooks, SOPs, and test cases are living documents updated in place as systems, procedures, and features change.
- Data Dictionary, Business Glossary, and Tech Stack Overview are one-per-repository singletons.
- Architecture Overview is living documentation. Its physical scope is Repository/Product, Module, Component, or Service as defined by `solution-structure`; its title and slug may cover a coherent area within that scope. Pick the narrowest useful audience.
- Brag documents and PIPs are personal/HR artifacts. Do not commit them to the repository.

## Templates

Templates below are ordered by lifecycle phase, matching the Lifecycle Phases section above.

### Phase 2 — Justification & Approval

#### Business Case
**Template:** [templates/business-case.md](templates/business-case.md)

Use to secure support, funding, or prioritization. **Scales to project size:**
- **Light usage** *(Project Brief equivalent)*: Executive Summary, Reasons, Business Options, Timescale, Major Risks. Skip the financial sections. Use when approval gates on capacity/strategy, not budget.
- **Heavy usage**: Fill all sections including Costs, Dis-benefits, Investment Appraisal. Use for funding/capital allocation decisions.
- **With dedicated Financial Model**: Keep financial sections high-level here and produce a Business Case Financial Model alongside it.

---

#### Business Case Financial Model
**Template:** [templates/business-case-financial-model.md](templates/business-case-financial-model.md)

Use to evaluate financial impact.

---

### Phase 3 / 9 — Knowledge Transfer (in) / Closure

#### Takeover & Handover
**Template:** [templates/takeover-handover.md](templates/takeover-handover.md)

Single template covering both directions of ownership transfer:
- **Phase 3 (Takeover)** — receiving party fills it in when **inheriting** ownership of an existing system or project.
- **Phase 9 (Handover)** — outgoing party fills it in when **transferring out** ownership at project closure or role change.

---

### Phase 4 — Decide & Design

#### Request for Comments (RFC)
**Template:** [templates/request-for-comments.md](templates/request-for-comments.md)

Use before implementing big changes.

---

#### Architecture Decision Record (ADR)
**Template:** [templates/architecture-decision-record.md](templates/architecture-decision-record.md)

Use when making or changing architecture.

---

#### Design Doc (aka Tech Spec)
**Template:** [templates/design-doc.md](templates/design-doc.md)

Use before coding complex features.

---

### Phase 5 — Build Contract

#### Test Plan
**Template:** [templates/test-plan.md](templates/test-plan.md)

Use for cross-feature, release, or project-level test strategy.

**Created by:** Test Lead (or senior Tester) — coordinates with Planner, Architect, and Tester(s) to define scope, environments, and exit criteria, and maintains the Test Cases Index inside the TP

**When to use:** opt-in, *not* per-feature.

- Multi-feature releases needing a coordinated test approach (shared environments, integration strategy, performance/load plans).
- Project-level work requiring a coordinated strategy across multiple features or deliverables.
- Regulated contexts (FDA, IEC 62304, ISO 13485, ISO 26262) where a Test Plan is a *required* deliverable.
- Non-functional test strategy (performance, security, accessibility, chaos) that doesn't fit cleanly under any single feature's Test Cases.

**Skip when:** feature-by-feature work where Planner's acceptance criteria + per-feature Test Cases + CI gates already capture the verification approach. Most agile change sets do not need a TP.

**Relationship to Test Cases:** A Test Plan *contains references to or implies* the set of Test Cases that fulfill it. One TP, many TCs. Do not duplicate scenario-level content between them — keep TC-level detail in the TC document; keep strategy / environment / schedule content in the TP.

---

#### Test Cases
**Template:** [templates/test-cases.md](templates/test-cases.md)

Use for QA verification of acceptance criteria.

**Created by:** Tester

**Timing:** Test Cases are **drafted before Developer starts** — they serve as the build contract, derived 1:1 from the Planner's acceptance criteria. Developer builds against them. After Developer passes Reviewer, the Tester implements the Test Cases as executable unit/integration tests. Both the Test Cases document and the executable tests are updated together during Reviewer FAIL iterations.

If a Test Plan exists for the release/project, ensure these Test Cases align with the TP's scope, exit criteria, environment expectations, and overall approach — and update the TP's Test Cases Index to link the new TC document (the index goes stale silently if nobody maintains it).

Drafting Test Cases pre-implementation catches missing or ambiguous acceptance criteria while they are still cheap to fix and prevents the Tester from backfilling cases to match what was built (confirmation bias).

---

### Phase 7 — Operate

#### Runbook
**Template:** [templates/runbook.md](templates/runbook.md)

Use for handling systems and failures.

**Audience:** On-call engineers who may be unfamiliar with the service

**Clarity Checklist:**
- [ ] Symptom clearly described (what does the alert/issue look like?)
- [ ] Steps are numbered and specific
- [ ] Commands are copy-pasteable (no placeholders without explanation)
- [ ] Expected output shown for each command
- [ ] Escalation path defined (who to contact, when)
- [ ] Rollback steps included
- [ ] No jargon without explanation

**Shell Commands:** Use PowerShell syntax (`pwsh` code blocks). Do not use Unix-style commands like `grep`, `awk`, `sed`. Use PowerShell equivalents:

| Unix Command | PowerShell Equivalent |
|--------------|----------------------|
| `grep "pattern"` | `Select-String -Pattern "pattern"` |
| `grep -i "pattern"` | `Select-String -Pattern "pattern" -CaseSensitive:$false` |
| `grep -A5 "pattern"` | `Select-String -Pattern "pattern" -Context 0,5` |
| `grep -B5 "pattern"` | `Select-String -Pattern "pattern" -Context 5,0` |
| `grep "a\|b\|c"` | `Select-String -Pattern "a|b|c"` |
| `cat file.txt` | `Get-Content file.txt` |
| `head -n 10` | `Select-Object -First 10` |
| `tail -n 10` | `Select-Object -Last 10` |

---

#### Standard Operating Procedure (SOP)
**Template:** [templates/standard-operating-procedure.md](templates/standard-operating-procedure.md)

Use for repetitive tasks requiring compliance and consistency.

---

### Phase 8 — Report Progress

#### Project Status Update
**Template:** [templates/project-status-update.md](templates/project-status-update.md)

Use for regular reporting to stakeholders.

---

### Phase 9 — Closure

#### Retrospective
**Template:** [templates/retrospective.md](templates/retrospective.md)

Use at project end to capture outcomes and lessons.

(Takeover & Handover template, also used in Phase 9 for outgoing transfer, is documented above under Phase 3 / 9.)

---

### Phase 10 — Always-Living Reference

#### Tech Stack Overview
**Template:** [templates/tech-stack-overview.md](templates/tech-stack-overview.md)

Use to document current technologies.

---

#### Architecture Overview
**Template:** [templates/architecture-overview.md](templates/architecture-overview.md)

Use to explain how an existing product, module, component, service, or coherent area works — the Diátaxis *Explanation* quadrant. Describes behavior and structure as they are today; defers the *why* to ADRs, *what tools* to Tech Stack Overview, and *fields* to Data Dictionary.

**Coverage is flexible; physical placement is not.** Select one Repository/Product, Module, Component, or Service scope from `solution-structure`, then describe the whole scope or a coherent area within it:
- Whole system — the complete app
- One service — its responsibilities, collaborators, and runtime behavior
- Auth flow — a coherent subsystem within a module
- Billing pricing engine — a specific area of complexity
- Refunds pipeline — a module-scoped area

Pick the narrowest scope that captures a useful audience. Don't try to put everything in one doc.

**When to use:** any time someone with zero prior context needs to understand a system or sub-system without reading the code. Common triggers: onboarding new engineers, post-acquisition integration, regulator/auditor walkthroughs, vendor due diligence, replacing tribal knowledge with written reference.

**Distinct from Design Doc:** Design Doc is forward-looking (*how we will build it*). Architecture Overview is retrospective (*how it works today*). The same system may have a Design Doc when first built and an Architecture Overview that lives on as the system evolves.

---

#### Data Dictionary
**Template:** [templates/data-dictionary.md](templates/data-dictionary.md)

Use to document schema, fields, data types, and governance.

---

#### Business Glossary
**Template:** [templates/business-glossary.md](templates/business-glossary.md)

Use to define key business and technical terms.

---

### Orthogonal Flow A — Incident

#### Post Incident Review (aka Postmortem)
**Template:** [templates/post-incident-review.md](templates/post-incident-review.md)

Use after incidents.

---

### Orthogonal Flow B — People & Recruiting (not in repo)

HR-adjacent docs. **None of these live in the repo** — they are personal or HR artifacts. Templates are kept in this skill so they are available when needed, but the produced documents are stored outside the repo.

#### Role Brief
**Template:** [templates/role-brief.md](templates/role-brief.md)

Tech-team intake brief handed to HR / recruiting when opening a new requisition. Documents what the engineering team is looking for so HR can source candidates and produce the public job posting.

**Created by:** Engineering Manager or Tech Lead, with input from the team.

**Reviewed by:** Hiring Manager + HR Partner.

**Scope:** Document the role, not specific candidates. One brief per role; updated as the role definition evolves.

---

#### Brag Document
**Template:** [templates/brag-document.md](templates/brag-document.md)

Use before reviews or promotion cycles.

---

#### Performance Improvement Plan (PIP)
**Template:** [templates/performance-improvement-plan.md](templates/performance-improvement-plan.md)

Use when an employee's performance needs formal guidance.
