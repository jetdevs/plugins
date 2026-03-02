---
name: spec-feedback-reviewer
description: Reviews PRDs, technical specs, implementation plans, and story lists to produce structured feedback.md with status-prefixed actionable bullets grounded in the repository's current code and patterns. Use when asked to "review specs", "give feedback on specs", "find gaps/risks/ambiguities in specs", or after create-specs to get external review.
---

# Spec Feedback Reviewer

Produce high-signal, repo-grounded feedback on product/technical specifications and generate a `feedback.md` that engineering can act on.

## Instructions

### Step 0: Confirm Inputs and Output

1. Collect the spec file paths (commonly in `_context/{project}/{feature}/`):
   - `prd.md` - Product requirements
   - `specs.md` - Technical specifications
   - `implementation.md` - Implementation plan
   - `story_list.json` - User stories

2. Confirm the required status prefix for every feedback item (default: `UNRESOLVED:`)

3. Confirm the output location (default: write `feedback.md` next to the specs)

### Step 1: Read the Specs End-to-End

Read all spec documents and verify internal consistency:

| Document | What to Verify |
|----------|----------------|
| PRD (`prd.md`) | "Current state" claims, user journeys, functional requirements, success metrics are internally consistent |
| Technical specs (`specs.md`) | Architecture choices, security model, operational constraints, testability |
| Implementation plan (`implementation.md`) | Reuses existing repo primitives/patterns, doesn't duplicate responsibilities |
| Stories (`story_list.json`) | Acceptance criteria are measurable and map to the PRD/specs (no missing critical stories) |

### Step 2: Ground-Check Against the Repository

Verify claims against actual code:

1. **Locate referenced files** - Confirm they exist or flag mismatches
2. **Search for existing patterns** - Align with what the codebase already does:
   - SSE: search `text/event-stream` and reuse established headers + cleanup patterns
   - Redis pub/sub: confirm expected APIs exist and define behavior when Redis is unavailable
   - Auth/session: confirm how the app stores permissions and enforces access today
3. **Point feedback at concrete files/symbols** - Include "what to change" vs abstract critiques

### Step 3: Write feedback.md Using the Template

Use the template from [assets/feedback-template.md](assets/feedback-template.md):

```markdown
---
type: feedback
feature: <feature-name>
version: "1.0"
status: Draft
created: <YYYY-MM-DD>
---

# <Feature Name> - Feedback

## Product / PRD (`prd.md`)

- UNRESOLVED: <issue> — <why it matters> — <concrete fix/decision to add>

## Technical Spec (`specs.md`)

- UNRESOLVED: <issue> — <why it matters> — <concrete fix/decision to add>

## Implementation Plan (`implementation.md`)

- UNRESOLVED: <issue> — <why it matters> — <concrete fix/decision to add>

## Stories (`story_list.json`)

- UNRESOLVED: <issue> — <why it matters> — <concrete fix/decision to add>
```

**For each feedback item:**
1. Use the correct status prefix (default `UNRESOLVED:`)
2. Create a sub-bullet prefixed with `Claude:` containing:
   - What's unclear/incorrect/missing
   - Why it matters (security/UX/reliability/ops/testability)
   - A concrete next step (add a decision, tighten schema, align with code, etc.)

### Step 4: Consistency Pass

1. Ensure all feedback is actionable (fixable by the spec author)
2. Reference the right system boundaries
3. Validate formatting - all bullet items must have status prefix

Run the validation script:
```bash
python3 .claude/skills/spec-feedback-reviewer/scripts/check_feedback_status.py <path/to/feedback.md> --prefix 'UNRESOLVED:'
```

## Status Prefixes

| Status | Meaning | When to Use |
|--------|---------|-------------|
| `UNRESOLVED:` | Issue needs attention | Initial feedback, not yet addressed |
| `ALIGNED:` | Issue resolved, agree with resolution | After spec author fixes issue |
| `CHALLENGED:` | Disagree with the feedback | When defending original spec decision |
| `PARTIAL:` | Partially agree | When feedback is partly valid |
| `RESOLVED:` | Issue fully addressed | Confirmed fixed and verified |

## Common Review Checks

### Correctness / Consistency
- "Current state" claims match reality (don't assume JWT caching if server does DB checks)
- Responsibilities are separated (server enforcement vs client UI vs session invalidation)
- Terms are consistent (org access vs permission revocation vs user deactivation)

### Security
- Stream subscription cannot be impersonated (don't trust `userId` query params)
- Auth mechanism works with SSE constraints (cookies; avoid "Authorization" header assumptions)
- Threat model ties directly to mitigations and verification

### SSE / Realtime Mechanics
- SSE format is defined (`event:` names, `id:` usage, reconnect story)
- Disconnect cleanup is defined (use `request.signal` / abort handling)
- Degraded mode is explicit (Redis missing, network loss, retry/backoff, polling fallback)

## Examples

### Example 1: Finding a Claim Mismatch

**Spec claims:** "The system uses JWT caching for performance"

**Investigation:**
```bash
grep -r "jwt\|token" src/server/auth/
```

**Finding:** Server actually queries DB on every request via `getUserSession()`.

**Feedback:**
```markdown
- UNRESOLVED: Spec claims JWT caching but `src/server/auth/session.ts:45` queries DB on every request
  - Claude: The spec's performance assumptions are incorrect. Either update the spec to reflect actual behavior or add JWT caching as a new story.
```

### Example 2: Missing Edge Case

**Spec says:** "On permission revocation, redirect user to login"

**Investigation:**
```bash
grep -r "permission.*revok\|revoke.*permission" src/
```

**Finding:** Code distinguishes between user deactivation, org removal, and full access loss.

**Feedback:**
```markdown
- UNRESOLVED: Permission revocation behavior unclear for multi-org users
  - Claude: Spec doesn't distinguish (1) user deactivated entirely, (2) user loses current org but has other orgs, (3) user loses all org access. Current code in `real-time-permissions.ts` handles this via `shouldMaintainSession`. Align spec with existing behavior or explicitly override.
```

### Example 3: Security Gap

**Spec proposes:** "Subscribe to SSE using `/events?userId=123`"

**Feedback:**
```markdown
- UNRESOLVED: SSE subscription uses query param for userId — security risk
  - Claude: Query params can be spoofed. Use session cookie for auth instead. See existing pattern in `src/app/api/v1/stream/route.ts:34` which validates session before streaming.
```

## Notes

- **Do NOT rubber-stamp** - Every review should challenge at least one assumption
- **Cite evidence** - Reference file paths and line numbers when possible
- **Prefer existing patterns** - Point to how the codebase already solves similar problems
- **Be specific** - "Add validation" is not actionable; "Add Zod schema for email field in `signup.ts:23`" is
- **Use PARTIAL** - Most feedback has some validity but may be overstated

## Integration with Other Skills

| Skill | Relationship |
|-------|--------------|
| `create-specs` | Creates the specs this skill reviews |
| `review-specs` | Alternative review approach (more investigative) |
| `develop-specs` | Implements specs AFTER review feedback is addressed |

**Recommended workflow:**
1. `/create-specs` - Create spec documents
2. `/spec-feedback-reviewer` - Generate structured feedback.md
3. Address feedback, iterate until all items are ALIGNED/RESOLVED
4. `/develop-specs` - Begin implementation
