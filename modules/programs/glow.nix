{ pkgs, ... }:

{
  # No home-manager module for glow on this pin - plain package + config file.
  home.packages = [ pkgs.glow ];
  xdg.configFile."glow/glow.yml".text = ''
    # style name or JSON path (default "auto")
    style: "auto"
    # mouse support (TUI-mode only)
    mouse: false
    # use pager to display markdown
    pager: false
    # word-wrap at width
    width: 80
    # show all files, including hidden and ignored.
    all: false
  '';
}
