{ ... }:

{
  programs.waybar = {
    enable = true;
    settings.mainBar = {
      height = 30;
      spacing = 4;
      modules-left = [
        "sway/workspaces"
        "sway/mode"
        "sway/scratchpad"
      ];
      modules-center = [ "sway/window" ];
      modules-right = [
        "network"
        "battery"
        "clock"
        "tray"
      ];
      "sway/mode".format = "<span style=\"italic\">{}</span>";
      "sway/scratchpad" = {
        format = "{icon} {count}";
        show-empty = false;
        format-icons = [ "" "" ];
        tooltip = true;
        tooltip-format = "{app}: {title}";
      };
      tray.spacing = 10;
      clock = {
        format = "{:%Y-%m-%d@%H%M}";
        tooltip-format = "<big>{:%A, %d}</big>\n<tt><small>{calendar}</small></tt>";
      };
      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{capacity}% {icon}";
        format-full = "{capacity}% {icon}";
        format-charging = "{capacity}% ";
        format-plugged = "{capacity}% ";
        format-alt = "{time} {icon}";
        format-icons = [ "" "" "" "" "" ];
      };
      network = {
        format-wifi = "";
        format-ethernet = "{ipaddr}/{cidr} ";
        tooltip-format-ethernet = "{ifname} via {gwaddr} ";
        tooltip-format-wifi = "{essid} ({signalStrength}%)";
        format-linked = "{ifname} (No IP) ";
        format-disconnected = "⚠";
        format-alt = "{ifname}: {ipaddr}/{cidr}";
      };
    };
    # Structural CSS only - no colors here. Stylix's waybar target
    # (stylix.targets.waybar.enable below) injects the Ancient Ruins
    # palette's @define-color variables and window#waybar/tooltip color
    # rules on top of this at build time.
    style = ''
      window#waybar {
          transition-property: background-color;
          transition-duration: .5s;
      }

      window#waybar.hidden {
          opacity: 0.2;
      }

      tooltip {
          border-radius: 0;
      }

      .tooltip label {
          margin-top: -6px;
      }

      button {
          /* Use box-shadow instead of border so the text isn't offset */
          box-shadow: inset 0 -3px transparent;
          /* Avoid rounded borders under each button name */
          border: none;
          border-radius: 0;
      }

      /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
      button:hover {
          background: inherit;
      }

      #workspaces button {
          padding: 0 5px;
          background-color: transparent;
      }

      #clock,
      #battery,
      #network,
      #tray,
      #mode,
      #scratchpad {
          padding: 0 10px;
      }

      #window,
      #workspaces {
          margin: 0 4px;
      }

      /* If workspaces is the leftmost module, omit left margin */
      .modules-left > widget:first-child > #workspaces {
          margin-left: 0;
      }

      /* If workspaces is the rightmost module, omit right margin */
      .modules-right > widget:last-child > #workspaces {
          margin-right: 0;
      }

      #clock {
          background-color: transparent;
      }

      #battery {
          background-color: transparent;
      }

      #network {
          background-color: transparent;
      }
    '';
  };

  stylix.targets.waybar.enable = true;
}
