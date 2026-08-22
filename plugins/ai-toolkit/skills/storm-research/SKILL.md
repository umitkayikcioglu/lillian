---
name: storm-research
description: Use when someone asks to run Storm Research, use the storm-research skill, run the STORM method on a topic, says "storm research this" / "storm report on X" / "give me a STORM briefing on X", or wants a multi-perspective, citation-verified HTML research briefing on a topic. Runs a 5-phase pipeline: scope -> five expert lenses (Practitioner, Academic, Skeptic, Economist, Historian) -> contradiction map -> synthesized HTML report -> adversarial peer review + primary-source verification. Best for topics where multiple viewpoints and fact-checked claims matter; overkill for a simple factual lookup.
type: guidance
applies_to:
  - All agents
mandatory: conditional
mandatory_when:
  - A multi-perspective, citation-verified research briefing is requested
note: heavyweight pipeline (~9-11 subagents per run); for a simple factual lookup, answer directly instead.
triggers:
  - storm research
  - storm report
  - STORM briefing
  - multi-perspective research
references:
  - assets/report-template.html
summary: Multi-perspective, citation-verified HTML research briefing — five expert lenses, contradiction map, synthesized report, adversarial peer review with primary-source verification.
---

# Storm Research

## What this does

Turns one topic into a verified, multi-perspective HTML briefing. It simulates five expert lenses on the topic, maps where they contradict each other, synthesizes everything into a single self-contained HTML report, then adversarially peer-reviews its own output and verifies every citation against its primary source before delivering. The output is one HTML file with its blind spot named and every claim checked.

Run the full pipeline end to end. Do not shortcut a phase. This is heavier than a quick web lookup; that is the point.

## Portability

This skill is self-contained. It depends only on built-in capabilities — parallel subagents (or a sequential fallback if your platform has none), file writing, and web search/fetch — plus `assets/report-template.html` in this skill folder. No external scripts, APIs, paid services, or other skills are required. Drop the folder into any skills directory and it works. When the containing repository also supplies `solution-structure`, use that optional authority for in-repository placement; its absence never blocks this skill.

Web access is the one hard requirement: if the platform cannot fetch the web, the skill must stop (see Phase 0) — it must never run from training memory.

## Phase 0: Scope the topic

1. If the invocation included a topic argument, use it. Otherwise ask what to research.
2. **Web preflight.** Run one real web search or fetch. If the platform has no web access, STOP and tell the user Storm Research cannot run here — never produce a report from training memory, and never emit a verification banner without fetched sources.
3. State your interpretation of the topic in one line and proceed. Only ask a clarifying question if the topic is genuinely ambiguous in a way that changes the research. Default to proceeding.
4. Identify the **reader's role** so the actionable section can target it. Infer it from the topic and any stated context; if unclear, ask in one line, or default to "a practitioner or decision-maker in this field." A role therefore always exists — the default counts and is written into the report's Audience field.
5. Derive a kebab-case `topic-slug` from the topic for the filename.
6. Tell the user the pipeline is running (5 lenses, then verify). One line.

## Phase 1: Five expert lenses (parallel agents)

Spawn **five research subagents in parallel** using your platform's subagent mechanism; if your platform cannot run subagents, execute the five lenses yourself sequentially, one at a time. Each gets the SAME topic framing plus its own lens. Use these exact prompts, substituting `{TOPIC}` and a one-line `{TOPIC_FRAME}` (your Phase 0 interpretation):

**1. THE PRACTITIONER** — `You are THE PRACTITIONER for: {TOPIC} ({TOPIC_FRAME}). You work with this daily. Do real web research (prioritize recent sources, case studies, practitioner threads, operator data). Surface the GAP between what hands-on operators know and what academics/pundits miss, and the practical realities (workflow friction, what actually works, where it breaks) that get ignored. Return EXACTLY: 1) CORE POSITION in 2 sentences. 2) STRONGEST EVIDENCE, 3-5 bullets each with a concrete data point/case/named source + URL. 3) THE ONE THING only a practitioner would say. Cite real sources with URLs. Under 400 words.`

