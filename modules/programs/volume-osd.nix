{ pkgs, ... }:

{
  xdg.configFile = {
    "quickshell/volume-osd/shell.qml".source = ./volume-osd/shell.qml;
    "quickshell/volume-osd/VolumeBar.qml".source = ./volume-osd/VolumeBar.qml;
    "quickshell/volume-osd/Theme.qml".source = ./quickshell-harness/Theme.qml;
  };

  systemd.user.services.volume-osd = {
    Unit = {
      Description = "Quickshell volume OSD";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      X-Restart-Triggers = [ "${./volume-osd}" "${./quickshell-harness/Theme.qml}" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/qs -c volume-osd";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
