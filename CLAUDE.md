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
- When finished work needs merging in, merge it into `dev`, not `main` —
  `git fetch . <worktree-branch>:dev` (or plain `git merge` from a worktree
  already on `dev`) works with zero manual intervention because nothing
  ever has `dev` checked out. `main` stays checked out in the primary
  checkout for interactive use, so git refuses any worktree-isolated
  session that tries to update it directly (`refusing to fetch into branch
  'refs/heads/main' checked out at ...`) — that's not a bug to work
  around, it's why `dev` exists as a separate branch. Periodically fold
  `dev` into `main` from the primary checkout (`git merge dev`) at your
  own convenience; that step still needs a human, but it's batched instead
  of blocking every single task.
- Before merging into `dev`, run `./check-hosts.sh` from the worktree. It
  builds (not switches — no host's running config is touched) every host
  in `flake.nix`'s `nixosConfigurations` against the worktree's tree: the
  local host directly, others over SSH via their `pas-<host>` alias.
  `[SKIP]` for an unreachable host is fine to merge past; a `[FAIL]`
  means fix it before merging — it means the change breaks eval/build on
  a host you're not sitting at.

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
  main).
- Further research or iteration goes into issue comments as it happens —
  brief and technical, for future reference, not narrative.
- Commit messages stay concise (what and why), even for the commit that
  closes an issue. They are not an archive either — detailed blow-by-blow
  belongs in issue comments, not in `notes/` and not in the commit log.
- No ADRs or decision docs live in-repo at this scale. If something here
  ever gets architecturally complex enough to warrant one, that's a
  decision to make then, not the default now.
