---
name: platform-review
description: Review and synthesize the current state across all platforms into a coherent status picture. Use when the user says "status update", "where are we", "platform review", "what's happening", "state of things", "progress report", or "what's in flight".
---

# Platform Review

Synthesize the current state across all platforms — what's shipped, what's in flight, what's blocked, what's drifting from the plan.

## Process

### Step 1: Gather Data

Read from all sources in parallel where possible:

**Jira** — Query active epics and in-progress stories:
```bash
# Active epics across all projects
curl -s -H "Authorization: Bearer $JIRA_API_TOKEN" \
  "https://jira.jetdevs.com/rest/api/2/search?jql=issuetype=Epic+AND+status+not+in+(Done,Closed)+ORDER+BY+project,priority"

# In-progress stories
curl -s -H "Authorization: Bearer $JIRA_API_TOKEN" \
  "https://jira.jetdevs.com/rest/api/2/search?jql=status='In+Progress'+ORDER+BY+project,priority"
```

**Git** — Recent activity across repos:
```bash
cd /Volumes/HD/code/monorepo/cadra-web && git log --oneline -10 --since="2 weeks ago"
cd /Volumes/HD/code/monorepo/cadra-api && git log --oneline -10 --since="2 weeks ago"
cd /Volumes/HD/code/monorepo/yobo-merchant && git log --oneline -10 --since="2 weeks ago"
# ... repeat for each active repo
```

**`_context/` docs** — Check for recent implementation progress:
```bash
find /Volumes/HD/code/monorepo/_context -name "implementation.md" -newer /Volumes/HD/code/monorepo/_context -maxdepth 4
```

**Slack** — Search for recent blockers, decisions, and concerns using Slack MCP tools.

**Notion** — Check existing roadmap pages for planned vs actual.

### Step 2: Synthesize Per Platform

For each platform, summarize:

```markdown
### [Platform Name]
**Phase:** [Building / Stabilizing / Growing / Maintaining]
**Recent Activity:** [1-2 sentences on what's been happening]
**Active Initiatives:**
- [Initiative] — [status: on track / at risk / blocked / completed]
**Blockers:** [Any blockers or risks]
**Drift from Plan:** [Anything that's diverged from the roadmap]
```

### Step 3: Cross-Platform Analysis

After reviewing each platform individually:
- **Dependencies at risk** — Is platform A waiting on platform B?
- **Resource conflicts** — Is the same person/agent split across too many things?
- **Emerging patterns** — Same issue appearing in multiple places?
- **Opportunities** — Work completed in one platform that could benefit another?

### Step 4: Update CTO State

Update `~/Main/spaces/JetDevs/CTO State.md` in Obsidian with:
- Refreshed platform status sections
- Updated active initiatives table
- New risks or blockers discovered
- Key decisions made since last update

### Step 5: Deliver Summary

Provide the founder with a concise summary:
1. **Headlines** — 2-3 most important things to know
2. **Per-platform status** — one paragraph each
3. **Risks and blockers** — what needs attention
4. **Recommendations** — what to do about the issues found

Write to Obsidian as `~/Main/spaces/JetDevs/reviews/YYYY-MM-DD Platform Review.md`.

If requested, also push to Notion as a shared status page.

## Critical Rules

- **Data first, opinions second** — base status on commits, tickets, and conversations, not assumptions
- **Flag drift early** — if something is off-plan, say so clearly with evidence
- **Don't sugarcoat** — the founder needs reality, not optimism
- **Compare to plan** — "we shipped X" means nothing without "and we planned Y"
- **Quantify when possible** — "3 of 7 epics complete" beats "making progress"
