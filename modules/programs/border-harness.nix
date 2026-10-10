{ config, lib, pkgs, ... }:

let
  palette = removeAttrs (import ../themes/ancient-ruins.nix) [ "slug" "scheme" "author" ];
  paletteJson = pkgs.writeText "border-harness-palette.json" (builtins.toJSON palette);

  selection = builtins.fromJSON (builtins.readFile ./border-harness-selection.json);
  selectionJson = pkgs.writeText "border-harness-selection.json" (builtins.toJSON selection);

  hyprlandConfig = config.wayland.windowManager.hyprland.settings.config;
  imgbordersFrame = hyprlandConfig.plugin.imgborders.sizes * hyprlandConfig.plugin.imgborders.scale;
  wallJson = pkgs.writeText "border-harness-wall.json" (builtins.toJSON {
    reach = hyprlandConfig.general.gaps_in + imgbordersFrame;
    edgeReach = hyprlandConfig.general.gaps_out + imgbordersFrame;
    pixelScale = hyprlandConfig.plugin.imgborders.scale;
  });

  generatorScript = ./ancient-ruins-border-gen.py;
  pythonWithPillow = pkgs.python3.withPackages (ps: [ ps.pillow ]);

  borderHarnessGenerate = pkgs.writeShellApplication {
    name = "border-harness-generate";
    runtimeInputs = [ pythonWithPillow ];
    text = ''
      palette="''${BORDER_HARNESS_PALETTE:-$HOME/.config/border-harness/palette.json}"
      out="''${BORDER_HARNESS_OUT:-$HOME/.cache/border-harness/current.png}"
      sheet="''${BORDER_HARNESS_SHEET:-$HOME/.cache/border-harness/autotile.png}"
      selection="''${BORDER_HARNESS_SELECTION:-$HOME/nixos-config/modules/programs/border-harness-selection.json}"
      live="''${BORDER_HARNESS_LIVE:-$HOME/.cache/border-harness/live.lua}"
      mkdir -p "$(dirname "$out")"
      python3 ${generatorScript} --palette "$palette" --out "$out" --sheet-out "$sheet" --write-selection "$selection" --live-lua "$live" "$@"
      hyprctl reload >/dev/null 2>&1 || true
    '';
  };

  defaultBorderImages = pkgs.runCommand "ancient-ruins-border-defaults" {
    nativeBuildInputs = [ pythonWithPillow ];
  } ''
    mkdir -p $out
    python3 ${generatorScript} --palette ${paletteJson} \
      --out $out/current.png --sheet-out $out/autotile.png \
      --algorithm ${selection.algorithm or "sprite"} \
      --accent ${selection.accent} \
      --stone-blend ${toString selection.stone_blend} \
      --highlight-blend ${toString selection.highlight_blend}
  '';
in
{
  home.packages = [ borderHarnessGenerate ];

  xdg.configFile."border-harness/palette.json".source = paletteJson;
  xdg.configFile."border-harness/selection.json".source = selectionJson;
  xdg.configFile."border-harness/wall.json".source = wallJson;

  home.activation.borderHarnessSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.cache/border-harness"
    $DRY_RUN_CMD install -m 644 ${defaultBorderImages}/current.png "$HOME/.cache/border-harness/current.png"
    $DRY_RUN_CMD install -m 644 ${defaultBorderImages}/autotile.png "$HOME/.cache/border-harness/autotile.png"
    $DRY_RUN_CMD rm -f "$HOME/.cache/border-harness/live.lua"
  '';

  wayland.windowManager.hyprland.settings.config.plugin.imgborders = {
    mode = if (selection.algorithm or "sprite") == "procedural" then "procedural" else "image";
    seed = selection.seed or 1;
    roughness = selection.roughness or 0.5;
    chipping = selection.chipping or 0.4;
    moss = selection.moss or 0.2;
    stone_blend = selection.stone_blend;
    highlight_blend = selection.highlight_blend;
    color_mortar = palette.base00;
    color_accent = palette.${selection.accent};
    color_moss = palette.base0B;
  };

  wayland.windowManager.hyprland.extraConfig = ''
    local borderHarnessOk, borderHarnessLive = pcall(dofile, os.getenv("HOME") .. "/.cache/border-harness/live.lua")
    if borderHarnessOk and type(borderHarnessLive) == "table" then
      hl.config({ plugin = { imgborders = borderHarnessLive } })
    end
  '';
}
