{ pkgs, ... }:

{
  home.packages = [ pkgs.quickshell ];

  xdg.configFile."quickshell/display-options".source = ./quickshell-harness;

  systemd.user.services.display-options = {
    Unit = {
      Description = "Quickshell display options panel";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      X-Restart-Triggers = [ "${./quickshell-harness}" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/qs -c display-options";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
