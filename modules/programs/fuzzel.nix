{ ... }:

{
  programs.fuzzel = {
    enable = true;
    settings = {
      main.filter-desktop = true;
      border = {
        width = 4;
        radius = 0;
      };
    };
  };

  stylix.targets.fuzzel.enable = true;
}
