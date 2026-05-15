#!/usr/bin/env bash
# Stop hook: run `npm test` at cwd when package.json exists. Requires bash, jq, npm.
# Uses `timeout 600` when the `timeout` command is available (GNU coreutils / busybox).
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo >&2 "ai-coding-hooks: npm-test-before-stop.sh requires jq"
  echo "{}"
  exit 0
fi

input=$(cat)

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

allow_stop_success() {
  if is_cursor_host; then
    if jq -e 'has("loop_count") and has("status")' <<<"$input" >/dev/null 2>&1; then
      echo "{}"
    else
      echo '{"permission":"allow"}'
    fi
  else
    echo "{}"
  fi
}

CWD=$(jq -r '.cwd // "."' <<<"$input")
CWD=$(cd "$CWD" && pwd)

if [[ ! -f "$CWD/package.json" ]]; then
  allow_stop_success
  exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
  allow_stop_success
  exit 0
fi

set +e
if command -v timeout >/dev/null 2>&1; then
  OUT=$(timeout 600 sh -c 'cd "$1" && export CI=true && npm test' _ "$CWD" 2>&1)
else
  OUT=$(sh -c 'cd "$1" && export CI=true && npm test' _ "$CWD" 2>&1)
fi
XS=$?
set -e

if [[ "$XS" -eq 0 ]]; then
  allow_stop_success
  exit 0
fi

DETAILS=$(printf '%s' "$OUT" | tail -c 8000)
MSG="npm test failed; fix failures before finishing.
${DETAILS}"

if is_cursor_host; then
  FM=$(printf '%s' "$MSG" | head -c 8000)
  jq -n --arg m "$FM" '{followup_message: $m}'
else
  jq -n --arg m "$MSG" '{decision: "block", reason: $m}'
fi
exit 0
