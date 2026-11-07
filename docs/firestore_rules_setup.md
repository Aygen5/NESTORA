# Cloud Firestore Güvenlik Kuralları (Security Rules) Kurulum Rehberi

Bu doküman, NESTORA projesi için hazırlanan `firestore.rules` dosyasının Firebase Console üzerinde nasıl yayınlanacağını açıklar.

---

## 1. Güvenlik Kuralları Neden Önemli?

NESTORA, **kullanıcı veri izolasyonu (User Data Isolation)** mimarisiyle tasarlanmıştır:
- Her kullanıcı sadece `users/{userId}` altındaki kendi profilini görebilir.
- Odaya, cihaza ve bildirimlere ait tüm alt koleksiyonlar (`users/{userId}/rooms`, `users/{userId}/devices`, `users/{userId}/notifications`) ilgili kullanıcının `request.auth.uid` kimliği ile korunur.
- Oturumu açılmamış yabancı kullanıcılar veya üçüncü partiler veri tabanına erişemez.
- `match /{document=**} { allow read, write: if false; }` kuralı ile tanımlanmamış her yol varsayılan olarak reddedilir (**Principle of Least Privilege**).

---

## 2. Firebase Console Üzerinden Yayınlama (Önerilen - 1 Dakika)

1. [Firebase Console](https://console.firebase.google.com/) sayfasına gidin.
2. **NESTORA** (`nestora-b6f6c`) projenizi seçin.
3. Sol menüden **Build > Firestore Database** sekmesine tıklayın.
4. Üst kısımdaki sekmelerden **Rules (Kurallar)** sekmesini açın.
5. Mevcut test modu kurallarını silin ve projenin kök dizinindeki `firestore.rules` dosyasının içeriğini yapıştırın:

```rules
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    match /users/{userId} {
      allow read, write: if isOwner(userId);

      match /rooms/{roomId} {
        allow read, write: if isOwner(userId);
      }

      match /devices/{deviceId} {
        allow read, write: if isOwner(userId);
      }

      match /notifications/{notificationId} {
        allow read, write: if isOwner(userId);
      }
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

6. Sağ üstteki **Publish (Yayınla)** butonuna basın.
7. Değişiklikler anında yürürlüğe girer.

---

## 3. Firebase CLI ile Yayınlama (Opsiyonel)

Terminal üzerinden tek komutla dağıtmak isterseniz:
```powershell
firebase deploy --only firestore:rules
```
*(Firebase CLI kurulu ve `firebase login` yapılmış olmalıdır).*
