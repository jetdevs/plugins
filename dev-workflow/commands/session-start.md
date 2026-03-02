Start a new development session by creating a session file in `_ai/sessions/` with the format `YYYY-MM-DD-[project]-$ARGUMENTS.md` (or just `YYYY-MM-DD-$ARGUMENTS.md` if no project context).

**IMPORTANT PATH RULES**:
- The `_ai/` folder is at the **MONOREPO ROOT** (`/Volumes/T9/code/_yobo/monorepo/_ai/`), NOT inside project folders
- NEVER create `_ai/` inside project folders like `core-saas/_ai/` or `cadra-web/_ai/`
- The folder is `_ai/` (with underscore prefix), NOT `ai/`

## Session Naming Convention
- Format: `YYYY-MM-DD-[project-name]-description.md`
- The `[project-name]` prefix identifies which monorepo project the session belongs to (e.g., `[crm]`, `[cadra-web]`, `[core-sdk]`)
- Example: `2026-02-09-[crm]-yobo-crm-specs-and-dev.md`

## Multiple Concurrent Sessions
The `.current-session` file supports **multiple active sessions** (one per line). Different Claude Code instances can work on different projects simultaneously.

The session file should begin with:
1. Session name and timestamp as the title
2. Session overview section with start time
3. Goals section (ask user for goals if not clear)
4. Empty progress section ready for updates

After creating the file, **append** the new session filename as a new line to `_ai/sessions/.current-session` (do NOT overwrite existing lines — other sessions may be active).

Confirm the session has started and remind the user they can:
- Update it with `/project:session-update`
- End it with `/project:session-end`

## Documentation Strategy
- Read @CLAUDE.md for core guidelines and documentation map
- Only read additional architecture documents when working on specific tasks:
  - Backend work: @.context/_arch/patterns-backend.md
  - Frontend work: @.context/_arch/patterns-frontend.md
  - Security tasks: @/ai/wiki/Permissions-Security-Handbook-concise.md
  - Debugging issues: @.context/_arch/lessons-*.md
- Check the session's **Context Documents** section for task-specific docs