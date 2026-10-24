# iris-desktop

[English](README.md) · **Türkçe**

KDE Plasma 6 için tam siyah bir masaüstü teması: saf `#000000` zemin, ağırlıklı
olarak siyah-beyaz, ince gri kenarlıklar ve her yerde 2px köşe yarıçapı. Renk
yalnızca bir anlam taşıdığı yerde kullanılır (hata, uyarı, başarı, düşük pil).

![Iris, gerçek masaüstünde](screenshots/desktop.png)

![Tema önizlemesi: panel, tepsi simgeleri ve Plasma bileşenleri](screenshots/preview.png)

> **Başlamadan önce küçük bir not:** iris-desktop en başta kendi kullanımım için tasarlandı; başkalarının da işine yarayabilir diye paylaşıyorum. Kendi ihtiyaçlarım ve tercihlerim doğrultusunda şekillendiği için herkese hitap etmeyebilir. Öneri ve geri bildirimlerinizi memnuniyetle karşılarım.

Yukarıdaki görüntü, temanın kendi SVG'leri, renk şeması ve simgeleriyle örnek
verilerle ekransız olarak çizildi; pencere başlıkları yer tutucudur.

| Duvar kağıdı | Tepsi simgeleri |
|---|---|
| ![Duvar kağıdı](screenshots/wallpaper.png) | ![Tepsi simgeleri](screenshots/tray-icons.png) |

Bütün tasarım değerleri tek bir yerde: [`docs/TOKENS.md`](docs/TOKENS.md).

## İçerik

