{ pkgs, ... }:

{
  imports = [ ./modules/nixvim.nix ];

  home.username = "soong";
  home.homeDirectory = "/home/soong";
  home.stateVersion = "24.11";

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
