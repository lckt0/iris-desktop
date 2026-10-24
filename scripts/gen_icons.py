#!/usr/bin/env python3
"""Iris — Windows 11 (Fluent) style system tray icons.

Generates a thin icon theme layer that inherits from Papirus: only battery,
volume, network, Bluetooth and notification icons are overridden, everything
else still comes from Papirus.

Drawn on a 22x22 grid, the same as Papirus' panel context, so pixels line up
at the size the icons are actually used.
"""
import math
import os
import shutil
import sys

OUT = sys.argv[1] if len(sys.argv) > 1 else "icons/Iris"

G = 22.0          # grid
SW = 1.6          # default stroke width
DIM = 0.3         # opacity of empty/inactive parts

HEADER = '''<svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 22 22" version="1.1">
 <defs>
  <style id="current-color-scheme" type="text/css">
   .ColorScheme-Text { color:#dfdfdf; } .ColorScheme-Highlight { color:#4285f4; } .ColorScheme-NeutralText { color:#ff9800; } .ColorScheme-PositiveText { color:#4caf50; } .ColorScheme-NegativeText { color:#f44336; }
  </style>
 </defs>
'''
FOOTER = '</svg>\n'

written = {}


def emit(name, body):
    written[name] = HEADER + body + FOOTER


# ------------------------------------------------------------------ helpers
def stroke(d, w=SW, opacity=None, cap="round", join="round"):
    o = f'opacity:{opacity};' if opacity is not None else ''
    return (f' <path style="{o}fill:none;stroke:currentColor;stroke-width:{w};'
            f'stroke-linecap:{cap};stroke-linejoin:{join}" class="ColorScheme-Text" d="{d}"/>\n')


def fill(d, opacity=None):
    o = f'opacity:{opacity};' if opacity is not None else ''
    return f' <path style="{o}fill:currentColor" class="ColorScheme-Text" d="{d}"/>\n'


def rect(x, y, w, h, rx=0, opacity=None, mask=None):
    o = f'opacity:{opacity};' if opacity is not None else ''
    m = f' mask="url(#{mask})"' if mask else ''
    return (f' <rect style="{o}fill:currentColor" class="ColorScheme-Text"{m} '
            f'x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}"/>\n')


def rect_stroke(x, y, w, h, rx=0, sw=1.4, opacity=None):
    o = f'opacity:{opacity};' if opacity is not None else ''
    return (f' <rect style="{o}fill:none;stroke:currentColor;stroke-width:{sw}" '
            f'class="ColorScheme-Text" x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}"/>\n')


def arc(cx, cy, r, a0, a1):
    """Centre (cx,cy), radius r, angles in degrees: 0° up, clockwise."""
    def pt(a):
        rad = math.radians(a - 90)
        return (cx + r * math.cos(rad), cy + r * math.sin(rad))
    x0, y0 = pt(a0)
    x1, y1 = pt(a1)
    large = 1 if abs(a1 - a0) > 180 else 0
    sweep = 1 if a1 > a0 else 0
    return f"M {x0:.2f},{y0:.2f} A {r},{r} 0 {large} {sweep} {x1:.2f},{y1:.2f}"


def circle(cx, cy, r, opacity=None):
    o = f'opacity:{opacity};' if opacity is not None else ''
    return (f' <circle style="{o}fill:currentColor" class="ColorScheme-Text" '
            f'cx="{cx}" cy="{cy}" r="{r}"/>\n')


def slash():
    """Disabled marker: a slash from left to right."""
    return (' <path style="fill:none;stroke:currentColor;stroke-width:3.2;stroke-linecap:round"'
            ' class="ColorScheme-Text" style2="" d="M 4,18 18,4" opacity="0"/>\n'
            + stroke("M 4,18 18,4", w=1.7))


def slash_cut():
    """Slash plus a mask that leaves a background-coloured gap under it."""
    return stroke("M 4.2,17.8 17.8,4.2", w=1.7)


# ==================================================================== BATARYA
BODY_X, BODY_Y, BODY_W, BODY_H, BODY_R = 2.4, 7.4, 15.0, 7.6, 2.2
CAP_X, CAP_Y, CAP_W, CAP_H = 18.2, 9.6, 1.5, 3.2
INNER_PAD = 1.9


