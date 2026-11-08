# Nestora — Proje Tanımı ve Gereksinimleri

## 1. Projenin Amacı

Nestora, kullanıcıların kendi sanal akıllı evlerini oluşturup yönetebildiği, odalarını düzenleyebildiği ve sanal akıllı cihazlarını tek bir mobil uygulama üzerinden kontrol edebildiği bir Flutter uygulamasıdır.

Uygulamanın temel amacı; akıllı ev yönetimi deneyimini modern, anlaşılır, estetik ve kolay kullanılabilir bir arayüzle sunmaktır.

Kullanıcılar uygulama üzerinden:
- Kendi evlerini ve odalarını oluşturabilir.
- Odalara sanal akıllı cihazlar ekleyebilir.
- Lambaların parlaklığını ve ışık rengini değiştirebilir.
- Klimaların çalışma durumunu, hedef sıcaklığını ve modunu ayarlayabilir.
- Akıllı priz gibi cihazları açıp kapatabilir.
- Cihaz ve oda durumlarını takip edebilir.
- Hızlı senaryolarla birden fazla cihazın durumunu değiştirebilir.
- Bildirimlerini ve hesap ayarlarını yönetebilir.

**Önemli ürün kararı:** Nestora gerçek IoT donanımlarına bağlanan bir uygulama değildir. Tuya, Smart Life, Home Assistant, MQTT, ESP32 veya fiziksel sensör entegrasyonu yapılmayacaktır. Cihazlar sanal olarak temsil edilecek; kullanıcı etkileşimleri sonucunda değişen durumlar uygulama içerisinde saklanacaktır.

Sıcaklık, nem, enerji tüketimi, güç ve bağlantı durumu gibi değerler gerçek sensör ölçümü değildir. Bunlar sanal ortamın örnek veya uygulama tarafından yönetilen göstergeleridir. Kullanıcıya gerçek ölçüm izlenimi verilmemelidir.

## 2. Platform ve Teknolojiler

- **Platform:** Flutter / Dart
- **Kimlik doğrulama:** Firebase Authentication
- **Veri saklama:** Cloud Firestore
- **Durum yönetimi:** Cubit (`flutter_bloc`)
- **Navigasyon:** GoRouter
- **Yerel tercihler:** SharedPreferences
- **Profil fotoğrafı:** `image_picker` ile seçilen görselin uygulamanın yerel dosya alanında saklanması
- **Hata takibi:** Firebase Crashlytics
- **Performans takibi:** Firebase Performance Monitoring
- **Kullanım analizi:** Firebase Analytics
- **Uzak yapılandırma:** Firebase Remote Config

Firebase projesi **Spark (ücretsiz) planında** tutulacaktır.

Cloud Functions ve Cloud Storage kullanılmayacaktır. Firebase planını Blaze'e yükseltmeyi gerektiren bir çözüm uygulanmayacaktır.

## 3. Kullanıcı Tipleri ve Ev Yapısı

MVP'de temel kullanıcı, kendi evini yöneten ev sahibidir.

Kullanıcı hesabı kendi sanal evine ve bu eve bağlı odalara, cihazlara ve tercihlere sahip olacaktır.

İlk sürümde aile üyeleriyle paylaşılan erişim ve çok kullanıcılı ev yönetimi görsel olarak gösterilebilir; ancak gerçek yetkilendirme ve paylaşım akışı ayrıca kapsamlandırılmadan tamamlanmış özellik gibi sunulmamalıdır.

## 4. Kimlik Doğrulama ve İlk Kullanım Akışı

### 4.1 Splash Screen

- Nestora logosu ve amblemi gösterilir.
- Koyu çam/fildişi tonlu arka plan ve sıcak glow efekti kullanılır.
- Logo ScaleTransition ve FadeTransition ile belirir.
- Tasarımdaki mevcut animasyon korunur.
- Açılış süresi yaklaşık 1,8 saniyedir; gereksiz uzatılmamalıdır.
- Reduced-motion tercihine saygı gösterilmelidir.
- Kullanıcının oturum durumu kontrol edilerek doğru akışa geçilir.

### 4.2 Onboarding

- Kullanıcıya Nestora'nın sunduğu deneyimi tanıtır.
- İzometrik akıllı ev görseli kullanılır.
- "Evinizi Kolayca Yönetin" mesajı öne çıkar.
- Kaydırma veya başlatma etkileşimiyle Welcome ekranına geçilir.

