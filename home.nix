{ pkgs, config, hostName, ... }:

{
  imports = [ ./modules/nixvim.nix ];

  home.username = "soong";
  home.homeDirectory = "/home/soong";
  home.stateVersion = "24.11";

  programs.git = {
    enable = true;
    userName = "Francis Usher";
    userEmail = "francis.w.usher@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };

  programs.gh = {
    enable = true;
    settings.aliases.co = "pr checkout";
  };

  # No home-manager module for glow exists on this nixpkgs/home-manager pin
  # (release-24.11) - config is a plain xdg.configFile instead of a
  # programs.glow block.
  home.packages = [ pkgs.glow ];
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

  # Per-host accent, standing in for real per-host base16 theming until
  # x1nano/red-sun-whorl has its own theme file the way bubu-brain has
  # modules/themes/ancient-ruins.nix (see TODO.md's "Split home.nix" item -
  # this doesn't do that split, just threads hostName through far enough
  # for fastfetch to tell hosts apart). Named colors only: fastfetch does
  # support #rrggbb, but its escaping rules for that are format-string
  # specific and unverified here without a real display to test against -
  # named colors are unambiguous.
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

  programs.bash.enable = true;
  programs.bat.enable = true;
  programs.ripgrep.enable = true;
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  # Stylix's system-level config (palette, fonts, console/plymouth targets,
  # autoEnable=false) lives in modules/stylix.nix; these per-app targets only
  # exist under home-manager, so they're enabled explicitly here instead.
  # kitty/waybar/fuzzel/sway stay dormant until those apps are actually
  # ported (see TODO.md).
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
