---
name: pressure-test
description: Use when someone asks to pressure-test or stress-test an idea, roast an idea, validate a business idea, "convene the council", get a brutal second opinion before building something, or says "/pressure-test". Spins up a 5-persona council that attacks the idea from every angle, then a Judge returns one GO / RESHAPE / KILL verdict with the cheapest test to de-risk it. Say "deep pressure-test" or "with peer review" to add an anonymized peer-review round before the verdict. Do not trigger on casual opinions, factual questions, or anything with one right answer — only decisions with real stakes.
type: guidance
applies_to:
  - All agents
mandatory: conditional
mandatory_when:
  - The user wants an idea or decision adversarially stress-tested before committing (GO / RESHAPE / KILL verdict)
note: adversarial 5-persona council + Judge (~5-11 subagents per run); uses the `council-*` agent personas. Not for casual opinions or factual questions.
triggers:
  - pressure-test
  - stress-test this idea
  - convene the council
  - validate a business idea
  - brutal second opinion
references:
  - references/calibration-briefs.md
summary: Adversarial 5-persona council that attacks an idea from every angle, then a Judge returns one GO / RESHAPE / KILL verdict with the cheapest 48-hour test to de-risk it. Optional anonymized peer-review round.
---

## What this does

AI's default is to agree with you. `/pressure-test` is the opposite. It convenes a council of five independent persona agents who tear an idea apart and build it up from every angle, then a Judge synthesizes everything into one honest verdict. Use it before you sink time and money into building the wrong thing.

The council is adversarial on purpose. No persona is allowed to hedge or be polite. The point is to surface what you can't see because you're too close to it.

Say **deep pressure-test** to add Step 2.5 — an anonymized peer-review round where the council critiques its own output blind before the Judge rules.

## Portability

This SKILL.md follows the Agent Skills open standard and runs unmodified across tools; frontmatter keys a tool doesn't understand are ignored. The five council personas (`council-contrarian`, `council-expansionist`, `council-logician`, `council-researcher`, `council-buyer`) ship with this toolkit as standard agent personas — where your platform supports custom agents they are installed alongside this skill; everywhere else the inline mandates in Step 2 are the source of truth.

Parallel fan-out requires a subagent mechanism. On a platform without one, run the five personas **sequentially** in isolated, clearly labeled sections, writing each response in full before starting the next. The peer-review round degrades to self-review there: run it only if asked — the auto-trigger is disabled in this fallback — and say plainly that the blind is gone and independence is weaker. Never present sequential role-play as independent agents.

If the platform has no web access, the Researcher seat runs blind. In the Researcher's mandate, replace the sentences "Use web research." and "Attach a URL to every number and named claim — uncited figures will be discarded from the verdict rationale." with: "You have no web access. Reason from prior knowledge only; cite nothing, invent no URLs, and prefix every figure with UNVERIFIED." Disclose the blind seat in the verdict; UNVERIFIED figures may inform the verdict but never decide it.

## Decorrelating the council (optional)

Five prompts on one model is self-play: the personas share the same training, so they share blind spots. The original council idea used different models. Reproduce that with whatever model routing your platform offers — and never hard-pin model names inside files you sync across tools.

- If your platform lets you set a model per agent persona, give different seats different models or model families in each persona's local configuration — not in the shared source files.
- Tool locks apply regardless of model: only the Researcher gets web tools. Where your platform supports per-agent tool configuration, enforce the lock there; on the general-purpose fallback the mandates' no-web lines are the only enforcement — additionally restrict the subagent's tools at spawn time if your platform allows it.
- **Strongest form:** mix vendors within one council where your platform supports per-seat models, or run the same brief through this skill on two different tools and diff the verdicts. Cross-vendor disagreement is exactly the signal a single-vendor council cannot produce.

## Step 1: Get the brief

If the invocation included the idea, start there. Then ask the user a tight set of clarifying questions so the council has real context to work with. Ask only what hasn't already been provided. Keep it to 3-4 questions max, in one batch:

1. **The idea** in one or two sentences (what it is, what it does).
2. **Who it's for** and **how it makes money** (the buyer + the price/model).
3. **Your edge** — relevant skills, audience, or assets you already have.
4. **Constraints** — budget, timeline, how fast you need first dollar.

For non-commercial ideas (an architecture choice, a career move, a process change), swap question 2 for "who has to live with it" and "first dollar" for "first result."

