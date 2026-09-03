{ pkgs, config, hostName, ... }:

{
  imports = [ ./modules/nixvim.nix ];

  home.username = "soong";
  home.homeDirectory = "/home/soong";
  home.stateVersion = "24.11";

  programs.git = {
    enable = true;
    settings = {
      user.name = "Francis Usher";
      user.email = "francis.w.usher@gmail.com";
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };

  programs.gh = {
    enable = true;
    settings.aliases.co = "pr checkout";
  };

  programs.swaylock = {
    enable = true;
    settings = {
      ignore-empty-password = true;
    };
  };

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

  home.packages = [ pkgs.glow pkgs.acpi pkgs.gitleaks ];
  xdg.configFile."glow/glow.yml".text = ''
    # style name or JSON path (default "auto")
    style: "auto"
    # mouse support (TUI-mode only)
    mouse: false
    # use pager to display markdown
    pager: false
    # word-wrap at width
    width: 80
    # show all files, including hidden and ignored.
    all: false
  '';

  programs.fastfetch = {
    enable = true;
    settings = {
      logo = "nixos_small";
      display.color = if hostName == "bubu-brain" then "yellow" else "red";
      modules = [
        "title"
        "separator"
        "os"
        "host"
        "uptime"
        "packages"
        "memory"
        "processes"
        "shell"
        "lm"
        "wm"
        "cursor"
        "terminal"
        "terminalfont"
      ];
    };
  };

  xdg.configFile."zmk/zmk.ini".text = ''
    [user]
    home = ${config.home.homeDirectory}/dev/zmk-config
  '';

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    defaultKeymap = "viins"; # enables vi mode
    history = {
      size = 20000;
      save = 50000;
    };
    shellAliases = {
      ":q" = "exit";
      ls = "ls --color=auto -la";
      vim = "nvim";
      battery = "acpi -b";
    };
    initContent = ''
      # Quickly connect to home server: try local mDNS first, fall back to
      # Tailscale if not on the LAN.
      bb() {
        if timeout 0.5 bash -c "echo > /dev/tcp/bubu-brain.local/22" 2>/dev/null; then
          mosh bubu
        else
          mosh bubu-jip
        fi
      }
    '';
  };

  programs.bash.enable = true;
  programs.bat.enable = true;
  programs.ripgrep.enable = true;
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  programs.kitty = {
    enable = true;
    settings = {
      scrollback_lines = 10000;
      mouse_hide_wait = -3.0;
      hide_window_decorations = true;
      tab_bar_style = "powerline";
      tab_powerline_style = "round";
      allow_remote_control = true;
    };
    shellIntegration = {
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };

  # Stylix's system-level config (palette, fonts, console/plymouth targets,
  # autoEnable=false) lives in modules/stylix.nix; these per-app targets only
  # exist under home-manager, so they're enabled explicitly here instead.
  # kitty/waybar/fuzzel/sway stay dormant until those apps are actually
  # ported.
  stylix.targets = {
    kitty.enable = true;
    waybar.enable = true;
    fuzzel.enable = true;
    sway.enable = true;
    nixvim.enable = true;
    swaylock.enable = true;
    # No starship target on stylix's release-24.11 branch (added in 25.05+)
    # - see flake.nix's stylix input comment. programs.starship above is
    # still enabled/themeable by hand meanwhile.
  };
  wayland.windowManager.sway = {
    enable = true;
    config = {
      modifier = "Mod4";
      terminal = "kitty";
      menu = "fuzzel";

      window = {
        titlebar = false;
        hideEdgeBorders = "smart";
      };
      floating.titlebar = false;

      gaps.smartGaps = true;
      gaps.smartBorders = "on";

      bars = [ { command = "waybar"; } ];

      keybindings =
        let
          modifier = config.wayland.windowManager.sway.config.modifier;
          menu = config.wayland.windowManager.sway.config.menu;
        in
        {
          "${modifier}+d" = null;
          "${modifier}+p" = "exec ${menu}";

          "Print" = "exec grim";
          "--locked XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
          "--locked XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
          "--locked XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
          "--locked XF86AudioMicMute" = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";
          "--locked XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
          "--locked XF86MonBrightnessUp" = "exec brightnessctl set 5%+";
        };
    };
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

  home.shellAliases = {
    cat = "bat";
    grep = "rg";
  };
  home.sessionVariables = {
    EDITOR = "nvim";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    MANROFFOPT = "-c";
  };
}
