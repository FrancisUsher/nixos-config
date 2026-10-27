{ config, lib, ... }:

{
  config.programs.git = {
    enable = true;
    settings = {
      user.name = "Francis Usher";
      user.email = "francis.w.usher@gmail.com";
      init.defaultBranch = "main";
      core.editor = "nvim";
      push.autoSetupRemote = true;
      pull.rebase = true;
      alias = {
        s = "status";
        c = "commit -m";
        d = "diff";
        l = "log";
        a = "add";
      };
    };
  };
  config.home.shellAliases = lib.mkIf config.programs.git.enable {
    g = "git";
    gs = "git status";
    gc = "git commit -m";
    gd = "git diff";
    gl = "git log";
    ga = "git add";
  };
}