**2. THE ACADEMIC** — `You are THE ACADEMIC for: {TOPIC} ({TOPIC_FRAME}). You care about peer-reviewed evidence and effect sizes, not anecdotes. Do real web research (peer-reviewed studies, arXiv, university and research-institute reports, journals). Answer: what does the rigorous evidence ACTUALLY say vs popular belief, and where does it CONTRADICT the hype. Return EXACTLY: 1) CORE POSITION in 2 sentences. 2) STRONGEST EVIDENCE, 3-5 bullets each tied to a named study/report + URL with the actual finding/effect size and its peer-review status (published vs preprint), flagging inline where evidence is thin or contested. 3) THE ONE THING only an academic would say. Under 400 words.`

**3. THE SKEPTIC** — `You are THE SKEPTIC for: {TOPIC} ({TOPIC_FRAME}). You think the mainstream view is overstated or wrong. Build the STRONGEST steelman bear case. Do real web research for backlash, failures, contradicting data, policy/regulatory changes, debunkings. Answer: the strongest counterargument, and what proponents conveniently ignore. Return EXACTLY: 1) CORE POSITION in 2 sentences. 2) STRONGEST EVIDENCE, 3-5 bullets each with a concrete source + URL. 3) THE ONE THING only a skeptic would say. Be rigorous, not contrarian for sport. Cite real sources with URLs. Under 400 words.`

**4. THE ECONOMIST** — `You are THE ECONOMIST for: {TOPIC} ({TOPIC_FRAME}). You follow the money. Do real web research for revenues, valuations, market size, funding flows, unit economics, incentives. Answer: who profits from the current narrative, and what financial incentives shape the research and hype. Return EXACTLY: 1) CORE POSITION in 2 sentences. 2) STRONGEST EVIDENCE, 3-5 bullets each with a real number (revenue/valuation/market size/funding) + named source + URL. 3) THE ONE THING only an economist would say (the follow-the-money insight). Cite real figures with URLs. Under 400 words.`

**5. THE HISTORIAN** — `You are THE HISTORIAN for: {TOPIC} ({TOPIC_FRAME}). You have seen disruption cycles before and look for patterns. Do real web research for genuine historical parallels (prior technologies, manias, market shifts). Answer: what parallels actually fit, and what we learn from how they played out (who won, who lost, what stabilized). Return EXACTLY: 1) CORE POSITION in 2 sentences. 2) STRONGEST EVIDENCE, 3-5 bullets each a specific historical case with dates/outcomes + a source URL. 3) THE ONE THING only a historian would say (the pattern no one else surfaces). Cite sources with URLs. Under 400 words.`

When all five return, post a 2-3 line note in chat: which way they converge, and the sharpest disagreement. Keep raw briefs out of chat — if you ran the lenses yourself sequentially, write each brief to a platform temporary directory instead of streaming it into chat or creating an in-repository scratch convention.

## Phase 2: Map the contradictions

Working only from the five briefs, determine (do this inline, no agents):

1. **Direct conflicts** — where two or more lenses claim opposite things. Name the specific clashing claims, not just topics.
2. **Strongest vs weakest evidence** — which lens is best-supported and which is weakest, with why. Rank on the same hierarchy used everywhere in this skill: peer-reviewed causal > official policy/financial data > single commissioned survey > analogy > preprint.
3. **The resolving question** — the single empirical question that would settle the biggest contradiction. This becomes the report's Frontier Question (section 05).
4. **Universal agreement** — what every lens confirms, even opponents. This is the likely-true load-bearing finding.
5. **The blind spot** — what NO lens addressed. This becomes the "missing 6th lens" box (section 03b).
6. **The hidden connection** — the non-obvious link, visible only with all five briefs side by side, that resolves or reframes the biggest apparent contradiction. This fills the report's Hidden Connection section (03).

