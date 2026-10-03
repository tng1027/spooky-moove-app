"""Generates the Xiangqi piece glyph SVGs (OB-044) from Noto Serif TC.

Noto Serif TC is licensed under the SIL Open Font License 1.1
(assets/pieces/xiangqi/OFL.txt). Only the 14 glyph outlines are bundled;
the font itself is not committed.

Usage: python3 tool/xiangqi_glyphs.py   (needs fontTools and network access)
"""

import os
import tempfile
import urllib.request

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

FONT_URL = (
    "https://github.com/notofonts/noto-cjk/raw/main/"
    "Serif/SubsetOTF/TC/NotoSerifTC-Bold.otf"
)
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "pieces", "xiangqi")

# Asset name = side letter (r = Red, b = Black) + FEN letter, upper case.
GLYPHS = {
    "rK": "帥", "rA": "仕", "rB": "相", "rN": "傌", "rR": "俥", "rC": "炮", "rP": "兵",
    "bK": "將", "bA": "士", "bB": "象", "bN": "馬", "bR": "車", "bC": "砲", "bP": "卒",
}


def main() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        font_path = os.path.join(tmp, "NotoSerifTC-Bold.otf")
        urllib.request.urlretrieve(FONT_URL, font_path)
        font = TTFont(font_path)
        glyph_set = font.getGlyphSet()
        cmap = font.getBestCmap()
        units = font["head"].unitsPerEm
        os.makedirs(OUT_DIR, exist_ok=True)
        for name, char in GLYPHS.items():
            glyph = glyph_set[cmap[ord(char)]]
            bounds = BoundsPen(glyph_set)
            glyph.draw(bounds)
            x_min, y_min, x_max, y_max = bounds.bounds
            # Square box of one em, glyph centred, y flipped (fonts are y-up).
            dx = (units - (x_max - x_min)) / 2 - x_min
            dy = (units - (y_max - y_min)) / 2 + y_max
            pen = SVGPathPen(glyph_set)
            glyph.draw(TransformPen(pen, (1, 0, 0, -1, dx, dy)))
            svg = (
                f'<svg xmlns="http://www.w3.org/2000/svg" '
                f'viewBox="0 0 {units} {units}">'
                f'<path fill="#000" d="{pen.getCommands()}"/></svg>\n'
            )
            with open(os.path.join(OUT_DIR, f"{name}.svg"), "w") as out:
                out.write(svg)
            print(name, char)


if __name__ == "__main__":
    main()
