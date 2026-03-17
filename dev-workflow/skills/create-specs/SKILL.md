---
name: create-specs
description: Creates and consolidates feature specification documentation in the .context/ directory. Use when creating new feature specs, consolidating planning artifacts (approach.md, architecture.md, mermaid.md) into specs.md, combining PRD and journey docs into prd.md, setting up implementation tracking, or creating story_list.json for the Agent Harness Protocol.
---

# Create Feature Specs

Create comprehensive feature specification documentation by consolidating multiple planning artifacts into well-organized, AI-optimized documentation in `_context/{project}/{feature-name}/`.

## Execution

**MANDATORY**: Spawn a dedicated agent (subagent) to execute this skill. Do NOT run inline in the main conversation — use the Agent tool with a complete prompt including these instructions and the user's request.

## Instructions

### Step 1: Determine Feature Location

Ask or determine:
1. **Project name**: Which project/repo does this feature belong to?
2. **Feature name**: Simple, descriptive name (e.g., "agents", "providers", "organizations")

Create the folder structure:
```bash
mkdir -p .context/{project}/{feature-name}/
```

### Step 2: Identify Source Documents

Look for existing planning documents that need consolidation:

| Source Document | Consolidate Into |
|-----------------|------------------|
| `approach.md` | `specs.md` |
| `architecture.md` | `specs.md` |
| `mermaid.md` | `specs.md` |
| `prd.md` (source) | `prd.md` (consolidated) |
| `journey.md` | `prd.md` |

### Step 3: Create specs.md (Technical Specifications)

Consolidate technical documents into a single `specs.md`:

```markdown
---
type: specs
feature: {Feature Name}
version: "1.0"
status: Draft
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
tags:
  - {tag1}
  - {tag2}
---

# {Feature Name} - Technical Specifications

## Table of Contents

- [Part 1: Epics & User Stories](#part-1-epics--user-stories)
- [Part 2: Technical Requirements](#part-2-technical-requirements)
- [Part 3: Architecture & Approach](#part-3-architecture--approach)
- [Part 4: System Diagrams](#part-4-system-diagrams)
- [Part 5: API Design](#part-5-api-design)
- [Part 6: Non-Functional Requirements](#part-6-non-functional-requirements)

---

## Part 1: Epics & User Stories
<!-- Technical user stories from implementation perspective -->

## Part 2: Technical Requirements
<!-- System architecture, data models, schemas -->

## Part 3: Architecture & Approach
<!-- Consolidated from architecture.md and approach.md -->

## Part 4: System Diagrams
<!-- All mermaid diagrams with context -->

## Part 5: API Design
<!-- Endpoints, contracts, schemas -->

## Part 6: Non-Functional Requirements
<!-- Performance, security, reliability -->

---

## Appendix: Technical References
<!-- Links to related docs, standards, patterns -->
```

### Step 4: Create prd.md (Product Requirements)

Consolidate product documents into a single `prd.md`:

```markdown
---
type: prd
feature: {Feature Name}
version: "1.0"
status: Draft
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
author: {author}
stakeholders:
  - {stakeholder1}
---

# {Feature Name} - Product Requirements Document

## Executive Summary
<!-- High-level overview, value proposition -->

## Problem Statement
<!-- What problem are we solving? -->

## User Personas & Scenarios
<!-- Who are the users? What are their needs? -->

## User Journey
<!-- Consolidated journey.md content with detailed flows -->

## Functional Requirements
<!-- What must the system do? -->

## Core Use Cases
<!-- Step-by-step user interactions -->

## Success Metrics
<!-- How do we measure success? -->

## User Experience Requirements
<!-- UX patterns, accessibility, responsiveness -->

---

## Appendix: Product References
<!-- Market research, competitive analysis -->
```

### Step 5: Create implementation.md (Progress Tracker)

Create the implementation tracker:

