#!/usr/bin/env python3
"""Iris Plasma desktop theme generator.

Generates Plasma FrameSvg 9-slice SVGs from the values in
docs/TOKENS.md. Borders are whole pixels, every radius is 2px.
"""
import os
import sys

OUT = sys.argv[1] if len(sys.argv) > 1 else "desktoptheme/iris"

# ---------------------------------------------------------------- tokens
BG0 = "#000000"
BG1 = "#0a0a0a"
BG2 = "#141414"
BG3 = "#242424"
BG4 = "#303030"
LINE = "#545454"   # kenarlik — bildirim basligindaki Kirigami ayraciyla ayni ton
LINE2 = "#6b6b6b"  # guclu kenarlik (giris kutusu, odaklanabilir yuzey)
FG0 = "#ffffff"
FG1 = "#b4b4b4"
FG2 = "#6e6e6e"
NEG = "#ff5555"
NEU = "#f5b43c"
POS = "#50d68c"

R = 2          # radius
C = 6          # corner slice. Must be EVEN to land on whole pixels at 1.5x scale:
               # 5*1.5=7.5 put everything on half pixels and blurred the border.
BW = 2         # border width; 1px was barely visible on black


# ------------------------------------------------------------- primitives
def _rounded_corner_path(x, y, c, r, which):
    """Closed path in a c x c box with one corner rounded to radius r."""
    if which == "topleft":
        return (f"M {x},{y+c} L {x},{y+r} A {r},{r} 0 0 1 {x+r},{y} "
                f"L {x+c},{y} L {x+c},{y+c} Z") if r > 0 else \
               f"M {x},{y} L {x+c},{y} L {x+c},{y+c} L {x},{y+c} Z"
    if which == "topright":
        return (f"M {x},{y} L {x+c-r},{y} A {r},{r} 0 0 1 {x+c},{y+r} "
                f"L {x+c},{y+c} L {x},{y+c} Z") if r > 0 else \
               f"M {x},{y} L {x+c},{y} L {x+c},{y+c} L {x},{y+c} Z"
    if which == "bottomright":
        return (f"M {x+c},{y} L {x+c},{y+c-r} A {r},{r} 0 0 1 {x+c-r},{y+c} "
                f"L {x},{y+c} L {x},{y} Z") if r > 0 else \
               f"M {x},{y} L {x+c},{y} L {x+c},{y+c} L {x},{y+c} Z"
    return (f"M {x},{y} L {x+c},{y} L {x+c},{y+c} L {x+r},{y+c} "
            f"A {r},{r} 0 0 1 {x},{y+c-r} Z") if r > 0 else \
           f"M {x},{y} L {x+c},{y} L {x+c},{y+c} L {x},{y+c} Z"


def _inset_for(which):
    """Which two directions the border is inset from in a corner slice."""
    return {"topleft": (1, 1, 0, 0), "topright": (1, 0, 0, 1),
            "bottomright": (0, 0, 1, 1), "bottomleft": (0, 1, 1, 0)}[which]


def _corner(cid, ox, oy, which, fill, stroke, r, c, fill_inset=0):
    """Corner slice. The border is a FILL, not a stroke, so it does not break
    when scaled or at slice boundaries. Everything is inside one <g id>,
    because KSvg only draws the element with that id."""
    parts = [f'<g id="{cid}">',
             f'<rect x="{ox}" y="{oy}" width="{c}" height="{c}" fill="none"/>']

    outer = _rounded_corner_path(ox, oy, c, r, which)
    it, il, ib, ir = _inset_for(which)
    # Shrink the border if the slice is too small to hold it.
    bw = max(1, min(BW, c - 1))
    ix = ox + (bw if il else 0)
    iy = oy + (bw if it else 0)
    ic_w = c - (bw if il else 0) - (bw if ir else 0)
    ir_r = max(0, r - bw)
    inner = _rounded_corner_path(ix, iy, ic_w, ir_r, which)
    # height difference: the box is square, so the same edge offset applies
    if stroke:
        parts.append(f'<path d="{outer} {inner}" fill-rule="evenodd" fill="{stroke}"/>')
        if fill:
            parts.append(f'<path d="{inner}" fill="{fill}"/>')
    elif fill:
        if fill_inset:
            fit, fil, fib, fir = _inset_for(which)
            fx = ox + (fill_inset if fil else 0)
            fy = oy + (fill_inset if fit else 0)
            fw = c - (fill_inset if fil else 0) - (fill_inset if fir else 0)
            parts.append(f'<path d="{_rounded_corner_path(fx, fy, fw, max(0, r - fill_inset), which)}" '
                         f'fill="{fill}"/>')
        else:
            parts.append(f'<path d="{outer}" fill="{fill}"/>')
    parts.append('</g>')
    return parts


