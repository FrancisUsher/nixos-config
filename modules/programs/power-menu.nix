{ ... }:

{
  xdg.desktopEntries = {
    "lock-screen" = {
      name = "System -> Lock screen";
      comment = "Lock the screen using swaylock";
      exec = "swaylock";
      icon = "icon-lock-128";
      terminal = true;
      type = "Application";
      categories = [ "System" ];
    };
    "logout" = {
      name = "Session -> Logout";
      comment = "Exit the user session and return to the greeter";
      exec = "swaymsg exit";
      icon = "icon-logout-128";
      terminal = true;
      type = "Application";
      categories = [ "System" ];
    };
    "power-reboot" = {
      name = "Power -> Reboot";
      comment = "Reboot the system";
      exec = "reboot";
      icon = "icon-reboot-128";
      terminal = true;
      type = "Application";
      categories = [ "System" ];
    };
    "power-shutdown" = {
      name = "Power -> Shutdown";
      comment = "Shutdown system immediately (but safely)";
      exec = "shutdown now";
      icon = "icon-power-128";
      terminal = true;
      type = "Application";
      categories = [ "System" ];
    };
  };

  home.file = {
    ".local/share/icons/hicolor/128x128/apps/icon-lock-128.png".source =
      ./power-menu-icons/icon-lock-128.png;
    ".local/share/icons/hicolor/128x128/apps/icon-logout-128.png".source =
      ./power-menu-icons/icon-logout-128.png;
    ".local/share/icons/hicolor/128x128/apps/icon-reboot-128.png".source =
      ./power-menu-icons/icon-reboot-128.png;
    ".local/share/icons/hicolor/128x128/apps/icon-power-128.png".source =
      ./power-menu-icons/icon-power-128.png;
  };
}