### 4.3 Welcome

- Nestora logosu ve yaşam alanı kimliği gösterilir.
- Akıllı ev görseli, kısa açıklama ve fayda kartları bulunur.
- "Hemen Başla" kullanıcıyı kayıt/giriş akışına yönlendirir.
- "Giriş Yap" mevcut hesabı olan kullanıcıyı Login ekranına götürür.

Kimlik doğrulaması yapılmamış kullanıcı doğrudan korumalı Dashboard ekranına alınmamalıdır.

### 4.4 Login

- E-posta ve şifre ile giriş.
- E-posta biçimi ve boş alan doğrulaması.
- Şifreyi göster/gizle.
- "Beni Hatırla" tercihi.
- Şifremi Unuttum bağlantısı.
- Kayıt ekranına geçiş.
- Firebase Authentication ile gerçek giriş.

### 4.5 Register

- Ad Soyad, e-posta, şifre ve şifre tekrarı.
- E-posta biçimi kontrolü.
- Şifrelerin eşleşmesi.
- Kullanım koşulları onayı.
- Anlık şifre güvenliği kontrolü:
  - En az 8 karakter.
  - En az bir büyük harf.
  - En az bir rakam.
  - En az bir özel karakter.
- Firebase Authentication üzerinde gerçek hesap oluşturma.
- Kayıt başarılı olduğunda kullanıcının oturumu açık kalır.
- Kullanıcıya ait Firestore profil dokümanı oluşturulur.
- Profil oluşturma tamamlanınca Dashboard'a geçilir.

Şifre kuralları arayüzde gösterilmekle kalmamalı, kayıt işleminden önce de doğrulanmalıdır.

### 4.6 Forgot Password

- E-posta adresi alınır.
- Firebase Authentication `sendPasswordResetEmail()` kullanılır.
- Başarılı veya başarısız işlem kullanıcıya açıkça bildirilir.
- Giriş ekranına dönüş bağlantısı bulunur.

### 4.7 Hızlı Demo ile Giriş Yap

Uygulamanın test edilmesini kolaylaştırmak için Login ekranında "Hızlı Demo ile Giriş Yap" seçeneği bulunmalıdır.

- Demo için Firebase Authentication üzerinde gerçek bir test hesabı kullanılmalıdır.
- Demo girişi sahte bir kullanıcı nesnesi oluşturarak yapılmamalıdır.
- Demo hesabı için Firestore üzerinde gerekli başlangıç profil ve ev verileri bulunmalıdır.
- Kullanıcı normal oturum açmış gibi uygulamayı deneyebilmelidir.
- Demo hesabının e-posta ve şifresi kaynak koduna açık biçimde yazılmamalıdır. Güvenli yapılandırma yaklaşımı kullanılmalıdır.
- Demo hesabı oluşturma ve başlangıç verisi hazırlama süreci belgelenmelidir.

## 5. Ana Uygulama Ekranları

Ürün kapsamında 16 temel ekran vardır. Components Preview ekranı ise geliştirme ve tasarım kontrolü için kullanılan yardımcı bir ekrandır; ürünün 16 ekranlık kullanıcı akışına dahil değildir.

### 5.1 Dashboard — Ana Sayfa

Kullanıcının akıllı evini genel olarak yönettiği merkezdir.

Bileşenler:
- Nestora logo başlığı.
- Bildirim zili ve okunmamış bildirim göstergesi.
- Profil avatarı.
- Ev adı ve karşılama mesajı içeren hero alanı.
- Enerji tüketimi özeti ve hedef göstergesi.
- Hızlı senaryo kartları.
- Odalar yatay karuseli.
- Aktif cihazların kompakt kartları.
- Lamba, klima ve priz gibi cihazların hızlı kontrolü.

Etkileşimler:
- Cihaz açma/kapatma.
- Oda detayına geçiş.
- Cihaz kontrol ekranına geçiş.
- Senaryo seçimi.
- Bildirimlere ve profile erişim.

Enerji değerleri fiziksel ölçüm değildir. Uygulama tarafından üretilen veya saklanan sanal göstergelerdir.

### 5.2 Rooms — Odalarım

