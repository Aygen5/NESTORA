# Nestora — Uygulama Geliştirme Yol Haritası (Master Plan)

Bu belge; `project.md`, `skills.md`, `architecture.md` ve `design-system.md` belgelerinde tanımlanan tüm gereksinimleri, mimari standartları ve ürün hedeflerini adım adım hayata geçirecek **ana geliştirme planıdır**.

Proje, mevcut 16 arayüz ekranının görsel tasarımını, animasyonlarını ve kullanıcı deneyimini bozmadan; aşamalı, test odaklı ve kontrollü bir sırayla geliştirilecektir.

---

## Faz 1: Temel Altyapı, Bağımlılıklar ve Mimari İskelet

> **Amaç:** Projenin ihtiyaç duyduğu resmi kütüphaneleri `pubspec.yaml`'a eklemek, çekirdek hata ve sonuç mekanizmalarını kurmak, Firebase ve bağımlılık enjeksiyon altyapısını hazırlamak.

### Adım 1.1: [x] Bağımlılıkların (`pubspec.yaml`) Yapılandırılması
- `firebase_core`, `firebase_auth`, `cloud_firestore` paketlerinin eklenmesi.
- `firebase_analytics`, `firebase_crashlytics`, `firebase_performance`, `firebase_remote_config` paketlerinin eklenmesi.
- `go_router` (rotalama ve korumalı yönlendirmeler için) eklenmesi.
- `image_picker` (yalnızca yerel profil fotoğrafı seçimi için) eklenmesi.
- `path_provider` (profil fotoğrafını cihazın kalıcı yerel uygulama alanında saklamak için) eklenmesi.
- `flutter_bloc`, `shared_preferences`, `google_fonts`, `intl`, `cupertino_icons` sürümlerinin uyumluluk denetimi.
- `flutter pub get` ve statik analiz doğrulaması.

### Adım 1.2: [x] Core Katmanı — Hata, Başarı ve Temel Tipler
- `lib/core/errors/failures.dart`: `Failure`, `AuthFailure`, `ServerFailure`, `CacheFailure`, `ValidationFailure` sınıflarının oluşturulması.
- `lib/core/errors/exceptions.dart`: Veri katmanında fırlatılacak özel exception sınıfları.
- `lib/core/utils/result.dart`: `Result<T>` veya temiz başarı/hata dönüş tipi (gereksiz ağır functional programming paketleri olmadan).
- `lib/core/constants/app_constants.dart`: Uygulama genel sabitleri, varsayılan değerler ve doğrulama regex'leri.
> *Not:* Bu adım tamamen yerel Dart kodudur, harici Firebase bağlantısı gerektirmez.

> [!IMPORTANT]
> **Manuel Olarak Yapılması Gereken (Firebase Console Başlangıcı):**
> Adım 1.2 tamamlandıktan hemen sonra ve Adım 1.3'e başlamadan önce:
> - **Neden Burada Gerekli?** Adım 1.3'te `lib/firebase_options.dart` dosyasının oluşturulması ve `main.dart` içinde `Firebase.initializeApp()` kodunun çalışabilmesi için Firebase üzerinde gerçek bir projenin var olması ve projenin Flutter uygulamasıyla eşleştirilmesi (Firebase CLI / FlutterFire) gerekir.
> - **Bu Noktada Console'da Yapılacaklar:**
>   1. Firebase Console'da yeni proje açmak (ücretsiz **Spark** planı).
>   2. Flutter uygulamasını bu projeye bağlamak (`google-services.json` / `GoogleService-Info.plist` / `firebase_options.dart`).

### Adım 1.3: [x] Firebase Başlangıç Yapılandırması
- `lib/firebase_options.dart` yapılandırmasının oluşturulması/entegrasyonu.
- `lib/main.dart` dosyasının yalnızca Flutter binding, Firebase initialization, yerel SharedPreferences başlatma ve Root App çağrısına odaklanacak şekilde sadeleştirilmesi (iş mantığından ve sayfa kodlarından arındırılması).

