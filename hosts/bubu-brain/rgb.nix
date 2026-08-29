{ config, lib, pkgs, ... }:

{
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];

  services.hardware.openrgb.enable = true;
  environment.etc."openrgb-off.orp".source = ./openrgb-off.orp;
  systemd.services.openrgb-off = {
    description = "Apply all-off OpenRGB profile (AIO + RAM lighting)";
    after = [ "openrgb.service" ];
    wants = [ "openrgb.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.openrgb}/bin/openrgb -p /etc/openrgb-off.orp";
    };
  };
}