- Kullanıcının evindeki odalar listelenir.
- İki sütunlu grid düzeni kullanılır.
- Oda adı, simgesi ve bağlı cihaz sayısı gösterilir.
- Sıcaklık gibi sanal ortam değerleri gösterilebilir.
- Oda arama ve filtreleme yapılabilir.
- Yeni oda ekleme ve mevcut odayı düzenleme mümkündür.
- Oda seçilince Room Detail ekranına gidilir.

### 5.3 Room Detail — Oda Detayı

- Seçilen odanın adı ve simgesi.
- Odaya bağlı cihazlar.
- Sanal sıcaklık, nem ve hava kalitesi göstergeleri.
- Cihazların hızlı kontrolü.
- Odaya özel toplu aksiyonlar.
- Oda düzenleme.
- Odaya cihaz ekleme.

Bir odadaki cihazların durumu, uygulamanın ortak cihaz verisiyle tutarlı olmalıdır.

### 5.4 Add/Edit Room — Oda Ekle ve Düzenle

- Oda adı.
- Oda simgesi seçimi.
- Varsayılan hedef sıcaklık gibi oda tercihleri.
- Oda oluşturma ve güncelleme.
- Oda silme ve onay diyaloğu.

Silme işleminde odaya bağlı cihazların nasıl ele alınacağı açıkça belirlenmelidir. İlişkili cihazlar sessizce kaybedilmemelidir.

### 5.5 Devices — Cihazlarım

- Tüm cihazların listesi.
- Kategori filtreleri: Tümü, Aydınlatma, İklimlendirme, Güvenlik, Prizler.
- Cihaz adı ve türü.
- Bağlı olduğu oda.
- Açık/kapalı ve sanal çevrim içi durumu.
- Sanal güç tüketimi göstergesi.
- Cihaz ekleme.
- Cihaz kartından hızlı açma/kapatma.
- Detaylı kontrol ekranına geçiş.

### 5.6 Lamp Control — Lamba Kontrolü

- Lambanın açık/kapalı durumu.
- Görsel lamba illüstrasyonu ve glow efekti.
- Parlaklık yüzdesi.
- Parlaklık slider'ı.
- Işık rengi veya renk sıcaklığı.
- Hazır atmosfer modları: Okuma, Dinlenme, Konsantrasyon, Gece Lambası.
- Zamanlayıcı arayüzü.

Davranışlar:
- Başlangıç parlaklığı %72 olabilir.
- Slider değiştikçe parlaklık ve glow etkisi değişir.
- Renk seçimi ışık efektinin rengini değiştirir.
- Lamba kapatıldığında glow söner.
- Parlaklık, renk ve açık/kapalı bilgisi aynı cihaz durumunda saklanır.

### 5.7 Climate Control — Klima Kontrolü

- Termostat görünümü.
- Hedef sıcaklık.
- Seçili çalışma modu.
- Fan hızı.
- Sanal ortam sıcaklığı ve nem göstergeleri.

Davranışlar:
- Hedef sıcaklık + ve - ile 0,5°C adımlarla değiştirilebilir.
- Sıcaklık değeri cihazın hedef değeridir; ortam sıcaklığıyla karıştırılmamalıdır.
- Soğutma, Isıtma, Otomatik ve Fan gibi desteklenen modlar gösterilebilir.
- Fan hızı Düşük, Orta, Yüksek ve Otomatik olabilir.
- Fan animasyonu hız ayarına göre değişebilir.
- Klima kapalıysa çalışma animasyonu durur.

Sanal cihazın desteklemediği özellikler varmış gibi gösterilmemelidir.

### 5.8 Add/Edit Device — Cihaz Ekle ve Düzenle

- Cihaz türü seçimi.
- Cihaz adı.
- Oda ataması.
- Cihaz ekleme ve düzenleme.
- Cihaz silme.
- Kaydetme ve doğrulama.

Gerçek ağ taraması veya fiziksel cihaz eşleştirme yapılmayacaktır. "Cihaz ara" benzeri arayüzler yalnızca sanal cihaz oluşturma akışını ifade etmelidir.

### 5.9 Notifications — Bildirimler

- Bildirimlerin tarih gruplarıyla listelenmesi.
- Okunmuş/okunmamış durumu.
- Bildirime tıklayınca ilgili oda veya cihaza gitme.
- Tümünü okundu işaretleme.
- Bildirim silme/temizleme.

