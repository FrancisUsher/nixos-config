{ config, lib, pkgs, unstableUnfreePkgs, ... }:

let
  fuzzel-cliphist = pkgs.writeShellScriptBin "fuzzel-cliphist" ''
    ${pkgs.cliphist}/bin/cliphist list | ${pkgs.fuzzel}/bin/fuzzel -d -p "Clipboard History" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
  '';

  mod0 = n: if n == 10 then 0 else n;

  ancientRuinsBorder = pkgs.runCommand "ancient-ruins-border.png" {
    nativeBuildInputs = [ (pkgs.python3.withPackages (ps: [ ps.pillow ])) ];
  } ''
    python3 ${./ancient-ruins-border-gen.py} $out
  '';

  imgborders = unstableUnfreePkgs.hyprlandPlugins.imgborders.overrideAttrs (_: {
    version = "2026-08-16";
    src = pkgs.fetchzip {
      url = "https://codeberg.org/zacoons/imgborders/archive/08be22236144d3c91607bcfa955ed0d457f4f50b.tar.gz";
      hash = "sha256-O+896T2qrisxiWTotB5HlzKw8XEJqPDTgSUHAAVUD18=";
    };
  });
in
{
  home.packages = [ pkgs.cliphist pkgs.wl-clipboard pkgs.wtype fuzzel-cliphist ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = unstableUnfreePkgs.hyprland;
    systemd.variables = [ "--all" ];
    configType = "hyprlang";

    plugins = [ imgborders ];

    settings = {
      "$mod" = "SUPER";
      "$terminal" = "kitty";
      "$menu" = "fuzzel";

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 0;
      };

      ecosystem.no_update_news = true;

      decoration.rounding = 0;

      plugin.imgborders = {
        image = "${ancientRuinsBorder}";
        sizes = 8;
        insets = 0;
        scale = 3;
        smooth = false;
        blur = false;
      };

      exec-once = [
        "waybar"
        "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store"
        "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store"
        "${pkgs.quickshell}/bin/qs -c display-options"
      ];

      bind =
        [
          "$mod, Return, exec, $terminal"
          "$mod, P, exec, $menu"
          "$mod, V, exec, fuzzel-cliphist"
          "$mod, D, exec, ${pkgs.quickshell}/bin/qs ipc -c display-options call displayOptions toggle"
          "$mod SHIFT, V, exec, ${pkgs.bash}/bin/bash -c \"fuzzel-cliphist && wtype -M ctrl -M shift v -m shift -m ctrl\""
          ", Print, exec, grim"

          "$mod SHIFT, Q, killactive"
          "$mod SHIFT, E, exit"
          "$mod SHIFT, Space, togglefloating"
          "$mod, F, fullscreen, 0"

          "$mod, H, movefocus, l"
          "$mod, L, movefocus, r"
          "$mod, K, movefocus, u"
          "$mod, J, movefocus, d"

          "$mod SHIFT, H, movewindow, l"
          "$mod SHIFT, L, movewindow, r"
          "$mod SHIFT, K, movewindow, u"
          "$mod SHIFT, J, movewindow, d"
        ]
        ++ (map (n: "$mod, ${toString (mod0 n)}, workspace, ${toString n}") (lib.range 1 10))
        ++ (map (n: "$mod SHIFT, ${toString (mod0 n)}, movetoworkspace, ${toString n}") (lib.range 1 10));

      bindl = [
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ];

      bindle = [
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
      ];
    };
  };

  stylix.targets.hyprland.enable = true;
  stylix.targets.hyprland.hyprpaper.enable = true;
  stylix.targets.gtk.enable = true;

  # needed for interactive auth in e.g. fprintd enrollment
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "polkit-gnome-authentication-agent-1";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
