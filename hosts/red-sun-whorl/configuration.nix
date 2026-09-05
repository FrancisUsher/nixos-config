{ config, lib, pkgs, ... }:

{
  imports = [
    # Generated on-device via `nixos-generate-config` - see BOOTSTRAP.md.
    ./hardware-configuration.nix
    ../../remote-operations.nix
    ../../modules/captive-portal.nix
    ../../modules/stylix.nix
    ../../modules/greetd-sway.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.plymouth.enable = true;
  boot.kernelParams = [ "quiet" ];
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;

  networking.hostName = "red-sun-whorl";
  networking.networkmanager.enable = true;

  # Avoids tailscaled/NetworkManager DNS conflicts: https://tailscale.com/s/dns-fight
  services.resolved.enable = true;
  networking.networkmanager.dns = "systemd-resolved";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  zramSwap.enable = true;

  programs.zsh.enable = true;

  # Physical-access laptop, not headless like bubu-brain: real password
  # login instead of autologin, and sudo still asks for a password.
  users.users.silk = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
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
    go
    uv
    kicad
  ];

  services.captivePortalAccept = {
    enable = true;
    autoAcceptKnownNetworks = true;
  };

  system.stateVersion = "24.11";
}
