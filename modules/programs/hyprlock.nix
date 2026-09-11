{ ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      general.ignore_empty_input = true;
      auth.fingerprint = {
        enabled = true;
        ready_message = "󰈷  Present the sacred sign";
        present_message = "󰈷  Reading the sign...";
      };
      label = [
        {
          text = "󰈷";
          font_family = "MesloLGS Nerd Font Mono";
          font_size = 48;
          halign = "center";
          valign = "center";
          position = "0, 130";
        }
        {
          text = "<b>$FPRINTPROMPT</b>";
          font_family = "MesloLGS Nerd Font Mono";
          font_size = 20;
          halign = "center";
          valign = "center";
          position = "0, 70";
        }
      ];
      input-field = {
        placeholder_text = "Speak the words of command";
        fail_text = "$FAIL ($ATTEMPTS)";
      };
    };
  };

  stylix.targets.hyprlock.enable = true;
}
