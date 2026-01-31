# TypeScript LSP Plugin

Provides TypeScript/JavaScript language intelligence for Claude Code.

## Features

Once installed, Claude gains:
- **Automatic diagnostics** - See type errors immediately after edits
- **Go to definition** - Jump to symbol definitions
- **Find references** - Find all usages of a symbol
- **Hover information** - Get type info on hover

## Prerequisites

Install the TypeScript language server:

```bash
npm install -g typescript typescript-language-server
```

## Supported Files

- `.ts`, `.tsx` - TypeScript
- `.js`, `.jsx` - JavaScript
- `.mts`, `.cts` - TypeScript modules
- `.mjs`, `.cjs` - JavaScript modules

## Troubleshooting

If you see `Executable not found in $PATH`:

```bash
# Verify installation
which typescript-language-server

# If not found, install globally
npm install -g typescript-language-server typescript
```

## Version

1.0.0