```markdown
---
type: implementation
feature: {Feature Name}
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
repo: {repository-name}
phase: planning
progress: 0
---

# {Feature Name} - Implementation Progress

**Last Updated:** {YYYY-MM-DD}
**Project:** {Project/Repo Name}

## Executive Summary
<!-- Current status, completion %, key highlights -->

## Progress Overview

### Completed Items
| Component | File(s) | Status |
|-----------|---------|--------|
| - | - | - |

### In Progress Items
| Component | Status | Notes |
|-----------|--------|-------|
| - | - | - |

### Remaining Items
| Priority | Item | Description | Status |
|----------|------|-------------|--------|
| P0 | {Critical} | {Details} | Not started |

## File Structure
```
{project-name}/
├── src/
│   └── ...
```

## Dependencies & Blockers

### Dependencies
| Dependency | Required For | Status |
|------------|--------------|--------|
| - | - | - |

### Blockers
| Blocker | Impact | Resolution |
|---------|--------|------------|
| - | - | - |

## Implementation Details

### Patterns Used
- Reference: `_context/{project}/_arch/patterns-*.md`

### Migrations & Seeding
```sql
-- Database migrations (if applicable)
```

### Environment Variables
```bash
# Required configuration
```

### Packages Installed
```json
{
  "dependencies": {}
}
```

## Recommended Next Steps
<!-- Prioritized list of what to do next -->
```

### Step 6: Create Optional Supporting Docs

#### log.md (Change Log)
```markdown
---
type: log
feature: {Feature Name}
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
---

# {Feature Name} - Change Log

## Table of Contents
- [{YYYY-MM-DD} - Initial Setup](#yyyy-mm-dd-initial-setup)

---

## {YYYY-MM-DD} - Initial Setup

**Commit:** `{hash}`
**Type:** chore
**Repo:** {repo-name}

**Files Impacted:**
- `_context/{project}/{feature}/specs.md`
- `_context/{project}/{feature}/prd.md`
- `_context/{project}/{feature}/implementation.md`

**Description:**
Initial feature documentation setup with consolidated specs and PRD.

---
```

#### feature.md (Feature Wiki) - Create after implementation
```markdown
---
type: feature
name: {Feature Name}
status: in-progress
created: {YYYY-MM-DD}
updated: {YYYY-MM-DD}
repo: {repository-name}
version: "1.0.0"
---

# {Feature Name}

## Overview
<!-- What is this feature? Why does it exist? -->

## Architecture
<!-- High-level architecture summary -->

## Configuration
<!-- How to set it up -->

## Usage
<!-- How to use it - code examples -->

## Patterns
### Recommended Patterns
<!-- From .context/{project}/_arch/ -->

### Anti-Patterns to Avoid
<!-- What NOT to do -->

## Common Problems
<!-- FAQ, troubleshooting -->

## Related Documentation
- [specs.md](./specs.md)
- [prd.md](./prd.md)
- [implementation.md](./implementation.md)
```

## Consolidation Guidelines

When consolidating source files:

1. **Preserve all content** - Do not omit important details
2. **Organize logically** - Group related content under clear headings
3. **Remove redundancy** - Merge duplicate content intelligently
4. **Maintain context** - Each section should stand alone
5. **Cross-reference** - Link between sections and to `_arch/` standards
6. **Update TOC** - Ensure table of contents reflects all sections
7. **Mark sources** - Use comments to indicate content origin
8. **Preserve diagrams** - Include ALL mermaid diagrams with context
9. **Keep metadata** - Preserve version info, dates, status

## Examples

### Example 1: New Feature Setup

User: "Create specs documentation for the agents feature in ai-saas"

```bash
# Create folder
mkdir -p .context/ai-saas/agents/

# Create files
touch .context/ai-saas/agents/{specs,prd,implementation}.md
```

Then populate each file using the templates above.

### Example 2: Consolidating Existing Docs

