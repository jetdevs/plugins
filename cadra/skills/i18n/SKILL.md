---
name: i18n
description: Use when working on internationalization, translations, locale management, language switcher, next-intl, RTL support, or translation keys in cadra-web. Also use when the user mentions "i18n", "translation", "locale", "language", "internationalization", or "multilingual".
---

# CadraOS Internationalization (i18n)

Full i18n implementation using next-intl v4 with 13 locales and 2,721+ translation keys.

## Architecture

- **Library**: next-intl v4
- **Locale Detection**: Cookie-based (`locale` cookie) — no URL prefix routing
- **Fallback**: English via `deepMerge` in `request.ts` (overlays locale on English base)
- **RTL**: Arabic (`ar`) and Hebrew (`he`) configured as RTL, `dir="rtl"` on `<html>`
- **Provider**: `NextIntlClientProvider` in root layout with `messages` and `locale` props

## Key Files

```
cadra-web/src/
  i18n/
    config.ts         # 13 locales, RTL support config
    request.ts        # deepMerge English fallback for missing keys
    actions.ts        # Server action to set locale cookie
  translations/       # MUST live inside src/ (Vercel can't resolve ../../ paths)
    en.json           # Master — 2,721+ keys across 25 namespaces
    es.json, fr.json, de.json, pt.json, ja.json, ko.json,
    zh.json, zh-HK.json, ar.json, he.json, id.json, ms.json
  components/i18n/
    HeaderLanguageSwitcher.tsx  # Flag emoji grid in header
```

## Usage Pattern

```typescript
// Client components
import { useTranslations } from 'next-intl';
const t = useTranslations('namespace');
t('key')                          // Simple
t('key', { variable })            // Interpolation
t('key', { count })               // Pluralization (ICU)

// Server components
import { getTranslations } from 'next-intl/server';
const t = await getTranslations('namespace');
```

## Translation Namespaces (25)

| Namespace | Keys | Coverage |
|-----------|------|----------|
| knowledgeBases | 302 | List, detail, chat, create, settings |
| settings | 263 | Profile, security, preferences, org, users, API keys |
| models | 241 | Pages, build/connect/update dialogs |
| agents | 236 | Data tables, wizard, teams, executions |
| decisioning | 232 | Tables, variables, detail pages |
| workforce | 414+ | Agent detail tabs, team config, executions |
| tools | 182 | Data table, form dialog, credentials |
| prompts | 142 | Data table, create/edit, versions |
| credits | 129 | Admin, badges, balance, purchase |
| billing | 98 | Settings, alerts, invoices, plans |
| auth | 71 | Login, register, forgot/reset password |
| common | 66 | Shared buttons, labels, status |
| nav | 22 | Sidebar items |
| dashboard | 22 | Welcome, quick actions |

## Critical Rules

### File Location
Translation files MUST live inside `src/` (at `src/translations/`). Webpack on Vercel cannot resolve `../../` paths that escape the source tree — dynamic imports, static imports, and `fs.readFileSync` all fail. Use static top-level imports from within `src/`.

### ICU Message Format
- Plurals: `{count, plural, one {# item} other {# items}}`
- Double curly braces (template vars like `{{variable_name}}`) MUST be escaped as `'{{variable_name}}'` — next-intl throws `MALFORMED_ARGUMENT`
- Tech terms (API, SDK, RAG, JSON) stay in English across all locales

### deepMerge Fallback
- `request.ts` loads English as base and overlays locale translations
- Prevents `MISSING_MESSAGE` errors for incomplete locale files
- **Warning**: If locale has `signOut: "Logout"` (string) but English has `signOut: { title, description }` (object), deepMerge replaces the object — validate structure consistency

### Complete Translation Coverage
- Every locale file MUST have complete translations — don't rely on English fallback
- English fallback "technically works" but shows mixed-language UI
- After merging feature branches, audit locale files for missing new keys
- Quick verify: `node -e "require('./src/translations/zh.json').namespace?.key"`

## Language Switcher

- Located in top-right header (`HeaderLanguageSwitcher.tsx`)
- Flag emojis in 2-column grid, alphabetically sorted
- Sets `locale` cookie via server action
- Also in mobile nav

## Adding New Translation Keys

1. Add keys to `src/translations/en.json` in the correct namespace
2. Add translations to ALL 12 non-English locale files simultaneously
3. Validate ICU syntax (escape `{{...}}` as `'{{...}}'`)
4. Verify structure matches between English and locale files

## SDK-Provided Strings

SDK factory components (e.g., `createOrgSwitcherFactory`) have hardcoded English strings. Override at app level with `t()` calls. Example: `sessionTimeoutOptions.label` overridden in `SessionManagement.tsx`.

## Parallel Agent Strategy (for bulk translation)

- Split work by module/extension (not by file type)
- Each agent writes to separate `_*-keys.json` file
- Merge into `en.json` afterward to avoid conflicts
- Run structure validation after all agents complete
- Translation agents work best with COMPLETE `en.json` → COMPLETE locale file

## Reference Documentation

- i18n config: `cadra-web/src/i18n/config.ts`
- Request handler: `cadra-web/src/i18n/request.ts`
- Master translations: `cadra-web/src/translations/en.json`
- Next-intl docs: Use context7 to fetch latest `next-intl` documentation
