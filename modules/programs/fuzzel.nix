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
    yazi = {
      name = "Yazi File Manager";
      comment = "Blazing fast terminal file manager written in Rust, based on async I/O";
      exec = "yazi %f";
      terminal = true;
      icon = "yazi";
      categories = [ "System" "FileManager" "FileTools" "ConsoleOnly" ];
      mimeType = [ "inode/directory" ];
      noDisplay = true;
    };
    nixos-manual = {
      name = "NixOS Manual";
      genericName = "System Manual";
      comment = "View NixOS documentation in a web browser";
      exec = "nixos-help";
      icon = "nix-snowflake";
      categories = [ "System" ];
      noDisplay = true;
    };
    "org.kicad.bitmap2component" = {
      name = "KiCad Image Converter";
      genericName = "Bitmap to Component Converter";
      comment = "Create a component from a bitmap for use with KiCad";
      exec = "bitmap2component %f";
      icon = "bitmap2component";
      categories = [ "Science" "Electronics" ];
      noDisplay = true;
    };
    "org.kicad.eeschema" = {
      name = "KiCad Schematic Editor (Standalone)";
      genericName = "Schematic Capture Tool";
      comment = "Standalone schematic editor for KiCad schematics";
      exec = "eeschema %f";
      icon = "eeschema";
      categories = [ "Science" "Electronics" ];
      mimeType = [ "application/x-kicad-schematic" ];
      noDisplay = true;
    };
    "org.kicad.gerbview" = {
      name = "KiCad Gerber Viewer";
      genericName = "Gerber File Viewer";
      comment = "View Gerber files";
      exec = "gerbview %F";
      icon = "gerbview";
      categories = [ "Science" "Electronics" ];
      mimeType = [ "application/x-gerber" "application/x-excellon" "application/x-gerber-job" ];
      noDisplay = true;
    };
    "org.kicad.pcbcalculator" = {
      name = "KiCad PCB Calculator";
      genericName = "PCB Calculator";
      comment = "Calculator for various electronics-related computations";
      exec = "pcb_calculator";
      icon = "pcbcalculator";
      categories = [ "Science" "Electronics" ];
      noDisplay = true;
    };
    "org.kicad.pcbnew" = {
      name = "KiCad PCB Editor (Standalone)";
      genericName = "PCB layout editor";
      comment = "Standalone circuit board editor for KiCad boards";
      exec = "pcbnew %f";
      icon = "pcbnew";
      categories = [ "Science" "Electronics" ];
      mimeType = [ "application/x-kicad-pcb" ];
      noDisplay = true;
    };
  };
}
