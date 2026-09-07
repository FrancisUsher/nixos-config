import os
import subprocess
import sys
import tempfile
import textwrap
from pathlib import Path

from flask import Flask, render_template_string, request
from PIL import Image, ImageDraw, ImageFont

app = Flask(__name__)

FONT_PATH = os.environ["LABEL_FONT"]
BROTHER_QL = str(Path(sys.executable).parent / "brother_ql")
LABEL_SIZE = "62"
LABEL_WIDTH_PX = 1440
LABEL_HEIGHT_PX = 696
MARGIN = 40
MAX_CHARS_PER_LINE = 13
MAX_FONT_SIZE = 180
MIN_FONT_SIZE = 60
FONT_STEP = 4
LINE_SPACING = 1.15

PAGE = """
<!doctype html>
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Label printer</title>
<body style="font-family: sans-serif; max-width: 480px; margin: 2rem auto; padding: 0 1rem;">
  <form method="post">
    <input name="text" autofocus autocomplete="off" style="width: 100%; font-size: 1.5rem; padding: 0.75rem; box-sizing: border-box;" placeholder="Label text">
    <button type="submit" style="width: 100%; font-size: 1.5rem; padding: 0.75rem; margin-top: 0.5rem;">Print</button>
  </form>
  {% if message %}<p>{{ message }}</p>{% endif %}
</body>
"""


def fit_lines(lines: list[str]) -> tuple[ImageFont.FreeTypeFont, list[str]]:
    max_width = LABEL_WIDTH_PX - 2 * MARGIN
    max_height = LABEL_HEIGHT_PX - 2 * MARGIN
    box = ImageDraw.Draw(Image.new("L", (1, 1)))
    font_size = MAX_FONT_SIZE
    while font_size > MIN_FONT_SIZE:
        font = ImageFont.truetype(FONT_PATH, font_size)
        widths = [box.textbbox((0, 0), line, font=font)[2] for line in lines]
        line_height = box.textbbox((0, 0), "Mg", font=font)[3] * LINE_SPACING
        total_height = line_height * len(lines)
        if max(widths) <= max_width and total_height <= max_height:
            return font, lines
        font_size -= FONT_STEP
    return ImageFont.truetype(FONT_PATH, MIN_FONT_SIZE), lines


def render_label(text: str) -> Path:
    lines = textwrap.wrap(text, width=MAX_CHARS_PER_LINE, break_long_words=True) or [""]
    font, lines = fit_lines(lines)

    image = Image.new("L", (LABEL_WIDTH_PX, LABEL_HEIGHT_PX), color=255)
    draw = ImageDraw.Draw(image)

    line_height = draw.textbbox((0, 0), "Mg", font=font)[3] * LINE_SPACING
    total_height = line_height * len(lines)
    y = (LABEL_HEIGHT_PX - total_height) / 2
    for line in lines:
        box = draw.textbbox((0, 0), line, font=font)
        x = (LABEL_WIDTH_PX - (box[2] - box[0])) / 2
        draw.text((x, y - box[1]), line, font=font, fill=0)
        y += line_height

    fd, path = tempfile.mkstemp(suffix=".png")
    os.close(fd)
    path = Path(path)
    image.save(path)
    return path


@app.route("/print", methods=["GET", "POST"])
def print_label():
    message = None
    if request.method == "POST":
        text = request.form.get("text", "").strip()
        if text:
            image_path = render_label(text)
            try:
                subprocess.run(
                    [
                        BROTHER_QL,
                        "-b", "linux_kernel",
                        "-m", "QL-600",
                        "-p", "file:///dev/usb/lp0",
                        "print",
                        "-l", LABEL_SIZE,
                        str(image_path),
                    ],
                    check=True,
                    capture_output=True,
                )
                message = f"Printed: {text}"
            except subprocess.CalledProcessError as e:
                message = f"Print failed: {e.stderr.decode(errors='replace')}"
            finally:
                image_path.unlink(missing_ok=True)
    return render_template_string(PAGE, message=message)


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8180)
