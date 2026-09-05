# Shared Stylix config for both hosts. Replaces arch-reference/themer/ (the
# old Python+Jinja engine) for everything Stylix has a target for; that
# engine's palette.toml is ported into modules/themes/ancient-ruins.nix.
# themer/ itself is left in place (not deleted), now just as dead reference
# material - plymouth_themes/oreb/ has been ported (see modules/
# plymouth-oreb.nix, imported below instead of stylix.targets.plymouth).
#
# This is the NixOS-level half. Per-app targets (kitty, waybar, fuzzel, sway,
# starship, nixvim) live under home-manager and are enabled in home.nix
# instead - stylix.targets.<app> for those only exists in the home-manager
# module tree, not here.
{ pkgs, ... }:

{
  imports = [ ./tuigreet-theme.nix ./plymouth-oreb.nix ];

  stylix.enable = true;
  stylix.base16Scheme = import ./themes/ancient-ruins.nix;
  # Explicit even though inferable from the scheme, for robustness against
  # future Stylix default changes.
  stylix.polarity = "dark";

  # stylix.image has no default and is required even with an explicit
  # base16Scheme (some targets read it unconditionally). No real wallpaper
  # exists yet (sway isn't ported), so this is a 1x1 placeholder in the
  # palette's own background color - swap for a real wallpaper once a Sway
  # session exists.
  stylix.image =
    let
      bg = (import ./themes/ancient-ruins.nix).base00;
    in
    pkgs.runCommand "ancient-ruins-placeholder-wallpaper.png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        convert -size 1x1 xc:'#${bg}' $out
      '';

  stylix.fonts.monospace = {
    package = pkgs.nerd-fonts.meslo-lg;
    name = "MesloLGS Nerd Font Mono";
  };

  # autoEnable=true (the default) tries to activate every target Stylix has
  # a module for, including ones we have no use for (e.g. fcitx5) - and on
  # this nixpkgs/home-manager pin (nixos-24.11) at least one of those
  # (fcitx5) hits an option path that
  # doesn't exist in this home-manager version and hard-fails eval. Turning
  # it off and listing targets explicitly avoids that, and avoids surprise
  # theming of apps we didn't ask for. This propagates to the home-manager
  # side too (stylix.autoEnable is one of the options followSystem forwards)
  # so it does not need to be repeated in home.nix.
  stylix.autoEnable = false;

  stylix.targets = {
    # Fixes the original pain point: TTY/vconsole colors, previously only
    # achievable by hand-setting COLOR_0..COLOR_15 in /etc/vconsole.conf.
    console.enable = true;

    # plymouth is turned off here (modules/plymouth-oreb.nix, imported
    # above, does that) in favor of the custom "oreb" theme, which now uses
    # this same palette instead of Stylix's own generated logo/spinner theme.
  };

  # see tuigreet-theme.nix - same named-color-via-console-palette mechanism
  environment.sessionVariables.NEWT_COLORS = "root=white,black:roottext=lightgrey,black:window=white,black:border=brightblack,black:shadow=brightblack,black:title=brightblue,black:button=brightblue,black:actbutton=brightblue,black:compactbutton=brightwhite,black:checkbox=brightgreen,black:actcheckbox=brightgreen,black:entry=white,black:disentry=gray,lightgray:label=black,lightgray:listbox=white,black:actlistbox=black,cyan:sellistbox=lightgray,black:actsellistbox=lightgray,black:textbox=black,lightgray:acttextbox=black,cyan:emptyscale=,gray:fullscale=,cyan:helpline=white,black:";
}
