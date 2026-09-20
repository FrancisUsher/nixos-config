{ pkgs, ... }:

{
  home.packages = [ pkgs.quickshell ];

  xdg.configFile."quickshell/display-options".source = ./quickshell-harness;
}
