# NESTORA — Design System & UI Implementation Guide

> **Belgenin amacı:** Stitch üzerinde hazırlanan Nestora tasarımını eksiksiz biçimde Flutter/Dart koduna aktarmak, görsel tasarım standartlarını belirlemek ve bu işlemin mevcut proje mimarisine uygun yapılmasını sağlamak.

Bu belge yalnızca görsel bir rehber değildir. Antigravity'nin tasarımı hangi kurallarla uygulayacağını, kodları hangi klasörlere yerleştireceğini, hangi bileşenlerin ortak kullanılacağını ve hangi etkileşimlerin çalışır olması gerektiğini belirleyen bir uygulama sözleşmesidir.

---

# 1. TEMEL UYGULAMA KURALLARI

## 1.1. Stitch tasarımı esas alınmalıdır

Nestora'nın UI tasarımı Stitch üzerinde hazırlanmıştır.

Antigravity'nin görevi yeni bir tasarım oluşturmak değil, mevcut Stitch tasarımını Flutter/Dart ile gerçek bir mobil uygulamaya dönüştürmektir.

Aşağıdaki kurallar zorunludur:

- Stitch'teki 16 ekranın tamamı uygulanmalıdır.
- Her ekranın içindeki bütün görsel bileşenler, kartlar, ikonlar, görseller, metinler, boşluklar, hizalamalar, butonlar ve kontrol alanları incelenmelidir.
- Hiçbir ekran atlanmamalıdır.
- Hiçbir ekran yalnızca benzer bir tasarımla değiştirilmemelidir.
- Ekranlar gereğinden fazla sadeleştirilmemelidir.
- Stitch'te bulunan özel tasarım detayları kaybedilmemelidir.
- Görsellerin yerine rastgele ikonlar veya placeholder alanlar kullanılmamalıdır.
- Tasarımda bulunan bileşenler, uygulamanın gerçek işlevleriyle ilişkilendirilmelidir.
- Tasarımın Flutter karşılığı, mümkün olduğunca Stitch'teki görünüme sadık olmalıdır.

**Eksik tasarım aktarımı kabul edilmeyecektir.**

Örneğin bir ekranda başlık, açıklama, üç kart, özel bir illüstrasyon, filtre alanı ve alt bölüm bulunuyorsa bunların tamamı uygulanmalıdır. Yalnızca başlık ve kartların oluşturulması ekranın tamamlandığı anlamına gelmez.

Bir tasarım öğesinin Flutter'da birebir karşılığı bulunmuyorsa uygun bir Flutter widget veya özel çizim yaklaşımı kullanılmalıdır. Tasarım öğesi kaldırılmamalıdır.

## 1.2. Önce mevcut projeyi incele

Kod yazmaya başlamadan önce:

1. Tasarım kodlarının mimarideki yerleşimini anla ve buna göre bir yerleştirme yap klasör dizininde. 
2. Stitch MCP bağlantısını ve mevcut ekranları incele.
3. Mevcut kodla çakışabilecek alanları belirle.

---

# 2. STITCH'TEN TASARIMI ALMA VE FLUTTER'A AKTARMA

## 2.1. Kullanılacak Stitch projesi

Stitch projesi:

- Project Title: Nestora Smart Home App
- Project ID: `9851939946750442552`

Tasarım MCP üzerinden alınacaktır.

Kullanıcının Stitch üzerinde kullandığı export yöntemi:

1. Stitch projesinde Export seçildi.
2. MCP seçildi.
3. Copy Prompt seçildi.
4. Aşağıdaki Stitch Instructions metni oluşturuldu.

Antigravity bu talimatı ve ekran kimliklerini kullanarak Stitch MCP üzerinden ekranların kodlarını ve görsellerini almalıdır.

## 2.2. Stitch Instructions

Aşağıdaki talimatı eksiksiz kullan:

```text
Stitch Instructions

Get the images and code for the following Stitch project's screens:

Project
Title: Nestora Smart Home App
ID: 9851939946750442552

Screens:

1. Nestora - Açılış (Splash)
ID: 3cb79796a7f6432a9ec81e49b3449b92

2. Nestora - Odalarım
ID: 296327fe02f9486e8156d302300e98b3

3. Nestora - Cihazlarım
ID: 3862ad4a7d5449daa7ccf6af46b8ba8e

4. Nestora - Yatak Odası Klima Kontrolü
ID: 62f517aa76eb415f9334680fb7935085

5. Nestora - Salon Oda Detayı
ID: 7bb72ca21f1942be830641f3582ee5c6

6. Nestora - Oda Ekle ve Düzenle
ID: 856f73cf2db84079862ef4a120aade2b

7. Nestora - Salon Lambası Kontrolü
ID: 85ff88fc5ced424bbafba83f735d7878

8. Nestora - Cihaz Ekle ve Düzenle
ID: a20b14db5c214c67b761d8158e46e6ba

9. Nestora - Giriş Yap
ID: a846160c62724e38836a64522828285a

10. Nestora - Karşılama (Welcome)
ID: 9e4b3929f51f412c817920f01ec1b083

11. Nestora - Şifremi Unuttum
ID: 4740849e74dd43c98b9d950b2eeb6b13

12. Nestora - Ana Sayfa (Dashboard)
ID: 6d0597b77e4e44b6a3b5ab3da88f8873

13. Nestora - Profil ve Ayarlar
ID: cc081625c5d941f1aec88ead95eba045

14. Nestora - Bildirimler
ID: e671e9a03dc54cf098ddb1ddd6012922

15. Nestora - Kayıt Ol
ID: b281b163be5e419ca1953bcfcd658be4

16. Nestora - Bileşenler ve Durumlar
ID: e66e75a6c75b438d8daefffc55a25043

Use a utility like curl -L to download the hosted URLs.
```

## 2.3. Tasarım alma işlemi için zorunlu adımlar

Antigravity aşağıdaki sırayı takip etmelidir:

