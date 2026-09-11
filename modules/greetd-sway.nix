{ config, lib, pkgs, ... }:

let
  sessionCommand = pkgs.writeShellScript "red-sun-whorl-session" ''
    case "$(whoami)" in
      jahlee) exec Hyprland ;;
      *) exec sway ;;
    esac
  '';
in
{
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = ''
        ${pkgs.tuigreet}/bin/tuigreet \
          --time --remember --asterisks \
          --cmd ${sessionCommand} --theme "${config.lib.tuigreet.themeArg}"
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
