{ pkgs, config, hostName, ... }:

{
  imports = [ ./modules/nixvim.nix ];

  home.username = "soong";
  home.homeDirectory = "/home/soong";
  home.stateVersion = "24.11";

  programs.git = {
    enable = true;
    settings = {
      user.name = "Francis Usher";
      user.email = "francis.w.usher@gmail.com";
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };

  programs.gh = {
    enable = true;
    settings.aliases.co = "pr checkout";
  };

  home.packages = [ pkgs.glow pkgs.acpi pkgs.gitleaks ];
  xdg.configFile."glow/glow.yml".text = ''
    # style name or JSON path (default "auto")
    style: "auto"
    # mouse support (TUI-mode only)
    mouse: false
    # use pager to display markdown
    pager: false
    # word-wrap at width
    width: 80
    # show all files, including hidden and ignored.
    all: false
  '';

  programs.fastfetch = {
    enable = true;
    settings = {
      logo = "nixos_small";
      display.color = if hostName == "bubu-brain" then "yellow" else "red";
      modules = [
        "title"
        "separator"
        "os"
        "host"
        "uptime"
        "packages"
        "memory"
        "processes"
        "shell"
        "lm"
        "wm"
        "cursor"
        "terminal"
        "terminalfont"
      ];
    };
  };

  xdg.configFile."zmk/zmk.ini".text = ''
    [user]
    home = ${config.home.homeDirectory}/dev/zmk-config
  '';

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

  programs.bash.enable = true;
  programs.bat.enable = true;
  programs.ripgrep.enable = true;
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # Stylix's system-level config (palette, fonts, console/plymouth targets,
  # autoEnable=false) lives in modules/stylix.nix; these per-app targets only
  # exist under home-manager, so they're enabled explicitly here instead.
  # kitty/waybar/fuzzel/sway stay dormant until those apps are actually
  # ported.
  stylix.targets = {
    kitty.enable = true;
    waybar.enable = true;
    fuzzel.enable = true;
    sway.enable = true;
    nixvim.enable = true;
    # No starship target on stylix's release-24.11 branch (added in 25.05+)
    # - see flake.nix's stylix input comment. programs.starship above is
    # still enabled/themeable by hand meanwhile.
  };
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    options = [ "--cmd cd" ];
  };
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    shellWrapperName = "y";
  };

  programs.fuzzel = {
    enable = true;
    settings = {
      main.filter-desktop = true;
      border = {
        width = 4;
        radius = 0;
      };
    };
  };

  home.shellAliases = {
    cat = "bat";
    grep = "rg";
  };
  home.sessionVariables = {
    EDITOR = "nvim";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
  };
}
