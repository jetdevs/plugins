---
name: jira-expert
description: Create and manage Jira issues via REST API on self-hosted Jira Data Center. Use when the user asks to create epics, stories, tasks, sub-tasks, search Jira, run JQL queries, list issues, link issues, or any Jira operations. Also use when user says "create tickets", "add to Jira", "search Jira", "find issues", or mentions Jira project keys like SAAS, YOBO, YMS.
---

# Jira Expert

Manages issues on self-hosted Jira Data Center via REST API v2 using curl with bearer token auth.

## Authentication

All requests use the `JIRA_API_TOKEN` env var. Every curl command must include:
```
-H "Authorization: Bearer $JIRA_API_TOKEN" -H "Content-Type: application/json"
```

Base URL: `https://jira.jetdevs.com`
API prefix: `/rest/api/2`

## Projects

| Key  | Name                | Lead        |
|------|---------------------|-------------|
| CAD  | Cadra               | Sean Liao   |
| SAAS | AI SaaS             | Sean Liao   |
| YOBO | Yobo                | Stanley Ma  |
| YMS  | Yobo Merchant SaaS  | Sean Liao   |

New projects may be added — use the list projects endpoint if unsure: `GET /rest/api/2/project`

## Issue Types

| Name     | ID    | Subtask |
|----------|-------|---------|
| Epic     | 10000 | No      |
| Story    | 10001 | No      |
| Task     | 10002 | No      |
| Sub-task | 10003 | Yes     |
| Bug      | 10004 | No      |

## Custom Fields

| Field ID          | Name       | Usage                                    |
|-------------------|------------|------------------------------------------|
| customfield_10103 | Epic Name  | Required when creating Epics             |
| customfield_10101 | Epic Link  | Set on Stories/Tasks to link them to Epic |

## Creating Issues

### Create Epic
```bash
curl -s -X POST -H "Authorization: Bearer $JIRA_API_TOKEN" -H "Content-Type: application/json" \
  "https://jira.jetdevs.com/rest/api/2/issue" \
  -d '{
    "fields": {
      "project": {"key": "PROJECT_KEY"},
      "summary": "Epic title",
      "issuetype": {"name": "Epic"},
      "customfield_10103": "Epic title",
      "description": "Epic description"
    }
  }'
```
Response: `{"id":"...","key":"PROJECT-123","self":"..."}`

### Create Story (linked to Epic)
```bash
curl -s -X POST -H "Authorization: Bearer $JIRA_API_TOKEN" -H "Content-Type: application/json" \
  "https://jira.jetdevs.com/rest/api/2/issue" \
  -d '{
    "fields": {
      "project": {"key": "PROJECT_KEY"},
      "summary": "Story title",
      "issuetype": {"name": "Story"},
      "customfield_10101": "PROJECT-123",
      "description": "Story description"
    }
  }'
```

### Create Sub-task (under a Story/Task)
```bash
curl -s -X POST -H "Authorization: Bearer $JIRA_API_TOKEN" -H "Content-Type: application/json" \
  "https://jira.jetdevs.com/rest/api/2/issue" \
  -d '{
    "fields": {
      "project": {"key": "PROJECT_KEY"},
      "summary": "Sub-task title",
      "issuetype": {"name": "Sub-task"},
      "parent": {"key": "PROJECT-456"},
      "description": "Sub-task description"
    }
  }'
```

### Batch Create (multiple issues)
Create issues one at a time via individual POST requests. There is no bulk create endpoint on this server. When creating multiple stories for an epic, create the epic first to get its key, then create stories with `customfield_10101` set to that key.

## Searching Issues (JQL)

```bash
curl -s -H "Authorization: Bearer $JIRA_API_TOKEN" \
  "https://jira.jetdevs.com/rest/api/2/search?jql=URL_ENCODED_JQL&fields=key,summary,status,issuetype,assignee&maxResults=50"
```

URL-encode the JQL string. Use `--data-urlencode` for complex queries:
```bash
curl -s -G -H "Authorization: Bearer $JIRA_API_TOKEN" \
  "https://jira.jetdevs.com/rest/api/2/search" \
  --data-urlencode "jql=project = SAAS AND type = Story AND status != Done" \
  --data-urlencode "fields=key,summary,status,assignee" \
  --data-urlencode "maxResults=50"
```

### Common JQL Patterns
- Epics in project: `project = SAAS AND type = Epic`
- Stories in epic: `"Epic Link" = SAAS-123`
- Open issues: `project = SAAS AND status != Done ORDER BY priority DESC`
- Assigned to user: `project = SAAS AND assignee = "username"`
- Recent issues: `project = SAAS AND created >= -7d`
- Overdue: `project = SAAS AND dueDate < now() AND status != Done`
- Sprint issues: `project = SAAS AND sprint in openSprints()`

## Linking Issues

```bash
curl -s -X POST -H "Authorization: Bearer $JIRA_API_TOKEN" -H "Content-Type: application/json" \
  "https://jira.jetdevs.com/rest/api/2/issueLink" \
  -d '{
    "type": {"name": "Blocks"},
    "inwardIssue": {"key": "PROJECT-456"},
    "outwardIssue": {"key": "PROJECT-123"}
  }'
```

Link types: Blocks, Cloners, Duplicate, Parent, Relates

## Viewing an Issue

```bash
curl -s -H "Authorization: Bearer $JIRA_API_TOKEN" \
  "https://jira.jetdevs.com/rest/api/2/issue/PROJECT-123?fields=key,summary,status,issuetype,assignee,description,customfield_10101,customfield_10103"
```

## Updating an Issue

```bash
curl -s -X PUT -H "Authorization: Bearer $JIRA_API_TOKEN" -H "Content-Type: application/json" \
  "https://jira.jetdevs.com/rest/api/2/issue/PROJECT-123" \
  -d '{
    "fields": {
      "summary": "Updated title",
      "description": "Updated description"
    }
  }'
```

## User Story Description Format

When creating stories, use this Jira wiki markup format for descriptions:

```
*As a* [user type], *I want* [goal], *so that* [benefit].

*Task #1: [Task Title]*
+Description:+
[Brief description]

+Tasks:+
 - [ ] Subtask 1
 - [ ] Subtask 2

+Definition of Done:+
- Criterion 1
- Criterion 2

+Acceptance Criteria:+
[What success looks like]
```

Notes on Jira markup:
- `*text*` = bold (single asterisks, not double)
- `+text+` = underline (used for section headers)
- ` - [ ] item` = checkbox (single space indent)
- Regular dashes for Definition of Done items (no checkboxes)

## Workflow

When asked to create an epic with stories:
1. Create the Epic first, capture its key from the response
2. Create each Story with `customfield_10101` set to the Epic key
3. If stories have sub-tasks, create Sub-tasks with `parent` set to the Story key
4. Verify by searching: `"Epic Link" = EPIC-KEY`

Always confirm the project key with the user if ambiguous.
