{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../remote-operations.nix
    # This is supposed to be a script that detects when you connect to an unsecured
    # network that has a "click this button to get internet access" screen, and does
    # the clicking for you. It unfortunately doesn't do anything yet but it has some
    # code written to get pretty close when we want to go for it later.
    ../../modules/captive-portal.nix
    ../../modules/stylix.nix
    ../../modules/greetd-sway.nix
    (import ../../modules/pas-automation.nix {
      authorizedKeyFiles = [ ../../bubu-brain-pas.pub ];
    })
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
    homeMode = "0711";
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = [
      ../../soong.pub
      ../../bubu-brain.pub
    ];
  };

  # Sandboxed account for Hyprland exploration (issue #4) - starts as a
  # clone of silk's desktop, isolated from it. wheel is needed since jahlee
  # rebuilds the system locally to test changes; no SSH keys otherwise.
  users.users.jahlee = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    homeMode = "0711";
    shell = pkgs.zsh;
  };

  hardware.graphics.enable = true;

  # Hyprland's home-manager module enables xdg.portal by default, which
  # needs these paths linked into /run/current-system/sw - home-manager
  # asserts on this itself.
  environment.pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];

  # From nixos-hardware's lenovo-thinkpad-x1-nano-gen1 module (imported in
  # flake.nix): trackpoint, the alsa audio-interference fix, and TLP power
  # management all come pre-wired. This just flips on fingerprint login -
  # after first boot, enroll with `fprintd-enroll`.
  services.fprintd.enable = true;

  security.pam.services.hyprlock.fprintAuth = false;
  security.pam.services.greetd.fprintAuth = false;

  environment.systemPackages = with pkgs; [
    git
    wget
    htop
    go
    uv
  ];

  services.captivePortalAccept = {
    enable = true;
    autoAcceptKnownNetworks = true;
  };

  system.stateVersion = "24.11";
}
