# bubu-brain hardware

Super low priority - it's a glowing light, not a functional problem, and the
root-cause chase already turned out deeper than expected (SMBus RGB chip
readiness timing, not the kernel param originally suspected - see
[[bubu-brain-rgb-race-root-cause|bubu-brain RGB race root-cause]]). Revisit
only if it comes up naturally, not worth deliberately spending time on.

- [x] Root-caused RAM RGB staying on after a cold power off/on - see [[bubu-brain-rgb-race-root-cause|bubu-brain RGB race root-cause]].
      Fixed in hosts/bubu-brain/rgb.nix. Deployed and manually verified
      working; still wants confirmation across a few more real cold
      power-on cycles since that's the actual race being fixed - low
      priority, not worth chasing further right now.