def battery(pct, charging=False, profile=None, special=None):
    b = ""
    # body outline + terminal
    b += rect_stroke(BODY_X + 0.7, BODY_Y + 0.7, BODY_W - 1.4, BODY_H - 1.4,
                     rx=BODY_R - 0.7, sw=1.4)
    b += rect(CAP_X, CAP_Y, CAP_W, CAP_H, rx=0.7)

    ix = BODY_X + INNER_PAD
    iy = BODY_Y + INNER_PAD
    iw_full = BODY_W - 2 * INNER_PAD
    ih = BODY_H - 2 * INNER_PAD

    if special == "missing":
        b += stroke("M 8,11.2 H 12", w=1.6)
        return b
    if special == "caution":
        b += rect(ix, iy, 1.9, ih, rx=0.6)
        b += stroke("M 11,9 V 12", w=1.5)
        b += circle(11, 13.6, 0.75)
        return b
    if special == "adapter":
        b += fill("M 11.6,8.6 8.4,12.2 h 2.2 l -0.5,2.6 3.3,-3.7 h -2.3 z")
        return b

    iw = max(0.0, iw_full * pct / 100.0)

    if charging:
        # Win11: while charging the body stays empty with a clear bolt inside;
        # at 22px a level fill plus a bolt ran together.
        b += fill("M 11.9,7.9 8.5,11.9 h 2.2 l -0.6,3.1 3.5,-4.1 h -2.3 z")
    else:
        if iw > 0.3:
            b += rect(ix, iy, round(iw, 2), ih, rx=0.9)

    # power profile marker: 1..3 small dots top right, not touching the body
    if profile:
        n = {"powersave": 1, "balanced": 2, "performance": 3}[profile]
        for i in range(n):
            b += circle(20.2 - i * 2.6, 3.4, 1.05)
    return b


for p in range(0, 101, 10):
    nm = f"battery-{p:03d}"
    emit(nm, battery(p))
    emit(nm + "-charging", battery(p, charging=True))
    for prof in ("powersave", "balanced", "performance"):
        emit(f"{nm}-profile-{prof}", battery(p, profile=prof))
        emit(f"{nm}-charging-profile-{prof}", battery(p, charging=True, profile=prof))

emit("battery-full-charged", battery(100))
emit("battery-full-charging", battery(100, charging=True))
emit("battery-full", battery(100))
emit("battery-missing", battery(0, special="missing"))
emit("battery-caution", battery(0, special="caution"))
emit("battery-low", battery(10))
emit("battery-ac-adapter", battery(0, special="adapter"))
emit("battery-charging", battery(50, charging=True))
emit("battery", battery(70))


# ======================================================================= SES
SPEAKER = "M 4.2,8.6 H 6.9 L 10.4,5.2 V 16.8 L 6.9,13.4 H 4.2 Z"


def volume(waves, muted=False):
    b = fill(SPEAKER)
    if muted:
        b += stroke("M 14.2,8.6 18.4,13.4 M 18.4,8.6 14.2,13.4", w=1.7)
        return b
    for i in range(3):
        r = 3.0 + i * 2.5
        if i < waves:
            b += stroke(arc(10.4, 11.0, r, 40, 140), w=1.55)
        else:
            b += stroke(arc(10.4, 11.0, r, 40, 140), w=1.55, opacity=DIM)
    return b


emit("audio-volume-muted", volume(0, muted=True))
emit("audio-volume-low", volume(1))
emit("audio-volume-medium", volume(2))
emit("audio-volume-high", volume(3))
emit("audio-volume-off", volume(0, muted=True))
emit("audio-volume-high-panel", volume(3))
emit("audio-volume-medium-panel", volume(2))
emit("audio-volume-low-panel", volume(1))
emit("audio-volume-low-zero-panel", volume(0))
emit("audio-volume-muted-panel", volume(0, muted=True))
emit("audio-volume-muted-blocked-panel", volume(0, muted=True))
emit("audio-volume-muted-blocking", volume(0, muted=True))
emit("audio-volume-muted-blocking-panel", volume(0, muted=True))
emit("audio-volume-high-warning", volume(3))
emit("audio-volume-high-danger", volume(3))


