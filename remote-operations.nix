{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tmux
    mosh
  ];

  # Auto-attach a persistent tmux session on interactive login (ssh or
  # mosh), so a dropped connection (e.g. laptop sleep) doesn't kill what
  # was running - just reconnect and you're back in it.
  programs.bash.interactiveShellInit = ''
    if [[ $- == *i* ]] && [ -z "''${TMUX:-}" ]; then
      tmux attach -t main || tmux new -s main
    fi
  '';

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      LogLevel = "VERBOSE";
    };
  };

  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];

  networking.firewall.allowedUDPPortRanges = [
    { from = 60000; to = 61000; }
  ];

  # Auto-authenticate on boot if not already logged in, using a reusable
  # key from https://login.tailscale.com/admin/settings/keys stored at
  # /etc/tailscale-authkey (chmod 600, like /etc/wifi-secrets.env).
  systemd.services.tailscale-autoconnect = {
    after = [ "network-online.target" "tailscaled.service" ];
    wants = [ "network-online.target" "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      if [ -f /etc/tailscale-authkey ] && ! ${pkgs.tailscale}/bin/tailscale status --json | grep -q '"BackendState": *"Running"'; then
        ${pkgs.tailscale}/bin/tailscale up --authkey "$(cat /etc/tailscale-authkey)"
      fi
    '';
  };

  services.fail2ban.enable = true;

  # Enable DNS to allow connecting to me via hostname
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };
}
