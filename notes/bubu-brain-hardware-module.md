# bubu-brain hardware module

Started as a question in the old Questions note: bubu-brain (the SFFPC) uses
nixos-hardware for the x1nano thinkpad, so why not the same for bubu-brain?
Answered - bubu-brain is a custom build, not a shipped model, so there's no
prebuilt nixos-hardware module to pull in.

That doesn't rule out writing our own, though - a local module (e.g.
hosts/bubu-brain/hardware.nix or modules/hardware/bubu-brain.nix) structured
the way a real nixos-hardware module is: the specific hardware quirks and
settings for this exact build, gathered in one importable place instead of
scattered across hosts/bubu-brain/configuration.nix and home.nix.

- [ ] Inventory what's actually bubu-brain-specific and currently scattered
      (CPU microcode, GPU driver settings, the RGB/openrgb config from
      [[bubu-brain-hardware|bubu-brain hardware]], any SFFPC-specific power/
      thermal tuning) and decide what's worth pulling into a dedicated module
      vs. what's fine staying inline
