---
name: cross-vendor-examine
description: Use when someone asks to get a second opinion from another AI, "discuss this with codex", "ask gemini", "run it past claude", "check with the other model", or says "/cross-vendor-examine". Convenes the AI assistants installed on this machine — each from a different vendor — as independent peer reviewers of a document, plan, or decision, then reports where they agree, where they disagree, and who is right. Works in whichever assistant is running: the host convenes, the peers respond. Do not trigger for factual lookups or anything with one right answer; the value is disagreement between vendors, and there has to be something to disagree about.
type: guidance
applies_to:
  - All agents
mandatory: conditional
mandatory_when:
  - The user wants a document, plan, or decision reviewed by an AI other than the one they are talking to
  - The user wants cross-vendor disagreement surfaced before committing to something
note: cross-vendor peer review over local CLIs; each round is a paid API call on the user's own account for that vendor. Not for factual questions or single-answer problems.
triggers:
  - cross-vendor-examine
  - second opinion
  - discuss with codex
  - ask gemini
  - run it past claude
  - check with the other model
  - cross-model review
  - cross-vendor review
summary: Convenes the AI assistants installed on the machine, each from a different vendor, as independent reviewers; relays their output verbatim and synthesizes agreement, disagreement, and error. Symmetric — any assistant can host.
---

## What this does

Every assistant on this machine ships a command-line interface with a headless mode: a prompt goes in, an answer comes out. That makes them reachable by each other. This skill uses that to get a real second opinion instead of a self-review.

**The value is independent scrutiny, including both convergence and disagreement.** Treat convergence as supporting evidence, not proof. When reviewers split, report each position and identify which is better supported; if the evidence does not resolve the issue, say so plainly.

It is also the fastest way to find your own errors. A peer given your analysis and asked what you got wrong will tell you, and it will frequently be correct.

## Portability

This SKILL.md follows the Agent Skills open standard and runs unmodified across tools; frontmatter keys a tool doesn't understand are ignored.

The skill is **symmetric**. Whichever assistant the user is talking to is the *host*; every other installed assistant is a *peer*. The host discovers peers, sends the brief, relays answers, and synthesizes. Nothing here assumes a particular host.

**Never hard-pin model names in this file.** Model lineups change; discover them at run time (below). If your platform cannot shell out to other processes, this skill cannot run — say so plainly rather than simulating a peer review by role-playing the other model. One model impersonating another vendor is worse than no review at all, because it manufactures the appearance of independence.

## Step 1 — discover the peers

Do not assume which assistants are installed. Probe, and use what answers.

| Peer | Command | Headless flag |
|---|---|---|
| Antigravity | `agy` | `-p` / `--print` |
| Claude Code | `claude` | `-p` / `--print` |
| Codex | `codex` | `exec` subcommand |

Check each with a `which` / `Get-Command`. Report which peers are available before starting, and never silently drop one that failed — a review that quietly became a monologue is a misleading result.

**Drop your own CLI from the discovery results before presenting them.** You are the host, not a peer; an assistant convening its own command produces the same-vendor self-review this skill exists to avoid. Note: `agy` (Antigravity) is the host CLI for Gemini models when running under Antigravity.

**Then ask the user which peers to convene. Do not default to all of them.** Present what's installed, note that each peer is a separate paid call on their account with that vendor, and let them choose. Reasons they will often want fewer than all:

- One strong peer plus the host finds most of what is findable; the third mostly agrees, and agreement is the one thing this exercise cannot use.
- They may not have credit or a subscription with every vendor.
- Some material should not be sent to some vendors.

Once chosen, keep that roster for the whole session unless the user changes it — swapping peers mid-review makes rounds incomparable.

**Use the peer CLI's configured default model** unless the user explicitly chooses a specific model or reasoning tier. If model selection matters, present the available choices and cost/latency trade-offs before proceeding; never silently select the highest-cost reasoning tier.

- `agy models` lists Antigravity models.
- Claude takes `--model <alias>` (e.g., `opus`, `sonnet`).
- Codex takes `-m <model>`; the user's `config.toml` holds their default.

**Never route a peer to a model from the host's own family.** A second opinion from the same vendor is not a second opinion. Most of these CLIs expose competitors' models — check, and skip them for this purpose.

## Step 2 — write your own analysis first

Before you read any peer output, write your own and save it. Once you have read theirs you cannot un-read it, and every later "independent" judgement of yours is contaminated.

## Step 3 — deliver the brief

Compose the brief per Step 4 first before delivering it; this section details the mechanics for delivering the prompt to each CLI once written.

Each CLI has its own arrangement of prompt, model, and permission flags. The traps below are real and each one fails *silently* — you get a plausible answer to the wrong question.

