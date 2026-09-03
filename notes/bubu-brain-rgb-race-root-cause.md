# bubu-brain RGB race root-cause

Referenced from [[bubu-brain-hardware|bubu-brain hardware]].

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
re-diagnosed further, see [[bubu-brain-hardware|bubu-brain hardware]] for
priority (low - not being actively chased right now).