Given source files:
```
.context/ai-saas/agents/
├── approach.md          # Technical approach
├── architecture.md      # System architecture
├── mermaid.md          # Diagrams
├── prd-draft.md        # Product requirements
└── journey.md          # User journey
```

Consolidation:
1. Create `specs.md` by merging approach.md + architecture.md + mermaid.md
2. Create `prd.md` by merging prd-draft.md + journey.md
3. Create `implementation.md` with task breakdown from specs.md
4. Optionally archive or delete source files

### Step 7: Create story_list.json (Agent Harness Protocol)

**IMPORTANT**: This file enables the Anthropic Agent Harness Protocol for reliable feature development across context resets.

#### Initialization Rules (CRITICAL)

When create-specs generates a story_list.json, ALL stories MUST have these exact initial values:
- `"status": "pending"` — NEVER `"in_progress"`, `"testing"`, or `"passes"`
- `"passes": false` — NEVER `true` (no code has been written yet)
- `"commits": []` — ALWAYS empty (no commits exist yet)
- `"blockers": []` — empty unless there are known blockers
- ALL `definition_of_done` items: `"done": false`
- ALL `acceptance_criteria` items: `"verified": false`

**Why**: The `done`, `verified`, and `passes` fields are ONLY set to `true` by the `develop-specs` skill AFTER actual source code is written, tests are run, and git commits are created. The create-specs skill defines WHAT needs to be done — it does NOT evaluate WHETHER it is done.

Create `story_list.json` in the feature folder:

```json
{
  "$schema": "./story_list.schema.json",
  "feature": "{feature-name}",
  "project": "{project-name}",
  "status": "planning",
  "created": "{YYYY-MM-DD}",
  "updated": "{YYYY-MM-DD}",
  "stories": [
    {
      "id": "STORY-001",
      "title": "{Story title from specs.md}",
      "description": "{User story: As a X, I want Y so that Z}",
      "priority": "P0",
      "status": "pending",
      "steps": [
        "Create the database schema and migrations",
        "Add RLS policies to registry",
        "Implement service layer",
        "Create tRPC router",
        "Build UI components"
      ],
      "definition_of_done": [
        { "item": "Code complete and compiles without errors (pnpm build passes)", "done": false },
        { "item": "Unit tests written and passing", "done": false },
        { "item": "Integration tests written and passing", "done": false },
        { "item": "No TypeScript errors in changed files (tsc --noEmit passes)", "done": false },
        { "item": "Documentation updated", "done": false }
      ],
      "acceptance_criteria": [
        { "item": "Uses createRouterWithActor pattern for tRPC router", "verified": false, "verification_method": "manual" },
        { "item": "RLS policies implemented and registered", "verified": false, "verification_method": "unit_test" },
        { "item": "Uses design system components", "verified": false, "verification_method": "manual" }
      ],
      "passes": false,
      "verification_script": "src/test/e2e/{feature}.spec.ts",
      "commits": [],
      "blockers": [],
      "dependencies": []
    }
  ]
}
```

#### Understanding steps vs definition_of_done vs acceptance_criteria

These three arrays serve distinct purposes:

| Field | Purpose | Examples |
|-------|---------|----------|
| **steps** | Implementation tasks - what to build | "Create database schema", "Build form component", "Add API endpoint" |
| **definition_of_done** | Completion checklist - is the work done? | "Code compiles (pnpm build)", "Tests passing", "No TS errors (tsc --noEmit)" |
| **acceptance_criteria** | Standards verification - does it meet architectural/quality standards? | "Uses createRouterWithActor pattern", "RLS policies implemented" |

**steps** = The ordered implementation tasks to complete the story (what you actually build)

**definition_of_done** = Generic completion checklist that applies to any story. Each item MUST be mechanically verifiable (can run a command to check):
- Code complete and compiles without errors (pnpm build passes)
- Tests written and passing (test runner output observed)
- No TypeScript errors in changed files (tsc --noEmit passes)
- Documentation updated

