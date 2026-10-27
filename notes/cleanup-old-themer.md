---
id: cleanup-old-themer
aliases: []
tags: []
---
# Dotfiles / editor
 
- [ ] Prune arch-reference/themer/'s Python engine (main.py, input/,
      output/, .venv/, uv.lock, pyproject.toml) as dead code, now that the
      oreb Plymouth port is complete - deliberately left alone since it's a
      destructive delete of local files outside git (arch-reference/ is
      gitignored); do it whenever it's actually wanted.
