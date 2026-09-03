# Migrate Arch laptop to NixOS

Big project, depends on [[home-manager|Home Manager]].

- [x] Restructure flake.nix for multiple hosts (shared modules + per-host config)
- [x] hosts/x1nano/configuration.nix scaffolded (unbootable until hardware
      config is added - see below)
- [x] WiFi: NetworkManager instead of static wireless.networks (roaming)
- [x] Headless captive-portal wifi login (modules/captive-portal.nix,
      services.captivePortalAccept, wired into x1nano)
- [x] hosts/x1nano/hardware-configuration.nix preview - generated via
      nixos-generate-config --no-filesystems while still on Arch (kernel
      modules, CPU microcode). fileSystems/LUKS still pending the real
      install, see below
- [x] Pull in NixOS/nixos-hardware's lenovo-thinkpad-x1-nano-gen1 module
      (flake input + import in hosts/x1nano/configuration.nix) - gives
      trackpoint config, the known x1-nano audio-interference fix, and TLP
      power management for free
- [x] Fingerprint reader: services.fprintd.enable = true (from the hardware
      module above) - still need to run `fprintd-enroll` after first boot
- [x] Push nixos-config to a git remote - github.com/FrancisUsher/nixos-config
      (private). bootstrap.sh's REPO_URL now points at it (plain https, no
      auth wired up yet - it'll fail non-interactively against a private
      repo until the deploy-key question in [[bootstrap-improvements|Bootstrap improvements]] is actually resolved)
- [ ] Finish migrating data off the Arch install
- [ ] Laptop hardware-configuration.nix's fileSystems/swapDevices/
      boot.initrd.luks are hand-filled placeholders matching BOOTSTRAP.md's
      documented partition plan (by-label/by-partlabel refs), not from a
      real scan - just enough for `nix flake check`/`nixos-rebuild build` to
      pass instead of failing the fileSystems assertion. MUST be regenerated
      for real during the actual install (nixos-generate-config --root /mnt,
      per BOOTSTRAP.md's x1nano section) - don't trust these values to boot
      the real hardware as-is
- [ ] Power management: TLP now on by default via nixos-hardware; backlight
      and any further battery tuning still open
- [ ] Sway desktop config, ported from current Arch setup
- [x] Home Manager config shared between bubu-brain and laptop - flake.nix's
      mkHost wires home-manager.users.soong = import ./home.nix identically
      for both hosts
- [ ] Split home.nix into shared + per-host pieces - see [[red-sun-whorl-rename-plan|red-sun-whorl rename plan]]
      for why this isn't just a themed variant of bubu-brain's setup