### Adım 1.4: [x] Bağımlılık Enjeksiyonu (Dependency Injection / Service Locator)
- `lib/app/di/injection.dart`: FirebaseAuth, FirebaseFirestore, SharedPreferences, Data Source'lar ve Repository'lerin merkezi, temiz ve yalın kaydı.
- Gereksiz karmaşık reflection ve kod üretiminden kaçınılması; doğrudan, tip güvenli kayıt mekanizması.

---

## Faz 2: Navigasyon Mimarisi (GoRouter) ve Uygulama Kabuğu

> **Amaç:** Sayfa geçişlerini GoRouter ile merkezi, tip güvenli, URL uyumlu ve oturum durumuna duyarlı (Route Guards) hâle getirmek; Bottom Navigation'ı 3 sekmeli hedefe uyarlamak.

### Adım 2.1: [x] GoRouter Rota Tanımları (`app/router/app_router.dart`)
- Rota isimlendirme ve hiyerarşisinin tanımlanması:
  - `/splash`
  - `/onboarding`
  - `/welcome`
  - `/login`
  - `/register`
  - `/forgot-password`
  - `/dashboard` (ShellRoute - Tab 0)
  - `/devices` (ShellRoute - Tab 1)
  - `/profile` (ShellRoute - Tab 2)
  - `/rooms` (Ayrı tam sayfa rota)
  - `/rooms/:roomId` (Oda detay rotası)
  - `/rooms/add-edit` (Oda ekleme/düzenleme rotası)
  - `/devices/lamp/:deviceId` (Lamba kontrol rotası)
  - `/devices/climate/:deviceId` (Klima kontrol rotası)
  - `/devices/add-edit` (Cihaz ekleme/düzenleme rotası)
  - `/notifications` (Ayrı tam sayfa bildirim rotası)
  - `/components-preview` (Yalnızca geliştirme modunda erişilebilen yardımcı rota)

### Adım 2.2: [x] Auth Durum Dinleyicisi ve Korumalı Rota Yönlendirmeleri (Redirect Guards)
- Oturum açmamış kullanıcının doğrudan `/dashboard` veya detay sayfalarına gitmesini engelleyip `/welcome` ya da `/login`'e yönlendirme.
- Oturum açmış kullanıcının Splash/Welcome/Login ekranlarına tekrar düşmesini engelleyip doğrudan `/dashboard`'a yönlendirme.
- GoRouter `refreshListenable` ile auth state değişimlerini dinleme.

### Adım 2.3: [x] `AppShell` Dönüşümü ve 3 Öğeli Bottom Navigation
- `lib/app/app_shell.dart`: Yalnızca **Ana Sayfa**, **Cihazlar** ve **Profil** sekmelerini barındıracak şekilde yapılandırılması.
- `IndexedStack(sizing: StackFit.expand)` düzeni ve `NestoraBottomNav` (64px sabit yükseklik) entegrasyonu ile sayfa gövdelerinin çökmesini önleyen yapının korunması.
- Ekran Galerisi FAB butonunun geliştirici bayrağına (kDebugMode) bağlanması.

---

## Faz 3: Kimlik Doğrulama (Auth) & İlk Kullanım Akışı

> **Amaç:** Firebase Authentication ile gerçek kayıt, giriş, çıkış, şifre sıfırlama ve demo giriş akışını kurmak; ilk kullanım arayüzlerini bağlamak.

> [!IMPORTANT]
> **Manuel Olarak Yapılması Gereken (Faz 3 — Adım 3.1 Öncesinde):**
> - **Firebase Authentication:** Firebase Console'dan *"Email/Password"* (E-posta/Şifre) sağlayıcısını tek tıkla aktif etmeniz gerekecektir.
> - **Hızlı Demo Hesabı (Adım 3.5 için):** Console'dan test/demo kullanıcısının (`users` altında) oluşturulması gerekecektir.

