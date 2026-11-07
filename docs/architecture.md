# Nestora — Uygulama Mimarisi

## 1. Mimari Hedefi

Nestora, Flutter ile geliştirilen ve Firebase servislerini kullanan modüler bir akıllı ev uygulamasıdır.

Projenin mimarisi **Feature-First + Sadeleştirilmiş Clean Architecture** yaklaşımına dayanacaktır.

Temel hedefler:
- Her özelliğin kendi sorumluluk alanına sahip olması.
- UI, iş mantığı ve veri erişiminin birbirinden ayrılması.
- Firebase bağımlılığının uygulamanın her yerine yayılmaması.
- Sanal cihaz durumlarının tek ve tutarlı bir kaynaktan yönetilmesi.
- Gereksiz soyutlama ve dosya kalabalığından kaçınılması.
- Mevcut tasarımın ve çalışan ekranların korunması.
- İleride yeni özellik eklenebilecek kadar esnek, ancak gereksiz karmaşıklık içermeyen bir yapı kurulması.

## 2. Mimari Katmanlar

Her feature için ihtiyaç duyulduğunda üç katman kullanılır.

### 2.1 Presentation

Kullanıcı arayüzünden ve kullanıcı etkileşimlerinden sorumludur.

İçerik:
- Pages
- Widgets
- Cubit
- State

Görevleri:
- Ekranları oluşturmak.
- Kullanıcı etkileşimlerini almak.
- Cubit üzerinden işlemleri başlatmak.
- State değişikliklerine göre arayüzü güncellemek.
- Loading, error, empty ve success durumlarını göstermek.

Presentation katmanı Firebase SDK ile doğrudan iletişim kurmaz.

### 2.2 Domain

İş kurallarını ve temel veri sözleşmelerini içerir.

İçerik:
- Entities
- Repository contracts
- Gerektiğinde UseCases

Görevleri:
- Uygulamanın temel kavramlarını tanımlamak.
- İş kurallarını belirlemek.
- Repository sözleşmelerini tanımlamak.

Domain katmanı Flutter, Firebase veya başka bir dış servis paketine bağımlı olmamalıdır.

Her feature için mutlaka üç katman oluşturulması gerekmez. Basit ve bağımsız bir özellikte gereksiz katman açılmamalıdır.

### 2.3 Data

Verilerin nereden ve nasıl alındığından sorumludur.

İçerik:
- Repository implementations
- Data sources
- Firebase işlemleri
- DTO / data models
- Serialization ve parsing

Görevleri:
- Firestore'dan veri okumak.
- Firestore'a veri yazmak.
- Firebase verisini uygulamanın model yapısına dönüştürmek.
- Hataları uygun şekilde ele almak.
- Repository sözleşmelerini gerçekleştirmek.

Firebase SDK yalnızca gerekli data katmanında kullanılmalıdır.

## 3. Katmanlar Arası İletişim

Temel veri akışı:

```text
User Interaction
       |
       v
     Page
       |
       v
     Cubit
       |
       v
Repository Contract
       |
       v
Repository Implementation
       |
       v
   Data Source
       |
       v
 Firebase / Firestore
```

Veri dönüşü ters yönde gerçekleşir:

```text
Firestore
    |
    v
Data Source
    |
    v
Repository
    |
    v
Cubit
    |
    v
State
    |
    v
   UI
```

Önemli kurallar:
- Page, Cubit'i çağırır.
- Cubit, repository sözleşmesini kullanır.
- Repository implementation, data source ile çalışır.
- Data source Firebase SDK ile iletişim kurar.
- Firebase işlemleri widget içinde yapılmaz.
- Domain katmanı Firebase tiplerini tanımaz.

## 4. Mevcut Projenin Yapısı

Antigravity tarafından oluşturulmuş mevcut klasör yapısı başlangıç noktasıdır.

Mevcut ekranlar ve tasarım bileşenleri korunmalıdır. Hedef mimariye geçiş yapılırken bütün proje tek seferde yeniden yazılmamalıdır.

Önerilen hedef yapı:

