---
name: develop-specs
description: Implements features using the Anthropic Agent Harness Protocol with story_list.json tracking. Use when developing features from specs, implementing user stories, or resuming work on a feature. Provides atomic task execution with git commits and verification.
---

# Develop Specs

Implement features systematically using the Anthropic Agent Harness Protocol. This skill treats the codebase + git + story_list.json as long-term memory, enabling reliable feature development across context resets.

## Core Philosophy

The agent completes ONE story at a time, verifies it with tests, updates the story_list.json, commits, and only then moves to the next story. This ensures:

1. **Atomic Progress**: Each commit represents a verified, working increment
2. **Resumability**: Any new agent instance can read story_list.json and continue
3. **Accountability**: All changes are tracked with verification status

## Instructions

### Step 1: Locate Feature Context

First, find the feature's story_list.json:

```bash
# Check for story_list.json in the feature folder
ls .context/{project}/{feature}/story_list.json

# Or find all story lists
find .context -name "story_list.json" -type f
```

Read the story_list.json to understand current state:
- Which stories have `passes: true`?
- Which story should be worked on next (first with `passes: false`)?
- Are there any blockers?

### Step 2: Read Supporting Documentation

Before implementing, read the feature's documentation:

```
.context/{project}/{feature}/
  - specs.md          # Technical specifications
  - prd.md           # Product requirements
  - implementation.md # Progress tracking
  - story_list.json  # Task tracking (THIS IS THE SOURCE OF TRUTH)
```

Also read relevant architecture docs:
```
.context/{project}/_arch/
  - patterns-*.md    # Coding patterns to follow
  - learning-*.md    # Project-specific knowledge
```

### Step 3: Implement ONE Story

**CRITICAL**: Only work on ONE story at a time. Never implement multiple stories before committing.

#### 3a. Mark Story as In Progress

Update story_list.json:
```json
{
  "id": "STORY-001",
  "status": "in_progress",
  ...
}
```

#### 3b. Work Through Definition of Done

For each item in `definition_of_done`:

1. Implement the requirement
2. Mark `"done": true` in story_list.json
3. Continue to next item

Example definition_of_done items:
- Database schema created -> Run migration
- API endpoint implemented -> Create tRPC router
- Unit tests passing -> Write and run tests
- UI components built -> Create React components

#### 3c. Verify Acceptance Criteria

For each item in `acceptance_criteria`:

1. Verify the criterion is met (run test or manual check)
2. Mark `"verified": true` in story_list.json
3. Note the `verification_method` used

**IMPORTANT**: Use the verification_script if specified:
```bash
# Run the specific test file
pnpm test:e2e {verification_script}

# Or run unit tests
pnpm test:unit --testPathPattern={feature}
```

### Step 4: Evaluate Completion

A story can ONLY have `passes: true` when:

1. **ALL** `definition_of_done` items have `"done": true`
2. **ALL** `acceptance_criteria` items have `"verified": true`
3. **ALL** relevant tests pass

```javascript
// Pseudo-code for passes evaluation
const allDoDDone = definition_of_done.every(item => item.done === true);
const allACVerified = acceptance_criteria.every(item => item.verified === true);
const passes = allDoDDone && allACVerified;
```

**If ANY item is false, passes MUST be false.**

### Step 5: Update story_list.json

Once all criteria are met:

```json
{
  "id": "STORY-001",
  "status": "passes",
  "definition_of_done": [
    { "item": "Database schema created", "done": true },
    { "item": "API endpoint implemented", "done": true },
    { "item": "Unit tests passing", "done": true }
  ],
  "acceptance_criteria": [
    { "item": "User can create X", "verified": true, "verification_method": "e2e_test" },
    { "item": "System validates input", "verified": true, "verification_method": "unit_test" }
  ],
  "passes": true,
  "commits": [
    { "hash": "abc123", "message": "feat: implement STORY-001", "date": "2024-01-15T10:30:00Z" }
  ]
}
```

Also update feature status if all stories pass:
```json
{
  "status": "completed"  // Only if ALL stories have passes: true
}
```

### Step 6: Git Commit (The Save Point)

**CRITICAL**: Commit after EVERY completed story.

