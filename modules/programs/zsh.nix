{ pkgs, ... }:

{
  home.packages = [ pkgs.acpi ]; # needed by the battery alias below

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    defaultKeymap = "viins"; # enables vi mode
    history = {
      size = 20000;
      save = 50000;
    };
    shellAliases = {
      ":q" = "exit";
      ls = "ls --color=auto -la";
      vim = "nvim";
      battery = "acpi -b";
    };
    initContent = ''
      # Quickly connect to home server: try local mDNS first, fall back to
      # Tailscale if not on the LAN.
      bb() {
        if timeout 0.5 bash -c "echo > /dev/tcp/bubu-brain.local/22" 2>/dev/null; then
          mosh bubu
        else
          mosh bubu-jip
        fi
      }
    '';
  };
}
