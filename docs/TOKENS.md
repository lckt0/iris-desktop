# Iris — Design Tokens

The single source of truth. Every component (desktop theme, applets, rofi,
decoration, wallpaper) uses these values.

## Colour

| Token          | Hex       | RGB           | Use |
|----------------|-----------|---------------|-----|
| `bg0`          | `#000000` | 0,0,0         | Pitch black — window, panel and desktop ground |
| `bg1`          | `#0A0A0A` | 10,10,10      | Raised surface (cards, popup body) |
| `bg2`          | `#141414` | 20,20,20      | Hover surface |
| `bg3`          | `#545454` | 84,84,84      | Selected surface (colour scheme `[Colors:Selection]`) |
| `bg4`          | `#303030` | 48,48,48      | Active control fill (slider, switch) |
| `line`         | `#545454` | 84,84,84      | Default 2px border. The Kirigami separator in notification headers uses the same tone. |
| `line2`        | `#6b6b6b` | 107,107,107   | Strong border — line edits, focusable surfaces |
| `fg0`          | `#FFFFFF` | 255,255,255   | Primary text, accent, focus ring |
| `fg1`          | `#B4B4B4` | 180,180,180   | Secondary text |
| `fg2`          | `#6E6E6E` | 110,110,110   | Inactive / disabled |
| `neg`          | `#FF5555` | 255,85,85     | Error, critical battery |
| `neu`          | `#F5B43C` | 245,180,60    | Warning, low battery |
| `pos`          | `#50D68C` | 80,214,140    | Success, charging |

The accent colour is **white**. Colour is only used where it carries meaning.

Title bars: the active window's is `bg0`, an inactive window's is `#1C1C1C`
(28,28,28). The text stays `fg0` on both; focus is shown by the background,
not by dimming the title.

## Control surfaces

On pure black, controls need their own tones or they blend into the window:

| Element | Fill | Border |
|---------|------|--------|
| Line edit | `#161616` | `#4d4d4d` (white ring when focused) |
| Button | `#1a1a1a` | `#4d4d4d` |
| Button hover | `#242424` | `#6b6b6b` |
| Switch (off) | `#1f1f1f` track, `#d8d8d8` knob | `#5a5a5a` |
| Switch (on) | white track, black knob | — |
| Slider groove | `#3a3a3a` / filled part white | — |
| Progress bar | `#333333` / filled part white, 4px | — |
| List highlight | hover `#2b2b2b`, selected `#3a3a3a`, full width | — |

## Taskbar background steps

Task button backgrounds are the text colour at low opacity, so the steps hold
with any colour scheme. On a black panel they come out as:

| State | Opacity | On black |
|-------|---------|----------|
| Inactive (rest) | 0.10 | `#1a1a1a` |
| Hover | 0.16 | `#292929` |
| Active | 0.24 | `#3d3d3d` |
| Pressed | 0.30 | `#4d4d4d` |

The active task also gets a thin white indicator line. **Minimised tasks are
not dimmed**; state is shown only by these steps and the indicator.

## Geometry

| Token             | Value | Note |
|-------------------|-------|------|
| `radius`          | 2px   | Everywhere — windows, menus, popups, buttons, cards |
| `radius-sm`       | 1px   | Small indicators, markers |
| `border`          | 2px   | All borders (1px was barely visible on black) |
| `panel-pad`       | 2px   | Outer padding inside the panel |
| `popup-pad`       | 6px   | Popup/dialog inner margin, so content does not touch the border |
| `item-pad-h`      | 8px   | Horizontal padding of list/task items |
| `item-pad-v`      | 4px   | Vertical padding |

## Popup borders

All four borders of the frame are defined. For popups attached to the panel,
Plasma itself hides the borders facing the panel and the screen edge (this
happens in `libPlasmaQuick` and cannot be overridden by the theme, window
rules or a KWin script). Free-floating notifications draw all four.

`horizontal-line` in `widgets/line.svg` is left transparent: Plasma places
that element on the top edge of panel-attached popups, where it showed up as
a thin separator between panel and popup.

## Shadow

Popups and dialogs have **no** shadow. Plasma draws dialog shadows from the
desktop theme's `shadow-*` slices, which are not generated. On pure black a
shadow only blurred the edge into the border.

## Motion

| Token         | Duration | Easing     | Use |
|---------------|----------|------------|-----|
| `dur-fast`    | 90ms     | OutCubic   | Hover, press feedback |
| `dur-base`    | 140ms    | OutCubic   | Adding/removing tasks, opening popups |
| `dur-slow`    | 220ms    | OutQuint   | Layout shifts, expanding |
| KWin factor   | 0.5      | —          | `kdeglobals` `AnimationDurationFactor` |

Animations only touch opacity, scale and x/y translation (cheap on the GPU).
Nothing spins or pulses continuously, to save power.

## Typography

JetBrains Mono 10 (system, fixed, window titles, panel clock) and JetBrains
Mono 11 (rofi). The terminal keeps its own font.
