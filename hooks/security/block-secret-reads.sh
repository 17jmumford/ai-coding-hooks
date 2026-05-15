#!/usr/bin/env bash
# Self-contained: no Python, no sibling _lib. Requires: bash, jq.
# stdin: agent hook JSON (Cursor beforeReadFile, or Claude/Codex Read PreToolUse).
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo >&2 "ai-coding-hooks: block-secret-reads.sh requires jq on PATH"
  echo "{}"
  exit 0
fi

input=$(cat)
PATH_RAW=$(jq -r '
  .file_path // .tool_input.file_path // .tool_input.path // .tool_input.target_file // ""
' <<<"$input")

deny_cursor() {
  local r=$1
  jq -n --arg r "$r" '{permission:"deny",user_message:$r}'
}

deny_claude_family() {
  local r=$1 ev=$2
  jq -n --arg r "$r" --arg ev "$ev" \
    '{hookSpecificOutput:{hookEventName:$ev,permissionDecision:"deny",permissionDecisionReason:$r}}'
}

allow_out() {
  if jq -e '.hook_event_name != null' <<<"$input" >/dev/null 2>&1; then
    echo "{}"
  elif jq -e 'has("file_path") and has("content")' <<<"$input" >/dev/null 2>&1; then
    jq -n '{permission:"allow"}'
  else
    jq -n '{permission:"allow"}'
  fi
}

if [[ -z "$PATH_RAW" ]]; then
  allow_out
  exit 0
fi

# Normalize for substring checks (tilde expanded paths from agents are usually absolute)
LOWER=$(echo "$PATH_RAW" | tr '[:upper:]' '[:lower:]')
BASE=$(basename "$PATH_RAW" | tr '[:upper:]' '[:lower:]')
REASON=""

if [[ "$BASE" == ".env" ]] || [[ "$BASE" == .env.* ]]; then
  if [[ "$BASE" != *example* ]] && [[ "$BASE" != *sample* ]]; then
    REASON="blocked read: environment file"
  fi
fi

if [[ -z "$REASON" ]] && [[ "$LOWER" == *"/.ssh/"* ]]; then
  case "$BASE" in
    id_rsa|id_ed25519|id_ecdsa) REASON="blocked read: SSH private key material" ;;
    *.pem|*_rsa|*_ed25519) REASON="blocked read: SSH key-like file" ;;
  esac
fi

if [[ -z "$REASON" ]] && [[ "$LOWER" == *"/.aws/"* ]] && [[ "$BASE" == "credentials" ]]; then
  REASON="blocked read: AWS CLI config"
fi

if [[ -z "$REASON" ]] && [[ "$BASE" == ".netrc" || "$BASE" == ".git-credentials" ]]; then
  REASON="blocked read: credential store"
fi

if [[ -z "$REASON" ]] && echo "$LOWER" | grep -qE 'gcloud[/\\]application_default_credentials\.json$'; then
  REASON="blocked read: GCP ADC file"
fi

if [[ -z "$REASON" ]] && [[ "$LOWER" == *"/.kube/"* ]] && [[ "$BASE" == "config" ]]; then
  REASON="blocked read: kubeconfig"
fi

if [[ -n "$REASON" ]]; then
  if jq -e '.hook_event_name != null' <<<"$input" >/dev/null 2>&1; then
    EV=$(jq -r '.hook_event_name // "PreToolUse"' <<<"$input")
    deny_claude_family "$REASON" "$EV"
  else
    deny_cursor "$REASON"
  fi
  exit 0
fi

allow_out
exit 0
