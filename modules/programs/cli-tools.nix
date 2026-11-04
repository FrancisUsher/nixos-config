{ pkgs, lib, config, ... }:

{

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

  home.shellAliases = {
    cat = lib.mkIf config.programs.bat.enable "bat";
    grep = lib.mkIf config.programs.ripgrep.enable "rg";
  };
  home.sessionVariables = {
    MANPAGER = lib.mkIf config.programs.bat.enable "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = lib.mkIf config.programs.bat.enable "-c";
  };
}
