# Turns the sway config already in modules/programs/sway.nix (home-manager)
# into an actual running session: greetd+tuigreet launches it on login,
# replacing the plain getty prompt. Only imported by red-sun-whorl -
# bubu-brain is headless and has no compositor to run.
#
# Also brings up the handful of system services sway's existing keybindings
# (modules/programs/sway.nix) already assume exist but nothing had wired up
# yet: pipewire + wireplumber (for the wpctl volume keybindings - neither
# services.pipewire.pulse nor .wireplumber actually installs a CLI client,
# so wpctl needs to be added explicitly), polkit (session/auth actions),
# dconf (registers the dconf D-Bus service as activatable - without this,
# home-manager's dconf activation step fails outright with "the name is
# not activatable" and takes the whole home-manager switch down with it),
# and udev perms for brightnessctl (brightness keybindings).
{ config, lib, pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = ''
        ${pkgs.tuigreet}/bin/tuigreet \
          --time --remember --remember-session --asterisks \
          --cmd sway --theme "${config.lib.tuigreet.themeArg}"
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
