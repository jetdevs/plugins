---
name: review-specs
description: Critically reviews feature specification documents (prd.md, specs.md, implementation.md, story_list.json) and generates feedback.md with structured feedback items. Use when reviewing specs before implementation, validating architectural decisions, or when specs need a critical eye before development begins.
---

# Review Feature Specs

Critically review feature specification documents to identify ambiguities, missing edge cases, security concerns, and architectural issues. Generate structured feedback that challenges assumptions rather than rubber-stamping.

## Philosophy

**Do NOT rubber-stamp specs.** A good review should:
- Challenge assumptions with evidence from the codebase
- Verify claims by reading actual code
- Defend good decisions when they're questioned
- Identify when the spec is solving the wrong problem
- Flag when design decisions need validation before implementation

## Instructions

### Step 1: Locate Spec Documents

Find the spec folder and identify all documents to review:

```bash
ls _context/{project}/{feature-name}/
```

Expected files:
| File | Purpose | Required |
|------|---------|----------|
| `specs.md` | Technical specifications | Yes |
| `prd.md` | Product requirements | Yes |
| `implementation.md` | Progress tracking | Yes |
| `story_list.json` | Stories for development | Yes |
| `feedback.md` | Previous feedback (if exists) | No |

### Step 2: Read All Spec Documents

Read each document thoroughly before generating feedback:

```bash
# Read in this order for context
cat _context/{project}/{feature}/prd.md
cat _context/{project}/{feature}/specs.md
cat _context/{project}/{feature}/implementation.md
cat _context/{project}/{feature}/story_list.json
```

### Step 3: Investigate the Codebase

**CRITICAL**: Do not generate feedback based only on the specs. Verify claims by reading actual code.

For each technical claim in the specs:
1. Find the relevant code files
2. Read the actual implementation
3. Verify if the claim is accurate
4. Note discrepancies

Common investigations:
```bash
# Find existing patterns mentioned in specs
grep -r "pattern_name" src/

# Check if claimed problems actually exist
cat src/path/to/file.ts

# Verify architectural claims
grep -r "function_name\|class_name" src/
```

### Step 4: Generate Structured Feedback

Create or update `feedback.md` in the feature folder:

```markdown
---
type: feedback
feature: {Feature Name}
version: "1.0"
status: Draft
created: {YYYY-MM-DD}
---

# {Feature Name} - Feedback

## Product / PRD (`prd.md`)

- UNRESOLVED: {Issue description}; {what needs to change}
- UNRESOLVED: {Another issue}

## Technical Spec (`specs.md`)

- UNRESOLVED: {Technical concern}; {recommendation}
- UNRESOLVED: {Missing consideration}

## Implementation Plan (`implementation.md`)

- UNRESOLVED: {Gap in plan}; {what to add}

## Story List (`story_list.json`)

- UNRESOLVED: {Story issue}; {correction needed}
```

### Step 5: Use Correct Status Tags

Each feedback item must have a status prefix:

| Status | Meaning | When to Use |
|--------|---------|-------------|
| `UNRESOLVED` | Issue needs attention | Initial feedback, not yet addressed |
| `ALIGNED` | Issue resolved, agree with resolution | After spec author fixes issue |
| `CHALLENGED` | Disagree with the feedback | When defending original spec decision |
| `PARTIAL` | Partially agree | When feedback is partly valid |

#### Format for Responses

When responding to feedback (as spec author):
```markdown
- ALIGNED: {Original feedback text}
  - Claude: {Verification notes, what was changed}

- CHALLENGED: {Original feedback text}
  - Claude: {Counter-argument with evidence from codebase}

- PARTIAL: {Original feedback text}
  - Claude: {What you agree with, what you disagree with, why}
```

### Step 6: Critical Review Categories

Review specs against these categories:

#### 1. Problem Validation
- Is the stated problem real? Verify in codebase.
- Are we solving the right problem?
- Is there existing code that already solves this?

#### 2. Architectural Accuracy
- Do claimed patterns exist in the codebase?
- Are file paths and module names accurate?
- Does the proposed solution fit existing architecture?

#### 3. Security Concerns
- Are there authentication/authorization gaps?
- Is sensitive data handled properly?
- Are there injection or privilege escalation risks?

#### 4. Missing Edge Cases
- What happens on failure?
- What about concurrent access?
- What about empty/null/invalid inputs?

#### 5. Ambiguous Requirements
- Are acceptance criteria testable?
- Are technical decisions specified or left vague?
- Are there multiple valid interpretations?