If the user says "just run it" or gives you enough already, skip the questions and proceed. Don't over-interrogate. One round, then convene the council.

Write the brief into a single short paragraph you will paste into every council member's prompt, so all five judge the same thing.

## Step 2: Convene the council (5 agents, in parallel)

Spin up **all five agents in one parallel batch** (your platform's equivalent of concurrent subagent dispatch) — by whatever name your platform registers the personas under (plugin installs may prefix a namespace, e.g. `<plugin>:council-contrarian`; check your platform's agent list), otherwise one general-purpose subagent per seat. If invocation by name errors, fall back to the general-purpose path — never abort the run over a name lookup. No subagent mechanism → sequential fallback per Portability. Paste the same brief into each; the mandates below are the source of truth on every platform.

Each council member returns this exact contract, under 300 words total:

```
STANCE: [one line]
POINTS: [3-5 sharpest bullets]
MUST-HEAR: [the single most important thing the user must hear]
DIVERGENCE: [one sentence if your honest call splits from your mandate, else "none"]
BUILD: n/10 (integer 1-10)
```

**BUILD** is scored **outside** the mandate: the persona's honest, all-things-considered call on whether this should actually get built (1 = walk away, 10 = no-brainer). Every persona answers the *same* question, so the five scores are comparable and the spread is signal.

**Assembling a general-purpose seat prompt** — a subagent knows only what is in its prompt. When a persona is not installed, each seat's prompt must contain, in order: (1) the mandate below, (2) the line "Return exactly this contract, under 300 words total:" followed by the contract block above verbatim, and (3) this line: "Stay fully in character everywhere except DIVERGENCE and BUILD — there you drop the act and give your honest, all-things-considered call on whether this should actually get built (1 = walk away, 10 = no-brainer)." Installed personas already carry the contract and that line in their system prompts.

**1. The Contrarian (Red Team)**
> You are the Contrarian on an idea council. Assume the idea in the brief fails. Find the fatal flaws, the fastest way it dies, and the load-bearing assumptions that are probably wrong. Be ruthless and specific. No hedging, no "but it could work." Attack the weakest points. Use no web research — argue from the brief and first-principles reasoning alone. THE BRIEF: [brief]

**2. The Expansionist (Bull)**
> You are the Expansionist on an idea council. Make the strongest possible case FOR the idea in the brief. Find the biggest upside, the 10x version, the adjacent opportunities and unlock points the founder isn't seeing. Fight for the potential. Be specific about where the real money and leverage could be. Use no web research — argue from the brief and reasoning alone. THE BRIEF: [brief]

**3. The Logician (First principles)**
> You are the Logician on an idea council. Use NO outside research and NO web. Reason purely from first principles about the idea in the brief: does the core mechanism make sense, do the incentives line up, is the underlying logic sound, does the math even work in theory? Strip it to fundamentals and say whether it holds together. THE BRIEF: [brief]

**4. The Researcher (Evidence)**
> You are the Researcher on an idea council. Use web research. Bring real-world evidence about the idea in the brief: who the existing competitors are, market size or demand signals, what comparable products charge, whether this is validated by what's already out there or contradicted by it. Attach a URL to every number and named claim — uncited figures will be discarded from the verdict rationale. Is the real world saying yes or no? THE BRIEF: [brief]

**5. The Buyer (Voice of customer)**
> You are the Buyer on an idea council. Role-play the exact target customer described in the brief — or for non-commercial briefs, whoever has to live with the consequences. React as them, in first person. Would you actually pay for (or adopt) this? What's your real objection? What would make you choose a competitor or just do nothing instead? For commercial briefs: what price feels right, and what would make you say yes today? Be the honest, slightly skeptical customer, not a cheerleader. Use no web research — react from the brief and your own experience as this customer. THE BRIEF: [brief]

## Step 2.5 (optional): Anonymized peer review

Run this round when the user asked for it ("deep pressure-test", "with peer review", or a `--review` flag in the invocation) — or automatically when the **BUILD** spread is ≥ 5 (max − min), because a hard split is exactly when cross-review pays for itself. Compute the spread once, after all contract-valid responses are in — after any re-run required by the Rules, and over four scores if you proceeded with four. The auto-trigger is disabled in the sequential fallback (see Portability): there, announce the spread and offer the disclosed self-review instead. If the round auto-triggers, say so in one line. Otherwise skip straight to Step 3.

