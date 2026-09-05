# Ports arch-reference/themer/plymouth_themes/oreb/ (a vendored third-party
# Plymouth theme by adi1090x, renamed "oreb" but otherwise untouched) to
# consume the Ancient Ruins palette instead of its hardcoded white text.
# See the "Port oreb Plymouth theme" todo in notes/dotfiles-and-editor.md.
#
# Note this is packaged and wired up (stylix.targets.plymouth.enable is off
# in favor of this theme) but boot.plymouth.enable itself is still off, same
# as it was before this file existed - actually turning the boot splash on
# is a separate, later decision, not made here.
{ pkgs, config, ... }:
let
  colors = config.lib.stylix.colors;

  orebScript = pkgs.replaceVars ./plymouth-oreb/theme/oreb.script.tmpl {
    text_r = colors.base05-dec-r;
    text_g = colors.base05-dec-g;
    text_b = colors.base05-dec-b;
  };

  orebTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "plymouth-theme-oreb";
    version = "0-unstable";
    src = ./plymouth-oreb/theme;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/plymouth/themes/oreb
      cp oreb.plymouth progress-*.png LICENSE $out/share/plymouth/themes/oreb/
      cp ${orebScript} $out/share/plymouth/themes/oreb/oreb.script
      runHook postInstall
    '';
  };
in
{
  stylix.targets.plymouth.enable = false;

  boot.plymouth = {
    theme = "oreb";
    themePackages = [ orebTheme ];
  };
}