### Adım 3.1: [x] Auth Domain & Data Katmanı
- `lib/features/auth/domain/repositories/auth_repository.dart`: Sözleşme tanımları (`signInWithEmail`, `signUpWithEmail`, `signOut`, `sendPasswordReset`, `signInDemo`, `authStateChanges`).
- `lib/features/auth/data/datasources/auth_remote_data_source.dart`: FirebaseAuth SDK çağrıları.
- `lib/features/auth/data/repositories/auth_repository_impl.dart`: Hataları `Failure` nesnelerine dönüştüren implementasyon.

### Adım 3.2: [x] `AuthCubit` ve Durum Yönetimi
- `lib/features/auth/presentation/cubit/auth_cubit.dart` ve `auth_state.dart`:
  - `AuthInitial`, `AuthLoading`, `Authenticated`, `Unauthenticated`, `AuthError`.
- E-posta doğrulama ve anlık şifre güçlülük kuralları (en az 8 karakter, büyük harf, rakam, özel karakter).

### Adım 3.3: [x] Splash, Onboarding & Welcome Ekranlarının Entegrasyonu
- `splash_page.dart`: Mevcut 220px büyük logo ve glow animasyonu korunarak, auth state kontrolüyle yönlendirme.
- `onboarding_page.dart`: 3D izometrik ev görseli ve interaktif `> Başla >>>` kaydırıcısı ile `/welcome`'a geçiş.
- `welcome_page.dart`: Suluboya villa görseli ve mikro ambiyans rozeti korunarak `Hemen Başla` (Register/Login) ve `Giriş Yap` butonlarının GoRouter rotalarına bağlanması.

### Adım 3.4: [x] Login, Register ve Şifremi Unuttum Ekranlarının Bağlanması
- `login_page.dart`: Gerçek Firebase giriş entegrasyonu, form validasyonu, hata durumlarında Türkçe SnackBar bildirimleri.
- `register_page.dart`: Hesap oluşturma, şifre eşleşme kontrolü, kullanıcı sözleşmesi onayı, Firestore profil dokümanı oluşturma.
- `forgot_password_page.dart`: Firebase `sendPasswordResetEmail` tetikleyicisi ve bilgilendirme ekranı.

### Adım 3.5: [x] "Hızlı Demo ile Giriş Yap" Özelliği
- Login ekranında tek dokunuşla çalışan demo butonu.
- Kaynak koda açık şifre/e-posta gömülmeden (Remote Config veya güvenli ortam yapılandırması üzerinden) Firebase üzerinde tanımlı gerçek test hesabına giriş.
- Demo hesabı için başlangıç odaları, sanal cihazları ve bildirimleri içeren Firestore seed verilerinin hazırlanması (`FirestoreSeedService`, `DemoConfigService`, `docs/demo_setup.md`).

---

## Faz 4: Domain & Data Katmanları (Firestore Şeması ve Modeller)

> **Amaç:** Oda, sanal cihaz, bildirim ve kullanıcı profili için Firestore veri modellerini, DTO dönüşümlerini ve Security Rules kurallarını hayata geçirmek.

> [!IMPORTANT]
> **Manuel Olarak Yapılması Gereken (Faz 4 — Adım 4.3 ve 4.5 Öncesinde):**
> - **Cloud Firestore:** Console üzerinden Firestore veritabanını oluşturmanız ("Test Modunda" başlatıp ardından hazırladığımız `firestore.rules` güvenlik kurallarını yapıştırmanız) gerekecektir.

### Adım 4.1: [x] Domain Entities (Dış Servislerden Bağımsız Saf Modeller)
- `lib/features/rooms/domain/entities/room.dart`: `id`, `name`, `iconName`, `targetTemperature`, `deviceCount`, `activeDeviceCount`, `humidity`, `imageAsset`, `createdAt`, `updatedAt`.
- `lib/features/devices/domain/entities/device.dart`: `id`, `name`, `type`, `roomId`, `isPoweredOn`, `brightness`, `colorHex`, `colorName`, `targetTemp`, `acMode`, `fanSpeed`, `currentPowerWatts`, `isFavorite`, `createdAt`, `updatedAt`.
- `lib/features/notifications/domain/entities/app_notification.dart`: `id`, `title`, `message`, `type`, `isRead`, `createdAt`, `relatedRoomId`, `relatedDeviceId`, `timeAgoFormatted`.
- `lib/features/profile/domain/entities/user_profile.dart`: `uid`, `email`, `displayName`, `homeName`, `photoPath`, `preferences` (`UserPreferences`), `initials`, `createdAt`, `updatedAt`.

