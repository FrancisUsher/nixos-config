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

## Tracking work

- The `notes/` directory is the todo backlog. A small item is just a line
  in `notes/todo.md`; once it has real substance or grows past 2-3
  sub-items, split it into its own note under `notes/` and link it from
  `todo.md`. Either way it's "not started yet" — never a project log or a
  record of finished work.
- When a todo is picked up: if the fix is obvious, just make it — no issue
  needed.
- If it needs research or iteration, or is more than a few lines / a
  standard config block, open a GitHub issue on this repo before starting.
  Move the note's content into the issue body, then delete the note file
  and its `todo.md` entry.
- Commit footers reference the issue: `Refs #N` while work is ongoing,
  `Closes #N` on the commit that finishes it (auto-closes on merge to
  master).
- Further research or iteration goes into issue comments as it happens —
  brief and technical, for future reference, not narrative.
- No ADRs or decision docs live in-repo at this scale. If something here
  ever gets architecturally complex enough to warrant one, that's a
  decision to make then, not the default now.
