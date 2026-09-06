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

  # Hide entries reached another way, so the launcher only lists things
  # actually meant to be picked from it. kitty has a dedicated Sway
  # hotkey; nvim/htop are launched from a terminal. Overriding (not
  # removing) the desktop entries keeps their functionality (e.g. nvim's
  # MimeType associations) intact for anything that looks them up
  # directly, while excluding them from menus.
  xdg.desktopEntries = {
    kitty = {
      name = "kitty";
      genericName = "Terminal emulator";
      comment = "Fast, feature-rich, GPU based terminal";
      exec = "kitty";
      icon = "kitty";
      categories = [ "System" "TerminalEmulator" ];
      noDisplay = true;
    };
    nvim = {
      name = "Neovim wrapper";
      genericName = "Text Editor";
      comment = "Edit text files";
      exec = "nvim %F";
      terminal = true;
      icon = "nvim";
      categories = [ "Utility" "TextEditor" "Development" ];
      mimeType = [
        "text/english"
        "text/plain"
        "text/x-makefile"
        "text/x-c++hdr"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-csrc"
        "text/x-java"
        "text/x-moc"
        "text/x-pascal"
        "text/x-tcl"
        "text/x-tex"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++"
      ];
      noDisplay = true;
    };
    htop = {
      name = "Htop";
      genericName = "Process Viewer";
      comment = "Show System Processes";
      exec = "htop";
      terminal = true;
      icon = "htop";
      categories = [ "System" "Monitor" "ConsoleOnly" ];
      noDisplay = true;
    };
  };
}
