{ pkgs, ... }:

let
  shellQml = pkgs.writeText "rebuild-sweep-shell.qml" ''
    import QtQuick
    import Quickshell
    import Quickshell.Io
    import Quickshell.Wayland

    PanelWindow {
        id: sweepWindow
        visible: false
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }

        IpcHandler {
            target: "rebuildSweep"
            function trigger(): void {
                sweepWindow.visible = true;
                line.x = -line.width;
                sweepAnim.restart();
            }
        }

        Rectangle {
            id: line
            width: 4
            height: parent.height
            color: "white"

            SequentialAnimation {
                id: sweepAnim
                NumberAnimation {
                    target: line
                    property: "x"
                    from: -line.width
                    to: sweepWindow.width
                    duration: 500
                    easing.type: Easing.OutCubic
                }
                ScriptAction { script: sweepWindow.visible = false }
            }
        }
    }
  '';

  nixosRebuild = pkgs.writeShellScriptBin "nixos-rebuild" ''
    /run/current-system/sw/bin/nixos-rebuild "$@"
    status=$?
    if [ "$status" -eq 0 ]; then
      ${pkgs.quickshell}/bin/qs ipc -c rebuild-sweep call rebuildSweep trigger 2>/dev/null || true
    fi
    exit "$status"
  '';
in
{
  home.packages = [ pkgs.quickshell nixosRebuild ];

  xdg.configFile."quickshell/rebuild-sweep/shell.qml".source = shellQml;
}
