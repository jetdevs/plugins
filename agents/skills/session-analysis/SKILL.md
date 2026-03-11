---
name: session-analysis
description: Use when analyzing development session files to extract knowledge for updating Claude Code agents and skills. Also use when the user mentions "analyze sessions", "extract from sessions", "session knowledge", "what changed recently", or "session lessons".
---

# Session Analysis for Plugin Updates

Extract structured knowledge from development session files (`_ai/sessions/`) to keep agents and skills current.

## Session File Structure

Session files follow this pattern:
```
_ai/sessions/YYYY-MM-DD-[project]-description.md
```

### Sections to Extract From

| Section | What to Extract | Maps To |
|---------|----------------|---------|
| Summary | New feature areas, high-level capabilities | Skill descriptions, agent examples |
| Git Changes | New files, new extensions, structural changes | Architecture sections, file paths in skills |
| Details | Implementation patterns, API shapes, component designs | Skill body content, code patterns |
| Context Documents | Key file paths, source of truth files | Reference documentation sections |
| Lessons Learned | Critical patterns, gotchas, architectural decisions | Critical rules sections, agent system prompts |

## Analysis Process

### 1. Filter Sessions
```bash
# By project tag and date range
ls _ai/sessions/ | grep -i '[tag]' | grep '^YYYY-MM-'

# Common tags: [cadra], [cadra-web], [yobo], [yobo-merchant], [crm], [slides], [core-saas]
```

### 2. Read Each Session — Extract Knowledge Items

For each session, create a knowledge inventory:

**New Features** (→ may need new skills or skill sections):
- Feature name, scope, key components
- Extension/module it belongs to
- Whether it's a new area or extension of existing

**New Patterns** (→ update skill bodies and agent system prompts):
- Code patterns (e.g., "always use atomic setStreamEntries")
- Architecture patterns (e.g., "single aggregated tRPC endpoint for dashboards")
- Anti-patterns to avoid (e.g., "never split state updates that depend on each other")

**New File Paths** (→ update reference documentation sections):
- New extensions, components, pages
- New config files, seed scripts
- Source of truth files mentioned in context

**Critical Lessons** (→ add as "Critical Rules" or "Critical Patterns" in skills):
- Items labeled "CRITICAL" or "IMPORTANT"
- Bug fixes that reveal fundamental patterns
- Recurring issues with specific solutions

**New Examples** (→ improve agent trigger matching):
- User requests that led to the session
- Common tasks within the feature area

### 3. Gap Analysis

Compare extracted items against existing plugin content:

```
For each knowledge item:
  1. Does an existing skill cover this area?
     YES → Does the skill mention this specific pattern/file/feature?
           YES → No action needed
           NO  → UPDATE skill with new content
     NO  → Is this area significant enough for its own skill?
           YES → CREATE new skill
           NO  → Add to nearest related skill or agent system prompt
```

### 4. Prioritize Updates

Priority order:
1. **Critical patterns/lessons** — These prevent bugs. Add immediately.
2. **New feature areas** — Missing skills mean the agent can't help with new features.
3. **New file paths** — Stale paths waste agent time searching.
4. **New examples** — Improve trigger accuracy.
5. **Structural updates** — Architecture diagrams, extension lists.

## Knowledge Extraction Templates

### For a New Feature Session
```markdown
Feature: [name]
Skill: [existing skill to update OR new skill needed]
Key Files:
- [path1] — [purpose]
- [path2] — [purpose]
Patterns:
- [pattern description with code if applicable]
Lessons:
- [lesson with context]
```

### For a Bug Fix Session
```markdown
Bug: [description]
Root Cause: [what went wrong]
Fix Pattern: [the correct approach]
Affected Skill: [which skill should document this]
Critical Rule: [one-line rule to add to skill]
```

### For a Refactoring Session
```markdown
Refactor: [what changed]
Before: [old pattern]
After: [new pattern]
Files Moved/Renamed:
- [old path] → [new path]
Skills to Update: [list of skills with stale references]
```

## Quality Checks

After extracting knowledge, verify:
- No duplicate information (check if skill already documents it)
- Correct file paths (files may have moved since session was written)
- Patterns are actionable (include code, not just descriptions)
- Lessons include the "why" (not just "do X" but "do X because Y")

## Cross-Session Patterns

When multiple sessions touch the same area, look for:
- **Evolving patterns**: Later sessions may supersede earlier ones
- **Repeated lessons**: If the same lesson appears twice, it's critical — flag prominently
- **Contradiction**: If sessions disagree, the later one wins (check git history if unsure)
