End the current development session by:

1. Check `_ai/sessions/.current-session` for active sessions

   **IMPORTANT PATH RULES**:
   - The `_ai/` folder is at the **MONOREPO ROOT** (`/Volumes/T9/code/_yobo/monorepo/_ai/`), NOT inside project folders
   - The folder is `_ai/` (with underscore prefix), NOT `ai/`

   **MULTIPLE SESSION SUPPORT**:
   - `.current-session` may contain **multiple active session filenames** (one per line)
   - Each session filename is prefixed with a project tag, e.g. `2026-02-09-[crm]-description.md`
   - To find the correct session, match the `[project-name]` prefix against the current working context
   - If `$ARGUMENTS` includes a project name or tag, use that to match
   - If only one session exists, use it
   - If multiple sessions exist and the correct one is ambiguous, list them and ask the user which to end

2. If no active session, inform user there's nothing to end
3. If the matching session exists, append a comprehensive summary including:
   - Session duration
   - Git summary:
     * Total files changed (added/modified/deleted)
     * List all changed files with change type
     * Number of commits made (if any)
     * Final git status
   - Todo summary:
     * Total tasks completed/remaining
     * List all completed tasks
     * List any incomplete tasks with status
   - Key accomplishments
   - All features implemented
   - Problems encountered and solutions
   - Breaking changes or important findings
   - Dependencies added/removed
   - Configuration changes
   - Deployment steps taken
   - Lessons learned
   - What wasn't completed
   - Tips for future developers
4. If ## Lessons Learned section exists, update `.claude.md` and relevant standards documents in `ai/arch` folder with lessons.
5. Update section called **Context Documents** with any documents including requirements and code referenced during the session that would be useful for another AI agent to quickly get up-to-speed on the current session.
6. **Remove only the matching session's line** from `_ai/sessions/.current-session` (do NOT clear the entire file — other sessions may still be active). If this was the last session, the file will be empty.
7. Inform user the session has been documented

The summary should be thorough enough that another developer (or AI) can understand everything that happened without reading the entire session.