---
name: release-notes
description: This skill should be used when the user asks to "generate release notes", "create release notes", "write release notes", "summarize recent changes", "what shipped this week", or wants a changelog from session files. Also use when the user mentions "release notes", "changelog", or "update notes".
version: 0.1.0
---

# Release Notes Generator

Generate consolidated release notes from `_ai/sessions/` files. Reads session logs within a date range, groups changes by application, and writes a clear summary suitable for the whole team — not just engineers.

## When to Use

- The user asks for release notes, a changelog, or a summary of recent work
- The user wants to know what shipped in a given time period
- The user asks to summarize session files into an update

## Instructions

### Step 1: Determine Date Range

Ask the user for a date range if not provided. Session files are named with date prefixes like `2026-03-08-[app]-description.md`.

If the user says something like "this week" or "last sprint", convert to concrete dates.

### Step 2: Find Matching Session Files

List files in `_ai/sessions/` and filter by the date prefix.

```bash
ls _ai/sessions/
```

Select files whose date prefix falls within the requested range. Read each matching file.

### Step 3: Extract Changes Per Application

For each session file, extract:
- What was added (new features, new pages, new capabilities)
- What was fixed (bugs, broken behavior, performance issues)
- What was changed (redesigns, reorganization, renamed things)

Group these by application. Common apps in this monorepo: Yobo Merchant, Slides, CadraOS Platform (cadra-web), CadraOS SDK (cadra-sdk), Cadra API, Boost Global, Core SDK.

### Step 4: Write in Plain Language

This is the most important step. Release notes are for the **entire team**, not just developers.

**Writing rules:**
- Describe what changed from a user's perspective, not an engineer's
- Never mention file names, component names, CSS classes, config files, framework internals, or code patterns
- Never use terms like: SSR, CSP, RLS, tRPC, Zustand, Suspense, middleware, mutation, query invalidation, hydration, inline styles, postMessage, MutationObserver, Drizzle, Zod, barrel export
- Instead of "Fixed Suspense boundary causing double loading states", write "Pages no longer flash through multiple loading spinners before showing content"
- Instead of "Added RLS policies and permissions", write "Access controls ensure each organization can only see their own data"
- Instead of "Switched from @jetdevs/cloud/storage to @jetdevs/cloud", write "File uploads now work reliably in all environments"
- Focus on outcomes: what can users do now, what works better, what was broken and is now fixed

**Structure each app section with these categories (skip empty ones):**
- **New** — things that didn't exist before
- **Changed** — things that work differently now
- **Fixed** — things that were broken and are now working

**Tone:** Straightforward, factual, no marketing language. This is an internal team update, not a press release. Don't oversell or use superlatives.

### Step 5: Write the File

Save to `_ai/sessions/YYYY-MM-DD-release-notes.md` using today's date.

Use this structure:

```markdown
# Release Notes — [Date Range]

---

## [App Name]

### New
- [Plain description of new capability]

### Changed
- [Plain description of what's different]

### Fixed
- [Plain description of what was broken and is now working]

---

## [Next App]
...
```

### Step 6: Review with User

Present the draft and ask if any sections need adjustment. Common feedback:
- Too technical — simplify further
- Missing context — add more detail about a specific change
- Wrong grouping — move items between apps
- Scope — include or exclude certain sessions

## Additional Resources

### Reference Files
- **`references/tone-guide.md`** — Examples of good vs bad release note language with before/after rewrites