def frame(prefix, ox, oy, w, h, fill, stroke=None, r=R, c=C,
          margins=None, insets=None, borders=("t", "r", "b", "l"), fill_inset=0):
    """Full 9-slice frame. With prefix '' the slice names are bare."""
    p = f"{prefix}-" if prefix else ""
    cw = w - 2 * c
    ch = h - 2 * c
    out = []

    fi = fill_inset
    out += _corner(f"{p}topleft", ox, oy, "topleft",
                   fill, stroke if ("t" in borders or "l" in borders) else None, r, c, fi)
    out += _corner(f"{p}topright", ox + w - c, oy, "topright",
                   fill, stroke if ("t" in borders or "r" in borders) else None, r, c, fi)
    out += _corner(f"{p}bottomleft", ox, oy + h - c, "bottomleft",
                   fill, stroke if ("b" in borders or "l" in borders) else None, r, c, fi)
    out += _corner(f"{p}bottomright", ox + w - c, oy + h - c, "bottomright",
                   fill, stroke if ("b" in borders or "r" in borders) else None, r, c, fi)

    def edge(eid, x, y, ew, eh, side):
        seg = [f'<g id="{eid}">',
               f'<rect x="{x}" y="{y}" width="{ew}" height="{eh}" fill="none"/>']
        drawn = stroke and side in borders
        bw = max(1, min(BW, (eh - 1) if side in ("t", "b") else (ew - 1)))
        if drawn:
            if side == "t":
                seg.append(f'<rect x="{x}" y="{y}" width="{ew}" height="{bw}" fill="{stroke}"/>')
                if fill:
                    seg.append(f'<rect x="{x}" y="{y+bw}" width="{ew}" height="{eh-bw}" fill="{fill}"/>')
            elif side == "b":
                seg.append(f'<rect x="{x}" y="{y+eh-bw}" width="{ew}" height="{bw}" fill="{stroke}"/>')
                if fill:
                    seg.append(f'<rect x="{x}" y="{y}" width="{ew}" height="{eh-bw}" fill="{fill}"/>')
            elif side == "l":
                seg.append(f'<rect x="{x}" y="{y}" width="{bw}" height="{eh}" fill="{stroke}"/>')
                if fill:
                    seg.append(f'<rect x="{x+bw}" y="{y}" width="{ew-bw}" height="{eh}" fill="{fill}"/>')
            else:
                seg.append(f'<rect x="{x+ew-bw}" y="{y}" width="{bw}" height="{eh}" fill="{stroke}"/>')
                if fill:
                    seg.append(f'<rect x="{x}" y="{y}" width="{ew-bw}" height="{eh}" fill="{fill}"/>')
        elif fill:
            dx = fill_inset if side == "l" else 0
            dy = fill_inset if side == "t" else 0
            dw = fill_inset if side in ("l", "r") else 0
            dh = fill_inset if side in ("t", "b") else 0
            seg.append(f'<rect x="{x+dx}" y="{y+dy}" width="{ew-dw}" height="{eh-dh}" fill="{fill}"/>')
        seg.append('</g>')
        return seg

    out += edge(f"{p}top", ox + c, oy, cw, c, "t")
    out += edge(f"{p}bottom", ox + c, oy + h - c, cw, c, "b")
    out += edge(f"{p}left", ox, oy + c, c, ch, "l")
    out += edge(f"{p}right", ox + w - c, oy + c, c, ch, "r")

    out.append(f'<g id="{p}center">'
               f'<rect x="{ox+c}" y="{oy+c}" width="{cw}" height="{ch}" '
               f'fill="{fill if fill else "none"}"/></g>')

    if margins:
        # A zero-sized hint rect counts as "no element" and the margin falls back
        # to the slice size; Breeze uses 0.001 for the same reason.
        t, rr, b, l = [v if v else 0.001 for v in margins]
        out.append(f'<rect id="{p}hint-top-margin" x="{ox}" y="{oy}" width="1" height="{t}" fill="none"/>')
        out.append(f'<rect id="{p}hint-right-margin" x="{ox}" y="{oy}" width="{rr}" height="1" fill="none"/>')
        out.append(f'<rect id="{p}hint-bottom-margin" x="{ox}" y="{oy}" width="1" height="{b}" fill="none"/>')
        out.append(f'<rect id="{p}hint-left-margin" x="{ox}" y="{oy}" width="{l}" height="1" fill="none"/>')
    if insets:
        t, rr, b, l = insets
        out.append(f'<rect id="{p}hint-top-inset" x="{ox}" y="{oy}" width="1" height="{t}" fill="none"/>')
        out.append(f'<rect id="{p}hint-right-inset" x="{ox}" y="{oy}" width="{rr}" height="1" fill="none"/>')
        out.append(f'<rect id="{p}hint-bottom-inset" x="{ox}" y="{oy}" width="1" height="{b}" fill="none"/>')
        out.append(f'<rect id="{p}hint-left-inset" x="{ox}" y="{oy}" width="{l}" height="1" fill="none"/>')
    return out


