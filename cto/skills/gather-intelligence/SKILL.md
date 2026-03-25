---
name: gather-intelligence
description: Ingest signals from Slack, Jira, Notion, and git to extract decisions, concerns, blockers, and opportunities. Use when the user says "what's happening in Slack", "catch me up", "what did I miss", "gather signals", "intelligence report", "scan channels", or "what's the team talking about".
---

# Gather Intelligence

Read from Slack channels, Jira activity, Notion updates, and git history to extract signals that matter to the CTO. This is the "listening" skill — it feeds the CTO's mental model.

## Process

### Step 1: Determine Scope

Clarify with the founder:
- **Time range** — last day? last week? since a specific date?
- **Focus area** — all platforms, or a specific one?
- **Signal type** — everything, or just blockers/decisions/risks?

### Step 2: Scan Slack

Use Slack MCP tools to search channels for:

**Decisions made:**
- Search for messages containing "decided", "going with", "let's do", "agreed", "approved"
- Look in engineering and product channels

**Blockers and concerns:**
- Search for "blocked", "stuck", "can't", "waiting on", "help", "issue", "problem"
- Look in engineering, support, and incident channels

**Opportunities and ideas:**
- Search for "idea", "what if", "could we", "proposal", "opportunity"
- Look in product, strategy, and general channels

**Customer signals:**
- Search for "customer", "feedback", "requested", "complaint", "churned"
- Look in sales, support, and customer-facing channels

### Step 3: Scan Jira

Query for recent activity:
```bash
# Recently updated issues (last 7 days)
curl -s -H "Authorization: Bearer $JIRA_API_TOKEN" \
  "https://jira.jetdevs.com/rest/api/2/search?jql=updated>='-7d'+ORDER+BY+updated+DESC&maxResults=50"

# Recently created issues
curl -s -H "Authorization: Bearer $JIRA_API_TOKEN" \
  "https://jira.jetdevs.com/rest/api/2/search?jql=created>='-7d'+ORDER+BY+created+DESC&maxResults=30"

# Blocked issues
curl -s -H "Authorization: Bearer $JIRA_API_TOKEN" \
  "https://jira.jetdevs.com/rest/api/2/search?jql=status='Blocked'+OR+labels='blocked'+ORDER+BY+priority"
```

### Step 4: Scan Git

Check recent commits across repos for patterns:
```bash
# Recent activity per repo
for repo in cadra-web cadra-api yobo-merchant crm slides core-sdk/core; do
  echo "=== $repo ==="
  cd /Volumes/HD/code/monorepo/$repo && git log --oneline -10 --since="1 week ago" 2>/dev/null
done
```

Look for:
- Repos with no recent activity (stalled?)
- Repos with unusual burst of activity (fire drill?)
- Large commits or merge patterns

### Step 5: Scan Notion

Use Notion MCP tools to check:
- Recently updated pages in project spaces
- Comments or discussions on roadmap pages
- New pages created (new initiatives?)

### Step 6: Synthesize Signals

Categorize everything found into:

| Category | Signal | Source | Urgency | Action Needed? |
|----------|--------|--------|---------|---------------|
| Decision | [what was decided] | Slack #channel | — | Update CTO State |
| Blocker | [what's blocked] | Jira/Slack | High | Investigate/unblock |
| Risk | [emerging risk] | Git/Slack | Medium | Monitor/mitigate |
| Opportunity | [new opportunity] | Slack/Notion | Low | Evaluate later |
| Customer | [customer signal] | Slack/Support | Varies | Assess impact |

### Step 7: Update CTO State

Update `~/Main/spaces/JetDevs/CTO State.md` with:
- New decisions captured
- New risks or blockers added
- Updated initiative status based on signals
- Customer intelligence that affects strategy

### Step 8: Report

Present a concise intelligence briefing:
1. **Top signals** — 3-5 most important things discovered
2. **Decisions captured** — decisions made that affect strategy
3. **Blockers found** — issues that need CTO attention
4. **Risks emerging** — patterns or signals that suggest future problems
5. **Opportunities spotted** — ideas or signals worth exploring

Write to Obsidian as `~/Main/spaces/JetDevs/intelligence/YYYY-MM-DD Intelligence Report.md`.

## Critical Rules

- **Signal, not noise** — filter aggressively. The CTO doesn't need every message, just the ones that matter
- **Attribute sources** — always say where a signal came from (which channel, which ticket, which commit)
- **Don't interpret too much** — present what was said/done, then offer interpretation separately
- **Flag contradictions** — if Slack says one thing and Jira says another, highlight the discrepancy
- **Respect context** — some Slack messages are casual venting, not strategic signals. Use judgment