# ===================================================================== WIFI
WIFI_CX, WIFI_CY = 11.0, 17.6
WIFI_R = (3.3, 6.0, 8.7, 11.2)
WIFI_SPAN = 52.0


def wifi(level, dot=True, extra=""):
    """level 0..4: how many arcs are filled."""
    b = ""
    for i, r in enumerate(WIFI_R):
        d = arc(WIFI_CX, WIFI_CY, r, -WIFI_SPAN, WIFI_SPAN)
        if i < level:
            b += stroke(d, w=1.7)
        else:
            b += stroke(d, w=1.7, opacity=DIM)
    if dot:
        b += circle(WIFI_CX, WIFI_CY - 0.2, 1.35)
    else:
        b += circle(WIFI_CX, WIFI_CY - 0.2, 1.35, opacity=DIM)
    return b + extra


emit("network-wireless-connected-00", wifi(0))
emit("network-wireless-connected-25", wifi(1))
emit("network-wireless-connected-50", wifi(2))
emit("network-wireless-connected-75", wifi(3))
emit("network-wireless-connected-100", wifi(4))
emit("network-wireless-signal-none", wifi(0))
emit("network-wireless-signal-weak", wifi(1))
emit("network-wireless-signal-ok", wifi(2))
emit("network-wireless-signal-good", wifi(3))
emit("network-wireless-signal-excellent", wifi(4))
emit("network-wireless-acquiring", wifi(1, dot=True))
emit("network-wireless-available", wifi(0, dot=True))
emit("network-wireless-disconnected", wifi(0, dot=False,
     extra=stroke("M 14.6,14.4 19.0,18.8 M 19.0,14.4 14.6,18.8", w=1.6)))
emit("network-wireless-offline", wifi(0, dot=False,
     extra=stroke("M 14.6,14.4 19.0,18.8 M 19.0,14.4 14.6,18.8", w=1.6)))
emit("network-wireless", wifi(4))


# ================================================================== WIRED
def wired(state="on"):
    b = rect_stroke(3.2, 5.2, 15.6, 10.0, rx=1.6, sw=1.5,
                    opacity=None if state != "off" else DIM)
    b += stroke("M 7.4,18.4 H 14.6", w=1.6,
                opacity=None if state != "off" else DIM)
    if state == "off":
        b += stroke("M 14.2,14.0 18.6,18.4 M 18.6,14.0 14.2,18.4", w=1.6)
    return b


emit("network-wired-activated", wired("on"))
emit("network-wired", wired("on"))
emit("network-wired-disconnected", wired("off"))
emit("network-wired-unavailable", wired("off"))
emit("network-disconnected", wired("off"))
emit("network-unavailable", wired("off"))
emit("network-offline", wired("off"))


# ===================================================================== VPN
def vpn():
    b = stroke("M 11,3.4 4.6,6.0 v 4.6 c 0,4.0 2.7,7.4 6.4,8.4 3.7,-1.0 6.4,-4.4 6.4,-8.4 V 6.0 Z", w=1.5)
    b += fill("M 9.6,10.6 h 2.8 v 4.0 H 9.6 Z")
    b += stroke("M 9.4,10.6 V 9.2 a 1.6,1.6 0 0 1 3.2,0 v 1.4", w=1.3)
    return b


emit("network-vpn", vpn())
emit("network-vpn-active", vpn())


# ================================================================= BLUETOOTH
BT_RUNE = "M 7.0,7.6 15.0,15.0 11.0,18.8 V 3.2 L 15.0,7.0 7.0,14.4"


def bluetooth(state="on"):
    if state == "on":
        return stroke(BT_RUNE, w=1.75)
    if state == "dim":
        return stroke(BT_RUNE, w=1.75, opacity=0.45)
    # off
    return stroke(BT_RUNE, w=1.75, opacity=0.45) + stroke("M 4.4,17.6 17.6,4.4", w=1.7)


emit("preferences-system-bluetooth", bluetooth("on"))
emit("preferences-system-bluetooth-activated", bluetooth("on"))
emit("preferences-system-bluetooth-inactive", bluetooth("dim"))
emit("bluetooth", bluetooth("on"))
emit("bluetooth-active", bluetooth("on"))
emit("bluetooth-online", bluetooth("on"))
emit("bluetooth-disabled", bluetooth("off"))
emit("bluetooth-inactive", bluetooth("dim"))
emit("bluetooth-off", bluetooth("off"))


