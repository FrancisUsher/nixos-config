{ config, lib, pkgs, ... }:

let
  fuzzel-cliphist = pkgs.writeShellScriptBin "fuzzel-cliphist" ''
    ${pkgs.cliphist}/bin/cliphist list | ${pkgs.fuzzel}/bin/fuzzel -d -p "Clipboard History" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
  '';
in
{
  home.packages = [ pkgs.cliphist pkgs.wl-clipboard pkgs.wtype fuzzel-cliphist ];

  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4";
      terminal = "kitty";
      menu = "fuzzel";

      window = {
        titlebar = false;
        hideEdgeBorders = "smart";
      };
      floating.titlebar = false;

      gaps.smartGaps = true;
      gaps.smartBorders = "on";

      bars = [ { command = "waybar"; } ];

      startup = [
        { command = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store"; }
        { command = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store"; }
      ];

      keybindings =
        let
          modifier = config.wayland.windowManager.sway.config.modifier;
          menu = config.wayland.windowManager.sway.config.menu;
        in
        lib.mkOptionDefault {
          "${modifier}+d" = null;
          "${modifier}+p" = "exec ${menu}";
          "${modifier}+v" = "exec fuzzel-cliphist";
          "${modifier}+Shift+v" = "exec ${pkgs.bash}/bin/bash -c \"fuzzel-cliphist && wtype -M ctrl -M shift v -m shift -m ctrl\"";

          "Print" = "exec grim";
          "--locked XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "--locked XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          "--locked XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          "--locked XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          "--locked XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
          "--locked XF86MonBrightnessUp" = "exec brightnessctl set 5%+";
        };
    };
  };

  stylix.targets.sway.enable = true;
  stylix.targets.gtk.enable = true;

  # needed for interactive auth in e.g. fprintd enrollment
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "polkit-gnome-authentication-agent-1";
      PartOf = [ "sway-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "sway-session.target" ];
  };
}
