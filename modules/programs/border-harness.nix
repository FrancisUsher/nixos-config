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
      mkdir -p "$(dirname "$out")"
      python3 ${generatorScript} --palette "$palette" --out "$out" --sheet-out "$sheet" --write-selection "$selection" "$@"
      hyprctl reload >/dev/null 2>&1 || true
    '';
  };

  defaultBorderImages = pkgs.runCommand "ancient-ruins-border-defaults" {
    nativeBuildInputs = [ pythonWithPillow ];
  } ''
    mkdir -p $out
    python3 ${generatorScript} --palette ${paletteJson} \
      --out $out/current.png --sheet-out $out/autotile.png \
      --algorithm ${selection.algorithm or "repeating"} \
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
  '';
}
