{ pkgs, ... }:

{
  home.packages = [ pkgs.quickshell ];

  xdg.configFile."quickshell/display-options/shell.qml".source =
    ./quickshell-harness/shell.qml;
}
