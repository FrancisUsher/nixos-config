{ lib, pkgs, ... }:

let
  palette = removeAttrs (import ../themes/ancient-ruins.nix) [ "slug" "scheme" "author" ];
  paletteJson = pkgs.writeText "border-harness-palette.json" (builtins.toJSON palette);

  selection = builtins.fromJSON (builtins.readFile ./border-harness-selection.json);
  selectionJson = pkgs.writeText "border-harness-selection.json" (builtins.toJSON selection);

  generatorScript = ./ancient-ruins-border-gen.py;
  pythonWithPillow = pkgs.python3.withPackages (ps: [ ps.pillow ]);

  borderHarnessGenerate = pkgs.writeShellApplication {
    name = "border-harness-generate";
    runtimeInputs = [ pythonWithPillow ];
    text = ''
      palette="''${BORDER_HARNESS_PALETTE:-$HOME/.config/border-harness/palette.json}"
      out="''${BORDER_HARNESS_OUT:-$HOME/.cache/border-harness/current.png}"
      selection="''${BORDER_HARNESS_SELECTION:-$HOME/nixos-config/modules/programs/border-harness-selection.json}"
      mkdir -p "$(dirname "$out")"
      python3 ${generatorScript} --palette "$palette" --out "$out" --write-selection "$selection" "$@"
      hyprctl reload >/dev/null 2>&1 || true
    '';
  };

  defaultBorderImage = pkgs.runCommand "ancient-ruins-border-default.png" {
    nativeBuildInputs = [ pythonWithPillow ];
  } ''
    python3 ${generatorScript} --palette ${paletteJson} --out $out \
      --accent ${selection.accent} \
      --stone-blend ${toString selection.stone_blend} \
      --highlight-blend ${toString selection.highlight_blend}
  '';
in
{
  home.packages = [ borderHarnessGenerate ];

  xdg.configFile."border-harness/palette.json".source = paletteJson;
  xdg.configFile."border-harness/selection.json".source = selectionJson;

  home.activation.borderHarnessSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.cache/border-harness"
    $DRY_RUN_CMD install -m 644 ${defaultBorderImage} "$HOME/.cache/border-harness/current.png"
  '';
}
