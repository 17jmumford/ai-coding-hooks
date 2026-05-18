#!/usr/bin/env bash
# Self-contained: post-edit golangci-lint run --fix then verify. Requires: bash, jq, golangci-lint.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo >&2 "ai-coding-hooks: golangci-lint-after-edit.sh requires jq"
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
  go) ;;
  *)
    allow_out
    exit 0
    ;;
esac

CWD=$(jq -r '.cwd // "."' <<<"$input")
if ! command -v golangci-lint >/dev/null 2>&1; then
  allow_out
  exit 0
fi

set +e
FIX_OUT=$(cd "$CWD" && golangci-lint run --fix "$FILE" 2>&1)
FIX_XS=$?
OUT=$(cd "$CWD" && golangci-lint run "$FILE" 2>&1)
XS=$?
set -e

if [[ "$XS" -eq 0 ]]; then
  allow_out
  exit 0
fi

MSG="golangci-lint run failed on ${FILE} (after --fix, exit ${FIX_XS}):
${OUT}"
if [[ -n "$FIX_OUT" && "$FIX_OUT" != "$OUT" ]]; then
  MSG="${MSG}

golangci-lint run --fix output:
${FIX_OUT}"
fi
feedback "$MSG"
exit 0
