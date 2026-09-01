{ config, lib, pkgs, ... }:

{
  imports = [
    # Generated on-device via `nixos-generate-config` - see BOOTSTRAP.md.
    # Does not exist yet; this host won't evaluate until it's added.
    ./hardware-configuration.nix
    ../../remote-operations.nix
    ../../modules/captive-portal.nix
    ../../modules/stylix.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "x1nano";
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  zramSwap.enable = true;

  # Physical-access laptop, not headless like bubu-brain: real password
  # login instead of autologin, and sudo still asks for a password.
  users.users.soong = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keyFiles = [
      ../../soong.pub
    ];
  };

  hardware.graphics.enable = true;

  # From nixos-hardware's lenovo-thinkpad-x1-nano-gen1 module (imported in
  # flake.nix): trackpoint, the alsa audio-interference fix, and TLP power
  # management all come pre-wired. This just flips on fingerprint login -
  # after first boot, enroll with `fprintd-enroll`.
  services.fprintd.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    htop
  ];

  services.captivePortalAccept = {
    enable = true;
    autoAcceptKnownNetworks = true;
  };

  system.stateVersion = "24.11";
}
