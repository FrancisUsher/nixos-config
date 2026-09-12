{ config, lib, pkgs, unstableUnfreePkgs, ... }:

let
  fuzzel-cliphist = pkgs.writeShellScriptBin "fuzzel-cliphist" ''
    ${pkgs.cliphist}/bin/cliphist list | ${pkgs.fuzzel}/bin/fuzzel -d -p "Clipboard History" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
  '';

  kitty-mirror-toggle = pkgs.writeShellApplication {
    name = "kitty-mirror-toggle";
    runtimeInputs = [ unstableUnfreePkgs.hyprland pkgs.jq pkgs.procps pkgs.util-linux pkgs.tmux pkgs.kitty ];
    text = ''
      class="kitty-mirror"

      existing=$(hyprctl clients -j | jq -r --arg c "$class" '.[] | select(.class==$c) | .address' | head -n1)
      if [[ -n "$existing" ]]; then
        hyprctl dispatch closewindow "address:$existing"
        exit 0
      fi

      active=$(hyprctl activewindow -j)
      active_class=$(jq -r '.class' <<<"$active")
      active_pid=$(jq -r '.pid' <<<"$active")

      [[ "$active_class" == "kitty" ]] || exit 0

      tty_short=""
      for cand_pid in $(pgrep -P "$active_pid"); do
        cand_tty=$(ps -o tty= -p "$cand_pid" | tr -d ' ')
        if [[ "$cand_tty" == pts/* ]]; then
          tty_short="$cand_tty"
          break
        fi
      done
      [[ -n "$tty_short" ]] || exit 0
      tty_path="/dev/$tty_short"

      session=$(tmux list-clients -F '#{client_tty} #{client_session}' 2>/dev/null | awk -v t="$tty_path" '$1==t {print $2}')
      [[ -n "$session" ]] || exit 0

      setsid -f kitty --class "$class" -e tmux attach -t "$session" >/dev/null 2>&1 &
    '';
  };

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
    pkgs.wlr-randr
    pkgs.nwg-displays
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

      windowrule = [
        "match:class ^(kitty-mirror)$, float on, size 1200 100, move 1000 60"
      ];

      plugin.imgborders = {
        image = "${ancientRuinsBorder}";
        sizes = 8;
        insets = 0;
        scale = 3;
        smooth = false;
        blur = false;
      };

      dwindle.preserve_split = true;

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
          "$mod, I, exec, ${kitty-mirror-toggle}/bin/kitty-mirror-toggle"
          "$mod, P, exec, $menu"
          "$mod, V, exec, fuzzel-cliphist"
          "$mod, D, exec, ${pkgs.quickshell}/bin/qs ipc -c display-options call displayOptions toggle"
          "$mod SHIFT, V, exec, ${pkgs.bash}/bin/bash -c \"fuzzel-cliphist && wtype -M ctrl -M shift v -m shift -m ctrl\""
          ", Print, exec, grim"

          "$mod SHIFT, Q, killactive"
          "$mod SHIFT, E, exit"
          "$mod SHIFT, Space, togglefloating"
          "$mod, F, fullscreen, 0"
          "$mod, S, layoutmsg, togglesplit"

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

  services.kanshi = {
    enable = true;
    systemdTarget = "graphical-session.target";
    settings = [
      {
        profile.name = "docked";
        profile.outputs = [
          { criteria = "eDP-1"; status = "disable"; }
          {
            criteria = "Dell Inc. DELL U4021QW 2C1D6H3";
            mode = "5120x2160";
            position = "0,0";
            scale = 1.6;
          }
        ];
      }
      {
        profile.name = "undocked";
        profile.outputs = [
          { criteria = "eDP-1"; status = "enable"; }
        ];
      }
    ];
  };
}
