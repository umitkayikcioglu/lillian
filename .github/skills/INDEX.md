# Skills Index

This file maps task triggers to skill documents.
If multiple skills match a task, apply all applicable skills.

> The per-skill entries below are **generated** by `tools/sync-ai-platforms.ps1` from each SKILL.md's frontmatter (`applies_to`, `mandatory_when`, `triggers`, `note`, `summary`). Edit the skill's frontmatter, not this block.

<!-- BEGIN GENERATED SKILLS (edit SKILL.md frontmatter, not this block) -->

## cross-vendor-examine
- Path: `cross-vendor-examine/SKILL.md`
- Applies to: All agents
- Mandatory when:
  - The user wants a document, plan, or decision reviewed by an AI other than the one they are talking to
  - The user wants cross-vendor disagreement surfaced before committing to something
- Triggers:
  - "cross-vendor-examine"
  - "second opinion"
  - "discuss with codex"
  - "ask gemini"
  - "run it past claude"
  - "check with the other model"
  - "cross-model review"
  - "cross-vendor review"
- Note: cross-vendor peer review over local CLIs; each round is a paid API call on the user's own account for that vendor. Not for factual questions or single-answer problems.

---

## documentation-generator
- Path: `documentation-generator/SKILL.md`
- Applies to: Documenter, Planner, Architect, Developer, Tester
- Mandatory when:
  - Creating ADRs or RFCs
  - Writing design documents
  - Creating runbooks or SOPs
  - Creating handover documentation
  - Creating data dictionaries
- Triggers:
  - "documentation"
  - "ADR"
  - "RFC"
  - "runbook"
  - "post incident review"
  - "postmortem"
  - "design doc"
  - "handover"
  - "SOP"
  - "business case"
  - "brag document"
  - "project status"
  - "retrospective"
  - "tech stack"
  - "architecture overview"
  - "data dictionary"
  - "performance improvement"
  - "test cases"
  - "test plan"
  - "role brief"
  - "job ad"
  - "hiring"
  - "recruiting"

---

## dotnet-service-generator
- Path: `dotnet-service-generator/SKILL.md`
- Applies to: Developer, Architect
- Mandatory when:
  - Creating a new .NET service
  - Scaffolding service modules
- Triggers:
  - "create a service"
  - "scaffold service"
  - "add a new service"
  - "generate service boilerplate"

---

## excalidraw-diagram-generator
- Path: `excalidraw-diagram-generator/SKILL.md`
- Applies to: Developer, Architect, Documenter
- Mandatory when:
  - Creating visual diagrams of workflows, architectures, or concepts
  - Generating Excalidraw JSON files
- Triggers:
  - "excalidraw"
  - "diagram"
  - "visualize"
  - "architecture diagram"
  - "workflow diagram"

---

## infrastructure
- Path: `infrastructure/SKILL.md`
- Applies to: Developer, Reviewer
- Mandatory when:
  - Creating or updating Dockerfiles
  - Creating or updating Kubernetes manifests
  - Configuring health probes
- Triggers:
  - "dockerfile"
  - "kubernetes"
  - "container"
  - "deployment"
  - "health probe"

---

## mssql-bulk-data-operations
- Path: `mssql-bulk-data-operations/SKILL.md`
- Applies to: Developer, DBA
- Mandatory when:
  - Performing large-scale UPDATE or DELETE operations (millions of rows)
  - Staging record IDs into a tracking table for batch processing
- Triggers:
  - "bulk update"
  - "bulk insert"
  - "bulk delete"
  - "update large dataset"
  - "update millions of records"
  - "batch update"
  - "batch insert"
  - "large data operation"
  - "update 3M records"
  - "mass update"

---

## mssql-table-scaffolder
- Path: `mssql-table-scaffolder/SKILL.md`
- Applies to: Developer, DBA
- Mandatory when:
  - Creating or standardizing MSSQL tables
  - Adding new schema artifacts
- Triggers:
  - "create table"
  - "generate table"
  - "scaffold table"
  - "standardize table"
  - "migrate table"

---

## node-development
- Path: `node-development/SKILL.md`
- Applies to: Planner, Architect, Developer, Reviewer, Tester, Documenter
- Mandatory when:
  - Implementing or reviewing Node.js backend, CLI, service, or library code
  - Resolving JavaScript or TypeScript runtime, package, workspace, or build validation
  - Working with npm, pnpm, Yarn, Bun, Nx, or Turborepo Node scopes
- Triggers:
  - "Node.js"
  - "Nodejs"
  - "Node backend"
  - "Node service"
  - "Node CLI"
  - "npm"
  - "pnpm"
  - "Yarn"
  - "Bun"
  - "Express"
  - "Fastify"
  - "NestJS"

---

## observability
- Path: `observability/SKILL.md`
- Applies to: Architect, Developer
- Mandatory when:
  - Defining SLIs or observability requirements
  - Creating dashboards or alerts
  - Instrumenting with OpenTelemetry
- Triggers:
  - "dashboard"
  - "metrics"
  - "tracing"
  - "alerting"
  - "SLI"
  - "observability"

---

## plantuml-sequence-diagram-generator
- Path: `plantuml-sequence-diagram-generator/SKILL.md`
- Applies to: Planner, Architect, Developer
- Mandatory when:
  - A sequence or interaction diagram is requested
