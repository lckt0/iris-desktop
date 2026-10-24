# iris-desktop

[English](README.md) · **Türkçe**

KDE Plasma 6 için tam siyah bir masaüstü teması: saf `#000000` zemin, ağırlıklı
olarak siyah-beyaz, ince gri kenarlıklar ve her yerde 2px köşe yarıçapı. Renk
yalnızca bir anlam taşıdığı yerde kullanılır (hata, uyarı, başarı, düşük pil).

![Iris, gerçek masaüstünde](screenshots/desktop.png)

> **Başlamadan önce küçük bir not:** iris-desktop en başta kendi kullanımım için tasarlandı; başkalarının da işine yarayabilir diye paylaşıyorum. Kendi ihtiyaçlarım ve tercihlerim doğrultusunda şekillendiği için herkese hitap etmeyebilir. Öneri ve geri bildirimlerinizi memnuniyetle karşılarım.

Ekran görüntüsünde Iris düzeni görünüyor: üstte 30px yüksekliğinde tek bir
panel; solda sanal masaüstü göstergesi ve görevler, ortada saat, sağda
uygulama tepsisi, ağ, Bluetooth, ses, pil, güç tüketimi ve bildirimler.
Simgeler Papirus. Görüntüdeki duvar kağıdı kişisel; temayla gelen Iris Topo
duvar kağıdı şöyle görünür:

![Iris Topo duvar kağıdı](screenshots/wallpaper.png)

Bütün tasarım değerleri tek bir yerde: [`docs/TOKENS.md`](docs/TOKENS.md).

## İçerik