**Default to inlining only the material the user approved and disabling peer tools.** Grant file-reading tools only when necessary, after stating the readable scope and verifying it excludes secrets or unrelated repository files. Read-only access does not mean disclosure-safe.

### Antigravity

```powershell
$prompt = Get-Content prompt.md -Raw
agy --model <model> -p $prompt --print-timeout 5m
```

- **`--model` must come before `-p`**, or it is ignored and the default model answers.
- **The prompt is an argument, not stdin.** Piping fails silently — it will answer something you never asked.
- **Headless mode auto-denies every tool permission**, so it cannot read files. **Inline the document into the prompt.** Do not reach for the skip-permissions flag: it auto-approves *all* tools including command execution and file edits.
- **On PowerShell**, pass single-quoted here-strings (`@'...'@`) or string variables so `$` and backticks stay literal. Windows caps command lines near 32,767 characters — if the inlined document approaches that limit, split the review into smaller topic rounds rather than truncating.
- Reasoning effort is part of the model name.
- Resume with `--conversation <id>`, or `-c` for the most recent.

### Claude Code

```
claude -p "<PROMPT>" --model <model> --tools "Read,Grep,Glob"
```

- Scope tools explicitly with `--tools` (or `--allowed-tools`). A reviewer needs to read, not to write.
- `--output-format text` for prose; `stream-json` if you need to parse.
- Resume with `--resume <session-id>`, or `-c` to continue the most recent.

### Codex

```
codex exec -C "<workdir>" -s read-only -m <model> -c 'model_reasoning_effort="<effort>"'
```

- Prompt arrives on **stdin**. Note that PowerShell has no `<` redirect — pipe instead (`Get-Content prompt.md -Raw | codex exec ...`).
- **Capture the session id from the startup banner.** You need it to continue the conversation.
- Resume: `codex exec resume [FLAGS] <SESSION_ID> -` — the trailing `-` reads stdin. Flags go *before* the id, and `resume` rejects `-C`/`-s` because it inherits the original session's workdir and sandbox; override with `-c sandbox_mode="read-only"` instead.
- `-o <file>` writes only the final message to stdout; without it progress outputs to stderr and final text to stdout.
- `--strict-config` errors on unrecognized `-c` keys — use it to verify an override actually took effect.
- If the user's config generates persistent memories, `-c memories.generate_memories=false` stops writing while still reading. Do not disable the memories *feature* wholesale unless the user asks — that stops reading too.

## Step 4 — write the brief well

Prompt quality decides whether this is useful or theatre.

- **`SETTLED — DO NOT REOPEN:`** followed by decisions already made and why. Without it, peers relitigate closed arguments every round.
- **"Give exact replacement text, not a description."** Otherwise you get "consider tightening this," which cannot be acted on.
- **"If it is clean, say so plainly. Do not manufacture findings to justify the pass."** Reviewers invent problems when they believe finding some is the job.
- **Word limits.** Unbounded reviews pad.
- **State what changed since their last read** and what was already fixed, so they don't re-flag resolved items.
- **Ask them to adjudicate you.** Hand over your own analysis and ask what you got wrong. Highest-value output available.
- **Name the register** if the answer will be pasted into someone's prose: "in the author's voice — short, plain, concrete, no jargon."
- **One topic per round.** Whole-document rounds produce shallow output.

## Step 5 — relay and synthesize

- **Quote peers verbatim.** Never paraphrase a reviewer you are also arguing with — you are an interested party.
- Report in this order: what converged, what peers caught that the host missed, where positions differ, which position is better supported (or why the issue remains unresolved), and what is still open.
- **When peers split against each other**, report both positions verbatim, rule on it yourself with a reasoned argument, and never resolve peer splits by simple majority vote.
- **Concede plainly when a peer is right.** State the correction and move on; do not narrate the mistake.
- When you disagree, defend the position with an argument, not with deference. Peers are often wrong, particularly about a user's deliberate stylistic choices and about anything they treat as a deviation from a published standard.

## Step 6 — confirmation pass

After applying changes, run at most one confirmation pass with the same roster. Stop when no material finding remains or after two total rounds (initial review plus confirmation). Obtain explicit user consent before any additional round, stating its expected benefit and cost.

## Constraints

- **Anything sent to a peer leaves the machine** and is billed to the user's account with that vendor. Say so before sending the first payload of real content.
- **Never modify the user's config files** to make a call work. Use per-invocation overrides, and tell the user what you overrode.
- **Never use a skip-all-permissions flag.** If a peer cannot read a file, inline the content instead.
- **Each round costs a full model invocation.** At high reasoning tiers these are slow and not cheap. Cap the rounds, and say what a further round would buy before spending it.
