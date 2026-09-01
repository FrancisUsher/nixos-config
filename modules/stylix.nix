# Shared Stylix config for both hosts. Replaces arch-reference/themer/ (the
# old Python+Jinja engine) for everything Stylix has a target for; that
# engine's palette.toml is ported into modules/themes/ancient-ruins.nix and
# themer/ itself is left in place (not deleted) since plymouth_themes/oreb/
# is still needed for a deferred follow-up, see below.
#
# This is the NixOS-level half. Per-app targets (kitty, waybar, fuzzel, sway,
# starship, nixvim) live under home-manager and are enabled in home.nix
# instead - stylix.targets.<app> for those only exists in the home-manager
# module tree, not here.
{ pkgs, ... }:

{
  imports = [ ./tuigreet-theme.nix ];

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
    package = pkgs.nerdfonts.override { fonts = [ "Meslo" ]; };
    name = "MesloLGS Nerd Font Mono";
  };

  # autoEnable=true (the default) tries to activate every target Stylix has
  # a module for, including ones we have no use for (e.g. fcitx5) - and on
  # this nixpkgs/home-manager pin (nixos-24.11, see TODO.md's "Nix release
  # bump" item) at least one of those (fcitx5) hits an option path that
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

    # Stylix's own theme (colors + logo), not the custom "oreb" owl theme at
    # arch-reference/themer/plymouth_themes/oreb/ - that has no palette hook
    # (hardcoded white text) and porting it to consume
    # config.lib.stylix.colors is deferred follow-up work, see TODO.md.
    plymouth.enable = true;
  };

  # see tuigreet-theme.nix - same named-color-via-console-palette mechanism
  environment.sessionVariables.NEWT_COLORS = "root=white,black:roottext=lightgrey,black:window=white,black:border=brightblack,black:shadow=brightblack,black:title=brightblue,black:button=brightblue,black:actbutton=brightblue,black:compactbutton=brightwhite,black:checkbox=brightgreen,black:actcheckbox=brightgreen,black:entry=white,black:disentry=gray,lightgray:label=black,lightgray:listbox=white,black:actlistbox=black,cyan:sellistbox=lightgray,black:actsellistbox=lightgray,black:textbox=black,lightgray:acttextbox=black,cyan:emptyscale=,gray:fullscale=,cyan:helpline=white,black:";
}