```text
lib/
│
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── app_shell.dart
│   ├── router/
│   │   └── app_router.dart
│   │
│   ├── di/
│   │   └── injection.dart
│   │
│   └── theme/
│       ├── app_colors.dart
│       ├── app_theme.dart
│       ├── app_typography.dart
│       └── theme_cubit.dart
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── widgets/
│       ├── nestora_bottom_nav.dart
│       ├── nestora_bottom_sheet.dart
│       ├── nestora_button.dart
│       ├── nestora_card.dart
│       ├── nestora_dialog.dart
│       ├── nestora_input.dart
│       ├── nestora_logo.dart
│       ├── nestora_snackbar.dart
│       └── nestora_switch.dart
│
└── features/
    │
    ├── auth/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── auth_remote_data_source.dart
    │   │   └── repositories/
    │   │       └── auth_repository_impl.dart
    │   │
    │   ├── domain/
    │   │   └── repositories/
    │   │       └── auth_repository.dart
    │   │
    │   └── presentation/
    │       ├── cubit/
    │       │   ├── auth_cubit.dart
    │       │   └── auth_state.dart
    │       ├── pages/
    │       │   ├── splash_page.dart
    │       │   ├── onboarding_page.dart
    │       │   ├── welcome_page.dart
    │       │   ├── login_page.dart
    │       │   ├── register_page.dart
    │       │   └── forgot_password_page.dart
    │       └── widgets/
    │           └── password_validator_widget.dart
    │
    ├── home/
    │   └── presentation/
    │       └── pages/
    │           └── dashboard_page.dart
    │
    ├── rooms/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── rooms_remote_data_source.dart
    │   │   └── repositories/
    │   │       └── rooms_repository_impl.dart
    │   │
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── room.dart
    │   │   └── repositories/
    │   │       └── rooms_repository.dart
    │   │
    │   └── presentation/
    │       ├── cubit/
    │       │   ├── rooms_cubit.dart
    │       │   └── rooms_state.dart
    │       └── pages/
    │           ├── rooms_page.dart
    │           ├── room_detail_page.dart
    │           └── add_edit_room_page.dart
    │
    ├── devices/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── devices_remote_data_source.dart
    │   │   └── repositories/
    │   │       └── devices_repository_impl.dart
    │   │
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── device.dart
    │   │   └── repositories/
    │   │       └── devices_repository.dart
    │   │
    │   └── presentation/
    │       ├── cubit/
    │       │   ├── devices_cubit.dart
    │       │   └── devices_state.dart
    │       └── pages/
    │           ├── devices_page.dart
    │           ├── lamp_control_page.dart
    │           ├── ac_control_page.dart
    │           └── add_edit_device_page.dart
    │
    ├── notifications/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── notifications_remote_data_source.dart
    │   │   └── repositories/
    │   │       └── notifications_repository_impl.dart
    │   │
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── app_notification.dart
    │   │   └── repositories/
    │   │       └── notifications_repository.dart
    │   │
    │   └── presentation/
    │       ├── cubit/
    │       │   ├── notifications_cubit.dart
    │       │   └── notifications_state.dart
    │       └── pages/
    │           └── notifications_page.dart
    │
    ├── profile/
    │   ├── data/
    │   │   ├── datasources/
    │   │   │   └── profile_remote_data_source.dart
    │   │   └── repositories/
    │   │       └── profile_repository_impl.dart
    │   │
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── user_profile.dart
    │   │   └── repositories/
    │   │       └── profile_repository.dart
    │   │
    │   └── presentation/
    │       ├── cubit/
    │       │   ├── profile_cubit.dart
    │       │   └── profile_state.dart
    │       └── pages/
    │           └── profile_page.dart
    │
    └── components_preview/
        └── presentation/
            └── pages/
                └── components_preview_page.dart
```

Bu yapı hedef örneğidir; her klasörün hemen oluşturulması zorunlu değildir. Özellik geliştirilirken gerçekten ihtiyaç duyulan dosyalar eklenmelidir.

