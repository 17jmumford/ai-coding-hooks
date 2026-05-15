#!/usr/bin/env bash
# Self-contained: post-edit ESLint via npx. Requires: bash, jq, npx (Node).
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo >&2 "ai-coding-hooks: eslint-after-edit.sh requires jq"
  echo "{}"
  exit 0
fi

input=$(cat)

edited_file() {
  jq -r '
    def ti_path:
      if (.tool_input | type) == "object" then
        (.tool_input.file_path // .tool_input.path // .tool_input.target_file // "")
      else "" end;
    ti_path as $p |
    if ($p != "") then $p
    elif (.file_path != null and .file_path != "") and ((.edits != null) or (.hook_event_name == "PostToolUse")) then .file_path
    elif (.hook_event_name == "PostToolUse") and (.file_path != null and .file_path != "") then .file_path
    elif ((.tool_name // "") | test("Write")) and (.tool_input | type) == "object" then ti_path
    else "" end
  ' <<<"$input"
}

# Match hooks/quality/ruff-after-edit.py _detect_host for stdout JSON shape.
is_cursor_host() {
  local r
  r=$(jq -r --arg agent "${AI_HOOKS_AGENT:-}" '
    ($agent | ascii_downcase) as $a |
    if $a == "cursor" then "yes"
    elif $a == "codex" or $a == "claude-code" then "no"
    elif (has("loop_count") and has("status") and (.hook_event_name == null)) then "yes"
    elif (.hook_event_name != null) then "no"
    elif ((.command | type) == "string") and (.tool_name == null) then "yes"
    elif ((.tool_name | type) == "string") and (.tool_name != "") and (.hook_event_name == null) then "yes"
    elif ((.file_path | type) == "string") and (.file_path != "") and (.hook_event_name == null) then "yes"
    else "no" end
  ' <<<"$input")
  [[ "$r" == "yes" ]]
}

allow_out() {
  echo "{}"
}

feedback() {
  local msg=$1
  if is_cursor_host; then
    jq -n --arg t "$msg" '{
      additional_context: (if ($t|length) > 9500 then $t[0:9500] + "\n…(truncated)" else $t end)
    }'
  else
    jq -n --arg t "$msg" '{
      hookSpecificOutput: {
        hookEventName: "PostToolUse",
        additionalContext: (if ($t|length) > 9500 then $t[0:9500] + "\n…(truncated)" else $t end)
      }
    }'
  fi
}

FILE=$(edited_file)
if [[ -z "$FILE" ]]; then
  allow_out
  exit 0
fi

case "${FILE##*.}" in
  ts|tsx|js|jsx|mjs|cjs) ;;
  *)
    allow_out
    exit 0
    ;;
esac

CWD=$(jq -r '.cwd // "."' <<<"$input")
if ! command -v npx >/dev/null 2>&1; then
  allow_out
  exit 0
fi

set +e
OUT=$(cd "$CWD" && npx --no-install eslint "$FILE" 2>&1)
XS=$?
set -e

if [[ "$XS" -eq 0 ]]; then
  allow_out
  exit 0
fi

MSG="eslint failed on ${FILE}:
${OUT}"
feedback "$MSG"
exit 0
