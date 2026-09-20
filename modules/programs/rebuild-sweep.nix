{ pkgs, config, ... }:

let
  targetUser = config.home.username;

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
      targetUid=$(${pkgs.coreutils}/bin/id -u ${targetUser})
      # We need to run these as the sudoing user, even though nixos-rebuild
      # is running as root via sudo.
      runAsUser() {
        if [ "$(${pkgs.coreutils}/bin/id -u)" -eq "$targetUid" ]; then
          "$@"
        else
          ${pkgs.util-linux}/bin/runuser -u ${targetUser} -- \
            env XDG_RUNTIME_DIR="/run/user/$targetUid" "$@"
        fi
      }
      runAsUser ${pkgs.quickshell}/bin/qs ipc --any-display -c rebuild-sweep call rebuildSweep trigger 2>/dev/null || true

      # Quickshell doesn't reread its QML on its own. Force a restart.
      runAsUser ${pkgs.quickshell}/bin/qs kill --any-display -c display-options 2>/dev/null || true
      sleep 0.3
      runAsUser ${pkgs.quickshell}/bin/qs -c display-options -d 2>/dev/null || true
    fi
    exit "$status"
  '';
in
{
  home.packages = [ pkgs.quickshell nixosRebuild ];

  xdg.configFile."quickshell/rebuild-sweep/shell.qml".source = shellQml;
}
