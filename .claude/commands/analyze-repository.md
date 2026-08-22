---
description: "Analyze a repository to understand its purpose, architecture, and how it works"
---

# Repository Analyzer

Analyze this repository to understand what it does, how it's structured, and how it works.

## Analysis Process

### 1. High-Level Overview

Start with these files (in order):
- `README.md` - Purpose and usage
- `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` - AI instructions (if present)
- `CLAUDE.md` - Workflow orchestration and authority routing
- `.github/CONTRIBUTING.md` - Broad cross-cutting engineering and quality principles
- `.claude/rules/*.md` - Applicable technology and artifact implementation conventions
- `.github/skills/INDEX.md` - Skill routing and specialized authority discovery
- `package.json`, `*.csproj`, `*.slnx`, and legacy `*.sln` - Dependencies and project structure

### 2. Project Structure

- Map the folder structure
- Identify the architecture pattern (clean architecture, vertical slices, etc.)
- Identify entry points (Program.cs, main.ts, index.js, etc.)
- Identify configuration files

### 3. Core Functionality

- What problem does this solve?
- What are the main features?
- What are the key domain concepts?
- What external services does it integrate with?

### 4. Technical Stack

- Language and framework
- Database(s)
- Message queues
- Caching
- External APIs
- Infrastructure (Docker, Kubernetes, etc.)

### 5. Data Flow

- How does data enter the system?
- How is it processed?
- How is it stored?
- How does it exit the system?

### 6. Key Components

Identify and describe:
- Services/Controllers
- Domain models
- Repositories/Data access
- Background jobs
- API endpoints

## Output Format

### Summary

[2-3 sentences describing what this repository does]

### Purpose

[What problem does it solve? Who is it for?]

### Architecture

```
[ASCII diagram or description of high-level architecture]
```

### Tech Stack

| Category | Technology |
|----------|------------|
| Language | |
| Framework | |
| Database | |
| Messaging | |
| Caching | |
| Infrastructure | |

### Key Components

| Component | Purpose | Location |
|-----------|---------|----------|
| [name] | [what it does] | [path] |

### Data Flow

1. [Entry point]
2. [Processing step]
3. [Storage/Output]

### External Dependencies

| Service | Purpose |
|---------|---------|
| [service] | [why it's used] |

### Entry Points

| Entry Point | Purpose |
|-------------|---------|
| [file/endpoint] | [what it does] |

### Configuration

| Config File | Purpose |
|-------------|---------|
| [file] | [what it configures] |

### Questions / Areas Needing Clarification

- [Any unclear aspects that need human input]
