---
name: plugin-authoring
description: Use when creating or improving Claude Code plugin agents, skills, or plugin structure. Also use when the user mentions "write agent", "write skill", "agent description", "skill description", "trigger phrases", "plugin structure", "agent examples", or "SKILL.md".
---

# Plugin Authoring Patterns

Best practices for writing high-quality Claude Code agents, skills, and plugin structures. These patterns are derived from the monorepo's 9 active plugins.

## Agent Definition (`agents/{name}.md`)

### Frontmatter
```yaml
---
name: agent-name           # kebab-case, descriptive
description: ...           # See "Agent Description" below
model: opus                # opus for complex domain agents, sonnet for simpler ones
color: cyan                # Unique per plugin: cyan, purple, green, blue, orange, etc.
---
```

### Agent Description (CRITICAL)

The description field is the most important part — it controls when Claude Code triggers the agent.

**Structure**: `Use this agent for [domain]. This agent specializes in [areas].\n\nExamples:\n- <example>...</example>`

**Rules**:
- First sentence: broad domain trigger ("developing the CadraOS AI SaaS platform")
- Second sentence: specific specializations as a comma-separated list
- 3-7 examples covering the most common tasks
- Each example: Context line, user quote, assistant quote, commentary with reasoning

**Example Pattern**:
```
<example>
  Context: [Brief situation description]
  user: "[Realistic user request]"
  assistant: "I'll use the {agent-name} agent to [action]"
  <commentary>
  [Why this agent is the right choice — mention specific knowledge required]
  </commentary>
</example>
```

**Trigger Diversity**: Examples should cover different task types:
- Creating new features/modules
- Fixing bugs in specific areas
- Optimizing performance
- Working with specific technology (Stripe, i18n, SSE, etc.)
- UI/UX changes

### System Prompt Structure

Follow this proven template (from cadra-dev, yobo-dev, crm-dev):

```markdown
You are a [Role] specializing in [domain]. You have deep expertise in [technologies].

## Communication Style
Be concise. Fragments OK. Code > words. No greetings or filler.

## Skills Available
Invoke these skills when relevant:
- `{plugin}:{skill}` — [brief description]

## Platform Architecture
[Directory tree showing key paths]

## Key Patterns
[3-5 most important code patterns with examples]

## Context Loading
### Phase 1: Always Load
[Files to read on every task]
### Phase 2: Architecture
[Authoritative architecture docs]
### Phase 3: Patterns (task-based)
[Pattern files loaded based on task type]
### Phase 4: Feature-Specific
[Feature docs loaded as needed]

## Reference Documentation
[Table or list mapping feature areas to doc paths]
```

### Agent Quality Checklist
- [ ] Description has 3+ examples with diverse task types
- [ ] System prompt lists all available skills
- [ ] Architecture section reflects current directory structure
- [ ] Key patterns include actual code snippets
- [ ] Context loading has clear phases (always → architecture → task-based → feature)
- [ ] Reference documentation paths are current (not stale)

## Skill Definition (`skills/{name}/SKILL.md`)

### Frontmatter
```yaml
---
name: skill-name           # kebab-case, matches directory name
description: Use when working on [area]. Also use when the user mentions "[trigger1]", "[trigger2]", or "[trigger3]".
---
```

### Skill Description (CRITICAL)

**Structure**: Two sentences joined by "Also use when".
1. First sentence: describe the work context ("Use when working on billing UI, credits system, Stripe integration")
2. Second sentence: list explicit trigger phrases ("Also use when the user mentions 'billing', 'credits', 'stripe'")

**Trigger Phrase Rules**:
- Include both technical terms AND casual terms users might say
- Include the feature name, technology name, and common abbreviations
- Example: "billing", "credits", "stripe", "subscription", "site license", "plan upgrade"
- 4-8 trigger phrases is the sweet spot

### Skill Body Structure

Follow this proven template:

```markdown
# [Feature Area Name]

[One-line description of what this skill covers]

## Architecture / Extension Structure
[Directory tree or component diagram]

## Key Files
[Table or list of important files with paths]

## [Feature Section 1]
### Subsection
[Patterns, code examples, file paths]

## [Feature Section 2]
...

## Critical Rules / Critical Patterns
[Must-follow rules, common pitfalls, anti-patterns]

## Reference Documentation
[Links to _context/ docs, source files]
```

### Skill Body Rules
- **Imperative form**: "Always use X", "Never do Y" (not "You should consider X")
- **Code > prose**: Include actual code patterns, not just descriptions
- **File paths**: Always include full paths from repo root
- **Progressive disclosure**: Most important info first, details later
- **1,500-2,500 words**: Long enough to be useful, short enough to not overwhelm context
- **No duplication**: If another skill covers it, reference that skill instead

### Skill Quality Checklist
- [ ] Description has both context trigger AND explicit trigger phrases
- [ ] Body starts with architecture/structure overview
- [ ] All code patterns are copy-pasteable
- [ ] File paths are absolute from repo root
- [ ] Critical rules section exists for gotchas
- [ ] Reference documentation section links to _context/ docs
- [ ] No stale file paths (verify key ones exist)

## Plugin Structure

