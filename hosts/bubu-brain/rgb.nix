{ config, lib, pkgs, ... }:

{
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];

  services.hardware.openrgb.enable = true;
  environment.etc."openrgb-off.orp".source = ./openrgb-off.orp;

  # The RAM's RGB controller chips (SMBus, ENE) don't expose any kernel/udev
  # readiness signal - after a real cold power-on they sometimes take a few
  # seconds to start answering SMBus reads, and OpenRGB has no way to wait
  # for that, only to try and see. A single early attempt (right after
  # openrgb.service starts) can lose that race and silently leave every
  # device - RAM included - at its power-on lighting default. Retry a
  # bounded number of times so a slow wake doesn't get missed, but fail the
  # unit for real (openrgb's own exit code is always 0, success or not) if
  # it never comes up, rather than retrying forever.
  systemd.services.openrgb-off = {
    description = "Apply all-off OpenRGB profile (AIO + RAM lighting)";
    after = [ "openrgb.service" ];
    wants = [ "openrgb.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "openrgb-off" ''
        set -u
        attempts=5
        delay=2
        # Retrying because it's flaky whether the RAM RGB chips will answer
        # SMBus reads right after boot - not every attempt should fail.
        for i in $(seq 1 "$attempts"); do
          out="$(${pkgs.openrgb}/bin/openrgb -p /etc/openrgb-off.orp 2>&1)"
          echo "$out"
          if echo "$out" | grep -q "Profile loaded successfully"; then
            exit 0
          fi
          echo "openrgb-off: attempt $i/$attempts did not report success"
          if [ "$i" -lt "$attempts" ]; then
            sleep "$delay"
          fi
        done
        echo "openrgb-off: giving up after $attempts attempts"
        exit 1
      '';
    };
  };
}