1. Collect the council responses. Strip explicit persona self-references (seat names, "as the Contrarian…", headers). Label them **Response A–E** in an order different from the convening order — e.g. sort by word count or by the first letter of the STANCE line — and note the shuffle *method* (e.g. "sorted by word count") before assigning letters, never the letter→persona mapping itself. The blind exists for the *reviewers*, not for you: the mapping must never appear in any reviewer prompt or in the transcript before Step 3; you, as Judge, hold it throughout.
2. Spawn **one reviewer agent per surviving seat in one parallel batch** — the same persona agents (by their registered names) if installed, otherwise your platform's general-purpose subagent. Each reviewer is one council persona reviewing the full anonymized set — including, unknowingly, their own response. If you proceeded with four seats under the Rules, the round runs over four responses (A–D) with four reviewers.

Reviewer prompt (one per persona):

> You are the [Persona] on an idea council, now reviewing the council's anonymized output on THE BRIEF: [brief]. Here are the five responses: [Response A] … [Response E]. Use no tools and no web — review what's in front of you, don't re-research. Skip your usual STANCE/POINTS/MUST-HEAR/DIVERGENCE/BUILD contract for this round. Judge each argument on its merits even if the writing style tells you who wrote it. Answer exactly three questions, referencing responses by letter, no hedging: 1) Which single response is strongest, and why? Pick one. 2) Which response has the biggest blind spot, and what is it? 3) What did ALL five miss that could change the verdict? Under 200 words.

3. De-anonymize when you rule: in Step 3, state the letter→persona mapping alongside the five reviews.

## Step 3: The Judge delivers the verdict

Once all five return, YOU act as the Judge. Extract the BUILD lines — the contract makes the row deterministic — then read every council member's findings, weigh them, and synthesize one decisive verdict. Do not just average the scores. Name the real tension between the personas and resolve it.

Read the BUILD row's *shape*, not its mean: five 7s = safe but probably dull; a wide spread like `3 · 9 · 6 · 4 · 8` = genuinely contested and worth a real decision. A non-"none" DIVERGENCE line ("sent to attack it, still strong") is high-value signal — weigh it above the number itself.

If the peer-review round ran, read the five reviews before ruling. Convergence is the signal: multiple reviewers independently naming the same strongest response or the same blind spot outranks the raw scores. Side with a lone dissenter when the reviews show the other four shared a blind spot. The answers to question 3 ("what ALL five missed") feed the verdict directly.

Fold in the **economics lens** yourself: rough pricing, realistic time-to-first-dollar, and whether the user can actually ship this fast given the edge they described. If the brief isn't commercial, **Money read** becomes **Cost read**: effort, opportunity cost, reversibility.

Anchor **Confidence** deterministically. Reviewers *converge* when at least three of them name the same strongest response; reviews *contradict* when no response is named strongest by more than one reviewer. High = spread ≤ 2 and (if the review ran) reviewers converge. Low = reviews contradict, or spread ≥ 5 with no review run. Spread ≥ 5 where the review ran and reviewers converge = medium — the review resolved the split. Medium otherwise. The disclosed self-review of the sequential fallback does not count as "the review ran" for this anchor or for the blind-spot line — treat its output as advisory.

Output the verdict in this exact shape:

```
## THE VERDICT: GO / RESHAPE / KILL
Confidence: [low / medium / high]

**The call in one line:** [the decision, plainly]

**Why:** [2-3 sentences resolving the council's tension]

**Biggest risk:** [the single thing most likely to kill it]
**Biggest upside:** [the strongest reason to do it]

**Blind spot the review caught:** [only when the peer-review round ran — requested
or auto-triggered — the thing no single persona saw until cross-review; omit this
line if the round didn't run]

**Money read:** [rough price, time-to-first-dollar, can they ship fast —
for non-commercial briefs retitle to Cost read: effort, opportunity cost, reversibility]

**The cheapest 48-hour test:** [the smallest, fastest thing they can do
to validate the riskiest assumption BEFORE building anything]

**If RESHAPE:** [the specific pivot that fixes the fatal flaw while keeping the upside]
```

Then list the five scores in one line:

```
BUILD — Contrarian X/10 · Expansionist X/10 · Logician X/10 · Researcher X/10 · Buyer X/10
```

If a seat was dropped under the Rules, render it as `—/10 (contract not met)` and compute the spread over the remaining scores.

