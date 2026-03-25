---
name: address-feedback
description: Process and respond to Codex/GPT-5 spec review feedback in feedback.md. Use after Codex has reviewed specs and written feedback.md, when you need to address each feedback item by updating specs, challenging incorrect feedback, or aligning with valid concerns. Also use when the user says "address feedback", "respond to feedback", "process codex feedback", or "fix the feedback items".
---

# Address Feedback

Read Codex/GPT-5's feedback on spec documents and respond to each item by updating specs, challenging incorrect feedback, or aligning with valid concerns.

## Context

This skill is used AFTER Codex has reviewed specs and written `feedback.md`. The cycle:
1. `/create-specs` creates spec documents
2. Codex auto-reviews and writes `feedback.md` (via PostToolUse hook)
3. **This skill** — Claude reads feedback.md and addresses each item
4. `/codex-review` triggers Codex to re-review Claude's responses
5. Repeat until all items are ALIGNED/RESOLVED

## Instructions

### Step 1: Locate Feedback and Spec Documents

Find the spec folder containing `feedback.md`:

```bash
ls _context/{project}/{feature-name}/
```

Expected files:
| File | Purpose | Required |
|------|---------|----------|
| `feedback.md` | Codex's feedback (items prefixed with GPT5:) | Yes |
| `specs.md` | Technical specifications | Yes |
| `prd.md` | Product requirements | Yes |
| `implementation.md` | Progress tracking | Yes |
| `story_list.json` | Stories for development | Yes |

### Step 2: Read All Documents

Read feedback.md first, then all spec documents for context:

1. Read `feedback.md` — understand each UNRESOLVED item
2. Read `specs.md`, `prd.md`, `implementation.md`, `story_list.json`

### Step 3: Investigate Each Feedback Item

**CRITICAL**: Do not respond to feedback without verifying claims against actual code.

For each UNRESOLVED item in feedback.md:
1. Understand what Codex is flagging
2. Find the relevant code files
3. Read the actual implementation
4. Determine if the feedback is valid, partially valid, or incorrect

### Step 4: Respond to Each Item

Update `feedback.md` with responses. Change the status prefix and add a `Claude:` sub-bullet:

#### If feedback is valid — update specs and mark ALIGNED:
```markdown
- ALIGNED: {Original feedback text}
  - GPT5: {Codex's original analysis}
  - Claude: {What was changed in which spec file, verification notes}
```
**Then actually update the spec files** — don't just say you will.

#### If feedback is incorrect — mark CHALLENGED with evidence:
```markdown
- CHALLENGED: {Original feedback text}
  - GPT5: {Codex's original analysis}
  - Claude: {Counter-argument with evidence from codebase, file paths, line numbers}
```

#### If feedback is partially valid — mark PARTIAL:
```markdown
- PARTIAL: {Original feedback text}
  - GPT5: {Codex's original analysis}
  - Claude: {What you agree with, what you disagree with, and why}
```

### Step 5: Update Spec Files

For every ALIGNED or PARTIAL item, make the actual changes to the spec files:
- Update `specs.md` for technical changes
- Update `prd.md` for product requirement changes
- Update `implementation.md` for plan changes
- Update `story_list.json` for story changes

### Step 6: Trigger Re-review

After addressing all items, invoke `/codex-review` to have Codex verify your responses.

**Critical rule:** Address ALL feedback immediately — never ask the user if they want to review first.

## Status Prefixes

| Status | Meaning | When to Use |
|--------|---------|-------------|
| `UNRESOLVED` | Issue needs attention | Initial feedback from Codex, not yet addressed |
| `ALIGNED` | Issue resolved, agree with resolution | After updating specs to fix the issue |
| `CHALLENGED` | Disagree with the feedback | When defending original spec decision with evidence |
| `PARTIAL` | Partially agree | When feedback is partly valid |
| `RESOLVED` | Issue fully addressed and verified | After Codex confirms the response |

## Guidelines

- **Be skeptical of your own specs** — Codex often catches real issues
- **Cite evidence** — Reference file paths and line numbers when challenging
- **Defend good decisions** — Don't agree with feedback just because it's feedback
- **Actually make changes** — ALIGNED without spec updates is not resolution
- **Propose alternatives** — When challenging, suggest what should be done instead

## Integration

| Skill | Relationship |
|-------|--------------|
| `create-specs` | Creates the specs that Codex reviews |
| `codex-review` | Launches Codex to review/re-review specs |
| `develop-specs` | Implements specs AFTER all feedback is resolved |

**Workflow:**
1. `/create-specs` — Create spec documents
2. [Codex auto-reviews via hook] — Writes feedback.md
3. `/address-feedback` — Claude addresses each item (this skill)
4. `/codex-review` — Codex re-reviews Claude's responses
5. Repeat 3-4 until all items ALIGNED/RESOLVED
6. `/develop-specs` — Begin implementation
