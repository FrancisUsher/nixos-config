{ config, ... }:

{
  xdg.configFile."zmk/zmk.ini".text = ''
    [user]
    home = ${config.home.homeDirectory}/dev/zmk-config
  '';
}