**acceptance_criteria** = Architectural and standards verification specific to this story:
- **Architectural standards**: "Uses createRouterWithActor pattern", "Follows repository pattern"
- **UI/UX standards**: "Uses design system components", "Follows standard form patterns"
- **Database standards**: "RLS policies implemented and registered", "Proper seeding added"
- **SDK patterns**: "Uses @jetdevs/core exports", "Follows SDK extension patterns"
- **Performance requirements**: "Page loads under 2s", "Query optimized with indexes"
- **Security requirements**: "Input validation with Zod", "CSRF protection enabled"

#### Story Extraction Guidelines

Extract stories from specs.md and prd.md:

1. **From specs.md Part 1 (Epics & User Stories)**:
   - Each epic becomes multiple stories
   - Each user story becomes one story entry

2. **From prd.md (Functional Requirements)**:
   - Each requirement maps to acceptance_criteria items
   - Use Given/When/Then format when possible

3. **Priority Assignment**:
   - P0: Core functionality, blockers for other features
   - P1: Important features, should be done soon
   - P2: Nice to have, can be deferred
   - P3: Low priority, future consideration

4. **Steps** (implementation tasks):
   - Break down the work into ordered implementation steps
   - Be specific: "Create user schema in database" not "Set up database"
   - Include all layers: database, API, UI as needed
   - Steps are what the developer will actually build

5. **Definition of Done** (completion checklist):
   - Keep generic across all stories
   - Standard items: code compiles (pnpm build), tests passing, no TS errors (tsc --noEmit), docs updated
   - Every item MUST be mechanically verifiable — the developer must be able to run a command to confirm it
   - Avoid subjective items like "code review completed" — use verifiable items like "no TypeScript errors (tsc --noEmit passes)"
   - Customize only if story has unique completion requirements

6. **Acceptance Criteria** (standards verification):
   - Focus on architectural patterns: "Uses createRouterWithActor pattern"
   - Include RLS/security: "RLS policies implemented and registered"
   - Reference design system: "Uses standard Button and Input components"
   - Add performance requirements: "Query uses proper indexes"
   - Include SDK patterns: "Uses @jetdevs/core exports"

#### Example: Converting Specs to Stories

Given this from specs.md:
```markdown
## Part 1: Epics & User Stories

### Epic 1: User Authentication
- US-1.1: As a user, I want to log in with email/password
- US-1.2: As a user, I want to reset my password
```

