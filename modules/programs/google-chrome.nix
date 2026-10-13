{ unstableUnfreePkgs, ... }:

{
  programs.google-chrome = {
    enable = true;
    package = unstableUnfreePkgs.google-chrome;
  };
}
