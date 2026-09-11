{ config, lib, pkgs, ... }:

let
  labelWebBase = pkgs.writers.writePython3Bin "label-web" {
    libraries = [
      pkgs.python3Packages.flask
      pkgs.python3Packages.pillow
      pkgs.python3Packages.brother-ql
    ];
    flakeIgnore = [ "E501" ];
  } (builtins.readFile ./label_web.py);

  labelWeb = pkgs.symlinkJoin {
    name = "label-web";
    paths = [ labelWebBase ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/label-web \
        --set LABEL_FONT ${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans-Bold.ttf
    '';
  };
in
{
  services.printing = {
    enable = true;
    listenAddresses = [ "*:631" ];
    allowFrom = [ "all" ];
    browsing = true;
    defaultShared = true;
    openFirewall = true;
  };

  hardware.printers = {
    ensureDefaultPrinter = "QL600";
    ensurePrinters = [
      {
        name = "QL600";
        description = "Brother QL-600 Label Printer (raw queue - client must render with Brother's own driver)";
        deviceUri = "usb://Brother/QL-600?serial=000A5G620869";
        model = "raw";
      }
    ];
  };

  systemd.services.label-web = {
    description = "Brother QL-600 quick label print web page";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${labelWeb}/bin/label-web";
      DynamicUser = true;
      SupplementaryGroups = [ "lp" ];
      Restart = "on-failure";
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."_" = {
      default = true;
    };
    virtualHosts."print.local" = {
      locations."/".proxyPass = "http://192.168.1.161";
      locations."/label".proxyPass = "http://127.0.0.1:8180/print";
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];

  # avahi-publish (used below to register print.local) goes through the
  # same D-Bus API as user-initiated service publishing, which
  # remote-operations.nix's services.avahi config leaves disabled.
  services.avahi.publish.userServices = true;

  systemd.services.avahi-alias-print-local = {
    description = "Publish print.local as an mDNS alias for this host";
    after = [ "avahi-daemon.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
    };
    script = ''
      while true; do
        ip=$(${pkgs.iproute2}/bin/ip -4 -o addr show scope global | ${pkgs.gawk}/bin/awk '{split($4, a, "/"); print a[1]; exit}')
        if [ -n "$ip" ]; then
          timeout 300 ${pkgs.avahi}/bin/avahi-publish -a -R print.local "$ip" || true
        else
          sleep 10
        fi
      done
    '';
  };
}