1. Stitch MCP aracılığıyla yukarıdaki 16 ekranın tamamına eriş.
2. Her ekranın tasarımını ayrı ayrı incele.
3. Ekranlara ait mevcut kodları ve görselleri al.
4. Görsel URL'lerini gerekiyorsa `curl -L` gibi uygun bir yöntemle indir.
5. İndirilen görselleri projedeki uygun asset klasörüne yerleştir.
6. Görsellerin hangi ekrana ve bileşene ait olduğunu belirle.
7. Ekranların tasarım özelliklerini incelemeden Flutter koduna geçme.
8. Tasarım ve bileşen eşleştirmesini tamamla.
9. Sonrasında Flutter widget'larını oluştur.

MCP'den gelen kod, doğrudan mevcut projeye kontrolsüz biçimde yapıştırılmamalıdır. Bu kod ve görseller tasarım referansıdır. Flutter/Dart karşılıkları mevcut proje mimarisi içerisinde uygulanmalıdır.

**Stitch'ten alınan tasarımın eksiksiz uygulanması ile mimari standartların korunması aynı anda zorunludur.**

## 2.4. Ekran tamamlama kontrolü

Her ekran için şu kontrol yapılmalıdır:

- Başlık ve açıklamalar eksiksiz mi?
- Bütün görseller mevcut mu?
- Kartlar ve kart içerikleri eksiksiz mi?
- Butonlar ve ikonlar doğru mu?
- Boşluklar ve hizalamalar korunmuş mu?
- Form alanları ve kontroller mevcut mu?
- Alt navigasyon doğru mu?
- Tasarımdaki görsel durumlar uygulanmış mı?
- Ekranın işlevsel etkileşimleri çalışıyor mu?

Bu kontroller tamamlanmadan ekran bitmiş kabul edilmemelidir.

---

# 3. MİMARİ SINIRLAR VE DOSYA YERLEŞİMİ

## 3.1. Ana mimari kararı

Nestora projesi:

**Feature-First + sadeleştirilmiş Clean Architecture**

yaklaşımını kullanır.

Feature-First, uygulamanın özelliklerine göre klasörlenmesini; Clean Architecture ise katmanların sorumluluklarını ve bağımlılık yönünü belirler.

Bu yaklaşım korunmalıdır.

Antigravity, Stitch tasarımını Flutter'a aktarırken kendi tercihine göre alternatif bir klasör düzeni oluşturmamalıdır.


## 3.2. Katmanların sorumlulukları

### Presentation

Kullanıcının gördüğü ve etkileşim kurduğu katmandır.

Şunları içerir:

- Pages
- Widgets
- Cubit
- States

Flutter widget'ları, sayfa düzenleri, animasyonlar, kartlar, butonlar ve görsel kontroller bu katmanda bulunur.

Presentation katmanı doğrudan Firebase SDK kullanmamalıdır.

### Domain

Uygulamanın iş kurallarını ve temel varlıklarını içerir.

Şunları içerebilir:

- Entities
- Repository contracts
- Gerektiğinde UseCases

Domain katmanı Flutter UI veya Firebase SDK'ya bağımlı olmamalıdır.

### Data

Verilerin alınması, saklanması ve dönüştürülmesinden sorumludur.

Şunları içerebilir:

- Models
- DataSources
- Repository implementations

Firebase Authentication, Firestore ve diğer veri kaynaklarıyla iletişim bu katmanda yönetilmelidir.

## 3.3. Tasarım kodlarının yerleşim kuralları

Tasarım bileşenleri rastgele klasörlerde toplanmamalıdır.

Örnek yerleşim:

```text
lib/
  app/
    app.dart
    router/
    theme/

  core/
    constants/
    errors/
    utils/
    widgets/

  features/
    auth/
      presentation/
        pages/
        widgets/
        cubit/
      domain/
      data/

    home/
      presentation/
        pages/
        widgets/
        cubit/

    devices/
      presentation/
        pages/
        widgets/
        cubit/
      domain/
      data/

    rooms/
      presentation/
        pages/
        widgets/
        cubit/
      domain/
      data/

    notifications/
      presentation/
        pages/
        widgets/
        cubit/
      domain/
      data/

    profile/
      presentation/
        pages/
        widgets/
        cubit/
      domain/
      data/

  main.dart
```


### UI yerleşim kuralları

- Login ve Register gibi ekranlar `auth/presentation/pages` altında bulunmalıdır.
- Auth ekranlarına özel input, şifre doğrulama bileşenleri ve butonlar `auth/presentation/widgets` altında bulunmalıdır.
- Ana sayfa bileşenleri `home/presentation/widgets` altında bulunmalıdır.
- Cihaz kartları, cihaz kontrol alanları ve cihaz detayları `devices/presentation` altında bulunmalıdır.
- Oda kartları ve oda detayları `rooms/presentation` altında bulunmalıdır.
- Bildirim kartları `notifications/presentation/widgets` altında bulunmalıdır.
- Profil ve ayarlar bileşenleri `profile/presentation` altında bulunmalıdır.
- Uygulama genelinde gerçekten tekrar kullanılacak tasarım bileşenleri `core/widgets` altında bulunabilir.
- Tema, renkler, typography ve ortak görsel tasarım tanımları `app/theme` altında yönetilmelidir.
- Ortak uygulama navigasyonu ve uygulama iskeleti `app` katmanında yönetilmelidir.

**Bir widget'ın birden fazla yerde kullanılması, otomatik olarak `core/widgets` altına taşınması gerektiği anlamına gelmez.** Öncelikle hangi feature'a ait olduğu değerlendirilmelidir.

## 3.4. Gereksiz dosya ve katman üretme

Aşağıdakiler yasaktır:

- Her widget için gereksiz bir klasör açmak.
- Aynı tasarım bileşenini farklı dosyalarda tekrar yazmak.
- Tek bir dosyaya yüzlerce veya binlerce satır kod doldurmak.
- Her işlem için otomatik olarak yeni bir UseCase oluşturmak.
- Her görsel için ayrı bir Manager veya Helper sınıfı oluşturmak.
- UI kodlarını Firebase servislerinin içine yerleştirmek.
- Firebase işlemlerini doğrudan widget içerisinde yapmak.
- Mevcut mimariyi yalnızca tasarımı kolaylaştırmak amacıyla değiştirmek.