Örneğin:
- Dashboard yalnızca diğer feature'ların verilerini sunan bir ekran ise sırf mimari simetri için `home/domain` ve `home/data` oluşturulmaz.
- Basit bir model için ayrıca UseCase yazılmaz.
- Bir feature'da tek bir repository işlemi varsa gereksiz katmanlar üretilmez.

## 5. Mevcut Dosyaların Dönüşümü

### 5.1 `main.dart`

Sorumlulukları:
- Flutter binding başlatma.
- Firebase initialization.
- Gerekli uygulama başlangıç işlemlerini çağırma.
- Uygulamayı başlatma.

İş mantığı veya ekran kodu barındırmamalıdır.

### 5.2 `app/app.dart`

- MaterialApp.router yapılandırması.
- GoRouter bağlantısı.
- ThemeData bağlantısı.
- Global uygulama yapılandırması.
- Gerekli üst seviye BlocProvider/RepositoryProvider bağlantıları.

### 5.3 `app/app_shell.dart`

- Üç öğeli Bottom Navigation kabuğu.
- Ana Sayfa, Cihazlar ve Profil bölümleri.
- Navigasyon durumunun yönetimi.

16 ekranın tamamını bu dosyada toplama. Ekran galerisi veya route yönetimi ile Bottom Navigation sorumluluklarını birbirine karıştırma.

### 5.4 `app/app_state.dart`

Mevcut `app_state.dart` dosyası başlangıç tasarımında oda, cihaz ve bildirim verilerini merkezi biçimde tutuyor olabilir.

Bu dosya kalıcı olarak bütün uygulamanın state yöneticisi hâline getirilmemelidir.

- İçindeki örnek verileri ve mevcut ekran bağımlılıklarını incele.
- Hangi sorumlulukların rooms, devices ve notifications feature'larına ait olduğunu belirle.
- Verileri ilgili repository ve Cubit yapılarına kontrollü biçimde taşı.
- Taşıma sırasında mevcut ekranların çalışmasını bozma.
- Aynı veriyi hem `app_state.dart` hem ayrı Cubit'lerde bağımsız olarak tutma.
- Geçiş tamamlandığında kullanılmayan merkezi state dosyasını kaldır veya gerçekten gerekli kalan ortak sorumluluğu açıkça tanımla.

### 5.5 `domain/room_model.dart` ve `domain/device_model.dart`

Mevcut model dosyalarını incele.

Domain katmanında Firebase bağımlılığı taşımayan Entity modelleri bulunmalıdır. Firestore'a özel dönüştürme işlemleri data katmanında yer almalıdır.

Gerekirse:
- `room_model.dart` → `entities/room.dart`
- `device_model.dart` → `entities/device.dart`

Ancak yalnızca dosya adını değiştirmek için çalışan kodu yeniden yazma.

## 6. Uygulama Başlangıcı ve Bağımlılık Yönetimi

Başlangıç akışı:

```text
main.dart
   |
   v
Firebase Initialization
   |
   v
Dependency Setup
   |
   v
App
   |
   v
GoRouter
   |
   v
Auth State Check
   |
   +---- Oturum yok ----> Splash / Onboarding / Welcome
   |
   +---- Oturum var ----> Dashboard
```

Bağımlılıklar merkezi bir noktada oluşturulabilir.

Örneğin:
- FirebaseAuth instance.
- FirebaseFirestore instance.
- Data source.
- Repository implementation.
- Cubit.

Ancak yalnızca gerçekten ihtiyaç duyulan bağımlılıklar kaydedilmelidir. DI yapısı gereksiz karmaşıklaştırılmamalıdır.

## 7. Kimlik Doğrulama Mimarisi

Auth akışı:

```text
Login Page
    |
    v
AuthCubit
    |
    v
AuthRepository
    |
    v
AuthRepositoryImpl
    |
    v
AuthRemoteDataSource
    |
    v
Firebase Authentication
```

Auth sorumlulukları:
- Login.
- Register.
- Logout.
- Password reset.
- Auth state takibi.
- Demo login.

Kayıt akışı:

```text
Register
   |
   v
Firebase Auth Account Creation
   |
   v
User ID
   |
   v
Firestore User Profile Creation
   |
   v
Profile Creation Success
   |
   v
Dashboard
```

