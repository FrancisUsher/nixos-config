{ config, lib, pkgs, ... }:

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

  directions = [
    { key = "H"; dir = "left"; }
    { key = "L"; dir = "right"; }
    { key = "K"; dir = "up"; }
    { key = "J"; dir = "down"; }
  ];
in
{
  home.packages = [ pkgs.cliphist pkgs.wl-clipboard pkgs.wtype fuzzel-cliphist ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.variables = [ "--all" ];
    configType = "lua";

    settings = {
      config = {
        general = {
          gaps_in = 5;
          gaps_out = 10;
        };
        ecosystem.no_update_news = true;
        decoration.rounding = 0;
      };

      bind =
        [
          { _args = [ "SUPER + Return" (mkExec "kitty") ]; }
          { _args = [ "SUPER + P" (mkExec "fuzzel") ]; }
          { _args = [ "SUPER + V" (mkExec "fuzzel-cliphist") ]; }
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
      end)
    '';
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
