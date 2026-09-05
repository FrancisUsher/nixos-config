{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "Francis Usher";
      user.email = "francis.w.usher@gmail.com";
      init.defaultBranch = "main";
      core.editor = "nvim";
      push.autoSetupRemote = true;
    };
  };
}
