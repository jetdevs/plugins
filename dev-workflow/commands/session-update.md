Update the current development session by:

1. Check if `_ai/sessions/.current-session` exists to find active sessions.

   **IMPORTANT PATH RULES**:
   - The `_ai/` folder is at the **MONOREPO ROOT** (`/Volumes/T9/code/_yobo/monorepo/_ai/`), NOT inside project folders
   - NEVER create `_ai/` inside project folders like `core-saas/_ai/` or `cadra-web/_ai/`
   - The folder is `_ai/` (with underscore prefix), NOT `ai/`
   - Always navigate to monorepo root first before accessing `_ai/sessions/`

   **MULTIPLE SESSION SUPPORT**:
   - `.current-session` may contain **multiple active session filenames** (one per line)
   - Each session filename is prefixed with a project tag, e.g. `2026-02-09-[crm]-description.md`
   - To find the correct session, match the `[project-name]` prefix in the filename against the current working context (e.g. if working in `crm/`, match `[crm]`)
   - If `$ARGUMENTS` includes a project name or tag, use that to match
   - If only one session exists, use it
   - If multiple sessions exist and the correct one is ambiguous, list them and ask the user which to update

2. If no active session, inform user to start one with `/project:session-start`
3. If the matching session exists, append to the session file with:
   - Current timestamp
   - The update: $ARGUMENTS (or if no arguments, summarize recent activities)
   - Git status summary:
     * Files added/modified/deleted (from `git status --porcelain`)
     * Current branch and last commit
   - Todo list status:
     * Number of completed/in-progress/pending tasks
     * List any newly completed tasks
   - Any issues encountered
   - Solutions implemented
   - Code changes made
   - Update section called **Context Documents** with any documents including requirements and code referenced during the session that would be useful for another AI agent to quickly get up-to-speed on the current session.

Keep updates concise but comprehensive for future reference.

Example format:
```
### Update - 2025-06-16 12:15 PM

**Summary**: Implemented user authentication

**Git Changes**:
- Modified: app/middleware.ts, lib/auth.ts
- Added: app/login/page.tsx
- Current branch: main (commit: abc123)

**Todo Progress**: 3 completed, 1 in progress, 2 pending
- ✓ Completed: Set up auth middleware
- ✓ Completed: Create login page
- ✓ Completed: Add logout functionality

**Details**: [user's update or automatic summary]
```

4. Summarize coding and thinking-lessons learned from the session, and add to the session file under heading ## Lessons Learned

Example format of Lessons Learned:
```
## Lessons Learned

**Architecture Lessons**
- There should be be references to "tenant" in the code nor database schema.
- Source of truth for users' orgIds are the user table in the org_data JSON field. Do not reference user_roles table to find user's assigned orgs.

**UI/UX Lessons**
- Gold-Standard for management module UI/UX is Decisioning module

**Tools Lessons**
- Use jira_update_issue tool for creating parent-child and epic links.

**Always** update each instance of `claude.md` with the correct learnings and standards based on the context of the folder's files.