This map is not a separate deliverable. It is the raw material for the report: findings with their supports/challenges chips (steps 1-2 and 4), the frontier question (step 3), the 6th-lens box (step 5), and the hidden connection (step 6).

## Phase 3: Synthesize the HTML report

1. Read `assets/report-template.html` in this skill folder. Clone it; do not rebuild the CSS.
2. **Fill every section now, with three groups of tokens provisional until Phase 4 overwrites them:** reliability scores (write your pre-verification estimate), the verification banner tag/counts and per-citation status tags (write `PENDING`), and the claim safety guide (draft it from current evidence). Phase 4c must replace every `PENDING`; never deliver a file that still contains one. Mapping from the phases:
   - **60-second summary** — one dense paragraph for the reader named in the Audience field. Lead with the settled fact, then the contested interpretation. Nuance, not headline.
   - **5 key findings, ranked by reliability** — most important things now known, highest reliability first. Each finding states the measured fact first, then the interpretation, and carries a 1-10 reliability score (finalized in Phase 4) plus Supported-by / Challenged-by chips drawn from the contradiction map.
   - **Reliability pills** — map each score to the pill class and label: 8-10 = `high` / "High", 6-7 = `medhigh` / "Med-High", 4-5 = `medium` / "Medium", 1-3 = `low` / "Low".
   - **Hidden connection** — Phase 2 step 6.
   - **Key assumption / missing 6th lens** — Phase 2 step 5, framed as the lens that could change the conclusions.
   - **Actionable insight** — 3-6 specific moves for the reader's role identified in Phase 0. Specific, not abstract.
   - **Claim safety guide** — assert / caveat / avoid; drafted now, finalized after Phase 4 verification.
   - **Frontier question** — Phase 2 step 3, the resolving question.
   - **References** — every citation, status tags `PENDING` until Phase 4.
   - **Contested sidebar & Corrected chips** — omit at Phase 3; Phase 4c adds the sidebar for claims flagged UNVERIFIED/contested/preprint and a Corrected chip wherever verification changed a figure.
   - **Dates** — set every `{{DATE}}` token from the system clock (`date +%Y-%m-%d` on POSIX, `Get-Date -Format yyyy-MM-dd` in PowerShell); never infer the date from memory. Use the same value everywhere.
