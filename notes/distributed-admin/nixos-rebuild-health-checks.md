# Post-rebuild health checks

Came up while chasing the tailscale/NetworkManager DNS-fight fix for
[[migrate-arch-laptop-to-nixos|the laptop migration]]: after `nixos-rebuild
switch`, how would we actually know something like MagicDNS silently broke,
short of hitting the failure by accident later? A few established options,
not yet adopted:

- [ ] `pkgs.nixosTest` (flake `checks.<system>.<name>`) - boots the config in
      a VM and asserts behaviors (service reaches active, a DNS query
      resolves, node A can ping node B). Validates the config is correct in
      principle at build time; doesn't touch real hardware/network, so it's a
      pre-deploy gate, not a post-deploy smoke test.
- [ ] A small post-switch smoke-test script (run by hand, from a
      Makefile/justfile target, or a systemd `ExecStartPost`) checking the
      handful of things that actually matter after a rebuild - e.g.
      `tailscale status` is `Running`, a known peer name resolves, `sshd` is
      listening.
- [ ] `deploy-rs` / `colmena` - flake-based deploy tools that support
      activate-then-health-check-then-auto-rollback. Specifically relevant
      for bubu-brain: it's reached over the network stack a bad config change
      could break, so a failed health check within N seconds could roll back
      automatically instead of requiring physical access to fix.
- [ ] `nixos-rebuild test` / `boot` instead of `switch` - no automation, but
      an already-built-in staged rollout (activate without making it the
      boot default, or defer to next reboot) worth using by habit for
      risky-looking changes even before any of the above exists.

## Distributed switch across the fleet, via pas

Now that every host has a `pas` automation user with sudo scoped to
`nixos-rebuild` (see the multi-host `check-hosts.sh` script, which only ever
calls `build`), the natural next step is letting a script also run `switch`
across hosts unattended. Researched what that needs to not be reckless -
none of this is adopted yet:

- [ ] **Pre-deploy gate**: a narrow `pkgs.nixosTest` in `checks.<system>.*`
      that boots just the `pas`/sudo/ssh module (not full real-hardware host
      configs, which won't evaluate cleanly in a VM) and asserts the actual
      privilege boundary - `pas` can run `nixos-rebuild`, can't run arbitrary
      sudo, can SSH host-to-host. Cheap per-eval once written, catches a
      privilege-escalation or lockout regression before it touches real
      hardware. A full multi-node network-topology replica (real tailscale
      etc.) isn't feasible in a VM and isn't worth chasing at 2-4 hosts.
- [ ] **Post-switch smoke test**: a short script run over SSH right after
      `switch` returns success (activation succeeding doesn't mean every
      unit came up) - `systemctl is-system-running`, `tailscale status`
      actually `Running` (this is the lifeline, tailscale not restoring
      cleanly after a unit change is a known nixpkgs issue - #409899),
      `sshd` active *and* actually listening, a known peer resolves/pings,
      `systemctl --failed` scan, plus whatever per-host service actually
      matters. Emit PASS/FAIL per check so a deploy loop can act on it.
- [ ] **Rollback**: prefer `nixos-rebuild test` over `switch` for anything
      pas-automates - it activates without becoming the boot default, so a
      hung/unreachable box self-heals on its next reboot with zero extra
      tooling. For a real automated loop: test -> smoke-test -> `boot` (or
      `switch`) to persist on pass, `switch --rollback` on fail-but-reachable.
      The gap: nothing forces a reboot if the box hangs on a bad activation
      without rebooting itself - closing that needs a dead-man timer
      (`systemd-run --on-active=N reboot`, armed before the switch and
      cancelled after a passing smoke test) armed with privileges beyond
      pas's current `nixos-rebuild`-only sudo scope.
      `deploy-rs` ships exactly this as "magic rollback" (target waits for a
      post-activate SSH confirmation within `confirmTimeout`, reverts itself
      if it doesn't arrive) and would be the lower-effort path to the real
      thing vs. hand-rolling it - `remoteBuild = true` keeps builds on the
      target, matching how `check-hosts.sh` already works. `colmena` doesn't
      have this (long-standing known gap); it'd mean hand-rolling the same
      logic deploy-rs already provides.
- [ ] **Observability**: `systemd` `OnFailure=` on the switch/smoke-test
      units firing a small notifier (ntfy/Pushover push, no server to run)
      beats journald shipping or a status dashboard for this scale - it
      pushes exactly when something needs a human, no polling required. A
      status file/dashboard is fine as a secondary "what's true right now"
      view later, not as the primary alert path.
