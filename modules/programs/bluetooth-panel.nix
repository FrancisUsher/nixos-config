{ pkgs, ... }:

{
  xdg.configFile = {
    "quickshell/bluetooth/shell.qml".source = ./bluetooth-panel/shell.qml;
    "quickshell/bluetooth/AdapterHeader.qml".source = ./bluetooth-panel/AdapterHeader.qml;
    "quickshell/bluetooth/DeviceSection.qml".source = ./bluetooth-panel/DeviceSection.qml;
    "quickshell/bluetooth/DeviceRow.qml".source = ./bluetooth-panel/DeviceRow.qml;
    "quickshell/bluetooth/TextButton.qml".source = ./bluetooth-panel/TextButton.qml;
    "quickshell/bluetooth/Theme.qml".source = ./quickshell-harness/Theme.qml;
    "quickshell/bluetooth/SectionLabel.qml".source = ./quickshell-harness/SectionLabel.qml;
  };

  systemd.user.services.bluetooth-panel = {
    Unit = {
      Description = "Quickshell Bluetooth panel";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      X-Restart-Triggers = [
        "${./bluetooth-panel}"
        "${./quickshell-harness/Theme.qml}"
        "${./quickshell-harness/SectionLabel.qml}"
      ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/qs -c bluetooth";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