3. When the repository contains [`solution-structure`](../solution-structure/SKILL.md#non-template-documentation-artifacts), resolve the complete timestamped Research briefing path there. Otherwise write `{yyyyMMddHHmm}-{topic-slug}.html` in the current working directory. In both cases, obtain `yyyyMMddHHmm` from the system clock rather than memory. Never commit report output unless the user asks. If the output is inside a Git working tree, add that exact generated report path to the repository-local `.git/info/exclude` before delivery so an uncommitted report is not staged accidentally; do not alter the shared `.gitignore`.

## Phase 4: Adversarial peer review + verification (do not skip)

This is what separates Storm Research from a normal report. Run it before delivering.

**4a. Self-review (inline).** Score each of the 5 findings 1-10 for reliability and justify. Identify the weakest link — if it cannot be verified in 4b, it moves to the Contested sidebar. Run a bias check (which lens dominated the synthesis, what got underweighted) and rebalance the summary or findings if it changed anything. Cross-check the missing-6th-lens box against what you now know; correct it if verification shifts the picture. Assign an honest overall grade — it goes in the chat summary at delivery.

**4b. Verify every citation (parallel agents).** Spawn verification subagents in parallel, one per distinct citation cluster (group related claims; ~4-6 agents); fall back to sequential verification if subagents are unavailable. Each agent prompt:

`Do real web research: fetch the primary source itself, not summaries of it. Independently verify EACH of the following citations against its PRIMARY source. Be skeptical; do not trust secondary blog summaries. CLAIMS: {numbered list: claim + cited figure + named source}. For EACH numbered claim: find the actual primary source and confirm or correct the exact title/authors/venue/year/URL, the real figure or effect size as published, sample/method and any author-stated limits, and peer-review status (published vs preprint). For any contested claim, find the strongest credible counter-source. Return one block per claim: N) VERDICT = CONFIRMED / PARTIALLY CONFIRMED (list corrections) / UNVERIFIED / FALSE, then the corrected one-line citation, then 2-3 bullets of specifics with the primary URL. Under 120 words per claim.`

**4c. Apply corrections.** Edit the report:
- **Map verdicts to report markup, exactly:**
  - CONFIRMED → status class `ok`, label "Confirmed".
  - PARTIALLY CONFIRMED → status class `part`, label "Corrected", count in **Y** (corrected). Fix the figure/title/date in the body and bold the correction.
  - UNVERIFIED → status class `weak`, label "Demoted", count in **Z** (demoted). Move the claim to the Contested sidebar or cut it from the body; the citation stays listed.
  - FALSE → cut the claim from the body, count in **X** (fabricated). Keep the citation in the evidence base with status class `weak`, label "Fabricated", so the tally stays auditable.
  - Real-but-contested or preprint sources → status class `weak`, label "Contested", count in **Z**. **This row takes precedence over the verdict rows**: if the verifier reports preprint status or finds a credible counter-source, the citation is Contested even when its verdict is CONFIRMED.
  - **Z ("demoted") is the umbrella count** for everything that lost assert-status: Demoted (UNVERIFIED) plus Contested (preprint/counter-sourced).
- Downgrade reliability scores where evidence turned out thin; update the pill class/label to match the new score.
- Re-attribute single-survey or commissioned stats honestly.
- Replace every `PENDING`: set the banner tag to "Verified", fill the banner and footer counts (`X fabricated, Y corrected, Z demoted`), and set every per-citation status tag.
- Finalize the claim safety guide from the verdicts.

## Output

1. Final deliverable: the canonical Research briefing path resolved in Phase 3 — the post-verification version, with every `PENDING` replaced.
2. Best-effort open with the platform's default opener: macOS `open <path>`; Linux `xdg-open <path>` if available; Windows `Start-Process <path>` in PowerShell or `start "" <path>` in cmd. If the command fails or the environment is headless/remote, skip opening and just give the path — a failed open is not a pipeline failure.
3. In chat, give: the file path, the verification tally (`N/N checked, X fabricated, Y corrected, Z demoted`), the honest overall grade from 4a, the one universal finding, the frontier question, and the claim safety summary (what is safe to assert vs avoid). Keep it tight.

## Notes & guardrails

- **Real research only.** Every lens and every citation must trace to a real, fetched source. No invented studies, numbers, or URLs. If a figure can't be verified, demote or cut it; never paper over it. If the platform has no web access, stop at Phase 0 — do not run the pipeline from memory.
- **The panel is author-built.** Always disclose this in the report. Agreement across lenses is a strong hypothesis, not independent proof. Do not present convergence as consensus of the field.
- **Verification is mandatory.** A report delivered without Phase 4 is not a Storm Research report. The verification banner must be truthful, and a file still containing `PENDING` must never be delivered.
- **Reliability = evidence quality, not confidence.** The 1-10 reliability score follows the source hierarchy: peer-reviewed causal > official policy/financial data > single commissioned survey > analogy > preprint.
- **Target the reader.** The actionable insight and claim safety guide speak to the role identified in Phase 0; when that role is the generic default, keep the moves broadly applicable.
- **Cost.** This spawns ~9-11 agents per run. That is expected. Do not fan out wider than five lenses or one verifier per citation cluster.
- **Design.** Clean white and professional (Montserrat / Roboto Mono where installed, system-font fallbacks otherwise; blue accent). Keep the template CSS verbatim. Do not swap in a different visual style.
