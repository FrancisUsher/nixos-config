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
