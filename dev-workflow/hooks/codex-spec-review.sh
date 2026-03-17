#!/bin/bash
set -euo pipefail

# PostToolUse hook: After create-specs completes, launch codex for spec review
# Triggered on Skill tool use, filters for create-specs skill only

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // ""')

# Only trigger for Skill tool
if [ "$tool_name" != "Skill" ]; then
  exit 0
fi

skill_name=$(echo "$input" | jq -r '.tool_input.skill // ""')

# Only trigger for create-specs skill (with or without namespace prefix)
if [[ "$skill_name" != "create-specs" && "$skill_name" != *":create-specs" ]]; then
  exit 0
fi

# Extract spec folder from skill args
skill_args=$(echo "$input" | jq -r '.tool_input.args // ""')
cwd=$(echo "$input" | jq -r '.cwd // "."')

spec_folder=""

# Try to extract _context path from args
if [[ "$skill_args" =~ _context/([a-zA-Z0-9_/.-]+) ]]; then
  spec_folder="_context/${BASH_REMATCH[1]}"
fi

# If no explicit path, try to find the most recently modified specs.md
if [ -z "$spec_folder" ]; then
  recent_spec=$(find "$cwd/_context" -name "specs.md" -maxdepth 4 -newer "$cwd/_context" 2>/dev/null | head -1 || true)
  if [ -n "$recent_spec" ]; then
    spec_folder=$(dirname "$recent_spec" | sed "s|^$cwd/||")
  fi
fi

# If still no folder found, check for prd.md as fallback
if [ -z "$spec_folder" ]; then
  recent_prd=$(find "$cwd/_context" -name "prd.md" -maxdepth 4 -newer "$cwd/_context" 2>/dev/null | head -1 || true)
  if [ -n "$recent_prd" ]; then
    spec_folder=$(dirname "$recent_prd" | sed "s|^$cwd/||")
  fi
fi

if [ -z "$spec_folder" ]; then
  echo '{"systemMessage": "codex-spec-review hook: Could not determine spec folder path from create-specs output. Skipping auto-review."}' >&2
  exit 0
fi

# Launch codex in background so it doesn't block Claude
nohup codex exec "/spec-feedback-reviewer @${spec_folder}" > /dev/null 2>&1 &

# Report back to Claude
echo "{\"systemMessage\": \"Launched codex spec review: codex exec \\\"/spec-feedback-reviewer @${spec_folder}\\\"\"}"
exit 0
