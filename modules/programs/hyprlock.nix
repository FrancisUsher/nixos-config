{ ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      general.ignore_empty_input = true;
      auth.fingerprint = {
        enabled = true;
        ready_message = "Scan fingerprint to unlock";
        present_message = "Scanning...";
      };
    };
  };

  stylix.targets.hyprlock.enable = true;
}