#### 6. Unrealistic Claims
- Are performance targets achievable?
- Are effort estimates reasonable?
- Do dependencies exist as claimed?

#### 7. Design Decision Validation
- Which decisions need stakeholder input before implementation?
- Are there multiple valid approaches not explored?
- Is the chosen approach justified?

### Step 7: Verify Before Marking ALIGNED

When spec author responds to feedback, verify before accepting:

1. **Check the updated spec file** - Was the change actually made?
2. **Verify code claims** - If they cite code, read it
3. **Test the logic** - Does the response make sense?
4. **Challenge weak responses** - "AGREED" without action is not resolution

## Examples

### Example 1: Investigating a Claim

**Spec claims:** "The current system queries the database on every request"

**Investigation:**
```bash
# Find the middleware or auth code
grep -r "getSession\|getServerSession" src/

# Read the actual implementation
cat src/server/auth.ts
```

**Finding:** The claim is TRUE - line 45 calls `db.query()` on every session check.

**Feedback:** None needed, claim is accurate.

### Example 2: Challenging a Claim

**Spec claims:** "WebSocket is required for real-time updates"

**Investigation:**
```bash
# Check if SSE is used elsewhere
grep -r "text/event-stream" src/

# Read existing streaming code
cat src/app/api/v1/stream/route.ts
```

**Finding:** SSE is already used for workflow streaming on line 34.

**Feedback:**
```markdown
- UNRESOLVED: Spec claims WebSocket is required, but SSE is already used for workflow streaming in `src/app/api/v1/stream/route.ts`. SSE may be sufficient and avoids WebSocket complexity on Vercel.
```

### Example 3: Identifying Missing Edge Cases

**Spec says:** "On permission revocation, redirect user to login"

**Missing consideration:** What if user has access to multiple organizations?

**Feedback:**
```markdown
- UNRESOLVED: Permission revocation behavior doesn't distinguish between (1) user deactivated entirely, (2) user loses current org but has other orgs, (3) user loses all org access. Current code in `real-time-permissions.ts` already handles this via `shouldMaintainSession` and `activeOrganizations`. Spec should align with existing behavior.
```

### Example 4: Defending Against Over-Engineering Feedback

**External feedback says:** "Add token versioning for security"

**Investigation:**
```bash
# Check current auth flow
cat src/lib/trpc-permissions.ts
# Check middleware
cat src/middleware.ts
```

**Finding:** tRPC already queries DB on every request. Token versioning would add latency without security benefit.

**Response:**
```markdown
- CHALLENGED: Token versioning proposal; after investigation, `trpc-permissions.ts` already queries DB on every tRPC request via `getUserPermissions()` (line 23). Middleware only handles routing, not permission checks. Token versioning would add DB reads + UX friction while protecting against zero real attack vectors. Recommend removing this story.
  - Claude: VERIFIED. Reviewed `trpc-permissions.ts` - line 23 calls `getUserPermissions(ctx.session.user.id, ctx.session.user.currentOrgId)` which hits DB directly. Token versioning is unnecessary overhead.
```

## Review Checklist

Before marking review complete:

- [ ] Read ALL spec documents (prd.md, specs.md, implementation.md, story_list.json)
- [ ] Verified key claims by reading actual code
- [ ] Checked for security concerns
- [ ] Identified ambiguous requirements
- [ ] Flagged unrealistic claims
- [ ] Noted missing edge cases
- [ ] Identified decisions needing validation
- [ ] Generated feedback.md with structured items
- [ ] Each item has correct status (UNRESOLVED/ALIGNED/CHALLENGED/PARTIAL)
- [ ] Challenged at least ONE assumption (no rubber-stamping)

## Notes

- **Be skeptical by default** - Verify claims, don't assume they're correct
- **Cite evidence** - Reference file paths and line numbers when possible
- **Defend good decisions** - Don't agree with feedback just because it's feedback
- **Propose alternatives** - Don't just criticize, suggest solutions
- **Consider effort vs value** - Is the proposed change worth the complexity?
- **Flag showstoppers** - Some issues block implementation entirely
- **Use PARTIAL** - Most feedback has some validity but may be overstated

## Integration with Other Skills

| Skill | Relationship |
|-------|--------------|
| `create-specs` | Creates the specs this skill reviews |
| `develop-specs` | Implements specs AFTER review is complete |
| `qa-testing` | Tests implementation after development |

**Recommended workflow:**
1. `/create-specs` - Create spec documents
2. `/review-specs` - Critical review (this skill)
3. Address feedback, iterate until ALIGNED
4. `/develop-specs` - Begin implementation
