{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tmux
    mosh
  ];

  programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g status-right "#{?#{==:#{client_key_table},root},,MODE:#{client_key_table} }%H:%M "
      set -g mouse off
      set -s set-clipboard external
      set -as terminal-overrides ',*:Ms=\E]52;c;%p2%s\7'
      set-window-option -g mode-keys vi

      bind-key -T root C-Space switch-client -T sway

      bind-key -T sway h select-pane -L
      bind-key -T sway j select-pane -D
      bind-key -T sway k select-pane -U
      bind-key -T sway l select-pane -R
      bind-key -T sway H resize-pane -L 10
      bind-key -T sway J resize-pane -D 10
      bind-key -T sway K resize-pane -U 10
      bind-key -T sway L resize-pane -R 10

      bind-key -T sway 1 select-window -t :1
      bind-key -T sway 2 select-window -t :2
      bind-key -T sway 3 select-window -t :3
      bind-key -T sway 4 select-window -t :4
      bind-key -T sway 5 select-window -t :5
      bind-key -T sway 6 select-window -t :6
      bind-key -T sway 7 select-window -t :7
      bind-key -T sway 8 select-window -t :8
      bind-key -T sway 9 select-window -t :9
      bind-key -T sway 0 select-window -t :10

      bind-key -T sway b split-window -h -c "#{pane_current_path}"
      bind-key -T sway f resize-pane -Z
      bind-key -T sway Q kill-pane
      bind-key -T sway Enter new-window -c "#{pane_current_path}"

      bind-key -T sway r switch-client -T sway-resize
      bind-key -T sway-resize h resize-pane -L 10
      bind-key -T sway-resize j resize-pane -D 10
      bind-key -T sway-resize k resize-pane -U 10
      bind-key -T sway-resize l resize-pane -R 10
      bind-key -T sway-resize Enter switch-client -T sway
      bind-key -T sway-resize Escape switch-client -T sway

      bind-key -T sway Escape switch-client -T root
    '';
  };

  # Auto-attach a persistent tmux session on interactive login (ssh or
  # mosh), so a dropped connection (e.g. laptop sleep) doesn't kill what
  # was running - just reconnect and you're back in it.
  programs.bash.interactiveShellInit = ''
    if [[ $- == *i* ]] && [ -z "''${TMUX:-}" ]; then
      tmux attach -t main || tmux new -s main
    fi
  '';
  programs.zsh.interactiveShellInit = ''
    if [[ -o interactive ]] && [ -z "''${TMUX:-}" ]; then
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
