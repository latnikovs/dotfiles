#!/usr/bin/env python3
"""Convert a Ghostty theme file into kitty color config, so both terminals
use byte-identical colors."""
import re
import sys

def _lum(h):
    """WCAG relative luminance of #rrggbb."""
    c = []
    for i in (1, 3, 5):
        v = int(h[i:i + 2], 16) / 255
        c.append(v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]


def contrast(a, b):
    """WCAG contrast ratio between two #rrggbb colors."""
    la, lb = _lum(a), _lum(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def dim_but_legible(bg, candidates, floor=3.0):
    """Dimmest candidate still readable on bg; best-contrast one if none pass."""
    ok = [c for c in candidates if contrast(bg, c) >= floor]
    return min(ok, key=lambda c: contrast(bg, c)) if ok else \
        max(candidates, key=lambda c: contrast(bg, c))


SCALAR = {
    "background": "background",
    "foreground": "foreground",
    "cursor-color": "cursor",
    "cursor-text": "cursor_text_color",
    "selection-background": "selection_background",
    "selection-foreground": "selection_foreground",
}


def convert(src, name):
    colors = {}
    palette = {}
    for line in open(src):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, _, val = (p.strip() for p in line.partition("="))
        if key == "palette":
            idx, _, hexv = val.partition("=")
            palette[int(idx)] = hexv.strip()
        elif key in SCALAR:
            colors[SCALAR[key]] = val

    missing = [k for k in SCALAR.values() if k not in colors]
    if missing or sorted(palette) != list(range(16)):
        sys.exit(f"ERROR: {src}: missing {missing} or palette {sorted(palette)}")

    out = [
        f"# {name} — generated from Ghostty's theme file so kitty and Ghostty",
        "# render identical colors. Regenerate rather than hand-edit.",
        "",
    ]
    for i in range(16):
        out.append(f"color{i:<21} {palette[i]}")
    out.append("")
    for k in ("background", "foreground",
              "selection_background", "selection_foreground"):
        out.append(f"{k:<26} {colors[k]}")
    out.append("")
    out.append("# Reverse video, matching this repo's Ghostty config, which overrides")
    out.append("# the theme's cursor with cursor-color = cell-foreground and")
    out.append(f"# cursor-text = cell-background. (Theme's own cursor was {colors['cursor']}.)")
    out.append(f"{'cursor':<26} none")
    out.append("")
    bg = colors["background"]
    # Dimmest palette colour that stays readable on this background: slot 8
    # suits light themes, but on dark ones it drops to ~2:1 contrast.
    inactive = dim_but_legible(bg, [palette[8], palette[7], colors["foreground"]])
    out.append("# Tab bar, derived from this palette (blue accent matches the")
    out.append("# active tmux pane border). inactive_tab_foreground is chosen by")
    out.append(f"# contrast against the background: {contrast(bg, inactive):.1f}:1.")
    out.append(f"{'active_tab_background':<26} {palette[4]}")
    out.append(f"{'active_tab_foreground':<26} {bg}")
    out.append(f"{'inactive_tab_background':<26} {bg}")
    out.append(f"{'inactive_tab_foreground':<26} {inactive}")
    out.append(f"{'tab_bar_background':<26} {bg}")
    out.append("")

    # Active tab text sits on palette[4]; make sure that pairing is readable too.
    ratio = contrast(palette[4], bg)
    if ratio < 3.0:
        print(f"WARNING: {name}: active tab {bg} on {palette[4]} is only "
              f"{ratio:.1f}:1", file=sys.stderr)
    return "\n".join(out)


if __name__ == "__main__":
    src, name, dest = sys.argv[1], sys.argv[2], sys.argv[3]
    open(dest, "w").write(convert(src, name))
    print(f"wrote {dest}")
