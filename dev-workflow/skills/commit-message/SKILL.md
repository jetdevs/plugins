---
name: commit-message
description: Generates contextual git commit messages by analyzing staged changes and current session context. Use when creating commits, reviewing staged changes, or when the user asks for a commit message.
---

# Commit Message Generator

Generate meaningful, contextual commit messages by combining:
1. Git staged changes analysis
2. Current session context from `ai/sessions/`

## Instructions

### Step 1: Read Current Session Context

1. Read the session filename from `ai/sessions/.current-session`
2. Read the full session file from `ai/sessions/{filename}`
3. Extract relevant context:
   - Summary of work being done
   - Active todos/tasks
   - Features or fixes in progress

### Step 2: Analyze Staged Changes

Run the following git commands:

```bash
# See what files are staged
git diff --staged --stat

# Get the full diff of staged changes
git diff --staged
```

Analyze:
- Which files are modified, added, or deleted
- What type of changes (feature, fix, refactor, docs, test, chore)
- Key code changes and their purpose

### Step 3: Review Recent Commits (Style Reference)

```bash
# Check recent commit message style
git log --oneline -10
```

Match the existing commit style (conventional commits, imperative mood, etc.)

### Step 4: Generate Commit Message

Create a commit message following these rules:

**Format**:
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `docs`: Documentation only changes
- `test`: Adding or updating tests
- `chore`: Maintenance tasks, dependencies, build changes
- `style`: Code style changes (formatting, semicolons, etc.)

**Guidelines**:
- Subject line: imperative mood, max 50 chars, no period
- Body: explain WHAT and WHY, not HOW
- Reference session context when relevant
- Include ticket/issue numbers if mentioned in session

### Step 5: Present Options

Present 2-3 commit message options:
1. **Concise**: Short, one-line message
2. **Detailed**: With body explaining the changes
3. **Contextual**: Including session/ticket references

## Example Output

Given staged changes to authentication and session file mentioning "user auth flow":

**Option 1 (Concise)**:
```
feat(auth): add session refresh on token expiry
```

**Option 2 (Detailed)**:
```
feat(auth): add session refresh on token expiry

Implement automatic token refresh when JWT expires during
active user session. This prevents users from being logged
out unexpectedly during long sessions.

- Add refresh token rotation logic
- Handle concurrent refresh requests
- Add retry with exponential backoff
```

**Option 3 (Contextual)**:
```
feat(auth): add session refresh on token expiry

Part of the user authentication flow improvements.
Implements automatic token refresh to improve UX.

Session: 2025-12-08-auth-improvements
```

## Notes

- Always read the session file first for context
- If no session file exists, proceed with git diff analysis only
- Ask user which option they prefer before committing
- Never commit without user confirmation
