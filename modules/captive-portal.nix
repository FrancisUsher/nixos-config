{ config, lib, pkgs, ... }:

let
  cfg = config.services.captivePortalAccept;

  scriptBase = pkgs.writers.writePython3Bin "captive-portal-accept" {
    libraries = lib.optional cfg.enableBrowserFallback pkgs.python3Packages.playwright;
    flakeIgnore = [ "E501" ]; # long lines are fine, this isn't a library
  } (builtins.readFile ./captive-portal-accept.py);

  script =
    if cfg.enableBrowserFallback then
      pkgs.symlinkJoin {
        name = "captive-portal-accept";
        paths = [ scriptBase ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/captive-portal-accept \
            --set PLAYWRIGHT_BROWSERS_PATH ${pkgs.playwright-driver.browsers}
        '';
      }
    else
      scriptBase;

  dispatcherScript = pkgs.writeShellScript "captive-portal-dispatcher" ''
    IFACE="$1"
    ACTION="$2"

    [[ "$ACTION" == "up" ]] || exit 0
    [[ -n "''${CONNECTION_UUID:-}" ]] || exit 0

    TARGET_USER=$(loginctl list-sessions --no-legend 2>/dev/null | awk '$3=="seat0"{print $2; exit}')
    [[ -n "$TARGET_USER" ]] || TARGET_USER=$(who | awk '{print $1; exit}')
    [[ -n "$TARGET_USER" ]] || exit 0

    USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    [[ -n "$USER_HOME" ]] || exit 0

    KNOWN_FILE="$USER_HOME/.local/state/captive-portal/known-networks"
    [[ -f "$KNOWN_FILE" ]] || exit 0
    grep -qxF "$CONNECTION_UUID" "$KNOWN_FILE" || exit 0

    logger -t captive-portal "known network reconnected (''${CONNECTION_UUID}) on $IFACE, auto-running captive-portal-accept"
    ${lib.getExe' pkgs.util-linux "runuser"} -u "$TARGET_USER" -- ${script}/bin/captive-portal-accept 2>&1 | logger -t captive-portal &
  '';
in
{
  options.services.captivePortalAccept = {
    enable = lib.mkEnableOption "headless captive-portal wifi login helper";

    enableBrowserFallback = lib.mkEnableOption ''
      headless-Chromium fallback (via Playwright) for portals the plain-HTTP
      form heuristic can't clear. Pulls in playwright-driver's browser
      binaries, which is a sizeable download
    '';

    autoAcceptKnownNetworks = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install a NetworkManager dispatcher hook that auto-runs the accept
        flow when reconnecting to a network already recorded in
        ~/.local/state/captive-portal/known-networks (written the first time
        a user successfully runs `captive-portal-accept` by hand on that
        network). Requires networking.networkmanager.enable = true.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ script ];

    networking.networkmanager.dispatcherScripts = lib.mkIf cfg.autoAcceptKnownNetworks [
      {
        source = dispatcherScript;
        type = "basic";
      }
    ];

    environment.shellAliases.autohack = "nmcli device wifi connect autohackbot2600";
  };
}
