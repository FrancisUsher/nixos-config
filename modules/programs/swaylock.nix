{ ... }:

{
  programs.swaylock = {
    enable = true;
    settings = {
      ignore-empty-password = true;
    };
  };

  stylix.targets.swaylock.enable = true;
}
