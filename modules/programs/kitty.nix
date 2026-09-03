{ ... }:

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
    };
    shellIntegration = {
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };

  stylix.targets.kitty.enable = true;
}