### Adım 4.2: [x] Data Modelleri / DTOs & Güvenli Firestore Parsing
- `RoomModel.fromFirestore` / `toFirestore` / `fromMap` / `toMap` (`lib/features/rooms/data/models/room_model.dart`).
- `DeviceModel.fromFirestore` / `toFirestore` / `fromMap` / `toMap` (`lib/features/devices/data/models/device_model.dart`).
- `NotificationModel.fromFirestore` / `toFirestore` / `fromMap` / `toMap` (`lib/features/notifications/data/models/notification_model.dart`).
- `UserProfileModel.fromFirestore` / `toFirestore` / `fromMap` / `toMap` (`lib/features/profile/data/models/user_profile_model.dart`).
- `FirestoreHelpers` (`lib/core/utils/firestore_helpers.dart`): Merkezi Timestamp <-> DateTime ve tip-güvenli (num/int/double/bool/String) parse mantığı.

### Adım 4.3: [x] Firestore Remote Data Sources
- `RoomsRemoteDataSource` & `RoomsRemoteDataSourceImpl` (`lib/features/rooms/data/datasources/rooms_remote_data_source.dart`): `users/{uid}/rooms` CRUD sorguları ve gerçek zamanlı stream dinleyicisi.
- `DevicesRemoteDataSource` & `DevicesRemoteDataSourceImpl` (`lib/features/devices/data/datasources/devices_remote_data_source.dart`): `users/{uid}/devices` CRUD, anlık state güncellemeleri, oda bazlı filtreleme/toplu taşıma/silme batch sorguları.
- `NotificationsRemoteDataSource` & `NotificationsRemoteDataSourceImpl` (`lib/features/notifications/data/datasources/notifications_remote_data_source.dart`): `users/{uid}/notifications` sorguları, tekil ve tümünü okundu işaretleme batch işlemleri.
- `ProfileRemoteDataSource` & `ProfileRemoteDataSourceImpl` (`lib/features/profile/data/datasources/profile_remote_data_source.dart`): `users/{uid}` profil dokümanı okuma, gerçek zamanlı stream, ev adı, görünen ad ve tercihler güncelleme.

### Adım 4.4: [x] Repository Implementasyonları
- `RoomsRepositoryImpl`, `DevicesRepositoryImpl`, `NotificationsRepositoryImpl`, `ProfileRepositoryImpl`.
- Firestore hatalarının yakalanıp `Failure` olarak Cubit katmanına aktarılması.

### Adım 4.5: [x] Firestore Security Rules (`firestore.rules`)
- `users/{userId}` altında kullanıcının yalnızca kendi verilerini okuyup yazabilmesini sağlayan (`request.auth.uid == userId`) güvenlik kuralları dosyasının hazırlanması.

---

## Faz 5: Durum Yönetimi (Cubits) & `app_state.dart`'ın Parçalanması

> **Amaç:** Geçici merkezi `app_state.dart` dosyasındaki karmaşık sorumlulukları ilgili feature Cubit'lerine dağıtarak ortadan kaldırmak; sanal cihazlarda "Tek Doğruluk Kaynağı" kurmak.

### Adım 5.1: [x] `ProfileCubit` ve Yerel Tercihler
- `ProfileCubit` oluşturulması: Kullanıcı adı, ev adı güncelleme, bildirim tercihleri toggle'ları.
- Profil fotoğrafının `image_picker` ile seçilip `path_provider` üzerinden yerel uygulama klasörüne kaydedilmesi ve dosya yolunun SharedPreferences'ta tutulması.

