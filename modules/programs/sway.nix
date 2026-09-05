{ config, lib, pkgs, ... }:

{
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

      # needed for interactive auth in e.g. fprintd enrollment
      startup = [
        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }
      ];

      keybindings =
        let
          modifier = config.wayland.windowManager.sway.config.modifier;
          menu = config.wayland.windowManager.sway.config.menu;
        in
        lib.mkOptionDefault {
          "${modifier}+d" = null;
          "${modifier}+p" = "exec ${menu}";

          "Print" = "exec grim";
          "--locked XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
          "--locked XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
          "--locked XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
          "--locked XF86AudioMicMute" = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";
          "--locked XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
          "--locked XF86MonBrightnessUp" = "exec brightnessctl set 5%+";
        };
    };
  };

  stylix.targets.sway.enable = true;
  stylix.targets.gtk.enable = true;
}
