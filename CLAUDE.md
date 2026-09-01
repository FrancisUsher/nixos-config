# Working conventions

- Always work in a git worktree (use the EnterWorktree tool) before making any
  code changes in this repo, even in interactive sessions — not just
  background jobs. This keeps parallel agents from clobbering each other or
  the primary checkout.
- Worktrees clean themselves up automatically: a SessionEnd hook
  (`.claude/hooks/cleanup-worktrees.sh`) removes any worktree under
  `.claude/worktrees/` that's unlocked and has no uncommitted changes when a
  session ends. It never touches a worktree an active session still holds
  the lock on, never touches dirty state, and never deletes branches — only
  the working-directory checkout. If a worktree's branch still needs
  attention, just re-enter it (`EnterWorktree` with `path`) or merge it;
  removing the checkout doesn't lose anything already committed and pushed.
