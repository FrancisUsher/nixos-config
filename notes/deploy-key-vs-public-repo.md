# Deploy key vs public repo

Split out of [[bootstrap-improvements|Bootstrap improvements]] - a design
decision, not a mechanical cleanup task.

## The problem

BOOTSTRAP.md's x1nano section has the live installer clone the flake using a
dedicated read-only deploy key (generated per-host, added on GitHub, copied
onto the install USB, then installed into the target's `~/.ssh/` post-install
so `git pull` keeps working). This exists only because the repo is private.
Managing a private key file on a USB stick per install feels heavier than it
should be for something that's just read access to config with no real
secrets committed (secrets/ is gitignored, installed to /etc separately).

## Options

- **Keep per-host deploy keys (status quo).** Simple to reason about,
  revocable per host, but couples every fresh install to GitHub being
  reachable and to correctly handling a private key on removable media.
- **Make the repo public**, per [[repo-visibility|Repo visibility]]. Kills
  the auth problem outright - `git clone` over https needs no credentials
  for a public repo, on the live installer or anywhere else. Gated on that
  note's secret-scanning item landing first. If this happens, the whole
  deploy-key mechanism in BOOTSTRAP.md's x1nano section goes away as a
  side effect, not something to solve independently.
- **Vendor the repo onto the install USB stick** instead of cloning at
  install time. No network/auth dependency during install, but risks
  building from a stale checkout if the stick isn't refreshed before use.

## Where this landed

Resolved: the repo was never meant to stay private long-term - the
private/deploy-key setup was only ever meant to hold until secret scanning
was in place, not a deliberate long-term choice. So this isn't really a
deploy-keys-vs-alternatives design decision at all, just sequencing: add
secret scanning, go public (see [[repo-visibility|Repo visibility]]), and
the whole deploy-key mechanism in BOOTSTRAP.md's x1nano section goes away
as a side effect. No separate deploy-key work needed.
