{ hostName, username, lib, ... }:

{
  imports = [
    ./modules/nixvim.nix
    ./modules/programs/claude-code.nix
    ./modules/programs/git.nix
    ./modules/programs/gh.nix
    ./modules/programs/glow.nix
    ./modules/programs/fastfetch.nix
    ./modules/programs/ssh.nix
    ./modules/programs/zmk.nix
    ./modules/programs/zsh.nix
    ./modules/programs/cli-tools.nix
    ./modules/programs/starship.nix
    ./modules/programs/kitty.nix
  ] ++ lib.optionals (hostName == "red-sun-whorl") ([
    ./modules/programs/hyprlock.nix
    ./modules/programs/waybar.nix
    ./modules/programs/fuzzel.nix
    ./modules/programs/qutebrowser.nix
  ] ++ lib.optionals (username == "jahlee") [
    ./modules/programs/hyprland.nix
  ] ++ lib.optionals (username != "jahlee") [
    ./modules/programs/sway.nix
    ./modules/programs/hotkey-overlay.nix
  ]);

  home.username = username;
  home.homeDirectory = "/home/${username}";
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

  home.activation.linkNixosConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/nixos-config" ]; then
      $DRY_RUN_CMD ln -s /etc/nixos "$HOME/nixos-config"
    elif [ -d "$HOME/nixos-config" ] && [ ! -L "$HOME/nixos-config" ] && [ -z "$(ls -A "$HOME/nixos-config" 2>/dev/null)" ]; then
      $DRY_RUN_CMD rmdir "$HOME/nixos-config"
      $DRY_RUN_CMD ln -s /etc/nixos "$HOME/nixos-config"
    fi
  '';
}
