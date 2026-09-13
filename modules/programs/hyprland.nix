{ config, lib, pkgs, unstableUnfreePkgs, ... }:

let
  inherit (lib.generators) mkLuaInline;
  toLuaValue = lib.generators.toLua { };

  fuzzel-cliphist = pkgs.writeShellScriptBin "fuzzel-cliphist" ''
    ${pkgs.cliphist}/bin/cliphist list | ${pkgs.fuzzel}/bin/fuzzel -d -p "Clipboard History" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
  '';

  mod0 = n: if n == 10 then 0 else n;

  mkExec = cmd: mkLuaInline "hl.dsp.exec_cmd(${toLuaValue cmd})";
  mkFocusDir = dir: mkLuaInline "hl.dsp.focus(${toLuaValue { direction = dir; }})";
  mkMoveDir = dir: mkLuaInline "hl.dsp.window.move(${toLuaValue { direction = dir; }})";
  mkFocusWs = n: mkLuaInline "hl.dsp.focus(${toLuaValue { workspace = n; }})";
  mkMoveWs = n: mkLuaInline "hl.dsp.window.move(${toLuaValue { workspace = n; }})";
  mkLayoutMsg = msg: mkLuaInline "hl.dsp.layout(${toLuaValue msg})";

  directions = [
    { key = "H"; dir = "left"; }
    { key = "L"; dir = "right"; }
    { key = "K"; dir = "up"; }
    { key = "J"; dir = "down"; }
  ];

  mkBezier = name: points: { _args = [ name { type = "bezier"; inherit points; } ]; };

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
    configType = "lua";

    plugins = [ imgborders ];

    settings = {
      config = {
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 0;
        };
        animations.enabled = true;
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
        dwindle.preserve_split = true;
      };

      curve = [
        (mkBezier "slam" [ [ 0.64 0 ] [ 0.78 0 ] ])
        (mkBezier "slamSettle" [ [ 0.64 0 ] [ 0.36 1.15 ] ])
        (mkBezier "vanish" [ [ 0.9 0 ] [ 0.95 0 ] ])
      ];

      animation = [
        { leaf = "windows"; enabled = true; speed = 4; bezier = "slamSettle"; style = "slide"; }
        { leaf = "windowsOut"; enabled = true; speed = 3; bezier = "slam"; style = "slide"; }
        { leaf = "workspaces"; enabled = true; speed = 5; bezier = "slamSettle"; style = "slide"; }
        { leaf = "fadeIn"; enabled = false; }
        { leaf = "fadeOut"; enabled = true; speed = 3; bezier = "vanish"; }
      ];

      bind =
        [
          { _args = [ "SUPER + Return" (mkExec "kitty") ]; }
          { _args = [ "SUPER + P" (mkExec "fuzzel") ]; }
          { _args = [ "SUPER + V" (mkExec "fuzzel-cliphist") ]; }
          { _args = [ "SUPER + D" (mkExec "${pkgs.quickshell}/bin/qs ipc -c display-options call displayOptions toggle") ]; }
          {
            _args = [
              "SUPER + SHIFT + V"
              (mkExec "${pkgs.bash}/bin/bash -c \"fuzzel-cliphist && wtype -M ctrl -M shift v -m shift -m ctrl\"")
            ];
          }
          { _args = [ "Print" (mkExec "grim") ]; }

          { _args = [ "SUPER + SHIFT + Q" (mkLuaInline "hl.dsp.window.close()") ]; }
          { _args = [ "SUPER + SHIFT + E" (mkLuaInline "hl.dsp.exit()") ]; }
          { _args = [ "SUPER + SHIFT + Space" (mkLuaInline "hl.dsp.window.float(${toLuaValue { action = "toggle"; }})") ]; }
          { _args = [ "SUPER + F" (mkLuaInline "hl.dsp.window.fullscreen()") ]; }
          { _args = [ "SUPER + S" (mkLayoutMsg "togglesplit") ]; }
        ]
        ++ map (d: { _args = [ "SUPER + ${d.key}" (mkFocusDir d.dir) ]; }) directions
        ++ map (d: { _args = [ "SUPER + SHIFT + ${d.key}" (mkMoveDir d.dir) ]; }) directions
        ++ map (n: { _args = [ "SUPER + ${toString (mod0 n)}" (mkFocusWs n) ]; }) (lib.range 1 10)
        ++ map (n: { _args = [ "SUPER + SHIFT + ${toString (mod0 n)}" (mkMoveWs n) ]; }) (lib.range 1 10)
        ++ [
          {
            _args = [
              "XF86AudioMute"
              (mkExec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
              { locked = true; }
            ];
          }
          {
            _args = [
              "XF86AudioMicMute"
              (mkExec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")
              { locked = true; }
            ];
          }
          {
            _args = [
              "XF86AudioLowerVolume"
              (mkExec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
              { locked = true; repeating = true; }
            ];
          }
          {
            _args = [
              "XF86AudioRaiseVolume"
              (mkExec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")
              { locked = true; repeating = true; }
            ];
          }
          {
            _args = [
              "XF86MonBrightnessDown"
              (mkExec "brightnessctl set 5%-")
              { locked = true; repeating = true; }
            ];
          }
          {
            _args = [
              "XF86MonBrightnessUp"
              (mkExec "brightnessctl set 5%+")
              { locked = true; repeating = true; }
            ];
          }
        ];
    };

    extraConfig = ''
      hl.on("hyprland.start", function()
        hl.exec_cmd("waybar")
        hl.exec_cmd("${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store")
        hl.exec_cmd("${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store")
        hl.exec_cmd("${pkgs.quickshell}/bin/qs -c display-options")
        hl.exec_cmd("${pkgs.quickshell}/bin/qs -c rebuild-sweep")
      end)
    '';
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
