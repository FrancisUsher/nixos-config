# bubu-brain hardware

Super low priority - it's a glowing light, not a functional problem. Low
priority does NOT mean fixed, see below - don't let that ambiguity recur.

- [ ] RAM RGB staying on after a cold power off/on is **not actually fixed**,
      despite earlier notes here previously (wrongly) claiming it was
      root-caused, fixed, and verified working. Confirmed still broken
      2026-09-02: `openrgb-off.service` reports success in
      `journalctl` ("Profile loaded successfully", exit 0, ran ~5h before
      this was checked) and the RGB is visibly still on. See
      [[bubu-brain-rgb-race-root-cause|bubu-brain RGB race root-cause]] for
      what's actually known - the retry-wrapper "fix" in
      hosts/bubu-brain/rgb.nix is trusting a success string that evidently
      doesn't mean what it was assumed to mean. Not being actively worked -
      revisit only if someone wants to dig in, no target date.
