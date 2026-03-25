---
name: strategic-planning
description: Build technology roadmaps, prioritize initiatives, and plan quarters aligned to business goals. Use when the user says "plan the quarter", "roadmap", "prioritize", "what should we focus on", "resource allocation", "initiative planning", or "strategic plan".
---

# Strategic Planning

Build prioritized roadmaps and initiative plans that connect business goals to technology execution across all platforms.

## Process

### Step 1: Load Current State

1. Read `CTO State.md` from Obsidian for business goals and current initiatives
2. Query Jira for active epics across all projects
3. Check Notion for existing roadmaps or plans
4. Read recent Slack signals (if `gather-intelligence` has been run recently)

### Step 2: Understand the Planning Horizon

Clarify with the founder:
- **Time horizon** — quarter, half-year, year?
- **Constraints** — budget, team capacity, external deadlines?
- **Must-haves** — any non-negotiable commitments?
- **Strategic themes** — growth, stability, new market, technical foundation?

### Step 3: Generate Initiative Candidates

For each platform, identify:
- **Unfinished work** — epics in progress, blocked items
- **New opportunities** — features that serve business goals
- **Technical debt** — risks that compound if ignored
- **Dependencies** — cross-platform work that unblocks multiple things

### Step 4: Prioritize

Use this framework for each initiative:

| Factor | Weight | Questions |
|--------|--------|-----------|
| Business impact | High | Revenue? Growth? Retention? Competitive advantage? |
| Complexity | Medium | How many platforms touched? How many dependencies? How clear is the architecture? |
| Dependencies | Medium | Does this unblock other work? Is it blocked by something? |
| Technical debt | Medium | Does this reduce or add debt? What's the compounding risk? |
| Customer impact | Medium | Does this solve a real customer problem? |
| Strategic fit | High | Does this align with where we want to be in 12 months? |

**Note on effort:** Do NOT use traditional effort estimates (story points, man-weeks). With AI agents, execution is fast — the constraints are architectural clarity and dependency sequencing, not labor. Estimate wall-clock time (hours/days), not human effort.

Produce a prioritized list with tiers:
- **P0 — Must do**: Critical for business goals, blocks other work, or high-risk if deferred
- **P1 — Should do**: Strong business case, good ROI, but not blocking
- **P2 — Could do**: Nice to have, low urgency, do if capacity allows
- **Defer**: Good idea, wrong time

### Step 5: Sequence and Assign

For each P0/P1 initiative:
- Define dependencies and sequencing
- Estimate wall-clock time (hours/days with AI agents, not traditional man-weeks)
- Identify which platform(s) and which agents/engineers own execution
- Flag risks and mitigation strategies

### Step 6: Deliver the Roadmap

Write outputs to the appropriate tools:

**Obsidian** — Update `CTO State.md` with new planning context. Create a planning note at `~/Main/spaces/JetDevs/YYYY-QN Roadmap.md` with the full analysis.

**Notion** — Create or update the roadmap page with:
- Initiative table (name, priority, platform, owner, target date, status)
- Dependencies diagram (mermaid)
- Strategic themes and how initiatives map to them

**Jira** — Create epics for P0/P1 initiatives that don't already exist. Use project key matching the platform (CAD for cadra, YOBO for yobo, etc.).

## Critical Rules

- **Never plan in isolation** — every initiative must connect to a business goal
- **Always consider opportunity cost** — doing X means NOT doing Y
- **Be honest about capacity** — overcommitting destroys credibility and morale
- **Account for AI agents** — they multiply capacity but need setup and oversight
- **Include buffer** — plan for 70-80% capacity, not 100%
- **Revisit quarterly** — plans drift, so planning is continuous
