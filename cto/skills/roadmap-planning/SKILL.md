---
name: roadmap-planning
description: Manage the Product Roadmap 2026 in Notion — create epics, break down stories, link relations, update statuses, and query views. Use when the user says "roadmap", "create epic", "add story", "break down epic", "roadmap status", "update roadmap", "link stories", "roadmap planning", or mentions the Product Roadmap 2026 Notion database.
---

# Product Roadmap Planning (Notion)

Manage the Product Roadmap 2026 Notion database — create EPICs, break them into stories, link relations, and track progress.

## Notion Database Reference

### Database Identity
- **Database ID**: `33359c0c-5507-80a1-8c43-f18a4dbd326b`
- **Data Source ID**: `33359c0c-5507-8124-9f5a-000b248798e0` (use this for creating pages)
- **Location**: Tech & Product > Product Mgmt > Product Roadmap 2026
- **Workspace**: Yobo (sean@yobo.id)

### Properties Schema

| Property | Type | Values |
|----------|------|--------|
| **Name** | title | Free text |
| **Type** | select | `EPIC`, `App`, `Module`, `Feature`, `API`, `Model`, `Knowledge Base`, `Tool`, `Improvement`, `Integration`, `Migration` |
| **Category** | select | `AI & Automation`, `Operations`, `Merchant`, `Core` |
| **Status** | status | `New`, `Not started`, `Hold`, `Need to start`, `In progress`, `Ready`, `Done` |
| **Priority** | select | `1-Very High`, `2-High`, `3-Medium`, `4-Low`, `TBD` |
| **Complexity** | select | `Very High`, `High`, `Medium`, `Low`, `TBD` |
| **Quarter** | select | `Current`, `Q3 2025`, `Q4 2025`, `Q1 2026`, `Q2 2026`, `Q3 2026`, `Future`, `To Be Scheduled` |
| **Milestone** | select | `Sprint 0-8`, `Checkpoint 1-2`, `Soft Launch: Sep 19`, `Go Live: Oct 10`, `Demo Day: Oct 15`, `Future`, `Merchant Portal`, `AI SaaS (Big Bro)` |
| **Owner** | person | User IDs |
| **Stakeholders** | select | `TBD`, `Account Managers`, `Legal`, `Merchants`, `Onboarding Specialists`, `Designers`, `Stakeholders`, `Finance Team`, `Sales Team`, `Area Supervisors`, `Ops Team`, `Data Team`, `Ops Management` |
| **Epic** | relation | Self-relation — links stories TO their parent epic |
| **Dependency** | relation | Self-relation — links epics TO their child stories |
| **Metric Impact** | relation | Links to external metrics data source |
| **Impacted Metrics** | multi_select | `Send WA`, `B2B Lead Gen`, `B2B CR %`, `B2B Go Live`, `B2C Signup`, `B2C CR %` |
| **POC Live Date** | date | Use expanded: `date:POC Live Date:start`, `date:POC Live Date:end`, `date:POC Live Date:is_datetime` |
| **Prod Live Date** | date | Use expanded: `date:Prod Live Date:start`, `date:Prod Live Date:end`, `date:Prod Live Date:is_datetime` |

### Database Views

| View | Type | Purpose |
|------|------|---------|
| **Table** | table | All items, all properties visible |
| **Manage** | table | Grouped by Epic — best for seeing epic/story hierarchy |
| **2026 Q2** | table | Grouped by Priority, filtered to Q2 |
| **Launch Critical** | table | Filtered to Priority: 1-Very High, grouped by Epic |
| **By Category** | board | Kanban by Category |
| **Status Tracker** | board | Kanban by Status |
| **Milestones** | board | Kanban by Milestone |
| **Milestones Tracking** | board | Kanban by Status, filtered to EPICs |
| **Goals** | board | Kanban by Impacted Metrics |
| **Timeline** | timeline | Gantt chart by POC Live Date |
| **(unnamed)** | board | Kanban by Quarter |

## How to Create an EPIC with Stories

### Step 1: Create the EPIC

```
Tool: mcp__claude_ai_Notion__notion-create-pages
Parent: { "type": "data_source_id", "data_source_id": "33359c0c-5507-8124-9f5a-000b248798e0" }

Properties:
  Name: "Epic Title"
  Type: "EPIC"
  Category: "Core" | "AI & Automation" | "Operations" | "Merchant"
  Priority: "1-Very High" | "2-High" | "3-Medium" | "4-Low"
  Status: "Not started"
  Quarter: "Q2 2026"
  Complexity: "Very High" | "High" | "Medium" | "Low"

Content: Epic-level description with:
  ## User Story
  ## Context
  ## Requirements (high-level, summarizing all stories)
  ## Acceptance Criteria (epic-level milestones)
  ## Dependencies (other epics or external)
```

Save the returned page URL — you need it to link stories.

### Step 2: Create Stories Linked to the EPIC

```
Tool: mcp__claude_ai_Notion__notion-create-pages
Parent: { "type": "data_source_id", "data_source_id": "33359c0c-5507-8124-9f5a-000b248798e0" }

Properties:
  Name: "Story Title"
  Type: "Feature" | "Module" | "API" | "Integration" | "Migration" | "Improvement" | etc.
  Category: same as epic or appropriate
  Priority: typically same or one level below epic
  Status: "Not started"
  Epic: "[\"https://www.notion.so/{epic-page-id-no-dashes}\"]"   # <-- CRITICAL: links story to epic

Content: Story-level description with:
  ## User Story
  ## Context (optional, if not obvious from epic)
  ## Requirements (specific to this story)
  ## Acceptance Criteria (checkboxes)
```