## Step 3.5 (optional): Render the verdict as an HTML artifact

Run this when the user asks for a visual, shareable, or HTML verdict (or make it a
default output alongside the markdown). It turns the same verdict into a one-page
briefing that reads as a set with the storm-research report.

1. Read `assets/verdict-template.html` in this skill folder. Clone it; do not rebuild the CSS.
2. Fill every `{{TOKEN}}` from the verdict you just produced:
   - Put the verdict class on `.page` — `verdict-go` / `verdict-reshape` / `verdict-kill` —
     it tints the banner and the Call box.
   - Repeat the `.score-row` once per seat (highest BUILD first); set the fill class by band
     (1–3 `fill-red` · 4–5 `fill-amber` · 6–7 `fill-green` · 8–10 `fill-blue`) and
     `width` = score×10%. A dropped seat reads `—/10`.
   - Repeat the `.seat` card once per persona: role label, one-line stance, 3–5 points,
     must-hear, divergence, and the BUILD chip.
   - Keep §04b "Blind spot the review caught" ONLY if the peer-review round ran; delete it otherwise.
   - Keep §08 "The Reshape" ONLY when the verdict is RESHAPE; delete it for GO / KILL.
     Retitle §06 "Money read" → "Cost read" for non-commercial briefs.
   - Set every `{{DATE}}` from the system clock, never from memory.
3. Save it per the verdict-saving rule in **Rules** (the same canonical Pressure-test result basename resolved from [`solution-structure`](../solution-structure/SKILL.md#non-template-documentation-artifacts), uncommitted unless asked; if files can't be written, output the full HTML inline).

## Step 4: The re-test (RESHAPE only)

If the user accepts the RESHAPE, don't reconvene the full council. Re-run only the personas whose objections drove the pivot — usually two — against the reshaped brief. Then re-issue the **complete** verdict block from the Step 3 template: replace the re-run seats' BUILD scores, carry the others forward marked "(carried)" in the score row, recompute the spread and Confidence over the mixed row, and add one line naming which seats were re-tested and why. If the verdict was saved to a file, append the new verdict under a `## Re-test [date]` heading — never overwrite the original. A full re-test is warranted only if the pivot changed who it's for or how it makes money.

## Rules

- Every persona stays in character for STANCE, POINTS, and MUST-HEAR. None of them hedges or softens — the value is in the friction. DIVERGENCE and BUILD are the *only* places they drop the mandate and give their honest call.
- A response that breaks the contract (including a non-integer BUILD) gets one re-run with "follow the output contract exactly." Still broken → proceed with four, disclose it in the verdict, render the seat as `—/10 (contract not met)` in the score row, and never invent the missing score.
- The Judge must make an actual call. "It depends" is not a verdict. Pick GO, RESHAPE, or KILL and own it.
- The cheapest 48-hour test is the most important output. It's how the user finds out if they're right without building the whole thing.
- Keep the final verdict skimmable. The council does the depth; the Judge does the decision.
- The peer-review round is opt-in (or auto on a BUILD spread ≥ 5 — never auto in the sequential fallback). It roughly doubles the run — 5 council + 5 reviewers + Judge — so don't spend it on throwaway ideas.
- Anonymization during review is mandatory, but know its limit: it mainly prevents deference, not identification — the Buyer and Researcher self-identify by style even with names stripped, so reviewers are told to score the argument anyway.
- Researcher figures without a URL are **discarded from the verdict rationale** — they must not appear in the Judge's reasoning. Sole exception: the disclosed no-web blind mode (see Portability), where every figure is UNVERIFIED and may inform the verdict but never decide it.
- If the user says "save the verdict", resolve the complete directory and timestamped basename from the Pressure-test result row in [`solution-structure`](../solution-structure/SKILL.md#non-template-documentation-artifacts), using the system clock rather than memory. Use its `.md` form for the full archive (brief + all five raw responses + reviews). When the user wants a visual, shareable, or HTML verdict, build the one-page artifact per Step 3.5 and use the same basename with `.html`, additionally or instead as requested. Outside a repository governed by that structure, use the same filename form in the current working directory. Leave outputs uncommitted unless the user asks. If the platform cannot write files, output the full markdown or HTML in the reply for the user to save.
- After editing this skill or the council personas, re-run the three fixture briefs in `references/calibration-briefs.md` on every platform you use it on. They assert mechanics, not verdicts — a run fails if a hard mechanical check fails.
