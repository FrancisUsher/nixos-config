{ ... }:

{
  imports = [
    ./modules/nixvim.nix
    ./modules/programs/git.nix
    ./modules/programs/gh.nix
    ./modules/programs/glow.nix
    ./modules/programs/fastfetch.nix
    ./modules/programs/zmk.nix
    ./modules/programs/zsh.nix
    ./modules/programs/cli-tools.nix
    ./modules/programs/kitty.nix
    ./modules/programs/sway.nix
    ./modules/programs/swaylock.nix
    ./modules/programs/waybar.nix
    ./modules/programs/fuzzel.nix
  ];

  home.username = "soong";
  home.homeDirectory = "/home/soong";
  home.stateVersion = "24.11";

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