### Directory Layout
```
plugins/{name}/
  .claude-plugin/
    plugin.json           # Required manifest
  agents/
    {name}-dev.md         # Primary development agent (optional)
  skills/
    {area-1}/SKILL.md     # One skill per feature area
    {area-2}/SKILL.md
  hooks/
    hooks.json            # PostToolUse/Stop hook definitions (optional)
    *.sh                  # Hook scripts (optional)
```

### plugin.json
```json
{
  "name": "{name}",
  "description": "{one-line description}",
  "version": "1.0.0",
  "author": { "name": "JetDevs Team" },
  "keywords": ["{word1}", "{word2}", "{word3}"]
}
```

### Naming Conventions
| Component | Convention | Example |
|-----------|-----------|---------|
| Plugin dir | kebab-case | `cadra`, `dev-workflow` |
| Agent file | `{name}.md` | `cadra-dev.md` |
| Skill dir | kebab-case | `billing-subscriptions` |
| Skill file | Always `SKILL.md` | `skills/billing-subscriptions/SKILL.md` |

### Skill Naming Rules

Skill names must clearly communicate **what the skill does** and **who acts**. A reader should understand the skill's purpose from the name alone without reading the description.

**Name by action, not by tool or actor:**
| Good | Bad | Why |
|------|-----|-----|
| `codex-review` | `spec-feedback-reviewer` | Tells you it launches Codex, not that "someone reviews feedback" |
| `address-feedback` | `review-specs-gpt5` | Tells you Claude addresses feedback, not "GPT-5 reviews specs" |
| `create-specs` | `spec-writer` | Action-oriented, not role-oriented |

**Rules:**
- Use `verb-noun` format: `create-specs`, `address-feedback`, `build-index`
- Name for what the skill DOES, not what it IS
- If multiple actors are involved in a workflow, name each skill for the actor that runs it:
  - `codex-review` — Claude launches Codex (Codex acts)
  - `address-feedback` — Claude processes feedback (Claude acts)
- Never name a Claude skill after another AI system (e.g., `review-specs-gpt5` confuses who acts)
- If a skill is a thin launcher for an external tool, name it `{tool}-{action}`: `codex-review`, not `launch-codex-for-spec-review`

**Multi-step workflow naming:**
When skills form a pipeline, names should read as a sequence:
```
/create-specs → /codex-review → /address-feedback → /codex-review → /develop-specs
```
Each name answers "what happens at this step?" not "what system is involved?"

### Avoiding Duplication

Before creating a new skill, check for overlap:

1. **Search existing skills** — `grep -r "description:" plugins/*/skills/*/SKILL.md` and look for similar trigger phrases
2. **Check for actor confusion** — Two skills that do the same thing but are named for different actors (e.g., `review-specs-gpt5` and `spec-feedback-reviewer` both "review specs")
3. **Check for scope overlap** — A broad skill and a narrow skill covering the same area (e.g., `review-feedback` duplicating `spec-feedback-reviewer`)

**Resolution:** If two skills overlap, merge into one with the clearer name. If they serve different actors in a workflow, give each a distinct action-oriented name.

### Agent vs Skill Separation

Agents and skills must not duplicate content:

| Agent contains | Skill contains |
|---------------|----------------|
| WHAT/WHEN (workflow, orchestration, inventory) | HOW (templates, patterns, checklists) |
| Ecosystem inventory (plugin list, skill counts) | Writing standards (frontmatter format, body structure) |
| Decision logic (gap analysis, update planning) | Quality checklists (trigger phrases, file paths) |
| Context loading order | Naming conventions, grouping strategy |

**Rule:** If the agent says "create a skill," it should invoke the skill for HOW. The agent should never contain templates or formatting rules that belong in the skill.

### One Agent Per Plugin (Guideline)
Most plugins have one primary agent (e.g., `cadra-dev`, `yobo-dev`, `crm-dev`). Exception: `dev-workflow` has two agents for different roles. Only add a second agent when the domains are truly distinct.

## Skill Grouping Strategy

Group skills by **feature area**, not by file type or action type:

**Good grouping** (by feature area):
- `billing-subscriptions` — all billing, credits, Stripe, plans
- `agents-playground` — all agent config, playground, execution
- `i18n` — all internationalization

**Bad grouping** (by action type):
- `database-skills` — too broad, spans all features
- `ui-components` — too broad, spans all features
- `api-endpoints` — too broad, mixes unrelated domains

### When to Create a New Skill vs Update Existing
- **New skill**: Feature area has 3+ distinct patterns AND is independently triggerable
- **Update existing**: Feature is a sub-aspect of an existing skill's domain
- **Rule of thumb**: If a user would say "I'm working on X" and X maps cleanly to one skill, the grouping is right

## Cross-Plugin Patterns

### Shared Skills
Some skills are referenced across plugins:
- `sdk:migrate-extension` — Used by cadra, yobo, crm agents
- `browser-testing` — Used by cadra, yobo, crm agents
- Reference with full qualified name: `{plugin}:{skill}`

### Consistent Terminology
All plugins in this monorepo use:
- `@jetdevs/*` SDK stack (NOT `@yobolabs/*`)
- `createRouterWithActor` for tRPC routers
- `_context/` for documentation
- `_ai/sessions/` for session files
- Extension pattern: schema, types, schemas, repository, router, client, index, components/
