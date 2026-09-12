{ pkgs, ... }:

let
  mirrorTmuxConf = pkgs.writeText "kitty-mirror-tmux.conf" ''
    set -g status off
    set -g prefix M-F12
    unbind C-b
  '';

  kittyMirrorShell = pkgs.writeShellScript "kitty-mirror-shell" ''
    exec ${pkgs.tmux}/bin/tmux -f ${mirrorTmuxConf} new-session -A -s "kw-$$"
  '';
in
{
  programs.kitty = {
    enable = true;
    settings = {
      scrollback_lines = 10000;
      mouse_hide_wait = -3.0;
      hide_window_decorations = true;
      tab_bar_style = "powerline";
      tab_powerline_style = "round";
      allow_remote_control = true;
      shell = "${kittyMirrorShell}";
    };
    shellIntegration = {
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };

  stylix.targets.kitty.enable = true;
}
