# Bootstrap improvements

- [x] "verify ssh/wifi" but presumably we're already connected to wifi because
      we just used git clone on a github repo. Anyway I think this verification
      should be scripted, not in the MD file. Done: `bootstrap.sh` now runs an
      automated pass/fail check (sshd, tailscaled, ping, DNS/HTTPS) after
      `nixos-rebuild switch`; the MD files just point at it plus the
      genuinely-manual second-session/captive-portal advice.
- [ ] There looks like a lot of stuff in the machine-specific setup that could
      be delegated to a script instead of written out in the MD file.
- [ ] I'm thinking we might just want to split out the bootstrapping MD files
      into separate ones for each purpose. So, some global bootstrapping in the
      root dir; but then some machine-specific bootstrpping in the hosts dirs.

Deploy-key auth design question split out to its own note - bigger decision
than the rest of this list, see [[deploy-key-vs-public-repo|Deploy key vs
public repo]].