### Adım 5.2: [x] `RoomsCubit` (Oda Yönetimi Durumu)
- `RoomsCubit`: Oda listesini getirme, yeni oda ekleme, oda düzenleme, oda silme.
- Oda silindiğinde odaya bağlı cihazların sahipsiz kalmaması için kullanıcıya seçim sunulması (cihazları başka odaya taşı veya sil).

### Adım 5.3: [x] `DevicesCubit` — Ortak Sanal Cihaz State'i (Single Source of Truth)
- Uygulama genelinde tüm cihazların tek bir merkezden yönetilmesi.
- Lamba parlaklığı (%72 -> %50) veya klima derecesi (22°C -> 24°C) değiştiğinde; **Dashboard**, **Cihazlar Listesi**, **Oda Detayı** ve **Lamba/Klima Kontrol** ekranlarının aynı state'i gecikmesiz yansıtması.
- Slider ve renk değişimlerinde kullanıcı arayüzünün anında tepki vermesi; Firestore yazmalarının ise kota tasarrufu için **debounce (örneğin 300ms)** ile yapılması.

### Adım 5.4: [x] `NotificationsCubit` (Bildirim Durumu)
- Bildirim listesini yükleme, tekil okundu işaretleme, tümünü okundu işaretleme, bildirim silme.
- Okunmamış bildirim sayısının Dashboard bildirim zilinde anlık kırmızı rozet olarak gösterilmesi.

### Adım 5.5: [x] `app_state.dart`'ın Güvenle Emekliye Ayrılması
- Mevcut ekranların `AppStateScope.of(context)` referanslarının ilgili `context.watch<DevicesCubit>()`, `context.watch<RoomsCubit>()` gibi Cubit çağrılarına geçirilmesi.
- `app_state.dart` dosyasının projeden temizlenmesi.

---

## Faz 6: Ekranların Gerçek Cubit ve Veri Akışına Bağlanması

> **Amaç:** 16 arayüz ekranının mock veriler yerine gerçek Cubit durumlarıyla çalışmasını sağlamak.

### Adım 6.1: [x] Dashboard (Ana Sayfa) Entegrasyonu
- Üst bar: `ProfileCubit`'ten ev adı ve profil ikonu, `NotificationsCubit`'ten okunmamış bildirim zili.
- Hero Banner: Güncel ev karşılama bilgisi.
- Enerji Özeti: Günlük sanal enerji tüketimi (7,8 kWh) ve ilerleme barı.
- Hızlı Senaryolar: *Evdeyim, Gündüz, Gece Modu, Dışarıda* modlarının tek dokunuşla birden fazla sanal cihazın durumunu değiştirmesi.
- Odalar Karuseli: `RoomsCubit`'ten gelen odalar ve anlık sıcaklıklar.
- Kompakt Cihazlar: `DevicesCubit`'ten gelen aktif cihazlar, anlık değerler (%72 Parlaklık, 22° Hedef sıcaklık, 240 W güç) ve doğrudan çalışan toggle anahtarları.

### Adım 6.2: [x] Odalarım ve Oda Detayı Ekranları
- `rooms_page.dart`: Gerçek oda listesi, arama/filtreleme, odaya dokununca `/rooms/:roomId` rotasına gitme.
- `room_detail_page.dart`: Odaya ait sanal ortam değerleri (sıcaklık, nem, hava kalitesi), odaya bağlı cihazların listesi ve toplu aksiyonlar.

### Adım 6.3: [x] Oda Ekle ve Düzenle Ekranı (`add_edit_room_page.dart`)
- Oda adı, simge seçici grid, varsayılan sıcaklık ayarı.
- Form doğrulama, Firestore kaydı ve onay diyaloğuyla oda silme.

### Adım 6.4: [x] Cihazlarım Ekranı (`devices_page.dart`)
- Kategori sekmeleri (*Tümü, Aydınlatma, İklimlendirme, Güvenlik, Prizler*).
- Anlık açık/kapalı toggle'ı, güç tüketimi göstergesi, detay kumandalarına yönlendirme.