- Triggers:
  - "sequence diagram"
  - "service flow"
  - "api interaction diagram"
  - "plantuml"

---

## pressure-test
- Path: `pressure-test/SKILL.md`
- Applies to: All agents
- Mandatory when:
  - The user wants an idea or decision adversarially stress-tested before committing (GO / RESHAPE / KILL verdict)
- Triggers:
  - "pressure-test"
  - "stress-test this idea"
  - "convene the council"
  - "validate a business idea"
  - "brutal second opinion"
- Note: adversarial 5-persona council + Judge (~5-11 subagents per run); uses the `council-*` agent personas. Not for casual opinions or factual questions.

---

## project-instructions-bootstrap
- Path: `project-instructions-bootstrap/SKILL.md`
- Applies to: Planner, Architect, Developer, Reviewer, Tester, Documenter
- Mandatory when:
  - Bootstrapping project-owned contributing guidelines from Lillian
  - Updating project-owned Copilot or Codex orchestration from detected repository evidence
  - Creating `.github/CONTRIBUTING.md` and `.github/copilot-instructions.md` for a consuming repository
- Triggers:
  - "project-instructions-bootstrap"
  - "bootstrap project instructions"
  - "create contributing instructions"
  - "update copilot instructions"
  - "generate repository instructions"

---

## python-development
- Path: `python-development/SKILL.md`
- Applies to: Planner, Architect, Developer, Reviewer, Tester, Documenter
- Mandatory when:
  - Implementing or reviewing Python application, API, CLI, worker, or library code
  - Resolving Python environment, package, test, type-check, build, or deployment validation
  - Working with pyproject.toml, requirements files, Poetry, uv, pip-tools, or Pipenv projects
- Triggers:
  - "Python"
  - "Python API"
  - "Python CLI"
  - "Python package"
  - "FastAPI"
  - "Django"
  - "Flask"
  - "pytest"
  - "Poetry"
  - "uv"

---

## session-handoff
- Path: `session-handoff/SKILL.md`
- Applies to: All agents
- Mandatory when:
  - The user wants to wrap up the session or hand off before clearing context
- Triggers:
  - "session handoff"
  - "wrap up session"
  - "hand off"
  - "handoff summary"
  - "summarize before I clear"
- Note: for a long-form project/role handover **document**, use `documentation-generator` (takeover-handover template) instead.

---

## solution-structure
- Path: `solution-structure/SKILL.md`
- Applies to: Developer, Architect, Documenter, Tester, DBA, Reviewer
- Mandatory when:
  - Deciding where a file/folder goes inside the .NET solution
  - Placing a doc, dashboard, Kubernetes manifest, embedded SQL, or service scaffold
- Triggers:
  - "folder structure"
  - "directory layout"
  - "solution structure"
  - "repo layout"
  - "where does this go"
  - "file placement"
  - "opinionated folder"

---

## storm-research
- Path: `storm-research/SKILL.md`
- Applies to: All agents
- Mandatory when:
  - A multi-perspective, citation-verified research briefing is requested
- Triggers:
  - "storm research"
  - "storm report"
  - "STORM briefing"
  - "multi-perspective research"
- Note: heavyweight pipeline (~9-11 subagents per run); for a simple factual lookup, answer directly instead.

---

## web-frontend-development
- Path: `web-frontend-development/SKILL.md`
- Applies to: Planner, Architect, Developer, Reviewer, Tester, Documenter
- Mandatory when:
  - Implementing or reviewing TypeScript frontend code
  - Implementing or reviewing React, Next.js, or Angular applications
  - Resolving frontend lint, type-check, test, build, package-manager, or workspace validation
- Triggers:
  - "web frontend"
  - "frontend development"
  - "TypeScript"
  - "React"
  - "Next.js"
  - "Nextjs"
  - "Angular"
  - "frontend lint"
  - "frontend test"
  - "frontend build"

---

## work-item-generator
- Path: `work-item-generator/SKILL.md`
- Applies to: Planner, Developer, Architect
- Mandatory when:
  - Creating work items (initiatives, epics, features, stories, bugs, spikes, enhancements, tasks)
  - Filing bugs or logging issues
- Triggers:
  - "work item"
  - "initiative"
  - "epic"
  - "feature"
  - "story"
  - "bug"
  - "spike"
  - "enhancement"
  - "task"
  - "create issue"
  - "create ticket"
  - "file a bug"
  - "log a bug"
  - "report a bug"

---

## workspace-productivity
- Path: `workspace-productivity/SKILL.md`
- Applies to: All agents
- Mandatory when:
  - The user wants to initialize the productivity system in Google Drive for the first time
  - The user wants to sync, update, or triage their task list
  - The user wants to perform a comprehensive scan of Workspace activities
- Triggers:
  - "workspace productivity"
  - "sync tasks"
  - "triage tasks"
  - "initialize productivity"
  - "memory system"
- Note: System initializes a Google Drive workspace or updates an existing one with current tasks and memory system.

---
<!-- END GENERATED SKILLS -->

# Libraries

[Ruya](https://github.com/cilerler/ruya) is the reference library implementation and owns the complete package catalog and package documentation.

A solution may use Ruya or compatible organization-owned libraries, including libraries maintained in a `common-libraries/` workspace. Ruya is not a required dependency.
