{ lib, pkgs, ... }:

let
  palette = removeAttrs (import ../themes/ancient-ruins.nix) [ "slug" "scheme" "author" ];
  paletteJson = pkgs.writeText "border-harness-palette.json" (builtins.toJSON palette);

  generatorScript = ./ancient-ruins-border-gen.py;
  pythonWithPillow = pkgs.python3.withPackages (ps: [ ps.pillow ]);

  borderHarnessGenerate = pkgs.writeShellApplication {
    name = "border-harness-generate";
    runtimeInputs = [ pythonWithPillow ];
    text = ''
      palette="''${BORDER_HARNESS_PALETTE:-$HOME/.config/border-harness/palette.json}"
      out="''${BORDER_HARNESS_OUT:-$HOME/.cache/border-harness/current.png}"
      mkdir -p "$(dirname "$out")"
      python3 ${generatorScript} --palette "$palette" --out "$out" "$@"
      hyprctl reload >/dev/null 2>&1 || true
    '';
  };

  defaultBorderImage = pkgs.runCommand "ancient-ruins-border-default.png" {
    nativeBuildInputs = [ pythonWithPillow ];
  } ''
    python3 ${generatorScript} --palette ${paletteJson} --out $out
  '';
in
{
  home.packages = [ borderHarnessGenerate ];

  xdg.configFile."border-harness/palette.json".source = paletteJson;

  home.activation.borderHarnessSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.cache/border-harness"
    $DRY_RUN_CMD cp -f ${defaultBorderImage} "$HOME/.cache/border-harness/current.png"
  '';
}
