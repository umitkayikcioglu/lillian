# Lillian Assistant GPT Builder Package

## GPT Builder Fields

**Name:** Lillian Assistant

**Description:** Repository-aware router that selects the smallest reliable Lillian skill, prompt, or specialist role and produces one copy-ready Codex VS Code prompt.

## Conversation Starters

- Bu iş için en küçük güvenilir Lillian route hangisi?
- Bu PR review için Codex promptu hazırla.
- Frontend hatasını Lillian skill route ile çözdürecek prompt üret.
- Approved planı Codex Goal için implementation promptuna çevir.

## Installation

1. In GPT Builder, set the GPT name to `Lillian Assistant`.
2. Set the description to the approved description above.
3. Copy the full contents of `tools/gpt/lillian-assistant.instructions.md` into the GPT Builder Instructions field.
4. Upload `tools/gpt/lillian-assistant-knowledge-tr.md` as the Knowledge document.
5. Add the four conversation starters above.

The Instructions file is raw GPT Builder content. It intentionally has no Markdown code fence, no character-count heading, and no report commentary.

## Validated Instructions Size

Exact Instructions character count: 7278 characters, including spaces and LF line breaks.

GPT Builder limit target: at most 8,000 characters.

## Model Labels

The following are current environment observations, not a permanent whitelist.

| Label | Routing guidance |
|---|---|
| 5.4 | Current user-reported option; select only from current environment/task evidence. |
| 5.5 | Current user-reported option; select only from current environment/task evidence. |
| 5.6 Sol | Flagship tier for complex work. |
| 5.6 Terra | Balanced everyday work. |
| 5.6 Luna | Fast, repeatable, cost-sensitive work. |

## Reasoning Labels

Use the exact reasoning labels verified in the user's VS Code Codex environment:

| Label | Routing guidance |
|---|---|
| Light | Mechanical, deterministic, small single-file work |
| Medium | Normal bounded .NET/frontend implementation |
| High | Multi-file debugging, integration, and test design |
| Extra High | Architecture, security, concurrency, migration, and data-integrity work |
| Ultra | Only the most complex, highest-risk, materially ambiguous work |

Ultra is exceptional and must not be the default.

Model and reasoning are independent selections. Every routing decision must report a complete exact model label, such as `5.6 Terra`, plus an exact reasoning label.

## Maintenance Checklist

- Re-check `.github/skills/INDEX.md` before changing the Knowledge catalog.
- Re-check `.github/prompts/` before changing prompt routing examples.
- Re-check `.github/agents/` before changing workflow or council agent references.
- Keep reasoning labels exactly as `Light`, `Medium`, `High`, `Extra High`, and `Ultra`.
- Verify both current model generations and all current 5.6 tier names before changing model guidance.
- Recompute the exact Instructions character count after every Instructions edit.
- Confirm the Instructions file remains under 8,000 characters.
- Confirm no ordinal reasoning labels remain.
- Do not edit generated `.agents/`, `.claude/`, `plugins/`, or `.ai/` copies for this package.

## Repository Evidence Override

The Knowledge document is a static reference. The assistant must always prefer current repository evidence over static Knowledge when producing a Codex prompt.

If current repository files disagree with this package, the generated Codex prompt must tell Codex to follow the current repository evidence and surface the conflict.