Kayıt başarılı olsa bile profil dokümanı oluşturma başarısızsa kullanıcıya hata bildirilmeli ve durum tutarlı biçimde ele alınmalıdır. Yarım kalmış profil sessizce başarılı kabul edilmemelidir.

Auth state uygulamanın navigasyonunu etkiler. GoRouter, Auth durumuna göre korumalı rotaları yönetmelidir.

## 8. Firestore Veri Yapısı

Veriler kullanıcıya göre ayrılmalıdır.

Önerilen koleksiyon yapısı:

```text
users/
  {userId}/
    profile fields
    homeName
    preferences

    rooms/
      {roomId}/
        name
        icon
        targetTemperature
        createdAt
        updatedAt

    devices/
      {deviceId}/
        name
        type
        roomId
        isOn
        brightness
        color
        targetTemperature
        mode
        fanSpeed
        createdAt
        updatedAt

    notifications/
      {notificationId}/
        title
        message
        type
        isRead
        relatedRoomId
        relatedDeviceId
        createdAt
```

Bu yapı temel öneridir. Firestore belge ve koleksiyon kuralları uygulanırken gerçek sorgu ihtiyaçları dikkate alınmalıdır.

Kurallar:
- Her kullanıcının kendi verisi bulunur.
- `userId` sahipliği güvenlik kurallarıyla doğrulanır.
- Oda ve cihaz ilişkileri ID üzerinden kurulur.
- Cihazın `roomId` değeri mevcut kullanıcıya ait bir odayı göstermelidir.
- Bir oda silinmeden önce ilişkili cihazlar için karar verilmelidir.
- Tarih alanları tutarlı biçimde saklanmalıdır.
- Gereksiz büyük belgeler ve yinelenen veriler oluşturulmamalıdır.

Senaryolar:
- Senaryo tanımları sabit uygulama yapılandırması olabilir.
- Kullanıcının özel senaryoları eklenirse ayrı bir veri yapısı oluşturulabilir.
- İlk sürümde yalnızca dört sabit senaryo için gereksiz koleksiyon oluşturulması zorunlu değildir.

## 9. Veri Modelleri ve Parsing

Firestore'dan gelen `Map<String, dynamic>` verileri doğrudan UI'da kullanılmamalıdır.

Örnek akış:

```text
Firestore Document
       |
       v
Data Model / DTO
       |
       v
Domain Entity
       |
       v
Cubit State
       |
       v
Widget
```

Kurallar:
- Firestore alanları açık biçimde parse edilmeli.
- Eksik veya null alanlar güvenli yönetilmeli.
- Yanlış veri tipi uygulamanın çökmesine neden olmamalı.
- Enum değerleri güvenli dönüştürülmeli.
- Timestamp ve DateTime dönüşümleri merkezi ve tutarlı olmalı.
- Domain Entity, Firestore `DocumentSnapshot` veya `Timestamp` tiplerini tanımamalı.

## 10. Sanal Cihaz State Mimarisi

Nestora'nın en önemli mimari gereksinimlerinden biri, aynı cihazın farklı ekranlarda aynı durumu göstermesidir.

Örneğin Salon Lambası:
- Dashboard kartında.
- Devices listesinde.
- Room Detail ekranında.
- Lamp Control ekranında.

Bu ekranların her biri lambanın bağımsız bir kopyasını yönetmemelidir.

Tek kaynak ilkesi:

```text
                 Devices Repository
                         |
                         v
                    DevicesCubit
                         |
             Shared Device State
                  /     |      \
                 /      |       \
          Dashboard  Devices  Room Detail
                              |
                              v
                         Lamp Control
```

Örnek:
- Kullanıcı Lamp Control ekranında parlaklığı %72'den %45'e düşürür.
- Cubit cihaz state'ini günceller.
- Repository gerekli veri kaydını yapar.
- Dashboard ve Devices ekranı aynı güncel değeri gösterir.
- Kullanıcı lambayı kapatırsa bütün ekranlarda kapalı görünür.

Uygulama içi state güncellemesi ile Firestore kalıcılığı tutarlı olmalıdır.

