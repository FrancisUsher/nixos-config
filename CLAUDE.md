# Working conventions

- Always work in a git worktree (use the EnterWorktree tool) before making any
  code changes in this repo, even in interactive sessions — not just
  background jobs. This keeps parallel agents from clobbering each other or
  the primary checkout.
