---
name: codex-review
description: Launch Codex (GPT-5) to review spec documents or re-review Claude's feedback responses. Use when you want an external AI review of specs, when the user says "codex review", "gpt5 review", "launch codex", "get external review", or when you need to trigger a re-review after addressing feedback items.
---

# Codex Review

Launch Codex CLI to get an external GPT-5 review of spec documents. Codex runs asynchronously and writes `feedback.md` in the spec folder.

## Context

Codex has its own skill (`spec-feedback-reviewer`) at `~/.codex/skills/` that knows how to review specs and produce structured feedback. This Claude skill just launches Codex with the right arguments.

**Automatic trigger:** The PostToolUse hook on `create-specs` already auto-launches Codex. Use this skill for:
- Manual re-reviews after addressing feedback
- Initial reviews when the hook didn't fire
- Re-reviews after significant spec changes

## Instructions

### Step 1: Determine the Spec Folder

Identify the spec folder path (relative to project root):

```bash
ls _context/{project}/{feature-name}/
```

Confirm these files exist:
- `specs.md` or `prd.md` (at minimum)
- `feedback.md` (if this is a re-review)

### Step 2: Determine Review Type

**Initial review** (no feedback.md yet):
```bash
codex exec "/spec-feedback-reviewer @_context/{project}/{feature}/"
```

**Re-review** (after Claude addressed feedback in feedback.md):
```bash
codex exec "Review Claude's responses to your (GPT5) feedback in @_context/{project}/{feature}/feedback.md alongside @_context/{project}/{feature}/specs.md, @_context/{project}/{feature}/prd.md, @_context/{project}/{feature}/implementation.md, and @_context/{project}/{feature}/story_list.json. For each item where Claude responded, evaluate whether the response is architecturally sound, logically consistent with the specs, and actually resolves the concern. Look for: architectural problems introduced by the response, logical disconnects between the response and existing spec decisions, conflicts with other parts of the spec, misalignments across prd/specs/implementation/stories, redundancies created by the changes, and cases where Claude dismissed valid feedback without adequate justification. Add your assessment as sub-bullets prefixed with 'Codex:' under each item."
```

### Step 3: Launch and Monitor

Run the codex command:
```bash
nohup codex exec "<prompt>" > /tmp/codex-spec-review-latest.log 2>&1 &
```

Tell the user:
- Codex is running in the background
- It will write/update `feedback.md` in the spec folder
- Check progress: `ps aux | grep codex`
- Fallback log: `/tmp/codex-spec-review-latest.log`

### Step 4: After Codex Completes

Once Codex finishes, invoke `/address-feedback` to process the feedback items.

## Notes

- Codex runs with `--sandbox workspace-write` so it CAN write feedback.md directly
- If Codex fails to write (permissions issue), capture output from the log file and write feedback.md manually
- The PostToolUse hook at `hooks/codex-spec-review.sh` handles automatic launches after `create-specs`

## Integration

| Skill | Relationship |
|-------|--------------|
| `create-specs` | Creates specs; hook auto-launches Codex after |
| `address-feedback` | Claude processes Codex's feedback output |
| `develop-specs` | Implements specs after feedback cycle completes |
