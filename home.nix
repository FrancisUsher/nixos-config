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
  # programs.glow block. acpi is for the zsh `battery` alias below.
  home.packages = [ pkgs.glow pkgs.acpi ];
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

  # zsh is the actual login shell (users.users.soong.shell in hosts/*/
  # configuration.nix); bash stays enabled below as a fallback/compat
  # shell, not the primary one.
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    defaultKeymap = "viins"; # bindkey -v, as in arch-reference's .zshrc
    history = {
      size = 20000;
      save = 50000;
    };
    shellAliases = {
      ":q" = "exit";
      ls = "ls --color=auto -la";
      vim = "nvim";
      battery = "acpi -b";
      # icat (kitten icat) deliberately left out - kitty itself isn't
      # ported yet (TODO.md), so `kitten` wouldn't exist. Add once kitty
      # lands.
    };
    # Bare-repo `dots` alias and `todo.sh` dropped (unused); `yay=paru` was
    # Arch/AUR-only and has no NixOS equivalent worth aliasing.
    initExtra = ''
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
    # Theme for newt-based TUIs (nmtui, etc). Named ANSI slots only - newt
    # reads the actual RGB for each one off the console's 16-color palette,
    # which Stylix already themes via modules/stylix.nix's
    # stylix.targets.console.enable, so this inherits the active base16
    # scheme automatically without needing its own Stylix wiring.
    NEWT_COLORS = "root=white,black:roottext=lightgrey,black:window=white,black:border=brightblack,black:shadow=brightblack,black:title=brightblue,black:button=brightblue,black:actbutton=brightblue,black:compactbutton=brightwhite,black:checkbox=brightgreen,black:actcheckbox=brightgreen,black:entry=white,black:disentry=gray,lightgray:label=black,lightgray:listbox=white,black:actlistbox=black,cyan:sellistbox=lightgray,black:actsellistbox=lightgray,black:textbox=black,lightgray:acttextbox=black,cyan:emptyscale=,gray:fullscale=,cyan:helpline=white,black:";
  };
}