| Parça | Yol | Ne yapar |
|---|---|---|
| Renk şeması | `colors/iris.colors` | Sistem geneli palet: saf siyah pencere ve görünüm zeminleri, gri seçim, beyaz odak halkası, gri etkin olmayan pencere başlıkları. |
| Plasma stili | `desktoptheme/iris/` | Panel, açılır pencere, ipucu, düğme ve liste SVG'leri (9 dilimli, 2px yarıçap). `scripts/gen_desktoptheme.py` üretir. |
| Pencere dekorasyonu | `decoration/klassyrc` | [Klassy](https://github.com/paulmcauley/klassy) yapılandırması: 2px köşeler, gri pencere kenarlığı, Fluent tarzı düğmeler. |
| Duvar kağıdı | `wallpaper/org.lckt0.iris.topo/` | 2880x1800 topografik eş yükselti çizgileri, neredeyse tamamı saf siyah. `scripts/gen_wallpaper.py` üretir. |
| Genel tema | `look-and-feel/org.lckt0.iris/` | Hepsini bir araya getiren genel tema: renkler, Plasma stili, Klassy, Papirus simgeleri, duvar kağıdı, siyah bir açılış ekranı ve panel düzeni. |
| Rofi teması | `rofi/iris.rasi` | Rofi için aynı palet. |
| KWin betiği | `kwinscript/iris-popup-anchor/` | Panel aletlerinin açılır pencerelerini sağ üst köşeye, panelin hemen altına sabitler. |

Panel aletleri:

| Alet | Kimlik | |
|---|---|---|
| Iris Tasks | `io.github.lckt0.iristasks` | Sade görev çubuğu: simge ve başlık, kayan etkin göstergesi, yer daraldıkça küçülen düğmeler. |
| Iris Digital Clock | `io.github.lckt0.irisclock` | Plasma'nın dijital saatinin (plasma-workspace 6.7.5) çatalı; ÖÖ/ÖS yerine her zaman AM/PM yazar. |
| Iris Power & Battery | `io.github.lckt0.irisbattery` | Plasma'nın pil aletinin (powerdevil 6.7.5) çatalı; yüzde simgenin yanında. |
| Iris Power | `io.github.lckt0.irispower` | Pilden çekilen gücün son bir dakikalık ortalaması. |
| Iris Fetch | `io.github.lckt0.irisfetch` | Masaüstü aleti: fastfetch çıktısını yerel olarak, anahtarlar ve değerler hizalı sütunlarda çizer. |

Çatallar kendi kimlikleriyle kurulur, böylece stok aletler çalışmaya devam
eder. Üst projeye göre değişiklikler [`patches/`](patches) dizinindedir.

Panel düzeni başka projelerden gelen şu aletleri de kullanır. Hiçbiri kesin
olarak gerekli değildir: biri eksikse düzen onun yerine Plasma'nın stok aletini
koyar.

| Alet | Kimlik | Kaynak | Yedek |
|---|---|---|---|
| Mike Desktop | `com.mike.desktop` | KDE Store (Yeni Araçlar Al → "Mike Desktop") | Sayfalayıcı |
| Advanced Separator | `luisbocanegra.advanced_separator` | [plasma-advanced-separator](https://github.com/luisbocanegra/plasma-advanced-separator) | Kenar Boşluklu Ayırıcı |
| Audio Volume (Multi-Output) | `io.github.lckt0.volume` | [iris-volume](https://github.com/lckt0/iris-volume) | Ses Düzeyi |

Ağ, Bluetooth ve bildirimler Plasma'nın kendi aletleridir; sistem tepsisinin
içinde değil, doğrudan panelde dururlar.

Hareket: genel animasyon çarpanı 0.5'e ayarlanır, geçişler 90–150 ms sürer ve
yalnızca opaklık, ölçek ve konum üzerinde çalışır. Sürekli dönen ya da nabız
atan bir öğe yoktur.

## Kurulum

### Gereksinimler

- KDE Plasma 6 (Wayland ya da X11)
- Pencere dekorasyonu ve uygulama stili için [Klassy](https://github.com/paulmcauley/klassy)
- [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) simge teması
- JetBrains Mono yazı tipi
- İsteğe bağlı: fastfetch (Iris Fetch için), rofi ve yukarıda listelenen
  üçüncü parti aletler

Arch Linux'ta:

```sh
sudo pacman -S --needed papirus-icon-theme ttf-jetbrains-mono fastfetch rofi
yay -S klassy          # AUR'dan; başka bir AUR yardımcısı da olur
```

Mike Desktop ve Advanced Separator, **panele sağ tık → Araç Ekle veya Yönet →
Yeni Araçlar Al → Yeni Plasma Araçları İndir** yoluyla kurulabilir. Audio
Volume (Multi-Output) için [iris-volume](https://github.com/lckt0/iris-volume)
README'sine bakın.

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
bash install.sh --layout     # panellerinizi de Iris düzeniyle değiştirir
```

Tam kurulum şu dosyaları kopyalar:

| Kaynak | Hedef |
|---|---|
| `colors/iris.colors` | `~/.local/share/color-schemes/Iris.colors` |
| `desktoptheme/iris/` | `~/.local/share/plasma/desktoptheme/iris/` |
| `wallpaper/org.lckt0.iris.topo/` | `~/.local/share/wallpapers/org.lckt0.iris.topo/` |
| `look-and-feel/org.lckt0.iris/` | `~/.local/share/plasma/look-and-feel/org.lckt0.iris/` |
| `applets/io.github.lckt0.*` | `~/.local/share/plasma/plasmoids/` |
| `decoration/klassyrc` | `~/.config/klassy/klassyrc` (var olan dosyanın yerine geçer) |
| `rofi/iris.rasi` | `~/.config/rofi/themes/iris.rasi` |

`--no-apply` verilmediyse ardından:

- Iris renk şemasını, Plasma stilini ve duvar kağıdını uygular; Papirus
  kuruluysa simge teması olarak onu seçer;
- Klassy'yi pencere dekorasyonu ve uygulama stili yapar, animasyon çarpanını
  0.5'e ayarlar, `kwinrc` içinde bulanıklık, kontrast, solma ve ölçek
  efektlerini açar (titreyen pencereler ve sihirli lamba kapalı);
- `kwinrulesrc`'ye "Iris title bar" pencere kuralını ekler; böylece etkin
  olmayan pencerelerin başlığı şemadaki gri zemini (`#1C1C1C`) alır, yazı rengi
  değişmez (Plasma şemayı `kdeglobals`'a kopyalarken bu renkleri atıyor);
- `dolphinrc`, `kdenliverc`, `konsolerc`, `katerc` ve `okularrc` içindeki
  Breeze renk şeması geçersiz kılmalarını siler;
- GTK animasyonlarını açar ve `~/.config/rofi/config.rasi` varsa rofi temasını seçer.

`--layout` verilirse Iris genel temasını masaüstü düzeniyle birlikte de
uygular (`plasma-apply-lookandfeel --apply org.lckt0.iris --resetLayout`). Bu
**mevcut panellerinizi ve masaüstü aletlerinizi kaldırır**; yerine Iris
panelini ve Iris Fetch masaüstü aletini kurar.

Pencere dekorasyonu değişiklikleri ve panelde zaten bulunan aletlerin yeni
sürümleri bir sonraki girişte etkin olur.

### Elle kurulum

Yukarıdaki tablodaki dosyaları hedeflerine kopyalayın, ardından seçin:

- **Sistem Ayarları → Renkler ve Temalar → Genel Tema → Iris**. Iris panel
  düzenini de istiyorsanız uygulama penceresinde "Masaüstü ve pencere düzeni"ni
  işaretleyin. Ya da parçaları tek tek seçin: **Renkler → Iris**,
  **Plasma Stili → Iris**, **Pencere Dekorasyonları → Klassy**,
  **Uygulama Stili → Klassy**, **Simgeler → Papirus**;
- duvar kağıdı: masaüstüne sağ tıklayın → **Masaüstünü ve Duvar Kağıdını Yapılandır** → **Iris Topo**.

### Aletler ve KWin betiği

Iris düzenini kullanmıyorsanız aletleri panele sağ tıklayıp **Araç Ekle veya
Yönet** ile ekleyin ve "Iris" diye arayın. Iris Fetch masaüstüne eklenir
(masaüstüne sağ tık → **Araç Ekle veya Yönet**).

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
   altında sıfırlayabilirsiniz. Varsayılan Breeze panelini de geri almak için
   yukarıdaki komuta `--resetLayout` ekleyin (ya da "Masaüstü ve pencere
   düzeni"ni işaretleyin).

2. Iris aletlerini panellerinizden ve masaüstünden kaldırın (sağ tık →
   **Kaldır**) ve etkinleştirdiyseniz **Iris Popup Anchor**'ı kapatın.

3. Kurulan dosyaları silin:

   ```sh
   rm -f  ~/.local/share/color-schemes/Iris.colors
   rm -rf ~/.local/share/plasma/desktoptheme/iris
   rm -rf ~/.local/share/wallpapers/org.lckt0.iris.topo
   rm -rf ~/.local/share/plasma/look-and-feel/org.lckt0.iris
   rm -rf ~/.local/share/plasma/plasmoids/io.github.lckt0.{iristasks,irisclock,irisbattery,irispower,irisfetch}
   rm -f  ~/.config/rofi/themes/iris.rasi
   kpackagetool6 --type KWin/Script --remove iris-popup-anchor   # yalnızca kurduysanız
   ```

4. İsteğe bağlı:
   - `~/.config/klassy/klassyrc` Iris yapılandırmasıyla değiştirildi; Klassy'nin
     varsayılanlarına dönmek için silin ya da Klassy'yi kaldırın.
   - `~/.config/rofi/config.rasi` içindeki `@theme "themes/iris"` satırını silin.
   - Kurulumun yazdığı KWin efekt ayarları `~/.config/kwinrc` içinde kalır;
     **Sistem Ayarları → Pencere Yönetimi → Masaüstü Efektleri**'nden değiştirin.
   - **Sistem Ayarları → Pencere Yönetimi → Pencere Kuralları**'ndan
     **Iris title bar** kuralını silin.
   - Simge teması Papirus olarak kalır; **Sistem Ayarları → Renkler ve
     Temalar → Simgeler**'den değiştirin.

## Bilinen sınırlar

- **Klassy anahtarları gruba duyarlıdır.** `klassyrc` içinde yanlış gruba
  yazılan anahtarlar sessizce yok sayılır; geçerli gruplar
  `/usr/share/config.kcfg/klassy-decoration.kcfg` ve
  `/usr/share/config.kcfg/klassy.kcfg` dosyalarında listelenir.
- **Klassy pencere kenarlığı yeni bir giriş ister.** `kwin reconfigure` onu
  yeni pencerelere uygulamaz.
- **Sistem tepsisi açılır penceresi yalnızca simgeli bir ızgaraya
  dönüştürülemez.** Plasma 6.7'den beri QML'i eklentinin içine derlenmiştir.
- Pil ve saat çatalları Plasma 6.7.5 tabanlıdır ve 6.8'de kullanılmaktadır;
  sonraki sürümlerde yeniden taşınmaları gerekebilir.

## Varlıkları yeniden üretmek

Plasma stili SVG'leri ve duvar kağıdı betiklerle üretilir; elle düzenlenmiş
dosya yoktur:

```sh
python3 scripts/gen_desktoptheme.py desktoptheme/iris
python3 scripts/gen_wallpaper.py   # belirlenimci, varsayılan tohum 20260914
```

`gen_wallpaper.py` için NumPy ve Pillow gerekir.

## Lisans

GPL-3.0-or-later, bkz. [LICENSE](LICENSE). KDE'den çatallanan pil ve saat
aletleri özgün GPL-2.0-or-later lisanslarını ve telif başlıklarını korur.
