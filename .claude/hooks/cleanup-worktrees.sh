#!/usr/bin/env bash
# Removes clean, unlocked worktrees under .claude/worktrees/ at session end.
# Never touches locked worktrees (an active session holds the lock) or ones
# with uncommitted changes - `git worktree remove` refuses those anyway, but
# checking status first avoids even attempting it. Branches/commits are never
# deleted, only the working-directory checkout.
set -u

common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
main_root=$(dirname "$common_dir")

git -C "$main_root" worktree list --porcelain | awk '
  /^worktree / { path=$2; locked=0; bare=0 }
  /^locked/    { locked=1 }
  /^bare/      { bare=1 }
  /^$/         { if (path != "" && !locked && !bare) print path; path="" }
  END          { if (path != "" && !locked && !bare) print path }
' | while IFS= read -r wt; do
  case "$wt" in
    "$main_root"/.claude/worktrees/*) ;;
    *) continue ;;
  esac
  [ -d "$wt" ] || continue
  if [ -z "$(git -C "$wt" status --porcelain 2>/dev/null)" ]; then
    git -C "$main_root" worktree remove "$wt" 2>/dev/null || true
  fi
done

git -C "$main_root" worktree prune >/dev/null 2>&1 || true
