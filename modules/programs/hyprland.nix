{ config, lib, pkgs, unstableUnfreePkgs, ... }:

let
  fuzzel-cliphist = pkgs.writeShellScriptBin "fuzzel-cliphist" ''
    ${pkgs.cliphist}/bin/cliphist list | ${pkgs.fuzzel}/bin/fuzzel -d -p "Clipboard History" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
  '';

  hyprctl = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl";

  # apply: names = every connected output; external = names minus eDP-1
  # (eDP-1 is the fixed connector name for the laptop's built-in panel).
  # If external is non-empty, disable eDP-1 and bring up each external
  # output at preferred/auto/auto-scale; otherwise (external empty) enable
  # eDP-1 the same way. Runs once at start, then again on every
  # monitoradded/monitorremoved line read off Hyprland's IPC event socket.
  hypr-monitor-autoswitch = pkgs.writeShellScriptBin "hypr-monitor-autoswitch" ''
    set -euo pipefail

    apply() {
      local names external
      names=$(${hyprctl} monitors -j | ${pkgs.jq}/bin/jq -r '.[].name')
      external=$(grep -v '^eDP-1$' <<< "$names" || true)

      if [ -n "$external" ]; then
        ${hyprctl} keyword monitor "eDP-1,disable"
        while IFS= read -r name; do
          ${hyprctl} keyword monitor "$name,preferred,auto,auto"
        done <<< "$external"
      else
        ${hyprctl} keyword monitor "eDP-1,preferred,auto,auto"
      fi
    }

    apply

    socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:"$socket" | while read -r line; do
      case "$line" in
        monitoradded*|monitorremoved*) apply ;;
      esac
    done
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
  home.packages = [
    pkgs.cliphist
    pkgs.wl-clipboard
    pkgs.wtype
    fuzzel-cliphist
    hypr-monitor-autoswitch
  ];

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

      animations = {
        enabled = true;
        bezier = [
          "slam, 0.64, 0, 0.78, 0"
          "slamSettle, 0.64, 0, 0.36, 1.15"
          "vanish, 0.9, 0, 0.95, 0"
        ];
        animation = [
          "windows, 1, 4, slamSettle, slide"
          "windowsOut, 1, 3, slam, slide"
          "workspaces, 1, 5, slamSettle, slide"
          "fadeIn, 0"
          "fadeOut, 1, 3, vanish"
        ];
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
        "${pkgs.quickshell}/bin/qs -c rebuild-sweep"
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

  stylix.cursor = {
    name = "phinger-cursors-dark";
    package = pkgs.phinger-cursors;
    size = 24;
  };

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

  systemd.user.services.hypr-monitor-autoswitch = {
    Unit = {
      Description = "hypr-monitor-autoswitch";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${hypr-monitor-autoswitch}/bin/hypr-monitor-autoswitch";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
