# Nestora — Geliştirme Becerileri ve Kodlama Standartları

Bu belge, Nestora projesinde kod yazarken kullanılacak teknolojileri, geliştirme yaklaşımını ve uyulması gereken standartları tanımlar.

Amaç yalnızca çalışan ekranlar oluşturmak değil; mevcut tasarımı koruyan, sürdürülebilir, test edilebilir, anlaşılır ve gereksiz karmaşıklıktan uzak bir Flutter uygulaması geliştirmektir.

## 1. Genel Geliştirme Kuralları

- Önce mevcut kodu, klasörleri, bağımlılıkları ve çalışan ekranları incele.
- Kullanıcının mevcut tasarımını ve onaylanmış kararlarını gerekçesiz değiştirme.
- Büyük çaplı refactor işlemlerine inceleme ve planlama yapmadan başlama.
- Bir özelliği tamamlamadan diğerine geçme.
- Gereksiz dosya, sınıf, manager, helper, wrapper veya abstraction üretme.
- Aynı işi yapan birden fazla çözüm oluşturma.
- Widget içinde iş mantığı ve Firebase işlemleri yazma.
- Kodun okunabilirliği, tekrar kullanılabilirlikten daha önemli olabilir. Her küçük widget için ayrı dosya oluşturma.
- Çalışan kodu sırf farklı bir mimari tercih etmek için yeniden yazma.
- Her değişiklikten sonra ilgili ekranı ve etkilenen akışları test et.

## 2. Flutter ve Dart

Kullanılacak temel teknolojiler:
- Flutter
- Dart
- Material 3

Kurallar:
- Null safety kullanılmalı.
- `const` constructor uygun olan yerlerde tercih edilmeli.
- Widget'lar küçük ve anlamlı sorumluluklara ayrılmalı.
- `build()` metotları gereksiz iş mantığı içermemeli.
- Uzun ve karmaşık widget ağaçları gerektiğinde özel widget'lara ayrılmalı.
- Gereksiz nested widget ve koşullu ifadeler azaltılmalı.
- `BuildContext` doğru kapsamda kullanılmalı.
- `mounted` kontrolü, async işlem sonrası context veya state kullanımı gerektiğinde yapılmalı.
- Controller ve listener kaynakları doğru zamanda dispose edilmeli.
- Gereksiz `setState` ve global mutable state kullanılmamalı.
- Sabit metinler ve tasarım değerleri dağınık biçimde tekrar edilmemeli.

Dart dil özellikleri:
- `final` ve `const` uygun yerlerde kullanılmalı.
- Nullable türler bilinçli yönetilmeli.
- `?.`, `??` ve `??=` operatörleri doğru kullanılmalı.
- Async işlemlerde `Future`, `async` ve `await` doğru yönetilmeli.
- Hatalar sessizce yutulmamalı.
- `dynamic` gereksiz kullanılmamalı.
- Model dönüşümleri açık ve güvenli olmalı.

## 3. Durum Yönetimi — Cubit

Uygulama genelinde `flutter_bloc` paketinin Cubit yapısı kullanılacaktır.

Kurallar:
- Her feature kendi sorumluluğuna uygun Cubit'e sahip olabilir.
- Tek bir global Cubit bütün uygulamayı yönetmemeli.
- Cubit yalnızca arayüz durumunu ve kullanıcı aksiyonlarını yönetmeli.
- Firebase SDK doğrudan Cubit içinde kullanılmamalı.
- Cubit, repository sözleşmeleri üzerinden veri işlemlerini çağırmalı.
- State sınıfları mümkün olduğunca immutable olmalı.
- State değişiklikleri `emit()` ile yapılmalı.
- Aynı state gereksiz yere tekrar emit edilmemeli.
- Async işlemlerde loading, success ve error durumları açıkça ele alınmalı.
- Hata mesajları kullanıcıya uygun bir dille sunulmalı.
- Birbirinden bağımsız özellikler tek Cubit'e yığılmamalı.

