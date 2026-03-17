#!/bin/bash
set -euo pipefail

# PostToolUse hook: After create-specs or spec-feedback-reviewer completes, launch codex
# - create-specs → codex runs /spec-feedback-reviewer to review the new specs
# - spec-feedback-reviewer → codex reviews Claude's inline responses to GPT5's feedback in feedback.md

input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // ""')

# Only trigger for Skill tool
if [ "$tool_name" != "Skill" ]; then
  exit 0
fi

skill_name=$(echo "$input" | jq -r '.tool_input.skill // ""')

# Determine which skill triggered the hook
is_create_specs=false
is_feedback_reviewer=false

if [[ "$skill_name" == "create-specs" || "$skill_name" == *":create-specs" ]]; then
  is_create_specs=true
elif [[ "$skill_name" == "spec-feedback-reviewer" || "$skill_name" == *":spec-feedback-reviewer" ]]; then
  is_feedback_reviewer=true
fi

# Exit if neither skill matched
if [[ "$is_create_specs" == false && "$is_feedback_reviewer" == false ]]; then
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

# If no explicit path, try to find the most recently modified specs.md or feedback.md
if [ -z "$spec_folder" ]; then
  if [[ "$is_feedback_reviewer" == true ]]; then
    recent_file=$(find "$cwd/_context" -name "feedback.md" -maxdepth 4 -newer "$cwd/_context" 2>/dev/null | head -1 || true)
  else
    recent_file=$(find "$cwd/_context" -name "specs.md" -maxdepth 4 -newer "$cwd/_context" 2>/dev/null | head -1 || true)
  fi
  if [ -n "$recent_file" ]; then
    spec_folder=$(dirname "$recent_file" | sed "s|^$cwd/||")
  fi
fi

# Fallback: check for prd.md
if [ -z "$spec_folder" ]; then
  recent_prd=$(find "$cwd/_context" -name "prd.md" -maxdepth 4 -newer "$cwd/_context" 2>/dev/null | head -1 || true)
  if [ -n "$recent_prd" ]; then
    spec_folder=$(dirname "$recent_prd" | sed "s|^$cwd/||")
  fi
fi

if [ -z "$spec_folder" ]; then
  echo '{"systemMessage": "codex-spec-review hook: Could not determine spec folder path. Skipping."}' >&2
  exit 0
fi

# Build the codex command based on which skill triggered
if [[ "$is_create_specs" == true ]]; then
  codex_prompt="/spec-feedback-reviewer @${spec_folder}"
  action_desc="spec review"
elif [[ "$is_feedback_reviewer" == true ]]; then
  codex_prompt="Review Claude's responses to your (GPT5) feedback in @${spec_folder}/feedback.md alongside @${spec_folder}/specs.md, @${spec_folder}/prd.md, @${spec_folder}/implementation.md, and @${spec_folder}/story_list.json. For each item where Claude responded, evaluate whether the response is architecturally sound, logically consistent with the specs, and actually resolves the concern. Look for: architectural problems introduced by the response, logical disconnects between the response and existing spec decisions, conflicts with other parts of the spec, misalignments across prd/specs/implementation/stories, redundancies created by the changes, and cases where Claude dismissed valid feedback without adequate justification. Add your assessment as sub-bullets prefixed with 'Codex:' under each item."
  action_desc="feedback response review"
fi

# Launch codex in background so it doesn't block Claude
nohup codex exec "$codex_prompt" > /dev/null 2>&1 &

# Report back to Claude
echo "{\"systemMessage\": \"Launched codex ${action_desc}: codex exec \\\"${codex_prompt}\\\"\"}"
exit 0
