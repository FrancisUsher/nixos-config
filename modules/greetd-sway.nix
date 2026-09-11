# Turns the compositor configs in modules/programs/{sway,hyprland}.nix
# (home-manager) into an actual running session: greetd+tuigreet lists both
# as pickable sessions and launches whichever is selected on login,
# replacing the plain getty prompt. Only imported by red-sun-whorl - bubu-brain
# is headless and has no compositor to run. silk runs sway, jahlee runs
# Hyprland (issue #4); --remember-user-session means each account keeps its
# own choice independently once picked once.
#
# Also brings up the handful of system services the compositor keybindings
# (modules/programs/sway.nix, modules/programs/hyprland.nix) already assume
# exist but nothing had wired up yet: pipewire + wireplumber (for the wpctl
# volume keybindings - neither services.pipewire.pulse nor .wireplumber
# actually installs a CLI client, so wpctl needs to be added explicitly),
# polkit (session/auth actions), dconf (registers the dconf D-Bus service as
# activatable - without this, home-manager's dconf activation step fails
# outright with "the name is not activatable" and takes the whole
# home-manager switch down with it), and udev perms for brightnessctl
# (brightness keybindings).
{ config, lib, pkgs, ... }:

{
  environment.etc = {
    "greetd/sessions/sway.desktop".text = ''
      [Desktop Entry]
      Name=Sway
      Comment=Sway, a tiling Wayland compositor
      Exec=sway
      Type=Application
    '';
    "greetd/sessions/hyprland.desktop".text = ''
      [Desktop Entry]
      Name=Hyprland
      Comment=Hyprland, a dynamic tiling Wayland compositor
      Exec=Hyprland
      Type=Application
    '';
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = ''
        ${pkgs.tuigreet}/bin/tuigreet \
          --time --remember --remember-user-session --asterisks \
          --sessions /etc/greetd/sessions --theme "${config.lib.tuigreet.themeArg}"
      '';
      user = "greeter";
    };
  };
  # Otherwise getty and greetd fight over tty1.
  systemd.services."getty@tty1".enable = lib.mkForce false;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  security.polkit.enable = true;

  programs.dconf.enable = true;

  environment.systemPackages = [ pkgs.wireplumber ];

  services.udev.packages = [ pkgs.brightnessctl ];
}