Gereksiz yazma yapılmamalıdır. Slider hareketlerinde her piksel değişimini Firestore'a yazmak yerine uygun bir debounce veya kontrollü kayıt yaklaşımı kullanılabilir. Arayüz ise gecikmesiz geri bildirim vermelidir.

### Cihaz türüne göre state

Lamba:
- `isOn`
- `brightness`
- `color` veya `colorTemperature`

Klima:
- `isOn`
- `targetTemperature`
- `mode`
- `fanSpeed`

Priz:
- `isOn`
- `power` (sanal gösterge)

Her cihazda bütün alanlar zorunlu tutulmamalıdır.

Cihaz kapatıldığında son parlaklık veya hedef sıcaklık gibi ayarların korunup korunmayacağı tutarlı biçimde belirlenmelidir. Varsayılan davranış, cihaz tekrar açıldığında son ayarları korumaktır.

## 11. Oda ve Cihaz İlişkisi

Bir cihaz bir odaya bağlanabilir.

- Oda detayında yalnızca o odaya ait cihazlar gösterilir.
- Cihazın oda ataması değiştiğinde eski ve yeni oda ekranları güncel veriyi göstermelidir.
- Oda silinirse ilişkili cihazlar için kullanıcıya açık bir seçenek sunulmalıdır.
- Oda ve cihaz verileri ayrı koleksiyonlarda tutulabilir; ilişki `roomId` üzerinden kurulur.

## 12. Dashboard Mimarisi

Dashboard bağımsız bir veri deposu olmamalıdır.

Gösterdiği veriler ilgili feature repository/state kaynaklarından gelmelidir:
- Oda sayısı ve oda listesi → Rooms.
- Cihazlar ve cihaz durumları → Devices.
- Okunmamış bildirim sayısı → Notifications.
- Kullanıcı adı ve ev adı → Profile / User data.

Dashboard üzerinde ayrı bir cihaz state'i oluşturulmamalıdır.

Dashboard yalnızca özet sunmalı ve ilgili sayfalara yönlendirme yapmalıdır.

## 13. Bildirim Mimarisi

Bildirimler kullanıcıya ait Firestore verisi olarak tutulabilir.

Temel işlemler:
- Bildirimleri listeleme.
- Okundu olarak işaretleme.
- Tümünü okundu işaretleme.
- Silme.
- İlgili oda veya cihaz sayfasına yönlendirme.

İlk sürümde uygulama içi bildirim listesi yeterlidir. Gerçek push notification, Firebase Cloud Messaging veya Cloud Functions gibi ek servisler ayrıca kararlaştırılmadan kapsam dışıdır.

## 14. Profil ve Tema Mimarisi

Profil verileri:
- Kullanıcı adı.
- E-posta.
- Avatar dosya yolu.
- Ev adı.
- Kullanıcı tercihleri.

E-posta Firebase Authentication kaynağından alınmalıdır.

Tema:
- `ThemeCubit` ile yönetilir.
- SharedPreferences ile kalıcı tutulur.
- Açık, Koyu ve Sistem seçenekleri bulunur.
- Tema renkleri ve tipografi `app/theme` altından yönetilir.
- Ekranlar kendi renklerini sabit değerlerle tanımlamamalıdır.

Profil fotoğrafı:
- Galeriden seçilir.
- Uygulamanın kalıcı yerel dosya alanına kopyalanır.
- Dosya yolu yerel olarak saklanır.
- Firestore'a görselin kendisi yazılmaz.
- Cloud Storage kullanılmaz.

## 15. Hata Yönetimi

Data katmanında oluşan Firebase hataları anlamlı uygulama hatalarına dönüştürülmelidir.

Örnek durumlar:
- Ağ bağlantısı yok.
- Yetkisiz erişim.
- Veri bulunamadı.
- Geçersiz veri.
- Firebase işlem hatası.

Cubit, bu hataları uygun state'e dönüştürür. UI ise kullanıcıya Türkçe ve anlaşılır geri bildirim verir.

Teknik hata ayrıntıları gerektiğinde Crashlytics veya geliştirici loglarında tutulabilir. Hassas kullanıcı verileri loglanmamalıdır.