Bildirim örnekleri:
- Cihaz durum değişiklikleri.
- Sanal güvenlik uyarıları.
- Enerji özeti.
- Cihaz hedef sıcaklığına ulaştı bilgisi.

Bunlar fiziksel sensör veya gerçek enerji ölçümüne dayalı bildirimler olarak sunulmamalıdır.

### 5.10 Profile & Settings — Profil ve Ayarlar

- Kullanıcı adı, e-posta, avatar ve rol.
- Ev adı yönetimi.
- Bildirim tercihleri.
- Açık/Koyu/Sistem tema seçimi.
- Çıkış yapma.

Profil e-postası Firebase Authentication üzerinden alınmalıdır.

Profil fotoğrafı:
- Kullanıcı galeriden fotoğraf seçebilir.
- Fotoğraf uygulamanın yerel dosya alanında saklanır.
- Dosya yolu SharedPreferences gibi yerel bir tercih alanında tutulabilir.
- Fotoğraf Base64 olarak Firestore'a yazılmaz.
- Cloud Storage kullanılmaz.
- Uygulama silinir veya cihaz değişirse fotoğrafın taşınmayacağı kabul edilir.

Tema:
- Varsayılan tema Açık Mod.
- Açık, Koyu ve Sistem seçenekleri.
- Seçim SharedPreferences ile kalıcı tutulur.
- Tüm ekranlar aynı tema sistemini kullanır.

### 5.11 Components Preview — Bileşen Önizleme

Bu ekran geliştirme ve tasarım doğrulama amacıyla kullanılacaktır.

- Buton çeşitleri.
- Kartlar.
- Input alanları.
- Switch ve toggle'lar.
- Dialog ve bottom sheet.
- Snackbar.
- Durum rozetleri.
- Renk ve tipografi örnekleri.

Bu ekran son kullanıcı navigasyonunda yer almamalıdır.

## 6. Navigasyon ve Uygulama Akışı

Bottom Navigation yalnızca üç ana bölüm içermelidir:
1. Ana Sayfa
2. Cihazlar
3. Profil

Odalar ve Bildirimler ayrı ekranlardır; Bottom Navigation öğesi değildir. Dashboard veya ilgili bağlantılardan açılırlar.

Diğer ekranlar GoRouter ile yönetilir.

Kimlik doğrulama yapılmamış kullanıcı korumalı uygulama sayfalarına erişememelidir. Giriş yapmış kullanıcı Splash/Welcome/Login akışına tekrar yönlendirilmemelidir.

Geri navigasyon ve deep-link davranışları tutarlı olmalıdır.

## 7. Sanal Ev ve Cihaz Verileri

Uygulama verileri kullanıcıya ait olmalıdır.

Temel veri grupları:
- User profile
- Home
- Room
- Device
- Notification
- Scenario / automation preference
- User preferences

Sanal cihaz durumlarına örnek:
- `isOn`
- `brightness`
- `color`
- `targetTemperature`
- `mode`
- `fanSpeed`
- `roomId`

Cihaz türüne göre kullanılmayan alanlar zorunlu tutulmamalıdır.

Senaryo örnekleri:
- Evdeyim
- Gündüz
- Gece Modu
- Dışarıda

Senaryolar yalnızca önceden tanımlanmış sanal cihaz durumlarını değiştirmelidir. Gerçek fiziksel cihazları tetiklememelidir.

## 8. Tasarım Sistemi

Nestora'nın tasarım dili:
- Warm minimal.
- Modern, premium ve doğal.
- Ferah ve güven veren.
- Çocuksu veya kurumsal değil.
- Gereksiz glassmorphism, neon, yoğun gradient ve kalabalık bileşenler yok.

Renkler:
- Ana arka plan için sıcak, nötr inci beyazı yönü: `#F4F3EC` değerlendirme adayıdır.
- Kart yüzeyi: `#FFFFFF`.
- İkincil yüzey: `#F1F4EF`.
- Primary green: `#344638`.
- Sage: `#DCE5D7`.
- Accent: `#E9C9A8`.
- Ana metin: `#292F29`.
- İkincil metin: `#777D73`.
- Border: `#E7EBE5`.
- Dark background: mevcut tasarımdaki `#131713` yönü.