| Parça | Yol | Ne yapar |
|---|---|---|
| Renk şeması | `colors/iris.colors` | Sistem geneli palet: saf siyah pencere ve görünüm zeminleri, gri seçim, beyaz odak halkası. |
| Plasma stili | `desktoptheme/iris/` | Panel, açılır pencere, ipucu, düğme ve liste SVG'leri (9 dilimli, 2px yarıçap). `scripts/gen_desktoptheme.py` üretir. |
| Pencere dekorasyonu | `decoration/klassyrc` | [Klassy](https://github.com/paulmcauley/klassy) yapılandırması: 2px köşeler, gri pencere kenarlığı, Fluent tarzı düğmeler. |
| Simge katmanı *(isteğe bağlı)* | `icons/Iris/` | Papirus'tan miras alır; yalnızca pil, ses, ağ, Bluetooth ve bildirim simgelerini Windows 11 tarzı çizimlerle değiştirir. `scripts/gen_icons.py` üretir. |
| Duvar kağıdı | `wallpaper/org.lckt0.iris.topo/` | 2880x1800 topografik eş yükselti çizgileri, neredeyse tamamı saf siyah. `scripts/gen_wallpaper.py` üretir. |
| Genel tema | `look-and-feel/org.lckt0.iris/` | Hepsini bir araya getiren genel tema; siyah bir açılış ekranı içerir. |
| Rofi teması | `rofi/iris.rasi` | Rofi için aynı palet. |
| KWin betiği *(isteğe bağlı)* | `kwinscript/iris-popup-anchor/` | Panel aletlerinin açılır pencerelerini sağ üst köşeye sabitler. |

Panel aletleri:

| Alet | Kimlik | |
|---|---|---|
| Iris Tasks | `io.github.lckt0.iristasks` | Sade görev çubuğu: simge ve başlık, kayan etkin göstergesi, yer daraldıkça küçülen düğmeler. |
| Iris Tray *(isteğe bağlı)* | `io.github.lckt0.iristray` | Ağ, ses, Bluetooth, pil ve bildirim göstergeleri tek sıkı bir kümede. |
| Iris Battery Percent | `io.github.lckt0.irisbatterylabel` | Pil yüzdesini stok pil simgesinin yanına düz metin olarak yazar. |
| Iris Power | `io.github.lckt0.irispower` | Pilden çekilen gücün son bir dakikalık ortalaması. |
| Iris Fetch | `io.github.lckt0.irisfetch` | fastfetch çıktısını masaüstünde yerel olarak, anahtarlar ve değerler hizalı sütunlarda çizer. |
| Iris Power & Battery | `io.github.lckt0.irisbattery` | Plasma'nın pil aletinin (powerdevil 6.7.5) çatalı; yüzde simgenin yanında. |
| Iris Digital Clock | `io.github.lckt0.irisclock` | Plasma'nın dijital saatinin (plasma-workspace 6.7.5) çatalı; ÖÖ/ÖS yerine her zaman AM/PM yazar. |
| Panel Colorizer (Iris) | `io.github.lckt0.panelcolorizer` | [Panel Colorizer](https://github.com/luisbocanegra/plasma-panel-colorizer) 8.0.0 çatalı; yüzen ve sabit panel için ayrı ayarlar. |

Çatallar kendi kimlikleriyle kurulur, böylece stok aletler çalışmaya devam
eder. Üst projeye göre değişiklikleri [`patches/`](patches) dizininde (pil ve
saat), Panel Colorizer kaynaklarında ise `Iris fork` işaretiyle belirtilmiştir.

Hareket: genel animasyon çarpanı 0.5'e ayarlanır, geçişler 90–150 ms sürer ve
yalnızca opaklık, ölçek ve konum üzerinde çalışır. Sürekli dönen ya da nabız
atan bir öğe yoktur.

## Kurulum

### Gereksinimler

- KDE Plasma 6 (Wayland ya da X11)
- Pencere dekorasyonu ve uygulama stili için [Klassy](https://github.com/paulmcauley/klassy)
- Papirus simge teması (Iris simge katmanı ondan miras alır)
- JetBrains Mono yazı tipi
- İsteğe bağlı: rofi, fastfetch (Iris Fetch için)

Arch Linux'ta:

```sh
sudo pacman -S --needed papirus-icon-theme ttf-jetbrains-mono rofi fastfetch
yay -S klassy          # AUR'dan; başka bir AUR yardımcısı da olur
```

Temanın kendisi için bir Arch paketi yok; kurulum betiğini kullanın.

### Kurulum betiği

```sh
git clone https://github.com/lckt0/iris-desktop.git
cd iris-desktop
bash install.sh
```

Seçenekler:

```sh
bash install.sh --no-apply   # yalnızca dosyaları kopyalar, hiçbir ayarı değiştirmez
bash install.sh --icons      # Iris simge katmanını da seçer
```

Tam kurulum şu dosyaları kopyalar:

| Kaynak | Hedef |
|---|---|
| `colors/iris.colors` | `~/.local/share/color-schemes/Iris.colors` |
| `desktoptheme/iris/` | `~/.local/share/plasma/desktoptheme/iris/` |
| `icons/Iris/` | `~/.local/share/icons/Iris/` |
| `wallpaper/org.lckt0.iris.topo/` | `~/.local/share/wallpapers/org.lckt0.iris.topo/` |
| `look-and-feel/org.lckt0.iris/` | `~/.local/share/plasma/look-and-feel/org.lckt0.iris/` |
| `applets/io.github.lckt0.*` | `~/.local/share/plasma/plasmoids/` |
| `decoration/klassyrc` | `~/.config/klassy/klassyrc` (var olan dosyanın yerine geçer) |
| `rofi/iris.rasi` | `~/.config/rofi/themes/iris.rasi` |

`--no-apply` verilmediyse ardından:

- Iris renk şemasını, Plasma stilini ve duvar kağıdını uygular;
- Klassy'yi pencere dekorasyonu ve uygulama stili yapar, animasyon çarpanını
  0.5'e ayarlar, `kwinrc` içinde bulanıklık, kontrast, solma ve ölçek
  efektlerini açar (titreyen pencereler ve sihirli lamba kapalı);
- `dolphinrc`, `kdenliverc`, `konsolerc`, `katerc` ve `okularrc` içindeki
  Breeze renk şeması geçersiz kılmalarını siler;
- GTK animasyonlarını açar ve `~/.config/rofi/config.rasi` varsa rofi temasını seçer;
- plasmashell'i yeniden başlatır ve pil aleti bulunan her panelde Iris Battery
  Percent'i stok pil aletinin yanına ekler.

Pencere dekorasyonu değişiklikleri bir sonraki girişte etkin olur.

### Elle kurulum

Yukarıdaki tablodaki dosyaları hedeflerine kopyalayın, ardından seçin:

- **Sistem Ayarları → Renkler ve Temalar → Genel Tema → Iris**, ya da tek tek
  **Renkler → Iris**, **Plasma Stili → Iris**, **Pencere Dekorasyonları → Klassy**,
  **Uygulama Stili → Klassy** ve isteğe bağlı olarak **Simgeler → Iris**;
- duvar kağıdı: masaüstüne sağ tıklayın → **Masaüstünü ve Duvar Kağıdını Yapılandır** → **Iris Topo**.

### Aletler ve KWin betiği

Aletleri panele sağ tıklayıp **Araç Ekle veya Yönet** ile ekleyin ve "Iris"
(ya da "Panel Colorizer (Iris)") diye arayın.

KWin betiği `install.sh` ile kurulmaz:

```sh
kpackagetool6 --type KWin/Script --install kwinscript/iris-popup-anchor
```

Ardından **Sistem Ayarları → Pencere Yönetimi → KWin Betikleri** içinde
**Iris Popup Anchor**'ı etkinleştirin.

## Kaldırma

1. Varsayılan temaya dönün:

   ```sh
   plasma-apply-lookandfeel -a org.kde.breezedark.desktop
   ```

   Bu, Breeze Koyu renklerini, Plasma stilini, simgeleri, pencere
   dekorasyonunu ve uygulama stilini geri getirir. Bunun yerine **Sistem
   Ayarları → Renkler ve Temalar → Genel Tema** içinden **Breeze Koyu**'yu (ya
   da **Breeze**'i) seçebilir, isterseniz animasyon hızını **Genel Davranış**
   altında sıfırlayabilirsiniz.

2. Iris aletlerini panellerinizden kaldırın (sağ tık → **Kaldır**) ve
   etkinleştirdiyseniz **Iris Popup Anchor**'ı kapatın.

3. Kurulan dosyaları silin:

   ```sh
   rm -f  ~/.local/share/color-schemes/Iris.colors
   rm -rf ~/.local/share/plasma/desktoptheme/iris
   rm -rf ~/.local/share/icons/Iris
   rm -rf ~/.local/share/wallpapers/org.lckt0.iris.topo
   rm -rf ~/.local/share/plasma/look-and-feel/org.lckt0.iris
   rm -rf ~/.local/share/plasma/plasmoids/io.github.lckt0.{iristasks,iristray,irisbatterylabel,irispower,irisfetch,irisbattery,irisclock,panelcolorizer}
   rm -f  ~/.config/rofi/themes/iris.rasi
   kpackagetool6 --type KWin/Script --remove iris-popup-anchor   # yalnızca kurduysanız
   ```

4. İsteğe bağlı:
   - `~/.config/klassy/klassyrc` Iris yapılandırmasıyla değiştirildi; Klassy'nin
     varsayılanlarına dönmek için silin ya da Klassy'yi kaldırın.
   - `~/.config/rofi/config.rasi` içindeki `@theme "themes/iris"` satırını silin.
   - Kurulumun yazdığı KWin efekt ayarları `~/.config/kwinrc` içinde kalır;
     **Sistem Ayarları → Pencere Yönetimi → Masaüstü Efektleri**'nden değiştirin.

## Bilinen sınırlar

- **Klassy anahtarları gruba duyarlıdır.** `klassyrc` içinde yanlış gruba
  yazılan anahtarlar sessizce yok sayılır; geçerli gruplar
  `/usr/share/config.kcfg/klassy-decoration.kcfg` ve
  `/usr/share/config.kcfg/klassy.kcfg` dosyalarında listelenir.
- **Klassy pencere kenarlığı yeni bir giriş ister.** `kwin reconfigure` onu
  yeni pencerelere uygulamaz.
- **Uygulama tepsi simgeleri Plasma'nın kendi sistem tepsisinde kalır.** Iris
  Tray yalnızca kendi göstergelerini çizer; StatusNotifierItem barındırmak bir
  containment gerektirir.
- **Sistem tepsisi açılır penceresi yalnızca simgeli bir ızgaraya
  dönüştürülemez.** Plasma 6.7'den beri QML'i eklentinin içine derlenmiştir.
- Pil ve saat çatalları Plasma 6.7.5 tabanlıdır ve 6.8'de kullanılmaktadır;
  sonraki sürümlerde yeniden taşınmaları gerekebilir.

## Varlıkları yeniden üretmek

Bütün SVG'ler, simgeler ve duvar kağıdı betiklerle üretilir; elle düzenlenmiş
dosya yoktur:

```sh
python3 scripts/gen_desktoptheme.py desktoptheme/iris
python3 scripts/gen_icons.py icons/Iris
python3 scripts/gen_wallpaper.py   # belirlenimci, varsayılan tohum 20260914
```

`gen_wallpaper.py` için NumPy ve Pillow gerekir.

## Lisans

GPL-3.0-or-later, bkz. [LICENSE](LICENSE). Çatallanan aletler özgün
lisanslarını ve telif başlıklarını korur: Panel Colorizer GPL-3.0, KDE'den
gelen pil ve saat aletleri GPL-2.0-or-later lisanslıdır.