## 16. Güvenlik

Firestore Security Rules zorunludur.

- Kullanıcı yalnızca kendi `users/{userId}` alanına erişebilmelidir.
- Alt koleksiyonlar da aynı sahiplik kontrolüne tabi olmalıdır.
- Kullanıcı ID'si istemciden gelen değere güvenilerek kabul edilmemelidir; Auth kimliği ile doğrulanmalıdır.
- Geçersiz veya yetkisiz veri yazma işlemleri reddedilmelidir.
- Remote Config güvenlik veya yetkilendirme amacıyla kullanılmamalıdır.
- Demo hesabı gerçek ve sınırlı bir test hesabı olmalıdır.
- Gizli bilgiler repoya eklenmemelidir.

## 17. Firebase Spark Planı ve Maliyet Kontrolü

Proje Firebase Spark planında kalacaktır.

Bu nedenle:
- Cloud Functions yok.
- Cloud Storage yok.
- Gereksiz Firestore listener yok.
- Gereksiz sorgu yok.
- Her ekran açılışında aynı veriyi tekrar tekrar çekme yok.
- Slider gibi sık değişen kontrollerde her ara değeri Firestore'a yazma yok.
- Liste sorgularında ihtiyaç olmayan tüm veriyi çekme yok.
- Mümkün olduğunda uygun yerel state ve kontrollü veri yenileme kullanılmalı.

## 18. Mevcut Tasarımdan Üretim Uygulamasına Geçiş

Mevcut projede 16 ürün ekranı ve bir Components Preview ekranı Flutter'a aktarılmıştır.

Bu ekranlar mimari dönüşüm sırasında korunmalıdır.

İlerleme sırası:

### Aşama 1 — Mevcut Yapıyı Anlama
- Bütün Dart dosyalarını incele.
- Mevcut route ve navigasyon davranışını incele.
- Ekranların hangi ortak widget'ları kullandığını belirle.
- `app_state.dart` ve örnek verilerin nerelerde kullanıldığını tespit et.
- Çalışan tasarım ve animasyonları kaydet.

### Aşama 2 — Temel Uygulama Altyapısı
- Firebase initialization.
- GoRouter.
- ThemeCubit.
- Gerekli dependency setup.
- Auth state yönetimi.

### Aşama 3 — Auth
- Login.
- Register.
- Forgot Password.
- Demo Login.
- Oturum kontrolü ve korumalı rotalar.

### Aşama 4 — Veri Katmanı
- User profile.
- Room.
- Device.
- Notification modelleri.
- Repository sözleşmeleri ve implementasyonları.
- Firestore datasource.
- Security Rules.

### Aşama 5 — Özelliklerin Bağlanması
- Oda CRUD.
- Cihaz CRUD.
- Ortak sanal cihaz state'i.
- Dashboard.
- Lamp Control.
- Climate Control.
- Bildirimler.
- Profil.

### Aşama 6 — Kalite Kontrolü
- Responsive ekranlar.
- Widget ve unit testler.
- Auth ve veri akışı testleri.
- Chrome kontrolü.
- Performans ve hata izleme.

Her aşama sonunda uygulama çalışır durumda olmalıdır.

## 19. Son Mimari İlkeler

1. Mevcut tasarım ve ekranlar korunur.
2. UI, Cubit ve repository sorumlulukları birbirinden ayrılır.
3. Firebase doğrudan UI veya Cubit içinde kullanılmaz.
4. Domain katmanı dış servislere bağımlı olmaz.
5. Aynı cihazın state'i uygulama genelinde tektir.
6. Dashboard ayrı bir veri kaynağı oluşturmaz.
7. Gereksiz UseCase ve abstraction oluşturulmaz.
8. Her feature'a zorunlu olarak üç katman eklenmez.
9. `app_state.dart` kalıcı bir global veri deposuna dönüşmez.
10. Firebase Spark planı korunur.
11. Gerçek IoT entegrasyonu yapılmaz.
12. Tasarım ve işlev geliştirmeleri küçük, test edilebilir adımlarla ilerler.