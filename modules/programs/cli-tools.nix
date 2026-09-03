{ pkgs, ... }:

{
  home.packages = [ pkgs.gitleaks ];

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
    # Stylix's starship target exists on this pin (26.05) but isn't wired up
    # yet - see the "Wire up Stylix theming for starship" todo in
    # notes/dotfiles-and-editor.md. Runs on plain upstream defaults meanwhile.
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
}