# ===================================================================== BELL
BELL = ("M 5.6,15.4 C 6.6,14.2 7.2,12.8 7.2,11.2 V 9.8 a 3.8,3.8 0 0 1 7.6,0 v 1.4 "
        "c 0,1.6 0.6,3.0 1.6,4.2 z")
CLAPPER = "M 9.3,17.3 a 1.9,1.9 0 0 0 3.4,0"


def bell(state="on"):
    if state == "off":
        b = stroke(BELL, w=1.5, opacity=0.45)
        b += stroke(CLAPPER, w=1.5, opacity=0.45)
        b += stroke("M 4.4,17.6 17.6,4.4", w=1.7)
        return b
    b = stroke(BELL, w=1.5)
    b += stroke(CLAPPER, w=1.5)
    if state == "badge":
        # keep a gap between the badge and the bell outline
        b = (' <mask id="nb">\n'
             '  <rect x="0" y="0" width="22" height="22" fill="#fff"/>\n'
             '  <circle cx="16.4" cy="6.2" r="4.0" fill="#000"/>\n'
             ' </mask>\n'
             + b.replace('class="ColorScheme-Text"', 'class="ColorScheme-Text" mask="url(#nb)"'))
        b += circle(16.4, 6.2, 2.7)
    return b

emit("notifications", bell("on"))
emit("notifications-disabled", bell("off"))
emit("notification-active", bell("badge"))
emit("notification-inactive", bell("on"))
emit("notification-disabled", bell("off"))
emit("preferences-desktop-notification-bell", bell("on"))
emit("preferences-desktop-notification", bell("on"))
emit("org.kde.plasma.notifications", bell("on"))


# ================================================================== YAZ / KUR
SIZE_DIRS = ["16x16", "18x18", "22x22", "24x24", "32x32"]
CONTEXTS = ["panel", "status"]

if os.path.isdir(OUT):
    shutil.rmtree(OUT)

for sz in SIZE_DIRS:
    for ctx in CONTEXTS:
        os.makedirs(os.path.join(OUT, sz, ctx), exist_ok=True)
os.makedirs(os.path.join(OUT, "symbolic", "status"), exist_ok=True)

for name, content in written.items():
    for sz in SIZE_DIRS:
        for ctx in CONTEXTS:
            with open(os.path.join(OUT, sz, ctx, name + ".svg"), "w") as f:
                f.write(content)
    with open(os.path.join(OUT, "symbolic", "status", name + "-symbolic.svg"), "w") as f:
        f.write(content)

dirs = []
for sz in SIZE_DIRS:
    for ctx in CONTEXTS:
        dirs.append(f"{sz}/{ctx}")
dirs.append("symbolic/status")

with open(os.path.join(OUT, "index.theme"), "w") as f:
    f.write("[Icon Theme]\n")
    f.write("Name=Iris\n")
    f.write("Name[tr]=Iris\n")
    f.write("Comment=Windows 11 style tray icons layered over Papirus\n")
    f.write("Comment[tr]=Papirus üzerine Windows 11 tarzı tepsi ikonları\n")
    f.write("Inherits=Papirus,breeze-dark,breeze,hicolor\n")
    f.write("Example=folder\n")
    f.write("FollowsColorScheme=true\n")
    f.write("Directories=" + ",".join(dirs) + "\n\n")
    for sz in SIZE_DIRS:
        n = int(sz.split("x")[0])
        for ctx in CONTEXTS:
            f.write(f"[{sz}/{ctx}]\n")
            f.write(f"Size={n}\nMinSize=8\nMaxSize=512\n")
            f.write("Context=Status\nType=Scalable\n\n")
    f.write("[symbolic/status]\nSize=16\nMinSize=8\nMaxSize=512\n")
    f.write("Context=Status\nType=Scalable\n")

print(f"{len(written)} benzersiz ikon, {len(written) * (len(SIZE_DIRS) * len(CONTEXTS) + 1)} dosya -> {OUT}")
