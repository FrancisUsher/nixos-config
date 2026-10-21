---
id: bubu-brain-hardware
aliases: []
tags: []
---
# bubu-brain hardware

## Turning off annoying RGBs in case

Super low priority - it's a glowing light, not a functional problem. Low
priority does NOT mean fixed, see below - don't let that ambiguity recur.

- [ ] RAM RGB staying on after a cold power off/on is **not actually fixed**,
      despite earlier notes here previously (wrongly) claiming it was
      root-caused, fixed, and verified working. Confirmed still broken
      2026-09-02: `openrgb-off.service` reports success in
      `journalctl` ("Profile loaded successfully", exit 0, ran ~5h before
      this was checked) and the RGB is visibly still on. See
      the below section with claude's notes for
      what's actually known - the retry-wrapper "fix" in
      hosts/bubu-brain/rgb.nix is trusting a success string that evidently
      doesn't mean what it was assumed to mean. Not being actively worked -
      revisit only if someone wants to dig in, no target date.

### Some more notes from this that claude put together

Not the `acpi_enforce_resources=lax` kernel param (never actually the issue -
dmesg never logged an ACPI resource conflict). The RAM's SMBus RGB chips
(ENE, 0x70/0x71) have no kernel/udev readiness signal and can take a few
seconds to start answering reads after a real cold boot; openrgb-off.service
was only trying once, right after openrgb.service started, so a slow wake
meant the whole off-profile silently failed to apply (openrgb's CLI exits 0
whether or not it succeeds) and every device - RAM and AIO both - was left
at its power-on lighting default.

Attempted fix in hosts/bubu-brain/rgb.nix: openrgb-off's ExecStart is a
small wrapper that retries up to 5 times, 2s apart, and only exits nonzero
(a real failed unit) if none of the attempts report "Profile loaded
successfully".

**This does not actually work.** Confirmed 2026-09-02: the service ran,
reported "Profile loaded successfully" on `journalctl`, exited 0 - and the
RGB was still visibly on hours later. So "Profile loaded successfully" is
not a reliable signal that the hardware write actually landed - it most
likely just confirms the `.orp` profile file parsed and the client
requested the controllers, not that the SMBus write to the RAM chips stuck.
That's the same class of false-positive this fix was written to guard
against (openrgb's own exit code lying about success), just recurring one
level up in a string the fix trusted instead. The underlying SMBus-timing
theory above may still be right, or may not be the whole story - not
re-diagnosed further.

## Dedicated hardware module for SFFPC specific hardware

Started as a question in the old Questions note: bubu-brain (the SFFPC) uses
nixos-hardware for the red-sun-whorl thinkpad, so why not the same for bubu-brain?
Answered - bubu-brain is a custom build, not a shipped model, so there's no
prebuilt nixos-hardware module to pull in.

That doesn't rule out writing our own, though - a local module (e.g.
hosts/bubu-brain/hardware.nix or modules/hardware/bubu-brain.nix) structured
the way a real nixos-hardware module is: the specific hardware quirks and
settings for this exact build, gathered in one importable place instead of
scattered across hosts/bubu-brain/configuration.nix and home.nix.

- [ ] Inventory what's actually bubu-brain-specific and currently scattered
      (CPU microcode, GPU driver settings, the RGB/openrgb config from
      the above section, any SFFPC-specific power/
      thermal tuning) and decide what's worth pulling into a dedicated module
      vs. what's fine staying inline
