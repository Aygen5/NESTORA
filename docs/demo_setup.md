# Nestora — Hızlı Demo Hesabı ve Başlangıç Verisi Kurulum Kılavuzu

Bu belge, Nestora akıllı ev uygulamasının **"Hızlı Demo ile Giriş Yap"** özelliği için Firebase Authentication, Cloud Firestore ve Firebase Remote Config yapılandırmasını açıklamaktadır.

---

## 1. Amaç ve İşleyiş

Nestora'nın test süreçlerini ve jüri/kullanıcı incelemelerini kolaylaştırmak amacıyla Login ekranında tek dokunuşla çalışan bir **Hızlı Demo** akışı sunulmaktadır.
- Demo girişi sahte (mock) kullanıcı nesnesi ile değil, Firebase Authentication üzerinde tanımlı gerçek bir test oturumu ile yapılır.
- Oturum açıldığında kullanıcının Cloud Firestore üzerinde kendisine ait hazır odaları, sanal cihazları ve bildirimleri (`users/{uid}`) bulunur.
- Spark (ücretsiz) plan sınırları korunur; Cloud Storage veya Cloud Functions gerektirmez.

---

## 2. Firebase Authentication Kurulumu

Demo kullanıcısı Firebase Authentication üzerinden şu bilgilerle çalışacak şekilde ayarlanmıştır:
- **E-posta:** `demo@nestora.app`
- **Şifre:** `DemoUser2026!`
- **Görünen Ad:** `Aygen Yıldırım`

> [!TIP]
> **Otomatik Test Hesabı Desteği:**
> Uygulamadaki `AuthRemoteDataSourceImpl`, demo hesabı Firebase Console'da henüz açılmamışsa dahi ilk demo girişinde hesabı otomatik olarak oluşturur ve profil dokümanını başlatır. İstenirse Firebase Console -> Authentication -> Users sekmesinden bu hesap manuel olarak da eklenebilir.

---

## 3. Cloud Firestore Seed Veri Şeması

Kullanıcı demo girişi yaptığında `FirestoreSeedService` kullanıcının odalarını kontrol eder. Eğer koleksiyon boşsa, aşağıdaki hazır akıllı ev ekosistemini **tek bir atomik batch yazımıyla** başlatır:

### A. Kullanıcı Profili (`users/{uid}`)
```json
{
  "displayName": "Aygen Yıldırım",
  "homeName": "Aygen'in Evi",
  "email": "demo@nestora.app",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp",
  "preferences": {
    "notificationsEnabled": true,
    "ecoModeEnabled": true,
    "temperatureUnit": "C"
  }
}
```

### B. Odalar (`users/{uid}/rooms/{roomId}`)
| ID | Oda Adı | İkon | Hedef Sıcaklık | Nem |
|---|---|---|---|---|
| `room-1` | Salon | `chair` | 22.4°C | %48 |
| `room-2` | Yatak Odası | `bed` | 24.0°C | %50 |
| `room-3` | Mutfak | `restaurant` | 21.8°C | %52 |
| `room-4` | Çalışma Odası | `desk` | 23.1°C | %45 |

### C. Sanal Cihazlar (`users/{uid}/devices/{deviceId}`)
| ID | Cihaz Adı | Oda | Tip | Durum | Değerler | Güç (W) |
|---|---|---|---|---|---|---|
| `dev-1` | Salon Lambası | Salon (`room-1`) | `bulb` | Açık | Parlaklık: %72, Renk: `#E1C1A0` | 12 W |
| `dev-2` | Televizyon | Salon (`room-1`) | `tv` | Kapalı | - | 0 W |
| `dev-3` | Akıllı Priz | Salon (`room-1`) | `plug` | Açık | - | 120 W |
| `dev-4` | Masa Lambası | Çalışma Odası (`room-4`) | `bulb` | Açık | Parlaklık: %85, Renk: `#EAF0E6` | 9 W |
| `dev-5` | Yatak Odası Kliması | Yatak Odası (`room-2`) | `ac` | Açık | Hedef: 24°C, Mod: `auto`, Fan: `mid` | 850 W |
| `dev-6` | Komodin Lambası | Yatak Odası (`room-2`) | `bulb` | Açık | Parlaklık: %50, Renk: `#FEDDBB` | 6 W |
| `dev-7` | Kahve Makinesi | Mutfak (`room-3`) | `plug` | Kapalı | - | 0 W |

### D. Bildirimler (`users/{uid}/notifications/{notificationId}`)
1. **Salon Lambası açıldı:** "Salon ortamında parlaklık %72 olarak devreye girdi." (Okunmamış)
2. **Masa Lambası parlaklığı güncellendi:** "Çalışma Odası için odak aydınlatması güncellendi." (Okunmamış)
3. **Yatak Odası kliması açıldı:** "Hedef sıcaklık 24°C olarak ayarlandı." (Okunmuş)

---

## 4. Firebase Remote Config & Güvenli Yapılandırma

Demo kimlik bilgileri istemci koduna açık ve statik olarak bağımlı kalmamak üzere tasarlanmıştır:
1. **Firebase Remote Config:**
   - `demo_account_email`: İstenen demo e-posta adresi.
   - `demo_account_password`: İstenen demo şifresi.
   Firebase Console -> Remote Config bölümünden bu değerler değiştirildiğinde uygulama yeniden derlenmeden yeni demo hesabı devreye girer.
2. **Derleme Anı Ortam Değişkenleri (`--dart-define`):**
   ```bash
   flutter run --dart-define=DEMO_EMAIL=demo@nestora.app --dart-define=DEMO_PASSWORD=GuvenliSifre2026!
   ```
3. **Varsayılan Fallback:** Remote Config veya `--dart-define` sağlanmadığında `DemoConfigService` yerleşik güvenli varsayılanları kullanarak geliştiricinin kesintisiz test yapabilmesini sağlar.