Örnek sorumluluklar:
- `AuthCubit`: giriş, kayıt, çıkış, şifre sıfırlama.
- `RoomsCubit`: oda listesi ve oda işlemleri.
- `DevicesCubit`: cihaz listesi ve cihaz işlemleri.
- `DeviceControlCubit`: ilgili sanal cihazın kontrol state'i. Ayrı Cubit gerçekten gerekli olduğunda kullanılmalı.
- `NotificationsCubit`: bildirim listesi ve okundu durumu.
- `ProfileCubit`: profil ve kullanıcı ayarları.
- `ThemeCubit`: tema tercihi.

Bu isimler zorunlu dosya listesi değildir. Her özellik için ayrı Cubit açmak yerine gerçek sorumluluk ve state karmaşıklığına göre karar verilmelidir.

## 4. Navigasyon — GoRouter

- Sayfa geçişleri GoRouter ile yönetilmeli.
- Route tanımları merkezi ve anlaşılır olmalı.
- Route isimleri ve parametreleri tutarlı olmalı.
- Oda ve cihaz detaylarında gerekli ID veya model referansı kullanılmalı.
- Giriş yapmamış kullanıcı korumalı sayfalara erişememeli.
- Auth durumu değiştiğinde yönlendirme doğru güncellenmeli.
- Login, Register, Forgot Password, Onboarding ve Welcome akışları karıştırılmamalı.
- Geri navigasyon davranışı kontrol edilmeli.
- Bottom Navigation yalnızca Ana Sayfa, Cihazlar ve Profil bölümlerini içermeli.
- Odalar ve Bildirimler ayrı route olarak açılmalı.
- Components Preview yalnızca geliştirme/önizleme amacıyla kullanılmalı; üretim navigasyonuna eklenmemeli.

## 5. Firebase Authentication

Kullanılacak işlemler:
- E-posta/şifre ile kayıt.
- E-posta/şifre ile giriş.
- Çıkış.
- Şifre sıfırlama e-postası.
- Oturum durumunu dinleme.

Kurallar:
- Firebase Authentication işlemleri repository/data katmanında yapılmalı.
- Kullanıcı e-postası Auth kaynağından alınmalı.
- Kayıt sonrasında kullanıcı oturumu açık kalmalı.
- Profil dokümanı oluşturulmadan uygulamanın ana akışına geçilmemeli.
- Auth hataları kullanıcıya anlaşılır mesajlarla gösterilmeli.
- Şifre veya hassas kimlik bilgileri loglanmamalı.
- Demo girişinde gerçek Firebase test hesabı kullanılmalı.
- Demo kullanıcı bilgileri uygulama kaynak koduna açık şekilde gömülmemeli.

Şifre doğrulaması:
- Minimum 8 karakter.
- Büyük harf.
- Rakam.
- Özel karakter.
- Şifre tekrarı ile eşleşme.

Bu kurallar hem arayüzde anlık gösterilmeli hem de kayıt işlemi öncesinde doğrulanmalıdır.

## 6. Cloud Firestore

Firestore veri işlemleri repository ve datasource sorumluluğunda olmalı.

Kurallar:
- Firestore çağrıları doğrudan widget veya Cubit içinde yapılmamalı.
- Kullanıcı verileri kullanıcı ID'si üzerinden ayrılmalı.
- Her veri modelinin açık `fromMap` / `toMap` veya eşdeğer dönüşüm yaklaşımı olmalı.
- Firestore'dan gelen veriler güvenli biçimde parse edilmeli.
- Eksik veya hatalı alanlar uygulamanın çökmesine neden olmamalı.
- Tarihler için tutarlı `Timestamp` / `DateTime` dönüşümü kullanılmalı.
- İhtiyaç olmayan alanlar Firestore'a yazılmamalı.
- Gereksiz gerçek zamanlı listener kullanılmamalı.
- Listener açılıyorsa uygun zamanda kapatılmalı.
- Liste ekranlarında gereksiz tekrar sorguları önlenmeli.
- Tek bir işlem için gereksiz birden fazla yazma yapılmamalı.

Güvenlik:
- Firestore Security Rules zorunludur.
- Kullanıcı yalnızca kendi verilerine erişebilmelidir.
- İstemci tarafındaki kontroller tek başına güvenlik sayılmaz.
- Remote Config ile güvenlik veya yetkilendirme yapılmaz.

## 7. Yerel Saklama

