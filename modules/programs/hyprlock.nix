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
      label = {
        text = "$FPRINTPROMPT";
        halign = "center";
        valign = "center";
        position = "0, 150";
      };
      input-field.fail_text = "$FAIL ($ATTEMPTS)";
    };
  };

  stylix.targets.hyprlock.enable = true;
}