Kodlar okunabilir, sorumlulukları belirgin ve gerektiğinde tekrar kullanılabilir olmalıdır.

---

# 4. LIGHT THEME VE DARK THEME

## 4.1. Tema stratejisi

Stitch üzerinde alınan mevcut tasarım Dark Theme olarak kabul edilecektir.

Stitch'ten alınan ekranların karanlık görünümü korunacak ve uygulamanın Dark Theme tasarım referansı olarak değerlendirilecektir.

Ancak uygulamanın varsayılan görünümü Light Theme olacaktır.

Uygulamada üç tema seçeneği bulunmalıdır:

- Açık
- Koyu
- Sistem

Varsayılan değer:

`ThemeMode.light`

Kullanıcı tema tercihini değiştirebilmelidir. Seçim uygulama yeniden açıldığında da korunmalıdır.

Tema yönetimi uygulama genelinde merkezi yapılmalıdır. Her ekran kendi içinde bağımsız tema rengi tanımlamamalıdır.

## 4.2. Light Theme renkleri

Light Theme için aşağıdaki renkler zorunludur.

| Kullanım        | Renk kodu | Açıklama             |
| --------------- | --------- | -------------------- |
| Ana arka plan   | `#FDF5E6` | Old Lace – Sıcak, yumuşak, klasik inci/fildişi beyazı (krem alt tonlu) |
| Kart arka planı | `#FFFFFF` | Saf beyaz yüzey (kontrast için) |
| İkincil yüzey   | `#F4EFE6` | Açık sıcak krem yüzey |
| Ana marka rengi | `#344638` | Doğal koyu orman yeşili |
| İkincil yeşil   | `#DCE5D7` | Açık sage yeşili     |
| Sıcak vurgu     | `#E9C9A8` | Yumuşak kehribar / altın ışıma |
| Ana metin       | `#292F29` | Koyu yeşilimsi metin |
| İkincil metin   | `#777D73` | Gri-yeşil metin      |
| Kenarlık        | `#E8ECE6` | Çok açık mineral sınır rengi |

### Çok önemli arka plan kuralı

Light Theme ekranlarının ana Scaffold arka planı:

`#FDF5E6` (Old Lace)

olmalıdır. Aşırı keskin, göz yoran saf beyaz yerine sıcak, yumuşak inci beyazı/krem tonu kullanılır. Kartlar ise `#FFFFFF` ile bu zemin üzerinde temiz bir derinlik kazanır.

## 4.3. Dark Theme

Dark Theme için mevcut Stitch tasarımı esas alınmalıdır:
- Scaffold: `#131713` (Koyu Çam)
- Kartlar: `#1C221D`
- Splash ekranı: `#131713` (Ortada parlayan logo ile)

## 4.4. Tema uygulama standartları

- Renkler merkezi theme tanımlarından alınmalıdır.
- Widget'ların içinde rastgele Hex renkler kullanılmamalıdır.
- Aynı renk farklı ekranlarda farklı tonlarda tanımlanmamalıdır.
- Durum renkleri de tema sistemine uygun olmalıdır.
- Light ve Dark Theme geçişleri yumuşak olmalıdır.
- Tema tercihi kalıcı saklanmalıdır.
- Varsayılan seçim açık tema olmalıdır.

---

# 5. TASARIM SİSTEMİ VE ORTAK BİLEŞENLER

## 5.1. Typography (Manrope Standardı)

Ana font modern, premium ve dengeli **Manrope** (`GoogleFonts.manrope`) olmalıdır.

Typography hiyerarşisi ve punto standartları:

| Kullanım | Boyut | Kalınlık | Açıklama |
| :--- | :---: | :---: | :--- |
| **Sayfa başlığı** | 24–28 px | 700 (Bold) | Ana ekran başlıkları (yalnızca gerekli yerlerde) |
| **Bölüm başlığı** | 18–20 px | 600 (SemiBold) | Liste ve kategori başlıkları |
| **Kart başlığı** | 15–16 px | 600 (SemiBold) | Cihaz ve oda kartı başlıkları |
| **Normal metin** | 14 px | 400 (Regular) | Standart gövde metinleri |
| **Açıklama** | 12–13 px | 400 (Regular) | Yardımcı metinler, durumlar |
| **Küçük etiket** | 11–12 px | 500 (Medium) | Rozetler, sensör birimleri |
| **Buton** | 14–15 px | 600 (SemiBold) | Eylem butonları |

> **Önemli:** Her ekranda 28–32 px başlık kullanılmamalıdır. Başlıklar ve değerler kontrollü tutulmalıdır.

## 5.2. Spacing

Uygulama genelinde tutarlı bir spacing sistemi kullanılmalıdır.

Önerilen temel aralıklar:

- 4 px: Çok küçük iç boşluk.
- 8 px: Yakın bileşenler.
- 12 px: Küçük bileşen aralığı.
- 16 px: Standart iç boşluk.
- 20 px: Kart ve bölüm boşluğu.
- 24 px: Bölümler arası boşluk.
- 32 px: Büyük görsel ayrımlar.

Bunlar başlangıç değerleridir. Stitch'teki gerçek yerleşim incelenerek uyarlanmalıdır.

## 5.3. Cards

Kartlar Nestora'nın temel tasarım bileşenlerindendir.

Kartların genel özellikleri:

- Yuvarlatılmış köşeler.
- Beyaz yüzey.
- Hafif ve kontrollü gölge.
- Gerektiğinde ince kenarlık.
- Dengeli iç boşluk.
- Net başlık ve içerik hiyerarşisi.

Her kartın aynı boyutta olması zorunlu değildir. Kart boyutları içerik ve ekran düzenine göre belirlenmelidir.

Kartların içinde gereksiz süsleme kullanılmamalıdır.

## 5.4. Buttons

Birincil butonlar:

- Ana marka rengi.
- Beyaz metin.
- Rahat dokunma alanı.
- Yuvarlatılmış köşeler.
- Belirgin ama ölçülü görsel ağırlık.

İkincil butonlar:

- Beyaz veya açık sage yüzey.
- Ana marka rengi metin ve ikon.

Destructive işlemler:

- Kontrollü kırmızı vurgu.
- Açık ve anlaşılır onay metni.

Butonların loading, disabled ve pressed durumları tasarlanmalıdır.

## 5.5. Inputs

Input alanları:

- Açık yüzey.
- İnce ve tutarlı kenarlık.
- Net label.
- Anlaşılır placeholder.
- Focus durumunda marka rengi.
- Error durumunda kontrollü hata rengi.
- Success durumunda tema ile uyumlu yeşil.

Input alanları gereğinden fazla yüksek veya küçük olmamalıdır.

## 5.6. Bottom Navigation

Uygulamanın ana navigasyonu üç bölümden oluşur:

1. Ana Sayfa
2. Cihazlar
3. Profil

Odalar ve Bildirimler ayrı bir bottom navigation öğesi değildir.

Bottom navigation:

- Sabit konumda olmalıdır.
- SafeArea ile uyumlu çalışmalıdır.
- Aktif öğe görsel olarak ayırt edilmelidir.
- İkon ve label birlikte kullanılmalıdır.
- Sayfa geçişlerinde tutarlı görünmelidir.
- İçerik ile çakışmamalıdır.

Mümkün olduğunda tek bir ortak uygulama navigasyonu kullanılmalıdır. Her sayfada farklı bir bottom bar oluşturulmamalıdır.

Auth ekranlarında bottom navigation gösterilmemelidir.

## 5.7. Dialog ve Bottom Sheet

Basit işlemler için kullanıcı gereksiz yere başka sayfaya gönderilmemelidir.

Uygun olduğunda:

- Hızlı cihaz kontrolü: Bottom Sheet.
- Cihaz ekle / oda ekle seçimi: Bottom Sheet.
- Filtre: Bottom Sheet.
- Silme onayı: Dialog.
- Başarılı işlem bildirimi: Snackbar.

Bu bileşenler ortak görsel standartlara sahip olmalıdır.

---

# 6. LOGO VE MARKA KİMLİĞİ

## 6.1. Mevcut logoyu kullanma

Mevcut Nestora logosu kullanıcı tarafından beğenilmemiştir.

Antigravity mevcut logoyu yalnızca farklı boyutlarda kullanarak devam etmemelidir.

Nestora'ya özel, yeni ve özgün bir logo tasarlanmalıdır.

## 6.2. Yeni logo tasarım yönü

Logo, uygulamanın akıllı ev ve konfor konseptini temsil etmelidir.

Beklenen özellikler:

- Ev formundan esinlenen özgün bir sembol.
- Işık veya aydınlatma fikrini temsil eden bir detay.
- Modern ve kolay hatırlanabilir şekil.
- Minimal ama karakter sahibi görünüm.
- Küçük boyutlarda da tanınabilirlik.
- Nestora'nın doğal yeşil marka kimliğiyle uyum.

Hazır bir ev ikonu tek başına logo olarak kullanılmamalıdır.

Logo, mevcut bir ikonun yanına Nestora yazılmasıyla geçiştirilmemelidir.

Özgün bir sembol tasarlanmalıdır.

## 6.3. Logo kullanım alanları

Yeni logo aşağıdaki alanlarda kullanılmalıdır:

- Splash.
- Welcome.
- Login.
- Register.
- Gerekli diğer marka alanları.

Logo değiştiğinde eski logo kullanılan bütün alanlar güncellenmelidir.

Logo farklı ekranlarda farklı şekillerde çizilmemelidir. Aynı asset veya ortak logo widget'ı kullanılmalıdır.

---

# 7. SPLASH VE ONBOARDING (AÇILIŞ DENEYİMİ)

## 7.1. Minimal Splash Ekranı
- **Arka Plan:** Koyu fildişi/koyu çam (`#131713`).
- **Görsel:** Ekranın tam ortasında büyük, öne çıkan Nestora logosu.
- **Efekt:** Logonun arkasında yumuşak parlayan kehribar halo/glow ışıması.
- **Süre:** Kısa ve net (~1.5–2.0 saniye). Ekranda hiçbir gereksiz slogan veya sürüm yazısı bulunmaz; saf logo deneyimi.
- **Geçiş:** Yumuşak bir fade animasyonu ile Onboarding ekranına akar.

## 7.2. Onboarding / Karşılama Ekranı ("Evinizi Kolayca Yönetin")
Splash sonrasında gelen, kullanıcının evini sahiplendiği karşılama ekranı:
- **Arka Plan:** `#FDF5E6` (Old Lace sıcak inci beyazı).
- **Ev Kartı:** Yuvarlatılmış modern mimari ev görseli ve etrafında organik sage/yeşil kontur.
- **Tipografi:** 
  - Kategori etiketi: `Evinizi Yönetin` (Koyu Orman Yeşili `#344638`, 12px SemiBold).
  - Başlık: `Evinizi Kolayca Yönetin` (Manrope 26px Bold, Koyu Yeşili `#344638`).
- **Gösterge:** Çoklu slayt/sayfa noktaları (Pagination dots).
- **İnteraktif Sağa Kaydırma Kilidi (Slide-to-Start):**
  - Altta yatay kapsül içinde sağa doğru kaydırılarak açılan interaktif slider düğmesi (`> Başla >>>`).
  - Hem mobil dokunmatik parmak kaydırmayı hem de masaüstü / Chrome fare sürükleme etkileşimini (`GestureDetector` + `PanUpdate`) destekler.
  - Sona kadar kaydırıldığında haptik geri bildirimle ana akışa (Dashboard / Welcome) geçiş yapar.

## 7.2. Splash ile ilgili kurallar

- "v.1.0" veya benzeri sürüm yazıları gösterilmemelidir.
- Gereksiz alt metin kullanılmamalıdır.
- Logo çok küçük olmamalıdır.
- Animasyonlar birbiriyle çakışmamalıdır.
- Splash sürekli tekrar etmemelidir.
- Oturum açmış kullanıcıda açılış sonrasında Auth durumuna göre uygun ana ekrana yönlendirme yapılmalıdır.

