# Sync check-hosts.sh via git instead of rsync

`check-hosts.sh` currently rsyncs the raw working tree to a scratch
directory on each remote host, then runs `nixos-rebuild build` there. Use
git instead: each host already has its own clone (`~/nixos-config`, from
bootstrap) - have it fetch and check out the branch under test there, then
build against that, rather than rsyncing files over.

- [ ] Work out the fetch mechanism as `pas` on each host.
