# NESTORA — Modern & Sürdürülebilir Akıllı Ev Platformu

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%2B%20BLoC-green)](https://bloclibrary.dev)
[![Tests](https://img.shields.io/badge/Tests-428%20Passed%20(100%25)-success)](test/)
[![Analysis](https://img.shields.io/badge/Analysis-0%20Issues-brightgreen)](#)
[![Design](https://img.shields.io/badge/Design%20Palette-Senaryo%20B%20(Modern%20Kaşmir)-EAE6DF)](#tasarım-sistemi)

**NESTORA**, kullanıcıların yaşam alanlarını enerji tasarrufu, konfor ve estetikle tek merkezden yönetebilmesi için tasarlanmış yüksek performanslı, modern bir akıllı ev mobil uygulamasıdır.

---

## 🌟 Öne Çıkan Özellikler

### 1. Hızlı Eylemler & Akıllı Ev Senaryoları
- **Evdeyim:** Yaşam alanları lambaları konfor seviyesine (%80), klima 22°C otomatik moda ve temel prizler aktif konuma geçer.
- **Gündüz:** Gün ışığından azami faydalanmak için lambalar kapatılır (0 Watt), klima 24°C eko moduna alınır.
- **Gece Modu:** Ana lambalar ve cihazlar kapatılır; yatak odası gece lambası loş sıcak amber tona (2200K, %15) çekilir, klima 21°C sessiz moda geçer.
- **Dışarıda:** Tüm lambalar, prizler ve televizyon kapatılır; klima 18°C bekleme moduna geçer (0 cihaz aktif, maksimum tasarruf).
- **Hero Canlı Senaryo Rozeti:** Dashboard üst alanında anlık senaryo ikonu, rengi, aktif cihaz sayısı ve açıklayıcı bilgi kartı.

### 2. İnteraktif Cihaz Kontrol Ekranları
- **Televizyon (`TvControlPage`):** Gerçekçi TV ekran figürü, güç anahtarı, ses seviyesi göstergesi/sliderı, favori kanal seçimi ve HDMI/Giriş yönetimi.
- **Akıllı Priz (`PlugControlPage`):** Hardware priz figürü, 16A röle anahtarı, anlık güç tüketimi (Watt), çocuk kilidi ve geri sayım zamanlayıcısı.
- **Kahve Makinesi (`CoffeeMachineControlPage`):** İnteraktif makine figürü, fincan boyutu seçimi (Tek/Çift Espresso, Americano, Latte), sertlik ayarı ve buhar animasyonu eşliğinde demleme fonksiyonu.
- **Salon Lambası (`LampControlPage`):** Parlaklık seviyesine göre fiziksel olarak aydınlanıp kararan dinamik ambient ortam ışığı; Sıcak Günışığı, Doğal Beyaz, Sıcak Sarı, Yumuşak Yeşil ve Gece Mavisi atmosfer renk modları.
- **Klima (`AcControlPage`):** Hassas 0.5°C sıcaklık ayar çarkı, fan hızı ve eko/uyku/otomatik çalışma modları.

### 3. Oda & Mekan Yönetimi
- **Modern Mimari Görseller:** Salon, Mutfak, Yatak Odası, Çalışma Odası ve Banyo için yüksek kaliteli gerçek mimari oda görselleri.
- **Güvenli Resim Seçici (`SecureImageService`):** Yalnızca JPG/PNG formatı, dosya boyutu doğrulaması ve yerel depolama ile kalıcı saklama.
- **Hızlı Oda Ekleme:** Dashboard üzerinde yer alan `+ Oda Ekle` butonu ile yeni oda tanımlama ve şeffaf modern placeholder üzerinden oda fotoğrafı atama.

### 4. Tasarım Sistemi — Senaryo B ("Modern Kaşmir & Doğal Taş")
- **Aydınlık Mod:** Doğal taş beji zemin (`#F5F3EF`), saf beyaz kartlar (`#FFFFFF`), kaşmir ikincil yüzeyler (`#EAE6DF`) ve derin orman yeşili butonlar (`#1E3023`).
- **Karanlık Mod:** Ferah grafit/antrasit zemin (`#121614`), saf beyaz yüksek kontrastlı tipografi (`#F5F5F7`), derin kart yüzeyleri (`#1A201C`).
- **Mikro Etkileşimler:** Kompakt yüzen `GlowingToast` bilgilendirme kartları (önce aydınlık parlayıp sonra yumuşakça sönen animasyon) ve yanıp sönen `PulsingGlowDot` canlı izleme rozetleri.

### 5. Profil, Tercihler & Güvenlik
- **Sıcaklık Birimi Senkronizasyonu:** Profil üzerinden seçilen °C veya °F birimi, tüm anasayfa kartlarında, oda detaylarında ve klima kontrollerinde anlık olarak evrensel formata dönüştürülür.
- **Haftalık Özet Raporu Bildirimi:** Profil ayarlarında haftalık rapor anahtarı açıldığında sisteme anında eko-enerji tasarruf bildirimi düşer ve unread rozeti artar.
- **Güvenlik Mimarisi:** Hardcoded API anahtarı içermeyen sıfır sızıntı altyapısı, derleme anında `--dart-define` desteği ve `.env.example` şablonu.

---

## 🏗️ Mimari & Teknoloji Yığını

```
lib/
├── app/                  # Uygulama başlatıcı, Shell, GoRouter ve DI enjeksiyonu
│   ├── router/           # GoRouter deklaratif rotalar ve korumalı yönlendirmeler
│   ├── theme/            # Senaryo B renkleri, Manrope tipografi ve açık/koyu tema
│   └── di/               # GetIt servis bulucu (Service Locator)
├── core/                 # Çekirdek yardımcılar, servisler, sabitler ve ortak widget'lar
│   ├── services/         # LocalCacheService, SecureImageService, vb.
│   ├── utils/            # TemperatureFormatter, Result monad
│   └── widgets/          # GlowingToast, PulsingGlowDot, NestoraButton, vb.
└── features/             # Özellik modülleri (Clean Architecture)
    ├── auth/             # Kimlik doğrulama, Splash (4.0s), Onboarding, Login/Register
    ├── home/             # Dashboard, Hero senaryo rozetleri, enerji izleme
    ├── rooms/            # Odalarım, Oda Detayı, Oda Ekle/Düzenle
    ├── devices/          # Cihazlar, Arama/Filtreleme, TV/Priz/Kahve/Lamba/Klima kontrolleri
    ├── notifications/    # Bildirimler listesi, tarih gruplaması, eko bildirimler
    └── profile/          # Profil düzenleme, fotoğraf seçici, tema ve Hakkında modalı
```

---

## 🚀 Başlangıç & Kurulum

### Gereksinimler
- Flutter SDK `>=3.3.0`
- Dart SDK `>=3.0.0`

### 1. Depoyu Klonlayın
```bash
git clone https://github.com/Aygen5/NESTORA.git
cd NESTORA
```

### 2. Bağımlılıkları Yükleyin
```bash
flutter pub get
```

### 3. Uygulamayı Çalıştırın (Demo / Offline Mod)
NESTORA varsayılan olarak demo modunda hazır sanal cihazlar ve odalarla anında çalışır:
```bash
flutter run
```

### 4. Canlı Firebase Ortamı ile Çalıştırma (Opsiyonel)
Canlı Firebase ortamında çalıştırmak için çevre değişkenlerini derleme parametresi olarak sağlayabilirsiniz:
```bash
flutter run \
  --dart-define=FIREBASE_WEB_API_KEY=your_web_key \
  --dart-define=FIREBASE_ANDROID_API_KEY=your_android_key \
  --dart-define=FIREBASE_IOS_API_KEY=your_ios_key
```

---

## 🧪 Testler & Kalite Güvencesi

Proje **428 adet otomatikleştirilmiş test** ile %100 kapsanmaktadır:

```bash
# Tüm test paketini çalıştırma
flutter test

# Statik analiz kontrolü (0 issues)
flutter analyze
```

---

## 📄 Lisans
Bu proje özel mülkiyet olup Nestora Smart Living bünyesinde geliştirilmiştir.