Not: Açık tema arka planının son kararı tasarım kontrolünden sonra verilecektir. `#FDF5E6` mevcut tasarımda kullanılmıştır ancak sarı/krem etkisi nedeniyle son tasarım kararı olarak kabul edilmemelidir.

Tipografi:
- Birincil font: Manrope.
- Tek font ailesi kullanılmalı.
- Sayfa başlığı: yaklaşık 24–28 px.
- Bölüm başlığı: 18–20 px.
- Kart başlığı: 15–16 px.
- Normal metin: 14 px.
- Yardımcı metin: 12–13 px.
- Küçük etiket: 11–12 px.
- Aşırı büyük başlıklar, ikonlar ve kartlar kullanılmamalı.

Responsive tasarım:
- 360–390 px mobil.
- 768 px tablet.
- 1024 px küçük masaüstü.
- 1440 px geniş masaüstü.
- İçerik sınırsız genişlememeli.
- Kartlar ve metinler taşmamalı veya üst üste binmemeli.
- Web görünümünde uygun max-width ve breakpoint düzeni kullanılmalı.

## 9. Güvenlik ve Veri Sınırları

- Firebase Authentication gerçek kimlik doğrulama kaynağıdır.
- Firestore Security Rules kullanıcıların yalnızca kendi verilerine erişmesini sağlamalıdır.
- Kullanıcı ID'si ve sahiplik ilişkisi sunucu tarafındaki güvenlik kurallarıyla doğrulanmalıdır.
- Remote Config güvenlik mekanizması değildir.
- Gizli bilgiler kaynak koduna yazılmamalıdır.
- Demo hesabı bilgileri istemci kaynak koduna gömülmemelidir.
- Firestore'da gereksiz sık okuma/yazma yapılmamalıdır.

## 10. Firebase Maliyet ve Kota İlkeleri

Firebase Spark planı korunacaktır.

- Cloud Functions kullanılmayacak.
- Cloud Storage kullanılmayacak.
- Gereksiz gerçek zamanlı listener açılmayacak.
- Ekran başına tekrar tekrar aynı veriler okunmayacak.
- Uygun yerlerde tek seferlik okuma ve yerel state güncellemesi tercih edilecek.
- Sık değişen sanal cihaz state'leri yalnızca gerekli olduğunda Firestore'a yazılacak.
- Aynı değişiklik için gereksiz ardışık Firestore yazmaları yapılmayacak.
- Liste ekranlarında gereksiz tüm koleksiyonu indirme yapılmayacak.

## 11. Uygulama Geliştirme Sırası

1. [x] Mevcut Flutter projesinin ve 16 ekranın incelenmesi.
2. [x] Mevcut tasarımın, widget'ların ve navigasyonun korunması.
3. [x] Tema, tipografi ve responsive düzenin iyileştirilmesi.
4. [ ] Auth ve ilk kullanım akışının tamamlanması.
5. [ ] Veri modelleri ve Firestore yapısının oluşturulması.
6. [ ] Oda ve cihaz CRUD işlemleri.
7. [ ] Sanal cihaz kontrol state'leri.
8. [ ] Dashboard ve senaryo etkileşimleri.
9. [ ] Bildirimler ve profil ayarları.
10. [ ] Hata yönetimi, güvenlik, testler ve performans kontrolü.

Her aşama sonunda çalışan uygulama test edilmelidir. Büyük değişiklikler tek seferde ve kontrolsüz biçimde yapılmamalıdır.

## 12. Kabul Kriterleri

- 16 ürün ekranı tasarım ve işlev açısından tamamlanmış olmalı.
- Components Preview ürün navigasyonundan ayrı tutulmalı.
- Login, Register, Forgot Password ve Demo Login çalışmalı.
- Kullanıcı verileri birbirinden izole olmalı.
- Oda ve cihaz ekleme, düzenleme ve silme çalışmalı.
- Cihaz kontrolleri tüm ekranlarda aynı state'i yansıtmalı.
- Tema tercihi kalıcı olmalı.
- Profil fotoğrafı yerel olarak korunmalı.
- Bottom Navigation yalnızca üç ana bölüm içermeli.
- Mobil, tablet ve web genişliklerinde taşma ve çakışma olmamalı.
- Firestore Security Rules uygulanmış olmalı.
- Spark planı sınırları aşılmamalı.
- `flutter analyze` hatasız olmalı.
- Kritik iş akışları test edilmiş olmalı.