SharedPreferences şu amaçlarla kullanılabilir:
- Tema tercihi.
- Küçük kullanıcı arayüzü tercihleri.
- Profil fotoğrafı yerel dosya yolu gibi küçük metaveriler.

SharedPreferences büyük görsel veya uygulama veritabanı gibi kullanılmamalıdır.

Profil fotoğrafı:
- `image_picker` ile seçilir.
- Uygulamanın kalıcı yerel dosya alanına kopyalanır.
- Dosya yolu yerel tercihlerde tutulur.
- Fotoğraf Base64 olarak Firestore'a yazılmaz.
- Cloud Storage kullanılmaz.
- Dosya yoksa varsayılan avatar gösterilir.
- Uygulama silindiğinde veya cihaz değiştiğinde fotoğrafın kaybolabileceği kabul edilir.

## 8. UI, Tasarım Sistemi ve Tipografi

Nestora tasarımında bütünlük zorunludur.

Font:
- Birincil font Manrope.
- Aynı uygulama içerisinde gereksiz font ailesi karışıklığı oluşturma.
- Font ağırlıklarını hiyerarşik ve tutarlı kullan.

Önerilen tipografi:
- Sayfa başlığı: 24–28 px.
- Bölüm başlığı: 18–20 px.
- Kart başlığı: 15–16 px.
- Normal metin: 14 px.
- Açıklama: 12–13 px.
- Küçük etiket: 11–12 px.
- Buton: 14–15 px.

Tasarım renkleri:
- Ana açık arka plan: son onaylanacak sıcak nötr inci tonu.
- Kart: `#FFFFFF`.
- İkincil yüzey: `#F1F4EF`.
- Primary: `#344638`.
- Sage: `#DCE5D7`.
- Accent: `#E9C9A8`.
- Ana metin: `#292F29`.
- İkincil metin: `#777D73`.
- Border: `#E7EBE5`.
- Koyu arka plan: `#131713`.

Açık tema ana arka planı için `#F4F3EC` değerlendirme adayıdır; kullanıcı onayı olmadan kesin tasarım kararı olarak kabul edilmemelidir.

UI kuralları:
- Ortak renkler ve tipografi merkezi theme dosyalarından yönetilmeli.
- Aynı tür butonlarda ortak bileşen kullanılmalı.
- Kartların padding, radius ve gölge değerleri tutarlı olmalı.
- Gereksiz büyük kart ve ikonlardan kaçınılmalı.
- Başlıklar içerik alanını gereksiz işgal etmemeli.
- Metin taşmaları ve sıkışmaları giderilmeli.
- Sabit yükseklikler yalnızca gerçekten gerekli olduğunda kullanılmalı.
- `Expanded`, `Flexible`, `Wrap`, `LayoutBuilder` ve scroll yapıları ihtiyaca göre kullanılmalı.
- Her taşma sorununu `SingleChildScrollView` ekleyerek gizleme.
- Kullanıcı etkileşimlerinde uygun loading, disabled ve feedback durumları bulunmalı.
- Tıklanabilir alanlar yeterli büyüklükte olmalı.
- Animasyonlar kontrollü ve amaca hizmet eder biçimde kullanılmalı.

Animasyon ilkeleri:
- Toggle/kart etkileşimi: yaklaşık 200–300 ms.
- Slider geri bildirimi: yaklaşık 100–200 ms.
- Sayfa geçişleri: yaklaşık 250–350 ms.
- Gereksiz sürekli animasyon yapılmamalı.
- Reduced-motion tercihi dikkate alınmalı.
- Animasyonlar cihaz state'i ile senkronize olmalı.

## 9. Responsive ve Flutter Web

Nestora mobil öncelikli tasarlanır; ancak Flutter Web üzerinde de düzgün çalışmalıdır.

Kontrol edilecek genişlikler:
- 360–390 px mobil.
- 768 px tablet.
- 1024 px küçük masaüstü.
- 1440 px geniş masaüstü.

Kurallar:
- Ekran genişliğine göre uygun grid sütun sayısı seçilmeli.
- Geniş masaüstünde içerik ekranın tamamına kontrolsüz yayılmamalı.
- Uygun `maxWidth` ve hizalama kullanılmalı.
- Kartlar ve metinler üst üste binmemeli.
- Formlar geniş ekranda gereğinden fazla uzamamalı.
- Yatay taşma olmamalı.
- Klavye açıldığında form alanları erişilebilir kalmalı.
- Mouse ve touch etkileşimleri birlikte düşünülmeli.