### Adım 6.5: [x] Salon Lambası Kontrol Ekranı (`lamp_control_page.dart`)
- Büyük aydınlatma görseli ve seçilen parlaklık/renge göre dinamik değişen glow ışığı.
- Hassas parlaklık slider'ı (%0 - %100).
- Renk sıcaklığı çarkı / renk paleti seçimi.
- Hazır modlar (*Okuma, Dinlenme, Konsantrasyon, Gece Lambası*).
- Lamba kapatıldığında ışık ve glow efektinin sönmesi, son ayarların hafızada korunması.

### Adım 6.6: [x] Yatak Odası Klima Kontrol Ekranı (`ac_control_page.dart`)
- Dairesel termostat kadranı (Thermostat Dial).
- 0.5°C adımlarla `+` ve `-` hedef sıcaklık ayarı.
- Çalışma modları (*Soğutma, Isıtma, Otomatik, Fan*).
- Fan hızı kademeleri (Düşük, Orta, Yüksek, Otomatik) ve hız animasyonu.

### Adım 6.7: Cihaz Ekle ve Düzenle Ekranı (`add_edit_device_page.dart`)
- Cihaz türü seçimi, cihaz adı, oda atama seçicisi.
- Sanal eşleştirme akışı ve kaydetme/silme işlemleri.

### Adım 6.8: Bildirimler Ekranı (`notifications_page.dart`)
- Tarih gruplamalı (Bugün, Dün, Geçen Hafta) bildirim kartları.
- Bildirime dokunulduğunda ilgili cihaza veya odaya akıllı yönlendirme.
- "Tümünü Okundu İşaretle" ve bildirim temizleme.

### Adım 6.9: Profil ve Ayarlar Ekranı (`profile_page.dart`)
- Profil bilgileri (Ad, E-posta, Ev Sahibi rolü).
- Galeri üzerinden profil fotoğrafı seçimi ve yerel depolama.
- Tema seçimi: Açık Mod, Koyu Mod, Sistem Modu (`ThemeCubit` ve SharedPreferences ile kalıcı).
- Güvenli oturum kapatma (Logout diyaloğu ve login rotasına dönüş).

### Adım 6.10: Components Preview Ekranı İzolasyonu
- `components_preview_page.dart`: Yalnızca tasarım kontrolü amacıyla korunması, son kullanıcı menülerinden tamamen çıkarılması.

---

## Faz 7: Tasarım İyileştirmeleri, Tipografi & Responsive Optimizasyon

> **Amaç:** Tasarım bütünlüğünü, Manrope tipografisini ve tüm ekran boyutlarında taşmasız (zero-overflow) görüntülemeyi garanti altına almak.

### Adım 7.1: Tema Renklerinin Son Uyarlaması
- Açık mod ana arka plan renginin değerlendirilmesi (`#F4F3EC` nötr inci tonu ile mevcut `#FDF5E6` karşılaştırması).
- Koyu mod (`#131713`) ve kart yüzeylerinin (`#FFFFFF` / `#1C221D`) kontrast denetimi.

### Adım 7.2: Manrope Tipografi Skalası Kontrolü
- Sayfa başlığı: 24–28 px (Bold 700)
- Bölüm başlığı: 18–20 px (SemiBold 600)
- Kart başlığı: 15–16 px (SemiBold 600)
- Normal metin: 14 px (Regular 400)
- Açıklama metni: 12–13 px (Regular 400)
- Küçük etiket/rozet: 11–12 px (Medium 500)
- Aşırı büyük veya orantısız metinlerin standartlaştırılması.

### Adım 7.3: Responsive & Web Uyumluluğu
- Mobil (360–390px), Tablet (768px), Küçük Masaüstü (1024px) ve Geniş Masaüstü (1440px) testleri.
- Geniş ekranlarda içeriklerin kontrolsüz yayılmasını önlemek için `maxWidth: 820` / `maxWidth: 480` sınırlayıcılarının doğrulanması.
- Klavye açıldığında formların erişilebilir kalması (`resizeToAvoidBottomInset` ve kaydırma kontrolleri).