## 7.3. Teknik uygulama

Flutter'ın Animation API'si kullanılabilir:

- AnimationController
- Tween
- CurvedAnimation
- FadeTransition
- SlideTransition
- ScaleTransition

İhtiyaç duyulan glow efekti özel widget veya uygun CustomPainter ile hazırlanabilir.

Sırf bu animasyon için gereksiz bir animasyon paketi eklenmemelidir.

Reduced motion tercihine saygı gösterilmeli; hareket azaltıldığında animasyonların daha sade bir karşılığı kullanılmalıdır.

---

# 8. EV İLLÜSTRASYONLARI VE GÖRSEL DERİNLİK

Stitch'teki Welcome ve Dashboard ekranlarında ev görselleri bulunmaktadır.

Bu görsellerin Flutter uygulamasındaki karşılığı düz, kesilmiş veya yapıştırılmış bir görsel gibi durmamalıdır.

Ev görselleri daha gerçekçi, derinlikli ve özenli görünmelidir.

## 8.1. Görsel hedef

Ev illüstrasyonunda:

- Katmanlı görünüm.
- Doğal ışık.
- Hafif gölge.
- Mekânsal derinlik.
- Gerçek bir ev maketi hissi.
- Yumuşak ışık yansımaları.
- Kontrollü parlama.
- Dengeli perspektif.

kullanılmalıdır.

Görsel, ekranın geri kalanından kopuk bir sticker gibi durmamalıdır.

## 8.2. Animasyon önerileri

Ev görseli için ölçülü animasyonlar uygulanabilir:

- Çok hafif yukarı-aşağı süzülme.
- Alt bölümde ince bir ışık/parıltı efekti.
- Pencerelerdeki ışıkların yumuşak değişimi.
- Çok hafif gölge hareketi.
- Katmanların birbirinden küçük miktarda ayrışması.

Bu animasyonlar dekoratif amaçlıdır ve kullanıcıyı rahatsız etmemelidir.

Özellikle Dashboard'daki pencere ışıkları, sanal cihaz durumlarıyla bağlantılı olabilir.

Örneğin Salon Lambası açıkken salon penceresindeki ışık yanabilir. Cihaz kapatıldığında ışık azalabilir veya kapanabilir.

Bu ilişki gerçek bir fiziksel ev durumu değil, uygulama içindeki sanal cihaz durumunun görsel temsilidir.

## 8.3. Görsel üretim yaklaşımı

Önce mevcut Stitch asset'leri incelenmelidir.

Mevcut görsel yeterliyse gereksiz yere yeniden oluşturulmamalıdır.

Yetersizse:

- Flutter widget katmanları.
- CustomPainter.
- Uygun görsel asset'leri.
- Hafif animasyonlar.

birlikte kullanılabilir.

Aşırı karmaşık 3D efektler veya performansı düşüren sürekli animasyonlar oluşturulmamalıdır.

---

# 9. CİHAZ KONTROL ANİMASYONLARI

Cihaz kontrol ekranları Nestora'nın en önemli etkileşim alanlarından biridir.

Kullanıcının yaptığı değişiklikler yalnızca sayısal değer olarak kalmamalı, ekrandaki cihaz görseline de yansımalıdır.

## 9.1. Salon Lambası

Salon Lambası kontrol ekranında parlaklık slider'ı kullanılır.

Başlangıç parlaklığı:

%72

Kullanıcı slider'ı hareket ettirdiğinde:

- Sayısal parlaklık değeri anlık güncellenmelidir.
- Lamba illüstrasyonunun parlaklığı aynı anda değişmelidir.
- Parlaklık arttıkça ışık daha güçlü görünmelidir.
- Parlaklık azaldıkça ışık daha zayıf görünmelidir.
- Glow/halo yoğunluğu parlaklıkla birlikte değişmelidir.
- Değişim sert değil, yumuşak olmalıdır.

Örnek:

%100 → Güçlü fakat kontrollü ışık.

%72 → Orta-yüksek ışık.

%35 → Daha düşük ışık.

%0 → Işık etkisi minimum veya kapalı.

Bu yalnızca slider değerini değiştiren bir UI işlemi olmamalıdır. Görsel de aynı state'e bağlı olmalıdır.

### Renk seçimi

Kullanıcı renk swatch'larından birini seçtiğinde:

- Lamba ışığının rengi değişmelidir.
- Glow efekti seçilen renge göre güncellenmelidir.
- Seçilen renk görsel olarak belirginleşmelidir.

### Açma / kapama

Lamba kapatıldığında:

- Glow efekti kaybolmalıdır.
- Lamba daha mat görünmelidir.
- Durum etiketi "Kapalı" olmalıdır.

Tekrar açıldığında mevcut parlaklık ve renk ayarları korunmalıdır.

## 9.2. Klima

Klima ekranında:

- Açık/kapalı durumu.
- Hedef sıcaklık.
- Soğutma/ısıtma/otomatik modu.

bulunmalıdır.

Hedef sıcaklık değiştiğinde sayı animasyonla güncellenebilir.

Kontrol alanındaki görsel vurgu, seçilen moda göre değişebilir.

Ancak gerçek oda sıcaklığı veya sensör ölçümü gösterilmemelidir.

## 9.3. Fan

Fan hız kontrolü değiştirildiğinde görsel fan hızı da değişmelidir.

Fan kapatıldığında hareket durmalıdır.

Bu hareket görsel animasyon olarak uygulanmalıdır; gerçek donanım bağlantısı değildir.

## 9.4. Animasyon standartları

Önerilen süreler:

| Etkileşim                    | Süre              |
| ---------------------------- | ----------------- |
| Toggle                       | 200–300 ms        |
| Kart state değişimi          | 200–300 ms        |
| Slider görsel geri bildirimi | 100–200 ms        |
| Sayı değişimi                | 150–250 ms        |
| Sayfa geçişi                 | 250–350 ms        |
| Bottom Sheet                 | 250–350 ms        |
| Snackbar                     | Kısa ve kontrollü |

Süreler gerektiğinde tasarıma göre uyarlanabilir.