def svg(body, w, h, extra=""):
    return (f'<?xml version="1.0" encoding="UTF-8"?>\n'
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
            f'viewBox="0 0 {w} {h}">\n'
            f'{extra}\n' + "\n".join(body) + "\n</svg>\n")


def write(path, content):
    full = os.path.join(OUT, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w") as f:
        f.write(content)
    print(f"  {path}")


FW, FH = 40, 40          # standard frame size
GAP = 10


def stack(specs):
    """Lays frames out vertically and returns (body, w, h)."""
    body, y = [], GAP
    for kw in specs:
        body += frame(ox=GAP, oy=y, w=FW, h=FH, **kw)
        y += FH + GAP
    return body, FW + 2 * GAP, y


# ------------------------------------------------------------------ widgets
print("generating desktoptheme SVGs:")

# --- panel background: pitch black, 2px radius
# No panel border: on a top panel the line would sit against the screen edge.
body, w, h = stack([
    dict(prefix="", fill=BG0, stroke=None, margins=(1, 1, 1, 1), insets=(0, 0, 0, 0)),
])
body.append(f'<rect id="hint-stretch-borders" x="0" y="0" width="1" height="1" fill="none"/>')
write("widgets/panel-background.svg", svg(body, w, h))

# --- popup / dialog background
# No shadow: Plasma draws dialog shadows from shadow-* slices in this SVG,
# so without them there is none. On pure black a shadow only blurred the
# edge into the border.
def dialog_svg():
    # Inner margin: 4px like Breeze. At 1px content touched the border.
    #
    # All four borders are defined. For popups attached to the panel Plasma
    # hides the borders facing the panel and screen edge; free-floating
    # notifications draw all four. The thin line between panel and popup
    # comes from horizontal-line in widgets/line.svg, not from this frame.
    body = frame("", GAP, GAP, FW, FH, BG1, LINE,
                 margins=(6, 6, 6, 6), insets=(0, 0, 0, 0))
    body.append('<rect id="hint-stretch-borders" x="0" y="0" width="1" height="1" fill="none"/>')
    return svg(body, FW + 2 * GAP, FH + 2 * GAP)

write("widgets/background.svg", dialog_svg())
write("dialogs/background.svg", dialog_svg())

# --- opaque / translucent / solid variants are identical (the theme is opaque black anyway)
for variant in ("opaque", "translucent", "solid"):
    write(f"{variant}/widgets/panel-background.svg",
          svg(frame("", GAP, GAP, FW, FH, BG0, None, margins=(1, 1, 1, 1), insets=(0, 0, 0, 0))
              + [f'<rect id="hint-stretch-borders" x="0" y="0" width="1" height="1" fill="none"/>'],
              FW + 2 * GAP, FH + 2 * GAP))
    write(f"{variant}/dialogs/background.svg", dialog_svg())
    write(f"{variant}/widgets/background.svg", dialog_svg())

# --- tooltip
write("widgets/tooltip.svg",
      svg(frame("", GAP, GAP, FW, FH, BG1, LINE, margins=(4, 6, 4, 6)),
          FW + 2 * GAP, FH + 2 * GAP))

# --- listitem: normal saydam, hover bg2, pressed bg3
def multi(prefixes, extra=()):
    body, y = [], GAP
    maxw = 0
    for entry in prefixes:
        pfx, fill, stroke, margins, borders = entry[:5]
        cs = entry[5] if len(entry) > 5 else C
        fi = entry[6] if len(entry) > 6 else 0
        body += frame(pfx, GAP, y, FW, FH, fill, stroke, r=min(R, cs), c=cs,
                      margins=margins, borders=borders, fill_inset=fi)
        y += FH + GAP
        maxw = max(maxw, FW)
    body.append(f'<rect id="hint-stretch-borders" x="0" y="0" width="1" height="1" fill="none"/>')
    for hint in extra:
        body.append(f'<rect id="{hint}" x="0" y="0" width="1" height="1" fill="none"/>')
    return svg(body, maxw + 2 * GAP, y)

# Like the Windows 10 menu: the highlight covers the whole row, no rounding.
write("widgets/listitem.svg", multi([
    ("normal", None, None, (2, 2, 2, 2), (), 1),
    ("hover", "#2b2b2b", None, (2, 2, 2, 2), (), 1),
    ("pressed", "#3a3a3a", None, (2, 2, 2, 2), (), 1),
    ("selected", "#3a3a3a", None, (2, 2, 2, 2), (), 1),
    ("separator", None, LINE, (0, 0, 0, 0), ("t",), 1),
]))

write("widgets/viewitem.svg", multi([
    ("normal", None, None, (2, 2, 2, 2), (), 1),
    ("hover", "#2b2b2b", None, (2, 2, 2, 2), (), 1),
    ("selected", "#3a3a3a", None, (2, 2, 2, 2), (), 1),
    ("selected+hover", "#464646", None, (2, 2, 2, 2), (), 1),
    ("focus", None, FG0, (2, 2, 2, 2), ("t", "r", "b", "l"), 2),
]))

# --- button: normal / hover / focus / pressed
write("widgets/button.svg", multi([
    ("normal", "#1a1a1a", "#3d3d3d", (4, 8, 4, 8), ("t", "r", "b", "l")),
    ("hover", "#242424", "#5a5a5a", (4, 8, 4, 8), ("t", "r", "b", "l")),
    ("focus", None, FG0, (4, 8, 4, 8), ("t", "r", "b", "l")),
    ("pressed", "#303030", "#5a5a5a", (4, 8, 4, 8), ("t", "r", "b", "l")),
    # Fill inset by 1px: otherwise the hover of heading buttons covered the
    # popup border.
    ("toolbutton-hover", "#2b2b2b", None, (4, 8, 4, 8), (), C, 1),
    ("toolbutton-pressed", "#3a3a3a", None, (4, 8, 4, 8), (), C, 1),
]))

# --- lineedit
# Line edit: the border must be visible on black and white when focused.
# The hover and focus frames use their own margins as negative anchors:
# unless the margin is 0 they spill outside the base frame and look like
# two nested rings. The inner margin comes only from "base".
write("widgets/lineedit.svg", multi([
    ("base", "#161616", "#4d4d4d", (3, 6, 3, 6), ("t", "r", "b", "l")),
    ("hover", "#1f1f1f", "#6b6b6b", (0, 0, 0, 0), ("t", "r", "b", "l")),
    # Without hint-focus-over-base Plasma draws the focus frame BEHIND the base
    # (z:-1), and with a 0 margin FrameSvg does not draw the edge slices at all.
    # Pure white focus ring was too loud; a readable but calm grey.
    ("focus", None, "#9a9a9a", (0, 0, 0, 0), ("t", "r", "b", "l"), 4),
    ("focusframe", None, "#9a9a9a", (0, 0, 0, 0), ("t", "r", "b", "l"), 4),
], extra=("hint-focus-over-base",)))

# --- frame
write("widgets/frame.svg", multi([
    ("plain", BG0, LINE, (1, 1, 1, 1), ("t", "r", "b", "l")),
    ("raised", BG1, LINE, (1, 1, 1, 1), ("t", "r", "b", "l")),
    ("sunken", BG0, LINE, (1, 1, 1, 1), ("t", "r", "b", "l")),
]))

# --- toolbar / plasmoidheading
write("widgets/toolbar.svg", multi([
    ("", None, LINE, (1, 1, 1, 1), ("b",)),
]))
# The heading strip spans the popup's full width, so an opaque fill covered
# the dialog border underneath it. The fill is the same tone as the popup
# anyway, so leave it transparent and draw only the separator line; the
# border then runs uninterrupted.
write("widgets/plasmoidheading.svg", multi([
    ("header", None, LINE, (4, 6, 4, 6), ("b",)),
    ("footer", None, LINE, (4, 6, 4, 6), ("t",)),
]))

# --- tabbar
write("widgets/tabbar.svg", multi([
    ("north-active-tab", BG2, None, (2, 8, 2, 8), ()),
    ("north-inactive-tab", None, None, (2, 8, 2, 8), ()),
    ("south-active-tab", BG2, None, (2, 8, 2, 8), ()),
    ("south-inactive-tab", None, None, (2, 8, 2, 8), ()),
    ("west-active-tab", BG2, None, (2, 8, 2, 8), ()),
    ("west-inactive-tab", None, None, (2, 8, 2, 8), ()),
    ("east-active-tab", BG2, None, (2, 8, 2, 8), ()),
    ("east-inactive-tab", None, None, (2, 8, 2, 8), ()),
]))

# --- separator line
write("widgets/line.svg", svg([
    # Plasma also places this element on the top edge of a panel-attached
    # popup; if visible it adds an unwanted line between panel and popup.
    f'<rect id="horizontal-line" x="0" y="0" width="32" height="{BW}" fill="none"/>',
    f'<rect id="vertical-line" x="0" y="6" width="{BW}" height="32" fill="{LINE}"/>',
], 40, 40))

# --- slider
write("widgets/slider.svg", svg([
    # oluk
    f'<rect id="groove" x="4" y="4" width="32" height="3" rx="1" fill="{BG3}"/>',
    f'<rect id="groove-highlight" x="4" y="12" width="32" height="3" rx="1" fill="{FG0}"/>',
    # handle
    f'<rect id="horizontal-slider-handle" x="4" y="20" width="10" height="14" rx="{R}" fill="{FG0}"/>',
    f'<rect id="horizontal-slider-focus" x="18" y="20" width="10" height="14" rx="{R}" fill="none" stroke="{FG0}" stroke-width="1"/>',
    f'<rect id="horizontal-slider-hover" x="32" y="20" width="10" height="14" rx="{R}" fill="{FG0}"/>',
    f'<rect id="vertical-slider-handle" x="46" y="20" width="14" height="10" rx="{R}" fill="{FG0}"/>',
    f'<rect id="vertical-slider-focus" x="62" y="20" width="14" height="10" rx="{R}" fill="none" stroke="{FG0}" stroke-width="1"/>',
    f'<rect id="vertical-slider-hover" x="78" y="20" width="14" height="10" rx="{R}" fill="{FG0}"/>',
], 100, 40))

# --- scrollbar
write("widgets/scrollbar.svg", svg([
    f'<rect id="background-vertical" x="0" y="0" width="10" height="40" fill="{BG0}"/>',
    f'<rect id="background-horizontal" x="14" y="0" width="40" height="10" fill="{BG0}"/>',
    f'<rect id="slider-vertical" x="58" y="0" width="8" height="40" rx="{R}" fill="{BG4}"/>',
    f'<rect id="slider-horizontal" x="0" y="46" width="40" height="8" rx="{R}" fill="{BG4}"/>',
    f'<rect id="mouseover-slider-vertical" x="70" y="0" width="8" height="40" rx="{R}" fill="{FG2}"/>',
    f'<rect id="mouseover-slider-horizontal" x="46" y="46" width="40" height="8" rx="{R}" fill="{FG2}"/>',
    f'<rect id="sunken-slider-vertical" x="82" y="0" width="8" height="40" rx="{R}" fill="{FG1}"/>',
    f'<rect id="sunken-slider-horizontal" x="92" y="46" width="40" height="8" rx="{R}" fill="{FG1}"/>',
], 140, 60))

# --- media-delegate (media player list)
write("widgets/media-delegate.svg", svg([
    f'<rect id="video-previous" x="0" y="0" width="16" height="16" fill="none"/>',
    f'<rect id="video-next" x="16" y="0" width="16" height="16" fill="none"/>',
], 40, 40))

# ==================================================================== ANAHTAR
# Plasma's Switch uses a 3-slice track (left/center/right) plus a separate
# handle. On: white fill with a black knob, unambiguous on black.
def _cap(cid, x, y, h, side, fill, stroke):
    r = h / 2.0
    out = []
    if side == "left":
        d = f"M {x+r},{y} A {r},{r} 0 0 0 {x+r},{y+h} Z"
        b = (f"M {x+r},{y+0.5} A {r-0.5},{r-0.5} 0 0 0 {x+r},{y+h-0.5}")
    else:
        d = f"M {x},{y} A {r},{r} 0 0 1 {x},{y+h} Z"
        b = (f"M {x},{y+0.5} A {r-0.5},{r-0.5} 0 0 1 {x},{y+h-0.5}")
    out.append(f'<path id="{cid}" d="{d}" fill="{fill if fill else "none"}"/>')
    if stroke:
        out.append(f'<path d="{b}" fill="none" stroke="{stroke}" stroke-width="{BW}"/>')
    return out


def switch_svg():
    """Plasma draws the handle with KSvg.SvgItem from ONE element id, so the
    visible shape must be INSIDE that id, not next to it. Hence every handle
    is a <g> group. If handle-active exists Plasma uses it when on, giving a
    black knob on the white track."""
    TH = 16          # track thickness
    CAP = TH / 2.0
    MID = 16         # middle slice width (32x16 track, 2:1 like Windows 11)
    HS = 16          # knob box (the visible circle is smaller, centred inside)
    KR = 5.0         # knob radius
    body = []

    def track(prefix, y, fill, stroke):
        x = GAP
        body.extend(_cap(f"{prefix}-left", x, y, TH, "left", fill, stroke))
        body.append(f'<path id="{prefix}-center" d="M {x+CAP},{y} h {MID} v {TH} h {-MID} Z" '
                    f'fill="{fill if fill else "none"}"/>')
        if stroke:
            body.append(f'<rect x="{x+CAP}" y="{y}" width="{MID}" height="{BW}" fill="{stroke}"/>')
            body.append(f'<rect x="{x+CAP}" y="{y+TH-BW}" width="{MID}" height="{BW}" fill="{stroke}"/>')
        body.extend(_cap(f"{prefix}-right", x + CAP + MID, y, TH, "right", fill, stroke))

    track("inactive", GAP, "#1f1f1f", "#5a5a5a")
    track("active", GAP + TH + GAP, FG0, None)

    hy = GAP + 2 * (TH + GAP)

    def knob(hid, x, fill, ring=None, ring_w=1.2, ring_only=False):
        # An invisible bounding box keeps the knob inset from the track;
        # KSvg uses element bounds as naturalSize.
        cx, cy = x + HS / 2.0, hy + HS / 2.0
        parts = [f'<g id="{hid}">',
                 f'<rect x="{x}" y="{hy}" width="{HS}" height="{HS}" fill="none"/>']
        if not ring_only:
            parts.append(f'<circle cx="{cx}" cy="{cy}" r="{KR}" fill="{fill}"/>')
        if ring:
            parts.append(f'<circle cx="{cx}" cy="{cy}" r="{KR}" fill="none" '
                         f'stroke="{ring}" stroke-width="{ring_w}"/>')
        parts.append('</g>')
        body.extend(parts)

    # off: light grey knob on a dark track
    knob("handle", GAP, "#d8d8d8")
    # on: black knob on a white track
    knob("handle-active", GAP + (HS + GAP), "#000000")
    # hover/pressed must read on both tracks -> mid tones
    knob("handle-hover", GAP + 2 * (HS + GAP), "#9a9a9a")
    knob("handle-pressed", GAP + 3 * (HS + GAP), "#707070")
    # focus ring: white outline over the knob
    knob("handle-focus", GAP + 4 * (HS + GAP), None, FG0, 1.6, ring_only=True)
    body.append(f'<rect id="handle-shadow" x="{GAP + 5*(HS+GAP)}" y="{hy}" '
                f'width="{HS}" height="{HS}" fill="#000000" opacity="0"/>')

    body.append(f'<rect id="hint-bar-size" x="0" y="0" width="{CAP*2 + MID}" height="{TH}" '
                f'fill="none"/>')
    body.append(f'<rect id="hint-stretch-borders" x="0" y="0" width="1" height="1" '
                f'fill="none"/>')
    return svg(body, GAP + 6 * (HS + GAP), hy + HS + GAP)


write("widgets/switch.svg", switch_svg())


# ============================================================ SLIDER (yeniden)
# The groove must be 9-sliced; plain rectangles could not be drawn by Plasma.
def slider_svg():
    # The groove is thin, but in a 9-slice frame the corner must stay under half
    # the height, otherwise the centre slice collapses and nothing is drawn.
    GH = 6                     # drawn height
    GC = 1.5                   # corner slice
    body = []
    y = GAP
    body += frame("groove", GAP, y, 40, GH, "#3a3a3a", None, r=GC, c=GC)
    y += GH + GAP
    body += frame("groove-highlight", GAP, y, 40, GH, FG0, None, r=GC, c=GC)
    y += GH + GAP

    HS = 18
    def handle(hid, x, fill):
        # KSvg draws the handle from one element id: the shape must be INSIDE the group.
        # A black ring separates the white fill from the white groove.
        body.append(f'<g id="{hid}">'
                    f'<circle cx="{x + HS/2}" cy="{y + HS/2}" r="{HS/2 - 1}" fill="#000000"/>'
                    f'<circle cx="{x + HS/2}" cy="{y + HS/2}" r="{HS/2 - 2.6}" fill="{fill}"/>'
                    f'</g>')

    handle("horizontal-slider-handle", GAP, FG0)
    handle("horizontal-slider-hover", GAP + HS + GAP, FG0)
    handle("horizontal-slider-focus", GAP + 2 * (HS + GAP), FG0)
    handle("vertical-slider-handle", GAP + 3 * (HS + GAP), FG0)
    handle("vertical-slider-hover", GAP + 4 * (HS + GAP), FG0)
    handle("vertical-slider-focus", GAP + 5 * (HS + GAP), FG0)
    for i, hid in enumerate(["horizontal-slider-shadow", "vertical-slider-shadow"]):
        body.append(f'<rect id="{hid}" x="{GAP + (6+i)*(HS+GAP)}" y="{y}" '
                    f'width="{HS}" height="{HS}" fill="#000000" opacity="0"/>')
    body.append(f'<rect id="hint-handle-size" x="0" y="0" width="{HS}" height="{HS}" '
                f'fill="none"/>')
    body.append(f'<rect id="hint-tile-center" x="0" y="0" width="1" height="1" '
                f'fill="none"/>')
    return svg(body, GAP + 8 * (HS + GAP), y + HS + GAP)


write("widgets/slider.svg", slider_svg())


# ================================================================ PROGRESS BAR
def bar_meter(vertical=False):
    TH = 6          # drawn height
    BC = 1.5        # corner slice
    BAR = 4         # actual thickness Plasma uses
    body = []
    y = GAP
    body += frame("bar-inactive", GAP, y, 40, TH, "#333333", None, r=BC, c=BC)
    y += TH + GAP
    body += frame("bar-active", GAP, y, 40, TH, FG0, None, r=BC, c=BC)
    body.append(f'<rect id="hint-bar-size" x="0" y="0" width="40" height="{BAR}" '
                f'fill="none"/>')
    body.append(f'<rect id="hint-tile-center" x="0" y="0" width="1" height="1" '
                f'fill="none"/>')
    return svg(body, 40 + 2 * GAP, y + TH + GAP)


write("widgets/bar_meter_horizontal.svg", bar_meter())
write("widgets/bar_meter_vertical.svg", bar_meter(True))
write("widgets/progressbar.svg", bar_meter())

print("bitti.")