### Adım 7.4: Mikro Etkileşimler ve Reduced-Motion Desteği
- Slider, toggle ve kart animasyonlarının 200–300ms arasında akıcı tutulması.
- Erişilebilirlik ayarlarında reduced-motion tercih eden kullanıcılar için animasyonların sadeleştirilmesi.

---

## Faz 8: Firebase İzleme, Spark Kota Kontrolü ve Güvenlik

> **Amaç:** Firebase Spark plan sınırları içinde kalarak uygulamanın kararlılığını ve güvenliğini sağlamak.

> [!IMPORTANT]
> **Manuel Olarak Yapılması Gereken (Faz 8 Öncesinde):**
> - **Remote Config, Crashlytics, Analytics:** İhtiyaç duyulan parametre ve ayarların Firebase Console'da açılması/kontrol edilmesi.

### Adım 8.1: Crashlytics & Analytics Entegrasyonu
- Beklenmeyen uygulama çökmelerinin Crashlytics'e bildirilmesi.
- Temel analitik olaylarının (giriş, oda oluşturma, senaryo seçimi) gizlilik kurallarına uygun olarak (şifre ve kişisel veri içermeden) kaydedilmesi.

### Adım 8.2: Performance Monitoring & Remote Config
- Sayfa yüklenme süreleri ve ağ gecikmelerinin izlenmesi.
- Remote Config üzerinden uygulama duyurusu ve dinamik parametre desteği.

### Adım 8.3: Spark Plan Kota Koruması
- Firestore okuma ve yazmalarının optimize edilmesi.
- Gereksiz gerçek zamanlı listener açılmaması; ekran kapandığında listener'ların iptal edilmesi.
- Cloud Storage ve Cloud Functions bağımlılığı oluşturulmadığının teyidi.

---

## Faz 9: Kapsamlı Test, Kalite Doğrulama ve Teslim

> **Amaç:** Projenin tüm kabul kriterlerini eksiksiz karşıladığını doğrulamak.

### Adım 9.1: Unit Testler
- Veri modelleri, DTO parsing (`fromFirestore` / `toFirestore`).
- `AuthCubit`, `RoomsCubit`, `DevicesCubit`, `NotificationsCubit`, `ProfileCubit` durum geçiş testleri.
- Şifre ve e-posta doğrulama kuralları testleri.

### Adım 9.2: Widget Testler
- Login, Register form alanları ve doğrulama hata mesajları.
- Cihaz kartları, lamba parlaklık slider'ı ve toggle anahtarları.
- Tema değiştirme etkileşimleri.

### Adım 9.3: Uçtan Uca Entegrasyon Testleri
- Splash -> Onboarding -> Welcome -> Login/Register -> Dashboard akışı.
- Hızlı demo ile giriş ve ana kontrol paneline erişim.
- Yeni oda ekleme, cihaza bağlama, cihaz durumunu değiştirme ve Dashboard'da anlık güncelleme.

### Adım 9.4: Statik Analiz & Derleme Kontrolü
- `flutter analyze`: **0 Hata, 0 Uyarı, 0 Lint Problemi**.
- `flutter test`: Tüm testlerin başarıyla geçmesi.
- `flutter run -d chrome`: Canlı web tarayıcısında tam kontrol.

---

## Özet İlerleme Çizelgesi

```text
[Faz 1: Altyapı & Paketler] ──> [Faz 2: GoRouter & Kabuk] ──> [Faz 3: Auth & İlk Akış]
                                                                        │
                                                                        v
[Faz 6: Ekran Entegrasyonu] <── [Faz 5: Cubits & State] <── [Faz 4: Domain & Data]
         │
         v
[Faz 7: Tasarım & Responsive] ──> [Faz 8: Güvenlik & Kotalar] ──> [Faz 9: Test & Teslim]
```

Bu plan, geliştirme süresince adım adım takip edilecek; her aşama tamamlandığında çalışan uygulama doğrulanarak bir sonraki adıma geçilecektir.

