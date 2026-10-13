import argparse
import json
import os


def to_lua(value, indent=""):
    if isinstance(value, dict):
        inner = indent + "  "
        body = "".join(f"{inner}{k} = {to_lua(v, inner)},\n" for k, v in value.items())
        return "{\n" + body + indent + "}"
    return json.dumps(value)


def write_live_lua(path, args, palette, layout):
    custom = args.algorithm != "none"
    profile = layout["custom" if custom else "minimal"]
    config = {
        "general": {
            "gaps_out": profile["gaps_out"],
            "border_size": profile["border_size"],
        },
        "plugin": {
            "imgborders": {
                "mode": "procedural" if custom else "image",
                "seed": args.seed,
                "roughness": args.roughness,
                "chipping": args.chipping,
                "moss": args.moss,
                "stone_blend": args.stone_blend,
                "highlight_blend": args.highlight_blend,
                "color_mortar": palette[args.mortar],
                "color_accent": palette[args.accent],
                "color_moss": palette[args.moss_slot],
                "merge": args.merge,
            },
        },
    }
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write("return " + to_lua(config) + "\n")
    os.replace(tmp, path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--palette", required=True, help="path to palette.json")
    parser.add_argument("--layout", required=True, help="layout.json with gap/border profiles for custom and minimal modes")
    parser.add_argument("--live-lua", required=True, help="write Hyprland config overrides as a Lua table to this path")
    parser.add_argument("--accent", default="base09", help="palette slot for the brick hue")
    parser.add_argument("--mortar", default="base00", help="palette slot for background/mortar")
    parser.add_argument("--stone-blend", type=float, default=0.20)
    parser.add_argument("--highlight-blend", type=float, default=0.45)
    parser.add_argument("--algorithm", choices=("none", "procedural"), default="procedural")
    parser.add_argument("--seed", type=int, default=1)
    parser.add_argument("--roughness", type=float, default=0.5)
    parser.add_argument("--chipping", type=float, default=0.4)
    parser.add_argument("--moss", type=float, default=0.2)
    parser.add_argument("--moss-slot", default="base0B")
    parser.add_argument("--merge", action=argparse.BooleanOptionalAction, default=True)
    parser.add_argument(
        "--write-selection",
        help="also write the applied params as JSON to this path, if its parent directory exists",
    )
    args = parser.parse_args()

    with open(args.palette) as f:
        palette = json.load(f)
    with open(args.layout) as f:
        layout = json.load(f)
    os.makedirs(os.path.dirname(args.live_lua), exist_ok=True)
    write_live_lua(args.live_lua, args, palette, layout)

    if args.write_selection and os.path.isdir(os.path.dirname(args.write_selection)):
        with open(args.write_selection, "w") as f:
            json.dump(
                {
                    "algorithm": args.algorithm,
                    "accent": args.accent,
                    "stone_blend": args.stone_blend,
                    "highlight_blend": args.highlight_blend,
                    "seed": args.seed,
                    "roughness": args.roughness,
                    "chipping": args.chipping,
                    "moss": args.moss,
                    "merge": args.merge,
                },
                f,
                indent=2,
            )
            f.write("\n")


if __name__ == "__main__":
    main()