**CRITICAL**: The `Epic` property value must be a JSON array string containing the epic's Notion URL:
```
"Epic": "[\"https://www.notion.so/EPIC_PAGE_ID_NO_DASHES\"]"
```

### Step 3: Link Stories Back on the EPIC (Dependency field)

After creating all stories, update the epic's `Dependency` field with all story URLs:

```
Tool: mcp__claude_ai_Notion__notion-update-page
page_id: {epic-page-id}
command: "update_properties"
properties:
  Dependency: "[\"https://www.notion.so/STORY1_ID\",\"https://www.notion.so/STORY2_ID\",...]"
```

This creates the bidirectional link:
- Stories → Epic (via `Epic` relation)
- Epic → Stories (via `Dependency` relation)

### Step 4: Verify

Fetch the epic to confirm both `Epic` (on stories) and `Dependency` (on epic) are populated. Check the **Manage** view (grouped by Epic) to see the hierarchy.

## Story Content Template

Each story page should follow this structure:

```markdown
## User Story
As a **{persona}**, I want {capability} so that {benefit}.

## Context
{Why this matters, what prompted it, link to meeting notes or decisions}

## Requirements
### Functional Requirements
- {Specific requirement 1}
- {Specific requirement 2}

### Non-Functional Requirements
- {Performance, security, compatibility requirements}

## Acceptance Criteria
- [ ] {Testable criterion 1}
- [ ] {Testable criterion 2}

## Dependencies
- {Other stories or epics this depends on}
```

## Common Operations

### Query the roadmap
```
Tool: mcp__claude_ai_Notion__notion-query-database-view
view_url: "https://www.notion.so/33359c0c550780a18c43f18a4dbd326b?v={VIEW_ID}"
```

Key view IDs:
- **Manage** (by Epic): `v=33359c0c-5507-81c4-b948-000ceeb9f620`
- **Status Tracker**: `v=33559c0c-5507-81f5-b729-000cad28550e`
- **Launch Critical**: `v=33559c0c-5507-8174-be2b-000c9543f0e6`
- **2026 Q2**: `v=33359c0c-5507-815b-af6e-000cfa4691d0`

### Update a roadmap item
```
Tool: mcp__claude_ai_Notion__notion-update-page
page_id: {page-id}
command: "update_properties"
properties: { "Status": "In progress", "Priority": "1-Very High" }
```

### Search for roadmap items
```
Tool: mcp__claude_ai_Notion__notion-search
query: "search terms"
query_type: "internal"
```

### Fetch a specific item
```
Tool: mcp__claude_ai_Notion__notion-fetch
id: {page-id-or-url}
```

## Existing EPICs (as of April 2026)

| EPIC | Category | Priority |
|------|----------|----------|
| Onboarding Redesign | Merchant | 1-Very High |
| Instagram DM Automation | Core | 1-Very High |
| US Market Launch — Shopify Integration | Core | 1-Very High |
| 0-Purchase Acquisition Engine | Operations | 1-Very High |
| Ad Studio — Campaign Integration + Collaborative Creative Suite | Core | 1-Very High |
| Campaign Canvas / Workspace | Core | 2-High |
| Agent System | AI & Automation | 2-High |
| Content & Intelligence Layer | AI & Automation | 2-High |
| Offers Engine | Core | 2-High |
| Credit & Monetization System | Core | 2-High |
| Indonesia Agency Model | Operations | 3-Medium |
| Offline/POS Integration — Square | Core | 4-Low |

## Relation Field Format

Relations in the Notion API use JSON array strings of page URLs:

```
# Single relation
"Epic": "[\"https://www.notion.so/PAGE_ID_NO_DASHES\"]"

# Multiple relations
"Dependency": "[\"https://www.notion.so/ID1\",\"https://www.notion.so/ID2\"]"
```

The page ID in the URL must have **no dashes**. Example:
- Page ID: `33559c0c-5507-8134-a1f4-e5df1803809f`
- URL format: `https://www.notion.so/33559c0c55078134a1f4e5df1803809f`

## Priority Guidelines

| Priority | When to use |
|----------|------------|
| 1-Very High | Launch-critical, blocks revenue, blocks other epics |
| 2-High | Important for next quarter, significant user impact |
| 3-Medium | Nice to have this quarter, improves experience |
| 4-Low | Future consideration, low urgency |

## Checklist: Breaking Down an Epic

1. [ ] Epic created with Type: EPIC
2. [ ] Epic has clear User Story and high-level Requirements
3. [ ] Stories created with appropriate Types (Feature, Module, API, Integration, Migration, etc.)
4. [ ] Each story has `Epic` relation pointing to parent epic
5. [ ] Epic has `Dependency` relation listing all child stories
6. [ ] Stories have individual Acceptance Criteria (checkboxes)
7. [ ] Priorities set on all stories (typically same or one below epic)
8. [ ] Category set correctly on all items
9. [ ] Verify in **Manage** view — stories appear grouped under their epic
