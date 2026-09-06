{ config, lib, pkgs, ... }:

let
  modifier = config.wayland.windowManager.sway.config.modifier;

  pythonEnv = pkgs.python3.withPackages (ps: [ ps.pygobject3 ]);

  hotkeyOverlay = pkgs.stdenv.mkDerivation {
    pname = "hotkey-overlay";
    version = "0.1.0";

    dontUnpack = true;
    dontBuild = true;
    dontWrapGApps = true;
    strictDeps = false;

    nativeBuildInputs = [ pkgs.wrapGAppsHook3 pkgs.gobject-introspection pkgs.makeWrapper ];
    buildInputs = [ pkgs.gtk3 pkgs.gtk-layer-shell ];

    installPhase = ''
      install -Dm444 ${./hotkey-overlay/hotkey-overlay.py} $out/share/hotkey-overlay/hotkey-overlay.py
    '';

    preFixup = ''
      makeWrapper ${pythonEnv}/bin/python3 $out/bin/hotkey-overlay \
        --add-flags $out/share/hotkey-overlay/hotkey-overlay.py \
        "''${gappsWrapperArgs[@]}"
    '';

    meta.mainProgram = "hotkey-overlay";
  };
in
{
  home.packages = [ hotkeyOverlay ];

  wayland.windowManager.sway.config.keybindings = lib.mkOptionDefault {
    "${modifier}+question" = "exec ${lib.getExe hotkeyOverlay}";
  };
}
