// Iris desktop layout: one 30px panel at the top.
//
//   pager | tasks ........ clock ........ tray | network bluetooth volume battery | power notifications
//
// Third-party widgets fall back to their stock counterparts when they are
// not installed.

function pick(preferred, fallback) {
    return knownWidgetTypes.indexOf(preferred) !== -1 ? preferred : fallback;
}

function separator(panel) {
    var type = pick("luisbocanegra.advanced_separator", "org.kde.plasma.marginsseparator");
    var w = panel.addWidget(type);
    if (type === "luisbocanegra.advanced_separator") {
        w.currentConfigGroup = ["General"];
        w.writeConfig("width", 2);
        w.writeConfig("lineColor", JSON.stringify({
            enabled: true, sourceType: 0, custom: "#666666", alpha: 0.7,
            systemColor: "highlightColor", systemColorSet: "Window",
            saturationEnabled: false, saturation: 0.5,
            lightnessEnabled: false, lightness: 0.5,
            list: ["#ED8796", "#A6DA95", "#EED49F", "#8AADF4", "#F5BDE6", "#8BD5CA", "#f5a97f"]
        }));
        w.writeConfig("initialized", true);
        w.reloadConfig();
    }
    return w;
}

var panel = new Panel;
panel.location = "top";
panel.height = 30;
panel.floating = false;
panel.hiding = "none";
panel.alignment = "center";

// Left: virtual desktops and tasks
var pagerType = pick("com.mike.desktop", "org.kde.plasma.pager");
var pager = panel.addWidget(pagerType);
if (pagerType === "com.mike.desktop") {
    pager.currentConfigGroup = ["General"];
    pager.writeConfig("useSystemColors", false);
    pager.writeConfig("windowIndicatorColor", "#898989");
    pager.currentConfigGroup = ["Pills"];
    pager.writeConfig("pillsDotSize", 2);
    pager.writeConfig("pillsMargin", 3);
    pager.reloadConfig();
}
separator(panel);

var tasks = panel.addWidget("io.github.lckt0.iristasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("maxTaskWidth", 100);
tasks.reloadConfig();

// Centre: clock
panel.addWidget("org.kde.plasma.panelspacer");

var clock = panel.addWidget("io.github.lckt0.irisclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("autoFontAndSize", false);
clock.writeConfig("fontFamily", "JetBrains Mono");
clock.writeConfig("fontSize", 6);
clock.writeConfig("fontStyleName", "Regular");
clock.writeConfig("fontWeight", 400);
clock.writeConfig("dateFormat", "custom");
clock.writeConfig("customDateFormat", "ddd, MMM d,");
clock.writeConfig("dateDisplayFormat", "BesideTime");
clock.writeConfig("use24hFormat", 0);
clock.reloadConfig();

panel.addWidget("org.kde.plasma.panelspacer");

// Right: application tray, then the indicators as separate widgets
var tray = panel.addWidget("org.kde.plasma.systemtray");
var trayId = tray.readConfig("SystrayContainmentId");
var trayConfig = trayId ? desktopById(trayId) : tray;
trayConfig.currentConfigGroup = ["General"];
// Network, Bluetooth, volume, battery and notifications sit in the panel
// themselves, so the tray does not load its own copies.
trayConfig.writeConfig("extraItems", [
    "org.kde.plasma.cameraindicator", "org.kde.plasma.devicenotifier",
    "org.kde.plasma.manage-inputmethod", "org.kde.kscreen",
    "org.kde.plasma.keyboardlayout", "org.kde.plasma.brightness",
    "org.kde.plasma.keyboardindicator", "org.kde.plasma.printmanager",
    "org.kde.plasma.mediacontroller", "org.kde.plasma.clipboard",
    "org.kde.plasma.vault", "org.kde.kdeconnect"
]);
trayConfig.writeConfig("hiddenItems", [
    "org.kde.plasma.brightness", "org.kde.plasma.keyboardindicator",
    "org.kde.plasma.printmanager", "org.kde.plasma.mediacontroller",
    "org.kde.plasma.clipboard", "org.kde.plasma.vault", "org.kde.kdeconnect"
]);
trayConfig.writeConfig("reverseIconOrder", true);
trayConfig.reloadConfig();

separator(panel);
panel.addWidget("org.kde.plasma.networkmanagement");
panel.addWidget("org.kde.plasma.bluetooth");
panel.addWidget(pick("io.github.lckt0.volume", "org.kde.plasma.volume"));
panel.addWidget("io.github.lckt0.irisbattery");
separator(panel);
panel.addWidget("io.github.lckt0.irispower");
panel.addWidget("org.kde.plasma.notifications");

// Desktop: wallpaper and fastfetch in the bottom-left corner
var desktopsArray = desktopsForActivity(currentActivity());
for (var i = 0; i < desktopsArray.length; i++) {
    var d = desktopsArray[i];
    d.wallpaperPlugin = "org.kde.image";
    var geo = screenGeometry(d.screen);
    d.addWidget("io.github.lckt0.irisfetch", 16, Math.max(0, geo.height - 416), 944, 352);
}