Amaç her hareketi animasyonlu yapmak değil, önemli etkileşimlere doğal geri bildirim vermektir.

---

# 10. KAYIT EKRANI VE ŞİFRE DOĞRULAMA

Kayıt ekranındaki şifre doğrulama alanı özel bir etkileşim olarak uygulanmalıdır.

Bu özellik yalnızca Register ekranında gösterilmelidir.

## 10.1. Şifre koşulları

Kullanıcıdan şu koşullar istenmelidir:

1. En az 8 karakter.
2. En az bir büyük harf.
3. En az bir rakam.
4. En az bir özel karakter.

Şifre yazılmaya başlandığında bu koşullar anlık kontrol edilmelidir.

## 10.2. Validation tasarımı

Şifre alanının hemen altında küçük bir doğrulama listesi bulunmalıdır.

Örnek:

- En az 8 karakter
- Bir büyük harf
- Bir rakam
- Bir özel karakter

Başlangıçta henüz karşılanmayan koşullar muted kırmızı tonuyla gösterilebilir.

Koşul sağlandığında:

- Yazı yumuşak biçimde yeşile dönüşmelidir.
- Yanında bir onay işareti görünmelidir.
- Değişim pat diye olmamalıdır.
- Renk ve ikon geçişleri yaklaşık 200–350 ms sürmelidir.

Kullanılan renkler Nestora'nın görsel sistemiyle uyumlu olmalıdır.

Neon yeşil veya parlak kırmızı kullanılmamalıdır.

## 10.3. Güçlü şifre durumu

Dört koşul da karşılandığında:

- Bütün doğrulama maddeleri yeşil olmalıdır.
- Bütün maddelerin yanında onay işareti bulunmalıdır.
- "Güçlü şifre" mesajı görünmelidir.
- Şifre input alanının border rengi başarı durumuna geçmelidir.
- Input arka planı çok hafif sage tonuna dönüşebilir.

Başarı durumu, kullanıcı tarafından kolayca fark edilmelidir.

## 10.4. Şifre eşleşmesi

Şifre tekrar alanı da kontrol edilmelidir.

Şifreler eşleşmiyorsa anlaşılır bir hata gösterilmelidir.

Eşleştiğinde başarı durumu gösterilmelidir.

Doğrulama metinleri küçük ve sade olmalıdır. Formun genel düzenini bozmamalıdır.

---

# 11. AUTHENTICATION VE GERÇEK UYGULAMA DAVRANIŞLARI

## 11.1. Şifremi Unuttum

Şifre sıfırlama ekranı yalnızca görsel olarak tasarlanmış olmamalıdır.

Gerçek Firebase Authentication işlemi çalışmalıdır.

Flutter tarafında Firebase Authentication'ın:

`sendPasswordResetEmail()`

işlemi kullanılmalıdır.

Kullanıcı e-posta adresini girip butona bastığında:

1. E-posta formatı kontrol edilmelidir.
2. Firebase Authentication üzerinden sıfırlama e-postası istenmelidir.
3. İşlem devam ederken loading durumu gösterilmelidir.
4. Başarılı durumda kullanıcıya anlaşılır başarı mesajı verilmelidir.
5. Hatalar kullanıcı dostu Türkçe mesajlara dönüştürülmelidir.
6. Gereksiz tekrar istekleri engellenmelidir.

Firebase Authentication e-posta dili Türkçe olarak ayarlanmalıdır.

Kullanıcıya başka birinin hesabının var olup olmadığını açığa çıkaran mesajlar gösterilmemelidir.

### **Firebase** Spark planı

Proje Spark planında kalacaktır.

Resmî Firebase limitlerine göre Spark planında şifre sıfırlama e-postaları için günlük 150 e-posta sınırı bulunmaktadır.

Bu sınır göz önünde bulundurulmalıdır.

Cloud Functions veya harici e-posta servisi sırf bu işlem için eklenmemelidir.

## 11.2. Kullanılacak profil e-postası

Kullanıcının profilinde gösterilecek e-posta:

`aygenyildirim27@gmail.com`

Bu e-posta tasarım referansında da kullanılmalıdır.

Ancak gerçek uygulamada profil e-postası sabit bir UI metni olarak kodlanmamalıdır. Firebase Authentication'daki oturum açmış kullanıcının e-posta bilgisinden alınmalıdır.

Kayıt olan diğer kullanıcıların kendi e-posta adresleri gösterilmelidir.

## 11.3. Kayıt sonrası otomatik giriş

Yeni kullanıcı kayıt işlemini tamamladığında tekrar Login ekranına gönderilmemelidir.

Firebase Authentication'ın başarılı hesap oluşturma işlemi sonrasında kullanıcı oturumu açık kalmalıdır.

Akış:

1. Kullanıcı kayıt formunu doldurur.
2. Validation kontrolleri yapılır.
3. Firebase Authentication hesabı oluşturur.
4. Kullanıcının temel profil bilgileri hazırlanır.
5. Gerekli kullanıcı dokümanı oluşturulur.
6. Kullanıcı doğrudan Ana Sayfa ekranına yönlendirilir.

Auth state merkezi olarak takip edilmelidir.

Kullanıcı uygulamayı yeniden açtığında mevcut oturum kontrol edilmelidir.

## 11.4. Profil fotoğrafı

Kullanıcı profil ekranından kendi fotoğrafını seçebilmelidir.

Sadece fotoğraf seçilmesine izin verilmelidir.

Dosya seçimi ve profil görseli kontrolü:

- Yalnızca desteklenen fotoğraf formatları kabul edilmelidir.
- Kamera veya video gibi gereksiz seçenekler eklenmemelidir.
- Fotoğraf seçimi için uygun image picker kullanılabilir.
- Seçilen fotoğraf gerektiğinde kırpılabilmelidir.
- Fotoğraf boyutu makul seviyeye düşürülmelidir.
- Profil avatarı bütün ilgili ekranlarda güncellenmelidir.

### Kalıcı saklama ve Spark planı

Cloud Storage for Firebase, güncel Firebase gereksinimleri nedeniyle Spark planında kullanılamamaktadır.

