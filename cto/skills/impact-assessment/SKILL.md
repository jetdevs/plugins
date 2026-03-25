---
name: impact-assessment
description: Evaluate the cross-platform impact of a proposed project, feature, or architectural decision. Use when the user says "what's the impact", "should we do this", "evaluate this", "trade-offs", "risk assessment", "is this worth it", "what happens if", or "assess this decision".
---

# Impact Assessment

Evaluate a proposed change, project, or decision across all platforms. Produce a thorough analysis covering technical impact, business value, risks, dependencies, and recommendation.

## Process

### Step 1: Understand the Proposal

Clarify exactly what's being proposed:
- What is the change/project/decision?
- What problem does it solve?
- Who requested it (customer, internal, market pressure)?
- What's the urgency?

### Step 2: Map the Blast Radius

For each platform, determine:

| Platform | Directly affected? | Indirectly affected? | How? |
|----------|-------------------|---------------------|------|
| cadra-web | | | |
| cadra-api | | | |
| yobo-merchant | | | |
| crm | | | |
| slides | | | |
| core-sdk | | | |
| message-api | | | |

Investigate by reading:
- Platform `_context/` architecture docs
- Relevant source code (schema, API contracts, shared modules)
- SDK dependencies that create coupling

### Step 3: Analyze Trade-offs

For each dimension, assess both "do it" and "don't do it":

**If we do this:**
- What does it enable? (new capabilities, unblocked work, customer value)
- What does it cost? (effort, complexity, technical debt, opportunity cost)
- What does it risk? (failure modes, timeline risk, quality risk)
- What does it constrain? (future flexibility, other work paused)

**If we don't do this:**
- What do we lose? (customer, market position, efficiency)
- What do we gain? (focus on other priorities, reduced risk)
- What happens if we defer 3 months? 6 months? Is this time-sensitive?

### Step 4: Dependencies and Sequencing

- What must exist before this can start?
- What does this unblock once complete?
- Can this be done incrementally or is it all-or-nothing?
- Are there parallel workstreams or is it serial?

### Step 5: Complexity & Timeline

| Component | Complexity | Wall-Clock Time | Blockers |
|-----------|-----------|----------------|----------|
| Platform A changes | | | |
| Platform B changes | | | |
| SDK/shared changes | | | |
| Testing/QA | | | |
| Migration/rollout | | | |
| **Total** | | | |

**Do NOT use traditional effort estimates.** With AI agents, the constraint is architectural clarity and dependency sequencing, not labor. Estimate in wall-clock hours/days. Flag complexity as low/medium/high based on number of platforms touched, dependency chains, and architectural ambiguity — not lines of code.

### Step 6: Recommendation

Provide a clear recommendation:
- **Do it now** — high value, manageable effort, good timing
- **Do it later** — good idea, wrong time or blocked by dependencies
- **Do it differently** — the goal is right but the approach needs rethinking
- **Don't do it** — low value, high cost, or misaligned with strategy

Include conditions: "Do this IF we also do X" or "Do this AFTER Y is complete."

### Step 7: Deliver

**Obsidian** — Write the analysis to `~/Main/spaces/JetDevs/assessments/YYYY-MM-DD Assessment Title.md` with wikilinks to related notes.

**Notion** — If this will become a shared decision record, create a page in the relevant project space.

Update `CTO State.md` if the assessment changes active initiatives or risks.

## Critical Rules

- **Never assess in a vacuum** — always consider what else the team could be doing instead
- **Be specific about risks** — "this is risky" is useless; "if the migration fails mid-way, we'll have split state across two systems for ~2 weeks" is useful
- **Challenge the premise** — sometimes the right answer is "we're solving the wrong problem"
- **Consider reversibility** — prefer reversible decisions over irreversible ones
- **Name the unknowns** — what can't you assess without more investigation? Flag it explicitly
