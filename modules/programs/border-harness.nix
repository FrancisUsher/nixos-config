{ config, lib, pkgs, ... }:

let
  palette = removeAttrs (import ../themes/ancient-ruins.nix) [ "slug" "scheme" "author" ];
  paletteJson = pkgs.writeText "border-harness-palette.json" (builtins.toJSON palette);

  selection = builtins.fromJSON (builtins.readFile ./border-harness-selection.json);
  selectionJson = pkgs.writeText "border-harness-selection.json" (builtins.toJSON selection);

  algorithm = selection.algorithm or "procedural";
  customBorders = algorithm != "none";
  layout = {
    custom = { gaps_out = 0; border_size = 0; };
    minimal = { gaps_out = 10; border_size = 1; };
  };
  layoutJson = pkgs.writeText "border-harness-layout.json" (builtins.toJSON layout);

  hyprlandConfig = config.wayland.windowManager.hyprland.settings.config;

  borderHarnessGenerate = pkgs.writeShellApplication {
    name = "border-harness-generate";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      palette="''${BORDER_HARNESS_PALETTE:-$HOME/.config/border-harness/palette.json}"
      selection="''${BORDER_HARNESS_SELECTION:-$HOME/nixos-config/modules/programs/border-harness-selection.json}"
      live="''${BORDER_HARNESS_LIVE:-$HOME/.cache/border-harness/live.lua}"
      layout="''${BORDER_HARNESS_LAYOUT:-$HOME/.config/border-harness/layout.json}"
      python3 ${./border-harness-apply.py} --palette "$palette" --write-selection "$selection" --live-lua "$live" --layout "$layout" "$@"
      hyprctl reload >/dev/null 2>&1 || true
    '';
  };
in
{
  home.packages = [ borderHarnessGenerate ];

  xdg.configFile."border-harness/palette.json".source = paletteJson;
  xdg.configFile."border-harness/selection.json".source = selectionJson;
  xdg.configFile."border-harness/layout.json".source = layoutJson;

  home.activation.borderHarnessReset = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD rm -f "$HOME/.cache/border-harness/live.lua"
  '';

  wayland.windowManager.hyprland.settings.config.general = {
    inherit (layout.${if customBorders then "custom" else "minimal"}) gaps_out border_size;
  };

  wayland.windowManager.hyprland.settings.config.plugin.imgborders = {
    mode = if customBorders then "procedural" else "image";
    seed = selection.seed or 1;
    roughness = selection.roughness or 0.5;
    chipping = selection.chipping or 0.4;
    moss = selection.moss or 0.2;
    stone_blend = selection.stone_blend;
    highlight_blend = selection.highlight_blend;
    color_mortar = palette.base00;
    color_accent = palette.${selection.accent};
    color_moss = palette.base0B;
    merge = selection.merge or true;
    merge_distance = 2 * hyprlandConfig.general.gaps_in + 2;
  };

  wayland.windowManager.hyprland.extraConfig = ''
    local borderHarnessOk, borderHarnessLive = pcall(dofile, os.getenv("HOME") .. "/.cache/border-harness/live.lua")
    if borderHarnessOk and type(borderHarnessLive) == "table" then
      hl.config(borderHarnessLive)
    end
  '';
}