Create these story entries:
```json
{
  "stories": [
    {
      "id": "STORY-001",
      "title": "Implement email/password login",
      "description": "As a user, I want to log in with email/password so that I can access my account",
      "priority": "P0",
      "status": "pending",
      "steps": [
        "Create login API endpoint in auth router",
        "Implement session management with secure cookies",
        "Build login form UI with email/password fields",
        "Add form validation with Zod schema",
        "Connect form to API endpoint",
        "Add error handling for failed login attempts"
      ],
      "definition_of_done": [
        { "item": "Code complete and compiles without errors (pnpm build passes)", "done": false },
        { "item": "Unit tests for auth service passing", "done": false },
        { "item": "E2E test for login flow passing", "done": false },
        { "item": "No TypeScript errors in changed files (tsc --noEmit passes)", "done": false }
      ],
      "acceptance_criteria": [
        { "item": "Uses createRouterWithActor pattern for auth router", "verified": false, "verification_method": "manual" },
        { "item": "Session uses secure httpOnly cookies", "verified": false, "verification_method": "unit_test" },
        { "item": "Login form uses design system Input and Button components", "verified": false, "verification_method": "manual" },
        { "item": "Input validation with Zod (email format, password min length)", "verified": false, "verification_method": "unit_test" },
        { "item": "Rate limiting on login endpoint", "verified": false, "verification_method": "integration_test" }
      ],
      "passes": false,
      "verification_script": "src/test/e2e/auth-login.spec.ts",
      "commits": [],
      "dependencies": []
    },
    {
      "id": "STORY-002",
      "title": "Implement password reset flow",
      "description": "As a user, I want to reset my password so that I can recover access to my account",
      "priority": "P1",
      "status": "pending",
      "steps": [
        "Create password reset request endpoint",
        "Implement secure token generation and storage",
        "Create email template for reset link",
        "Build password reset request form UI",
        "Build new password form UI",
        "Create password update endpoint with token validation",
        "Add token expiry handling"
      ],
      "definition_of_done": [
        { "item": "Code complete and compiles without errors (pnpm build passes)", "done": false },
        { "item": "Unit tests for token generation/validation passing", "done": false },
        { "item": "Integration tests for email sending passing", "done": false },
        { "item": "E2E test for full reset flow passing", "done": false },
        { "item": "No TypeScript errors in changed files (tsc --noEmit passes)", "done": false }
      ],
      "acceptance_criteria": [
        { "item": "Reset tokens are cryptographically secure (crypto.randomBytes)", "verified": false, "verification_method": "unit_test" },
        { "item": "Tokens expire after 1 hour", "verified": false, "verification_method": "unit_test" },
        { "item": "Email template follows design system patterns", "verified": false, "verification_method": "manual" },
        { "item": "Forms use design system components", "verified": false, "verification_method": "manual" },
        { "item": "Password strength validation (min 8 chars, mixed case, numbers)", "verified": false, "verification_method": "unit_test" }
      ],
      "passes": false,
      "verification_script": "src/test/e2e/auth-reset.spec.ts",
      "commits": [],
      "dependencies": ["STORY-001"]
    }
  ]
}
```

## Quality Checklist

Before marking specs complete:

- [ ] `specs.md` exists with consolidated technical content
- [ ] `prd.md` exists with consolidated product content
- [ ] `implementation.md` exists with progress tracking
- [ ] `story_list.json` exists with stories extracted from specs/prd
- [ ] All files have YAML frontmatter (except JSON)
- [ ] All mermaid diagrams included with context
- [ ] Cross-references to `_arch/` standards present
- [ ] Table of contents accurate in each file
- [ ] No source content omitted
- [ ] story_list.json has proper definition_of_done and acceptance_criteria for each story

## Notes

- **Location**: Feature folders go DIRECTLY under `_context/{project}/` (not in `_specs/` or `_wiki/`)
- **Learning docs**: Go in `_context/{project}/_arch/learning-*.md` (separate from specs)
- **Golden vs Operational**: specs.md and prd.md are operational docs (can change); feature.md is a golden doc (stable)
- **AI-Optimized**: Use YAML frontmatter, markdown tables, mermaid diagrams, and hierarchical headings
- **Update triggers**: Update when architecture changes, implementation progresses, or requirements evolve
- **story_list.json**: Enables the Anthropic Agent Harness Protocol - JSON is used instead of markdown because LLMs are less likely to corrupt JSON structure during context compaction
- **Schema reference**: The story_list.json schema is at `.claude/skills/create-specs/story_list.schema.json`
- **Template reference**: A story_list template is at `.claude/skills/create-specs/story_list.template.json`

## Integration with develop-specs Skill

**Handoff contract**: create-specs produces story_list.json with all stories in `pending` state. develop-specs consumes it and advances stories through implementation.

| Field | create-specs sets | develop-specs sets |
|-------|------------------|-------------------|
| `status` | `"pending"` | `"in_progress"` → `"testing"` → `"passes"` |
| `passes` | `false` | `true` (only after code + tests + commits) |
| `done` (DoD) | `false` | `true` (only after implementing the item) |
| `verified` (AC) | `false` | `true` (only after running verification) |
| `commits` | `[]` | `[{ hash, message, date }]` |

**CRITICAL**: create-specs MUST NEVER set `done: true`, `verified: true`, `passes: true`, or `status: "passes"`. These fields are exclusively managed by develop-specs after actual source code is written, tests are executed, and git commits are created.