## 10. Hata Yönetimi ve Kullanıcı Geri Bildirimi

- Hatalar kullanıcıya anlaşılır Türkçe mesajlarla sunulmalı.
- Teknik hata detayları kullanıcıya gösterilmemeli.
- Hatalar uygun biçimde loglanmalı.
- Başarılı işlemlerde Snackbar veya uygun görsel geri bildirim kullanılmalı.
- Silme gibi kritik işlemler onay istemeli.
- Loading sırasında tekrar tıklama ve yinelenen işlem engellenmeli.
- İnternet bağlantısı ve Firebase hataları ele alınmalı.
- Uygulama beklenmeyen durumda çökmek yerine anlamlı hata durumu göstermeli.

## 11. Firebase İzleme ve Analitik

- Firebase Crashlytics: uygulama hatalarını takip etmek için.
- Firebase Performance Monitoring: performans problemlerini izlemek için.
- Firebase Analytics: temel kullanım olaylarını takip etmek için.
- Firebase Remote Config: güvenlik değil, uzaktan yapılandırma amacıyla.

Kullanıcı gizliliğine dikkat edilmeli; şifre, token, özel profil bilgisi veya hassas veri analitik olaylarına eklenmemelidir.

## 12. Test ve Kalite Kontrolü

Her önemli özellikte uygun testler yazılmalıdır.

Unit test:
- Model dönüşümleri.
- Cubit state geçişleri.
- Doğrulama kuralları.
- Repository davranışları.

Widget test:
- Login/Register form doğrulaması.
- Buton etkileşimleri.
- Cihaz toggle ve slider davranışları.
- Tema değişimi.
- Hata ve loading durumları.

Integration test:
- Demo giriş akışı.
- Kayıt/giriş/çıkış.
- Oda oluşturma ve düzenleme.
- Cihaz ekleme ve kontrol etme.
- Bildirim okundu durumu.
- Tema tercihi kalıcılığı.

Kontrol komutları:

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Web üzerinde özellikle overflow, responsive düzen, font yüklenmesi ve navigasyon test edilmelidir.

## 13. Antigravity Çalışma Protokolü

1. Önce ilgili dosyaları oku.
2. Değişiklikten etkilenecek ekran ve bileşenleri belirle.
3. Değişiklik planını kısa biçimde açıkla.
4. Onaylanmış tasarım kararlarını koru.
5. Gereksiz dosya ve bağımlılık ekleme.
6. Değişiklikleri küçük, kontrol edilebilir adımlarla uygula.
7. İlgili testleri ve `flutter analyze` çalıştır.
8. Chrome ve mobil görünümü kontrol et.
9. Tamamlanan işleri ve bilinen eksikleri raporla.

Kullanıcı istemeden:
- Yeni teknoloji veya paket ekleme.
- Mimariyi kökten değiştirme.
- Firebase planını yükseltme.
- Cloud Functions veya Cloud Storage ekleme.
- Gerçek IoT entegrasyonuna girişme.
- Tasarım ekranlarını sadeleştirme veya atlama.
- Mock verileri gerçek veri gibi sunma.

## 14. Yasaklanan Yaklaşımlar

- Firebase işlemlerini widget içinde yapmak.
- Tüm state'i tek Cubit'e toplamak.
- Gereksiz UseCase sınıfları üretmek.
- Her widget için ayrı dosya açmak.
- Gereksiz manager/helper/service katmanları oluşturmak.
- Tek bir devasa Dart dosyasında tüm ekranları toplamak.
- Aynı veriyi farklı ekranlarda birbirinden bağımsız kopyalarla yönetmek.
- `setState` ile global uygulama state'ini yönetmek.
- Hataları boş `catch` bloklarıyla gizlemek.
- Kaynak koduna şifre, API anahtarı veya hassas bilgi yazmak.
- Tasarım sorunlarını yalnızca ekranı kaydırılabilir yaparak gizlemek.
- Gerçek sensör veya cihaz bağlantısı varmış gibi davranmak.