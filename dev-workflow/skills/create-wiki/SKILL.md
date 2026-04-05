---
name: create-wiki
description: Creates comprehensive wiki documentation from specs, sessions, and code into structured topic folders with focused documents and indexes. Use when the user asks to "create a wiki", "write a guide", "document how X works", "create a comprehensive guide", "wiki for", "knowledge base for", or wants to turn scattered specs and session knowledge into organized reference documentation. Also use when the user wants to update or add to an existing wiki topic.
---

# Create Wiki

Create comprehensive, RAG-optimized wiki documentation by synthesizing knowledge from specs, development sessions, and source code into structured topic folders with focused documents.

## When to Use

- Creating a new wiki topic (e.g., "create a wiki guide for agent execution")
- Expanding an existing wiki with a new topic
- Turning scattered specs and session lessons into organized reference docs
- Documenting how a system works end-to-end for developer onboarding

## Output Structure

Each wiki topic lives in its own folder under a project's `_wiki/` directory:

```
_context/{project}/_wiki/
├── _master-index.md          ← Lists all topics (create if missing)
└── {topic-name}/
    ├── _index.md             ← Topic overview + document listing
    ├── overview.md           ← Architecture, concepts, system diagram
    ├── {aspect-1}.md         ← Focused guide on one aspect
    ├── {aspect-2}.md         ← Focused guide on another aspect
    ├── {aspect-N}.md
    └── key-files.md          ← File paths and responsibilities reference
```

## Execution

### Step 1: Determine Scope

Ask or determine:
1. **Project**: Which project does this wiki belong to? (cadra, yobo, crm, slides, etc.)
2. **Topic**: What system/feature/workflow to document? (e.g., "agent-execution", "billing", "permissions")
3. **Wiki root**: `_context/{project}/_wiki/{topic-name}/`

### Step 2: Research (Parallel)

The quality of a wiki depends on thorough research. Spawn up to 3 parallel research agents to gather material:

**Agent 1 — Specs Search**:
Search `_context/{project}/_specs/` for all specs related to the topic. For each spec found, extract: file path, summary, key technical details (endpoints, types, data flows), and current status (draft/implemented).

**Agent 2 — Sessions Search**:
Search `_ai/sessions/` for all sessions related to the topic. Focus on: Lessons Learned sections, Architecture Issues, bugs found and fixed, patterns discovered, code paths documented.

**Agent 3 — Code Exploration**:
Explore the actual codebase for the topic area. Map out: entry points, key functions and their signatures, how data flows between components, types and schemas, which files are involved.

Give each agent specific keywords to search for. Be thorough — a wiki that misses key aspects is worse than no wiki.

### Step 3: Plan Documents

Before writing, plan the document breakdown. Each document should cover one coherent aspect (~100-200 lines). The goal is self-contained documents that make sense when retrieved independently by a RAG system.

**Always include**:
- `_index.md` — Topic overview with document table
- `overview.md` — Architecture, concepts, system diagram, mode comparison
- `key-files.md` — File path reference across all repos involved

**Add topic-specific documents** based on the natural sub-domains found during research. For agent-execution these were: single-agent, team, direct-tool, context-propagation, streaming, efficiency. For a different topic the breakdown will be different.

Present the planned document list to the user before writing.

### Step 4: Write Documents

Write each document following these conventions:

**Frontmatter** (every document):
```yaml
---
type: wiki
topic: Human Readable Topic Name
updated: YYYY-MM-DD
tags: [relevant, semantic, tags]
---
```

**Writing principles**:
- **Self-contained sections**: Each `##` section should make sense if retrieved independently by a RAG system
- **Specific, not generic**: Use exact function names, file paths, error messages, type names
- **Explain WHY, not just WHAT**: "Changed X because Y was causing Z" not "Updated X"
- **Include code paths**: Show the actual flow with file references, not abstract descriptions
- **Diagrams as ASCII art**: Use code blocks with ASCII flow diagrams — they survive all rendering contexts
- **Cross-reference related docs**: Link to specs, sessions, and other wiki documents using relative paths
- **Include diagnostic tips**: How to verify something is working, common symptoms when it's not

**Document sizing**:
- Aim for 100-200 lines per document
- If a document exceeds 250 lines, split it into sub-topics
- `key-files.md` can be longer since it's a reference table

**_index.md format**:
```markdown
---
type: wiki-index
topic: Topic Name
updated: YYYY-MM-DD
---

# Topic Name

Brief description of the topic.

## Documents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Architecture, concepts |
| [Aspect 1](aspect-1.md) | What this covers |
| ...

## Quick Reference

(Optional: a compact cheat-sheet for the most common lookups)
```

### Step 5: Update Master Index

If `_context/{project}/_wiki/_master-index.md` exists, add the new topic to the Topics table. If it doesn't exist, create it:

```markdown
---
type: wiki-master-index
project: {project}
updated: YYYY-MM-DD
---

# {Project} Wiki

Brief description.

## Topics

| Topic | Path | Description |
|-------|------|-------------|
| [Topic Name](topic-name/_index.md) | `topic-name/` | What this topic covers |
```

### Step 6: Summary

Report what was created:
- Number of documents and total line count
- Sources referenced (which specs, sessions, code areas)
- Any gaps identified (areas where specs/sessions didn't cover something that should be documented)

## Quality Checklist

Before presenting to the user, verify:
- [ ] Every document has YAML frontmatter with type, topic, updated, tags
- [ ] `_index.md` lists all documents in the topic
- [ ] `_master-index.md` includes the topic
- [ ] No placeholder text ("TBD", "TODO", "fill in later")
- [ ] File paths reference actual files in the codebase
- [ ] Diagrams render correctly in plain text (ASCII art, not mermaid)
- [ ] Each document is self-contained (makes sense without reading others)
- [ ] `key-files.md` covers all repos involved in the topic
