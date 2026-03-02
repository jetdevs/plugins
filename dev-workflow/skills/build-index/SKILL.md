---
name: build-index
description: Generates or updates AGENTS.md index files for directory trees. Use when the user asks to build an index, update an index, regenerate AGENTS.md, or wants a file listing in the pipe-delimited index format.
---

# Build Index

Generates AGENTS.md index files that serve as a compact, pipe-delimited directory listing for AI agents to navigate a codebase.

## Index Format

```
[Title]|root: ./relative/path
|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning
|dir/subdir:{file1.ext,file2.ext,file3.ext}
|dir/subdir/nested:{fileA.ext,fileB.ext}
```

**Format rules:**
- Line 1: `[Human-readable Title]|root: ./path/to/indexed/directory`
- Line 2: `|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning`
- Remaining lines: `|relative/path:{comma-separated sorted filenames}`
- Files directly in the root directory go on their own line: `|filename.ext`
- Directories are listed alphabetically, depth-first
- Files within each directory are listed alphabetically
- Binary files (images, etc.) are included in the listing
- No trailing commas inside `{}`

## AGENTS.md Placement

AGENTS.md files live at the **root of the web project**, not inside the indexed directory. This is because they serve as a navigation aid for agents working within that project.

**Placement rule:** `{project-root}/AGENTS.md` indexes a subdirectory within or related to that project.

**Known mappings in this monorepo:**

| Project Root | Indexed Directory | AGENTS.md Location |
|---|---|---|
| `cadra-web/` | `_context/cadra/` | `cadra-web/AGENTS.md` |

When the user asks to index a directory, determine which web project it belongs to and place the AGENTS.md at that project's root. If no project mapping exists, ask the user where to put it.

## Instructions

### Step 1: Identify the Target

Determine the directory to index. The user will specify a path like `_context/cadra` or `src/components`.

### Step 2: Determine Output Location

Place the AGENTS.md at the root of the web project that owns the indexed content. Check the mapping table above. If no mapping exists, ask the user which project root to use.

### Step 3: Scan the Directory

Use `Glob` with the pattern `{target}/**/*` to get a complete file listing. If results are truncated, run additional targeted globs on subdirectories to get the full picture.

### Step 4: Build the Index

1. Group files by their parent directory (relative to the target root)
2. Sort directories alphabetically (depth-first: parent before children)
3. Sort filenames alphabetically within each directory
4. Format each directory as: `|relative/dir:{file1,file2,file3}`
5. For files in the root directory, list them directly: `|filename.ext`

### Step 5: Write the AGENTS.md

Write the file to `{project-root}/AGENTS.md`. Use a descriptive title derived from the indexed directory name.

### Step 6: Report

Tell the user:
- Where the file was written
- What directory was indexed
- How many directories and files were indexed

## Examples

### Example 1: Simple Directory

Input directory:
```
src/
  components/
    Button.tsx
    Modal.tsx
  utils/
    helpers.ts
  index.ts
```

Output AGENTS.md:
```
[Source Code Index]|root: ./src
|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning
|index.ts
|components:{Button.tsx,Modal.tsx}
|utils:{helpers.ts}
```

### Example 2: Nested Directory

Input directory:
```
docs/
  _overview.md
  api/
    auth/
      login.md
      logout.md
    users.md
  guides/
    getting-started.md
```

Output AGENTS.md:
```
[Docs Index]|root: ./docs
|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning
|_overview.md
|api:{users.md}
|api/auth:{login.md,logout.md}
|guides:{getting-started.md}
```

## Notes

- Always use `Glob` to discover files rather than relying on memory or assumptions
- If the target already has an AGENTS.md, overwrite it with fresh data
- The AGENTS.md file itself should NOT appear in its own index
- PNG, JSON, HTML, and all other file types are included -- this is a complete listing
- When re-indexing, scan everything from scratch to catch additions and deletions