Bu nedenle Blaze planına geçmeden profil fotoğrafı için şu yöntem kullanılmalıdır:

- Fotoğraf uygulamanın kalıcı yerel dosya alanına kaydedilmelidir.
- Dosya yolu yerel tercih saklama alanında tutulmalıdır.
- Uygulama yeniden başlatıldığında kayıtlı fotoğraf yüklenmelidir.
- Fotoğraf değiştirildiğinde eski dosya gerektiğinde temizlenmelidir.
- Fotoğraf seçilmemişse varsayılan avatar kullanılmalıdır.

Fotoğraf verisi Base64 olarak Firestore dokümanına yazılmamalıdır.

Bu yöntem aynı cihazda uygulama açılışları arasında kalıcılık sağlar. Uygulama silinirse veya başka bir cihaza geçilirse fotoğrafın otomatik senkronize olacağı iddia edilmemelidir.

İleride bulut senkronizasyonu istenirse ayrıca değerlendirilmelidir. Şu anki kapsamda Spark planı korunacaktır.

---

# 12. PROFİL VE AYARLAR

Profil ekranı aşağıdaki özellikleri içermelidir:

- Profil fotoğrafı.
- Kullanıcı adı.
- E-posta adresi.
- Profil düzenleme.
- Tema seçimi.
- Bildirim tercihleri.
- Hakkında.
- Uygulama sürümü.
- Çıkış yap.

Profil fotoğrafı değiştirildiğinde uygulama içindeki ilgili avatarlar da güncellenmelidir.

Tema seçimi:

- Açık
- Koyu
- Sistem

Varsayılan: Açık.

Tema tercihi uygulama yeniden açıldığında korunmalıdır.

---

# 13. BİLDİRİMLER VE GÖRSEL DURUMLAR

Bildirimler uygulama içinde gerçekleştirilen sanal işlemleri temsil etmelidir.

Örnekler:

- Salon Lambası açıldı.
- Masa Lambası parlaklığı %85 olarak değiştirildi.
- Yeni cihaz eklendi.
- Yeni oda oluşturuldu.

Gerçek cihaz bağlantısı olmadığı için fiziksel cihaz bağlantı hatası veya sensör alarmı gösterilmemelidir.

Bildirim listesinde:

- Okunmamış durum.
- Okunmuş durum.
- Bildirim zamanı.
- Tümünü okundu işaretleme.
- Boş liste durumu.

bulunmalıdır.

Empty, loading ve error state'leri de Stitch'teki bileşen referanslarıyla uyumlu uygulanmalıdır.

---

# 14. ORTAK ANİMASYON VE ETKİLEŞİM STANDARTLARI

Nestora'nın animasyonları zarif, doğal ve kontrollü olmalıdır.

Öncelikle Flutter'ın kendi animasyon araçları kullanılmalıdır.

Kullanılabilecek araçlar:

- AnimatedContainer
- AnimatedOpacity
- AnimatedSwitcher
- AnimatedSize
- TweenAnimationBuilder
- AnimationController
- SlideTransition
- FadeTransition
- ScaleTransition

Gerektiğinde `flutter_animate` kullanılabilir.

Ancak yalnızca animasyon yapmak için gereksiz paket eklenmemelidir.

### Uygulanması gereken etkileşimler

| Bileşen            | Beklenen davranış                    |
| ------------------ | ------------------------------------ |
| Cihaz toggle       | Açık/kapalı görsel geçişi            |
| Favori ikonu       | Seçili/seçili değil durumu           |
| Parlaklık slider'ı | Lamba ışığıyla senkron değişim       |
| Renk seçimi        | Lamba glow renginin değişmesi        |
| Klima sıcaklığı    | Sayısal ve görsel güncelleme         |
| Fan hızı           | Fan animasyon hızının değişmesi      |
| Kartlar            | Kontrollü dokunma geri bildirimi     |
| Bottom Sheet       | Yumuşak açılma/kapanma               |
| Dialog             | Kontrollü görünme/kapanma            |
| Snackbar           | Kısa başarı/hata geri bildirimi      |
| Splash             | Özel marka animasyonu                |
| Ev illüstrasyonu   | Hafif derinlik ve ışık animasyonları |

Animasyonlar gereksiz yere sürekli çalışmamalıdır.

Kullanıcı etkileşimiyle ilişkili olmalıdır.

Performansı düşüren karmaşık animasyonlardan kaçınılmalıdır.

---

# 15. GERÇEK VERİ VE UI STATE İLİŞKİSİ

Tasarım bileşenleri gerçek uygulama state'lerinden beslenmelidir.

Örneğin:

Salon Lambası'nın parlaklık değeri yalnızca widget içerisinde sabit bir sayı olarak tutulmamalıdır.

İlgili cihaz state'i üzerinden yönetilmelidir.

Akış:

UI → Cubit → Repository → DataSource → Firestore

Veri değiştiğinde:

- İlgili state güncellenmeli.
- UI yeniden oluşturulmalı.
- Animasyonlar yeni state'i yansıtmalı.
- Verinin kalıcılığı sağlanmalıdır.

Özellikle cihaz detay ekranında slider, lamba illüstrasyonu ve parlaklık değeri aynı state'i kullanmalıdır.

Aynı değer farklı widget'larda birbirinden bağımsız şekilde tutulmamalıdır.

UI katmanında Firestore sorgusu yapılmamalıdır.

---

# 16. RESPONSIVE TASARIM VE ERİŞİLEBİLİRLİK

Uygulama farklı telefon boyutlarında kullanılabilir olmalıdır.

- Sabit ekran boyutlarına bağımlı tasarım yapılmamalıdır.
- Gerekli yerlerde scroll kullanılmalıdır.
- Klavye açıldığında formlar kullanılabilir kalmalıdır.
- SafeArea doğru uygulanmalıdır.
- Küçük ekranlarda kartlar taşmamalıdır.
- Uzun kullanıcı adları ve metinler düzeni bozmamalıdır.
- Dokunma alanları yeterli olmalıdır.
- Metin kontrastı korunmalıdır.
- Animasyon azaltma tercihi dikkate alınmalıdır.

