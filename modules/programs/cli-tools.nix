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
