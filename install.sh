#!/usr/bin/env bash
# Iris — full install.
#
#   bash install.sh              install everything and apply it
#   bash install.sh --no-apply   only install the files, leave settings alone
#   bash install.sh --files      same as --no-apply
#   bash install.sh --icons      also select the Windows 11 style tray icon layer
#                                (default: installed but not selected)
#
# Safe to run more than once.
set -euo pipefail
cd "$(dirname "$0")"
REPO="$PWD"

APPLY=1
ICONS=0
for a in "$@"; do
  case "$a" in
    --no-apply|--files) APPLY=0 ;;
    --icons) ICONS=1 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
  esac
done

say() { printf '\033[1m>>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- 1. files
say "colour scheme"
mkdir -p ~/.local/share/color-schemes
rm -f ~/.local/share/color-schemes/iris.colors
install -m644 "$REPO/colors/iris.colors" ~/.local/share/color-schemes/Iris.colors

say "Plasma stili"
mkdir -p ~/.local/share/plasma/desktoptheme
rm -rf ~/.local/share/plasma/desktoptheme/iris
cp -a "$REPO/desktoptheme/iris" ~/.local/share/plasma/desktoptheme/iris

say "icon layer (Windows 11 style tray icons over Papirus)"
mkdir -p ~/.local/share/icons
rm -rf ~/.local/share/icons/Iris
cp -a "$REPO/icons/Iris" ~/.local/share/icons/Iris
gtk-update-icon-cache -f -t ~/.local/share/icons/Iris >/dev/null 2>&1 || true

say "wallpaper"
mkdir -p ~/.local/share/wallpapers
rm -rf ~/.local/share/wallpapers/org.lckt0.iris.topo
cp -a "$REPO/wallpaper/org.lckt0.iris.topo" ~/.local/share/wallpapers/

say "look-and-feel package"
mkdir -p ~/.local/share/plasma/look-and-feel
rm -rf ~/.local/share/plasma/look-and-feel/org.lckt0.iris
cp -a "$REPO/look-and-feel/org.lckt0.iris" ~/.local/share/plasma/look-and-feel/

say "applets"
mkdir -p ~/.local/share/plasma/plasmoids
for a in io.github.lckt0.iristasks io.github.lckt0.iristray io.github.lckt0.irisbatterylabel io.github.lckt0.panelcolorizer \
         io.github.lckt0.irispower io.github.lckt0.irisbattery io.github.lckt0.irisclock io.github.lckt0.irisfetch; do
  rm -rf ~/.local/share/plasma/plasmoids/"$a"
  cp -a "$REPO/applets/$a" ~/.local/share/plasma/plasmoids/
  echo "   $a"
done

say "Klassy configuration (decoration + Qt style)"
mkdir -p ~/.config/klassy
install -m600 "$REPO/decoration/klassyrc" ~/.config/klassy/klassyrc

say "rofi theme"
mkdir -p ~/.config/rofi/themes
install -m644 "$REPO/rofi/iris.rasi" ~/.config/rofi/themes/iris.rasi

if [ "$APPLY" -eq 0 ]; then
  say "files installed, settings untouched (--no-apply)"
  exit 0
fi

# ---------------------------------------------------------------- 2. settings
say "kdeglobals"
# Delete the key first, otherwise plasma-apply-colorscheme skips copying the
# colours into kdeglobals.
kwriteconfig6 --file kdeglobals --group General --key ColorScheme --delete 2>/dev/null || true
kwriteconfig6 --file kdeglobals --group General --key ColorSchemeHash --delete 2>/dev/null || true
# An accent colour would override the scheme's own selection grey.
kwriteconfig6 --file kdeglobals --group General --key AccentColor --delete 2>/dev/null || true
kwriteconfig6 --file kdeglobals --group General --key LastUsedCustomAccentColor --delete 2>/dev/null || true
if [ "$ICONS" -eq 1 ]; then
  kwriteconfig6 --file kdeglobals --group Icons --key Theme "Iris"
  say "icon theme set to Iris"
else
  say "icon theme unchanged (use --icons to select Iris)"
fi
kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle "Klassy"
kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor "0.5"

say "KWin"
for grp in org.kde.kdecoration2 org.kde.kdecoration3; do
  kwriteconfig6 --file kwinrc --group "$grp" --key library "org.kde.klassy"
  kwriteconfig6 --file kwinrc --group "$grp" --key theme "Klassy"
  kwriteconfig6 --file kwinrc --group "$grp" --key BorderSize "Tiny"
  kwriteconfig6 --file kwinrc --group "$grp" --key BorderSizeAuto "false"
done
kwriteconfig6 --file kwinrc --group Compositing --key AnimationSpeed "3"
kwriteconfig6 --file kwinrc --group Compositing --key LatencyPolicy "Low"
kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled "true"
kwriteconfig6 --file kwinrc --group Plugins --key contrastEnabled "true"
kwriteconfig6 --file kwinrc --group Plugins --key kwin4_effect_fadeEnabled "true"
kwriteconfig6 --file kwinrc --group Plugins --key kwin4_effect_scaleEnabled "true"
kwriteconfig6 --file kwinrc --group Plugins --key wobblywindowsEnabled "false"
kwriteconfig6 --file kwinrc --group Plugins --key magiclampEnabled "false"
kwriteconfig6 --file kwinrc --group Effect-kwin4_effect_scale --key Duration "140"
kwriteconfig6 --file kwinrc --group Effect-kwin4_effect_fade --key FadeInTime "120"
kwriteconfig6 --file kwinrc --group Effect-kwin4_effect_fade --key FadeOutTime "90"

say "removing per-application colour scheme overrides"
for f in dolphinrc kdenliverc konsolerc katerc okularrc; do
  [ -f ~/.config/"$f" ] || continue
  sed -i '/^ColorScheme=Breeze/d;/^ColorSchemePath=Breeze/d' ~/.config/"$f"
done

say "GTK animations"
for f in ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini; do
  [ -f "$f" ] || continue
  if grep -q '^gtk-enable-animations=' "$f"; then
    sed -i 's/^gtk-enable-animations=.*/gtk-enable-animations=true/' "$f"
  else
    sed -i '/^\[Settings\]/a gtk-enable-animations=true' "$f"
  fi
done

say "selecting the rofi theme"
if [ -f ~/.config/rofi/config.rasi ]; then
  if grep -q '^@theme' ~/.config/rofi/config.rasi; then
    sed -i 's|^@theme .*|@theme "themes/iris"|' ~/.config/rofi/config.rasi
  else
    printf '\n@theme "themes/iris"\n' >> ~/.config/rofi/config.rasi
  fi
fi

say "applying"
plasma-apply-colorscheme Iris >/dev/null 2>&1 || warn "could not apply the colour scheme"
plasma-apply-desktoptheme iris >/dev/null 2>&1 || warn "could not apply the Plasma style"
plasma-apply-wallpaperimage ~/.local/share/wallpapers/org.lckt0.iris.topo >/dev/null 2>&1 \
  || warn "could not apply the wallpaper"
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

say "restarting plasmashell"
if systemctl --user is-enabled plasma-plasmashell.service >/dev/null 2>&1 \
   || systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
  systemctl --user restart plasma-plasmashell.service
else
  kquitapp6 plasmashell >/dev/null 2>&1 || true
  sleep 2
  (setsid plasmashell >/dev/null 2>&1 &)
fi

# Battery percentage: turn off the stock applet's in-icon badge and put the
# Iris label next to it. Done through plasmashell's scripting API because the
# panel configuration is keyed by applet ids.
say "battery percentage label"
sleep 3
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
for (var i = 0; i < panelIds.length; i++) {
  var p = panelById(panelIds[i]);
  var ws = p.widgets();
  var battery = null, label = null;
  for (var j = 0; j < ws.length; j++) {
    if (ws[j].type === "org.kde.plasma.battery") battery = ws[j];
    if (ws[j].type === "io.github.lckt0.irisbatterylabel") label = ws[j];
  }
  if (!battery) continue;
  battery.currentConfigGroup = ["General"];
  battery.writeConfig("showPercentage", false);
  battery.reloadConfig();
  if (!label) label = p.addWidget("io.github.lckt0.irisbatterylabel");
  p.currentConfigGroup = ["General"];
  var order = String(p.readConfig("AppletOrder", "")).split(";")
      .filter(function (s) { return s !== "" && s !== String(label.id); });
  order.splice(order.indexOf(String(battery.id)) + 1, 0, String(label.id));
  p.writeConfig("AppletOrder", order.join(";"));
}
' >/dev/null 2>&1 || warn "could not add the battery percentage label to the panel"

cat <<'NOTE'

>> Done.

   Window decoration settings (2px corners, grey outline, Fluent buttons)
   need KWin to reload the Klassy plugin and take effect at the next login.
   Everything else is active now.
NOTE