```bash
git add .
git commit -m "feat({feature}): {STORY-ID} - {brief description}

Definition of Done: ALL COMPLETE
- [x] Database schema created
- [x] API endpoint implemented
- [x] Unit tests passing

Acceptance Criteria: ALL VERIFIED
- [x] User can create X (e2e_test)
- [x] System validates input (unit_test)

Story Status: PASSES"
```

### Step 7: Update Progress Log (Optional)

If the project uses claude-progress.md or implementation.md:

```markdown
## {YYYY-MM-DD} - {STORY-ID} Complete

**Feature**: {feature-name}
**Story**: {story-title}
**Commits**: {commit-hash}

### What Was Done
- Implemented {X}
- Added tests for {Y}
- Verified acceptance criteria via {method}

### Next Steps
- Continue with {next-story-id}
```

### Step 8: Repeat or Report

If more stories remain:
- Return to Step 3 with the next story

If all stories complete:
- Report feature completion
- Update feature status to "completed"
- Create summary for handoff

## Workflow Loop Summary

```
READ story_list.json
  -> Find next story with passes: false
  -> Read specs/docs
  -> Implement (working through DoD items)
  -> Run tests (verify AC items)
  -> ALL DoD done? ALL AC verified?
     -> YES: Set passes: true, COMMIT, update log
     -> NO: Fix issues, do NOT set passes: true
  -> REPEAT until all stories pass
```

## Resume Protocol

When resuming work (new context/session):

```bash
# 1. Orient yourself
pwd
git log --oneline -10
git status

# 2. Find and read the story list
cat .context/{project}/{feature}/story_list.json

# 3. Identify current state
# - Which stories have passes: true?
# - Which is the next story to work on?
# - Are there any blockers?

# 4. Continue from Step 3 above
```

## Examples

### Example 1: Starting a New Feature

User: "Implement the agents feature from specs"

```bash
# Read the story list
cat .context/ai-saas/agents/story_list.json

# Output shows:
# STORY-001: passes: false
# STORY-002: passes: false

# Start with STORY-001
# 1. Mark as in_progress
# 2. Read specs.md for details
# 3. Implement each DoD item
# 4. Verify each AC item
# 5. Update story_list.json with passes: true
# 6. Commit
# 7. Move to STORY-002
```

### Example 2: Resuming After Context Reset

User: "Resume work on agents feature"

```bash
# Check git state
git log --oneline -5
# Shows: "feat(agents): STORY-001 - Verified Passing"

# Read story list
cat .context/ai-saas/agents/story_list.json
# Shows: STORY-001 passes: true, STORY-002 passes: false

# Continue with STORY-002
```

### Example 3: Handling Test Failures

When a test fails:

1. Keep `passes: false` in story_list.json
2. Document the failure in blockers array
3. Fix the issue
4. Re-run tests
5. Only set `passes: true` when ALL tests pass

```json
{
  "id": "STORY-001",
  "status": "in_progress",
  "passes": false,
  "blockers": ["Test failing: expected 200, got 401 - auth issue"]
}
```

## story_list.json Rules

### NEVER Do These:
- Set `passes: true` if ANY DoD item has `"done": false`
- Set `passes: true` if ANY AC item has `"verified": false`
- Implement multiple stories before committing
- Skip the commit step after completing a story
- Modify completed stories (passes: true) unless fixing bugs

### ALWAYS Do These:
- Read story_list.json before starting work
- Update status to "in_progress" when starting
- Check ALL DoD and AC items before setting passes
- Include commit hash in the story after committing
- Update the "updated" date in story_list.json

## Integration with Existing Workflow

This skill integrates with:

- **create-specs**: Creates the initial story_list.json from specs/prd
- **browser-testing**: Provides Playwright tests for AC verification
- **commit-message**: Generates appropriate commit messages
- **update-wiki-docs**: Updates implementation.md after progress

## Notes

- story_list.json is per-feature, not global (enables parallel feature work)
- The schema is at `.claude/skills/create-specs/story_list.schema.json`
- Template is at `.claude/skills/create-specs/story_list.template.json`
- This protocol is based on the Anthropic Agent Harness Protocol
- JSON is used instead of markdown for better LLM parsing reliability
