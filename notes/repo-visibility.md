# Repo visibility

- [x] Add automated secret scanning: gitleaks, both as a pre-commit hook
      (.githooks/pre-commit, wired up via `git config core.hooksPath
      .githooks` - bootstrap.sh now sets this on every clone) and a CI
      check (.github/workflows/gitleaks.yml, gitleaks/gitleaks-action@v2).
      pkgs.gitleaks added to home.nix so the binary is on PATH; the hook
      skips (doesn't block) if gitleaks isn't there yet, e.g. before the
      first home-manager switch on a fresh machine.
- [x] One-time full-history scan (`gitleaks detect --log-opts="--all"`)
      before making the repo public - clean, 46 commits, no leaks found
      (2026-09-02)
- [x] Make github.com/FrancisUsher/nixos-config public - done 2026-09-02.
      Unblocks [[deploy-key-vs-public-repo|Deploy key vs public repo]]'s
      resolution: hosts/x1nano/bootstrap-install.sh's plain `git clone`
      (no deploy key) now actually works.
