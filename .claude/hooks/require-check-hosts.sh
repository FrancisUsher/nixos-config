#!/usr/bin/env bash
# PreToolUse hook (Bash matcher): before a `git commit` runs in this repo,
# run check-hosts.sh and block the commit if any host fails to build.
set -u

input=$(cat)

# Cheap text-only prefilter (no jq needed) so the vast majority of Bash
# calls - which don't mention "commit" at all - short-circuit instantly.
printf '%s' "$input" | grep -qi 'commit' || exit 0

if ! command -v jq >/dev/null 2>&1; then
  echo "require-check-hosts hook: this Bash call mentions 'commit' but jq isn't on PATH, so the hook can't confirm whether it's a real git commit. Blocking to be safe - install jq (environment.systemPackages) or fix PATH." >&2
  exit 2
fi

verdict=$(jq -r '
  if .tool_name != "Bash" then "skip"
  elif ((.tool_input.command // "") | test("(^|[;&|]|\\s)git\\s+commit(\\s|\"|$)")) then "commit"
  else "skip"
  end
' <<<"$input")

[ "$verdict" = "commit" ] || exit 0

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
check_script="$repo_root/check-hosts.sh"
[ -x "$check_script" ] || exit 0

output=$(cd "$repo_root" && ./check-hosts.sh 2>&1)
status=$?

if [ "$status" -ne 0 ] || printf '%s' "$output" | grep -q '\[FAIL\]'; then
  {
    echo "check-hosts.sh failed - commit blocked until every host builds clean."
    echo
    echo "$output"
  } >&2
  exit 2
fi

exit 0