Stitch'teki referans ekran ölçüleri temel alınmalı, farklı ekranlarda orantılı şekilde uyarlanmalıdır.

---

# 17. ZORUNLU TEKNİK SINIRLAR

1. Flutter/Dart dışında farklı bir UI teknolojisine geçilmemelidir.
2. Mevcut GoRouter mimarisi korunmalıdır.
3. Mevcut Cubit yapısı korunmalıdır.
4. Firebase işlemleri Data katmanında yönetilmelidir.
5. UI widget'ları Firebase SDK'ya doğrudan bağlanmamalıdır.
6. Renkler merkezi tema sisteminden alınmalıdır.
7. Light Theme varsayılan olmalıdır.
8. Dark Theme Stitch tasarımından türetilmelidir.
9. Yeni logo ortak bir asset/widget üzerinden kullanılmalıdır.
10. Tasarım bileşenleri ilgili feature altında tutulmalıdır.
11. Ortak widget'lar yalnızca gerçekten tekrar kullanıldıklarında core altına alınmalıdır.
12. Gereksiz dosya, paket ve mimari katman oluşturulmamalıdır.
13. Mock veya placeholder veri, gerçek veri kaynağı yerine kullanılmamalıdır.
14. Fiziksel IoT bağlantısı veya gerçek sensör verisi eklenmemelidir.
15. Firebase Spark planını aşan servisler izinsiz eklenmemelidir.

---

# 18. UYGULAMA SIRASI VE KABUL KRİTERLERİ

Antigravity aşağıdaki sırayla ilerlemelidir.

### Aşama 1 — İnceleme

- Stitch MCP üzerinden 16 ekranın tamamını al.
- Bütün görsel asset'leri incele.
- Ekran ve bileşen listesini çıkar.

### Aşama 2 — Tasarım altyapısı

- Light Theme oluştur.
- Dark Theme oluştur.
- Tema yönetimini merkezi hale getir.
- Typography ve spacing sistemini oluştur.
- Ortak tasarım bileşenlerini belirle.
- Yeni Nestora logosunu tasarla.

### Aşama 3 — Splash ve Auth

- Splash animasyonu.
- Welcome.
- Login.
- Register.
- Forgot Password.
- Şifre validation.

### Aşama 4 — Ana uygulama

- Dashboard.
- Cihazlar.
- Cihaz detayları.
- Odalar.
- Oda detayları.
- Ekleme ve düzenleme ekranları.

### Aşama 5 — Diğer ekranlar

- Bildirimler.
- Profil.
- Ayarlar.
- Bottom Sheet.
- Dialog.
- Snackbar.
- Empty, loading ve error durumları.

### Aşama 6 — Görsel ve işlevsel kontrol

Her ekran Stitch referansıyla karşılaştırılmalıdır.

Eksik öğeler tamamlanmalıdır.

Light ve Dark Theme ayrı ayrı test edilmelidir.

Splash animasyonu kontrol edilmelidir.

Slider ve cihaz görsellerinin senkron çalıştığı doğrulanmalıdır.

Flutter analyze çalıştırılmalı.

---

# 19. TAMAMLANMA KRİTERLERİ

Nestora tasarım aktarımı ancak aşağıdaki koşulların tamamı sağlandığında bitmiş kabul edilir:

- [ ] Stitch'teki 16 ekranın tamamı Flutter/Dart ile oluşturuldu.
- [ ] Ekranların hiçbirinde tasarım öğesi atlanmadı.
- [ ] Stitch görselleri doğru şekilde kullanıldı.
- [ ] Yeni Nestora logosu tasarlandı ve eski logo kullanımları güncellendi.
- [ ] Splash animasyonu tamamlandı.
- [ ] Light Theme oluşturuldu.
- [ ] Dark Theme oluşturuldu.
- [ ] Varsayılan tema Light Theme olarak ayarlandı.
- [ ] Light Theme ana arka planı tam olarak `#FFFFFF`.
- [ ] Tema seçimi kalıcı hale getirildi.
- [ ] Bütün ekranlar mevcut mimariye uygun yerleştirildi.
- [ ] Ortak kart, buton ve navigasyon bileşenleri tutarlı.
- [ ] Lamba parlaklığı görsel parlaklıkla senkron çalışıyor.
- [ ] Klima ve fan kontrolleri state ile bağlantılı.
- [ ] Kayıt ekranında anlık şifre validation çalışıyor.
- [ ] Kayıt sonrasında kullanıcı doğrudan Ana Sayfa'ya yönlendiriliyor.
- [ ] Şifre sıfırlama e-postası Firebase Authentication üzerinden gönderiliyor.
      !! Senden firebase, authentication, router vs. bunlarla ilgili bir şey yapmanı istemiyorum. Şu anda sadece tasarım ile ilgileniyoruz. Önden bilgin olsun, akışı anla diye bu bilgi verdim. Tasarımı buna göre ayarlarsın diye.
- [ ] Profil fotoğrafı yerel olarak kalıcı saklanıyor.  - Bunun olması gerektiğini bil. Şu anda kalıcı saklama için bi şey      yapmaana gerek yok. Tasarımla ilgileniyoruz. 
- [ ] Empty, loading ve error durumları uygulanıyor.
- [ ] Flutter analyze hatasız.
- [ ] Tasarım ve işlev testleri tamamlandı.

**Son kural:**

Stitch'teki tasarımın Flutter karşılığı eksiksiz oluşturulmadan, yalnızca temel sayfaların açılması veya birkaç kartın görünmesi tamamlanmış bir uygulama olarak kabul edilmemelidir.

Öncelik sırası:

1. Tasarımın eksiksiz aktarılması.
2. Mimari kuralların korunması.
3. Bütün etkileşimlerin çalışır olması.
4. Light ve Dark Theme tutarlılığı.
5. Animasyon ve performans kalitesi.

Nestora'nın amacı yalnızca çalışan bir uygulama değil, tasarımı özenle uygulanmış, mimarisi düzenli ve kullanıcı deneyimi güçlü bir Flutter uygulaması ortaya çıkarmaktır.
