{ pkgs, ... }:

{
  home.packages = [ pkgs.kicad ];
  # Kicad wants to expose lots of different desktop entries to our launcher
  # so disable all of these except the one(s) we want to use regularly.
  # Why override visibility rather than removing the entry?
  # Because we still want stuff like e.g. MimeType associations intact for
  # anything that looks them up directly; just exclude them from menus.
  xdg.desktopEntries = {
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
