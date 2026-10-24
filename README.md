# Güven Yüzüğü (com.mavera)

Hareket sensörlü yüzükten Bluetooth ile gelen veriyi izleyen; hareket aniden kesilirse önce kullanıcıya soran, cevap gelmezse Telegram grubuna acil durum mesajı ve canlı konum gönderen Flutter uygulaması (Android + iOS).

## Derleme (Windows)

Android Gradle eklentisi ve Dart analiz sunucusu, yolunda Türkçe karakter bulunan klasörlerde (`Masaüstü`) çalışmıyor. Kaynak burada durur, derleme ASCII bir kopyada yapılır:

```powershell
robocopy "<bu klasör>" C:\mavera_build /MIR /XD build .dart_tool .gradle .idea Pods .cxx /XF local.properties *.iml
cd C:\mavera_build
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release   # → build\app\outputs\bundle\release\app-release.aab
flutter build apk --release         # doğrudan kurulum için
```

İmza: `android/key.properties` + `android/upload-keystore.jks`. **Bu iki dosyayı yedekleyin**; kaybolursa aynı uygulamaya güncelleme imzalanamaz. Git'e eklenmezler (`.gitignore`).

## Mimari

- `lib/core/` — saf Dart: `Monitor` (tek karar noktası), `RingProtocol`, `LineBuffer`, `MessageComposer`, `SleepSchedule`, `HealthCheck`.
- `lib/services/` — eklenti arkasındaki arayüzler ve uygulamaları; `AlarmDispatcher`; hepsini bağlayan `AppCore`.
- `lib/data/` — ayarlar (shared_preferences), token (secure storage), kişiler ve olaylar (sqflite), bekleyen alarm (atomik JSON).
- `lib/ui/` — ekranlar; yalnızca provider'ları izler, `AppCore`'a komut verir.
- Android yerel: `MaveraApplication.kt` (önbellekli motor), `SmsPlugin.kt`, `SystemPlugin.kt`.
- iOS yerel: `AppDelegate.swift` (`BackgroundTaskPlugin` dahil), `Info.plist`.

## KARAR notları

| Konu | Karar |
|---|---|
| Paket adı | İstek üzerine `com.mavera` (promptta `com.guvenyuzuk.app`). Görünen ad "Güven Yüzüğü". |
| R1/R2 (Android arka plan) | Plan A'nın güçlendirilmiş hâli: ana Flutter motoru `MaveraApplication`'da oluşturulup önbelleğe alınır, aktiviteyle yok edilmez. Ön plan servisi süreci canlı tuttukça çekirdek ana isolate'te çalışır; açılışta süreç başlayınca `main()` ekransız çalışır. TaskHandler isolate'i kullanılmaz. |
| Arka plan konumu (Android) | `ACCESS_BACKGROUND_LOCATION` yok (Play arka plan konum beyanı/videosu gerekmesin). Arka planda konum, `location` tipli ön plan servisi + "kullanılırken" izniyle alınır. |
| Ön plan servis tipi | `location` tipi yalnızca uygulama ön plandayken ve konum izni varken eklenir. Açılışta (arka planda) servis yalnızca `connectedDevice` ile başlar; uygulama ilk açıldığında `ensureForegroundCapabilities` servisi konum tipiyle yeniden başlatır. O zamana kadar alarm konumsuz gider. |
| Göze çarpan açıklama | Konum ve SMS izinleri istenmeden önce `disclosure_dialog.dart` penceresi gösterilir (Google Play şartı). |
| iOS yaşam döngüsü (R3) | UIScene kapatıldı, klasik `AppDelegate`: Bluetooth geri yüklemesiyle arka planda başlatılınca da Flutter motoru `didFinishLaunching` sırasında yüklenir. İleride Apple UIScene'i zorunlu kılarsa ekransız motor ayrıca kurulmalı. |
| "Koruma durdu" (iOS) | Yalnızca `AppDelegate.applicationWillTerminate` zamanlar (kimlik "302"); açılışta Dart iptal eder. |
| Ön uyarıda hareket | İptal sebebi değildir; yalnızca "Hareket algılandı" ipucu gösterilir. |
| Geciken deadline (iOS) | Deadline geçmiş ve iptal edilmemişse alarm her zaman gönderilir. |
| Konum bekleme | En fazla 8 sn; gelmezse metin konumsuz gider, konum gelince canlı konum ayrıca gönderilir. |
| Teslim edilmemiş alarm kapatılırsa | Gruba hiçbir şey gitmez (grup alarmı hiç görmedi). |
| SMS | `SEND_SMS` Play Store dışı dağıtım için; Play'e çıkılacaksa kaldırılmalı. SMS metinleri ASCII (GSM-7). `smsAttempted` bayrağı "tam bir kez" garantisi verir. |
| LineBuffer taşması | 256 baytı aşan satır bir sonraki `\n`'e kadar atılır. |
| HB içindeki SOS/TRM bayrakları | Yok sayılır; olaylar ayrı `SOS`/`TRM` satırıyla gelir (çift alarm olmasın). |
| BLE lisansı | flutter_blue_plus 2.x lisans parametresi: `License.nonprofit` (kişisel kullanım). |
| Secure storage | v11'de `encryptedSharedPreferences` kalktı; varsayılan Android seçenekleri Keystore + AES-GCM. |
| BackgroundTaskPlugin | Xcode projesine elle dosya eklemeden derlensin diye `AppDelegate.swift` içinde. |
| Simüle yüzük | Yalnızca debug derlemede görünür (Yardım ve tanılama). |

## Gerçek cihazda doğrulanacaklar

**R1 – Android, uygulama kaydırılınca:** Kurulumu bitir, ana ekranda "Koruma açık" görün. Son uygulamalardan kaydırarak kapat. Bildirim çubuğunda "Güven Yüzüğü · Koruma açık" kalmalı. Yüzüğü 3+ dk masada bırak → ön uyarı bildirimi tam ekran gelmeli. Gelmezse Plan B: çekirdeği `TaskHandler` isolate'ine taşımak.

**R2 – Android, yeniden başlatma:** Telefonu yeniden başlat, kilidi açma. 1–2 dk içinde "Koruma açık" bildirimi görünmeli; yüzük bağlanmalı (Geçmiş'te "Yüzük bağlandı").

**R3 – iOS (Mac + iPhone):** `flutter build ios`, Xcode'da Signing & Capabilities → Background Modes: *Uses Bluetooth LE accessories*, *Location updates*. Ekran kilitliyken 1 saat sinyaller kesintisiz gelmeli (Geçmiş'te boşluk yok). Gelmezse Plan B: `CBCentralManager` (restore id `guvenyuzuk.central`) kullanan Swift köprüsü.

Kabul listesinin tamamı: prompt Bölüm 16.

## iOS kurulumu (Mac'te, sırayla)

1. `flutter pub get`, ardından `cd ios && pod install && open Runner.xcworkspace`.
2. **İzinler:** `ios/Podfile` Bluetooth, konum ve bildirim izinlerini `permission_handler` için etkinleştirir. Proje Swift Package Manager ile derlenirse eklenti bunları Info.plist'ten kendisi bulur; ancak **Xcode'un Run düğmesiyle** derlerken önce `launchctl setenv PERMISSION_HANDLER_INFO_PLIST "$(pwd)/Runner/Info.plist"` çalıştırın (terminalden `flutter run` / `flutter build ios` ile gerek yok). Bu yapılmazsa kurulumdaki İzinler adımı geçilemez.
3. **Signing & Capabilities:** Team seçin. `Runner.entitlements` içinde *Time Sensitive Notifications* hazır; listede görünmüyorsa "+ Capability" ile ekleyin. Ücretsiz hesap bu yeteneği imzalayamazsa entitlements dosyasındaki anahtarı silin (ön uyarı Odak modlarında sessiz kalabilir).
4. Background Modes listesinde *Uses Bluetooth LE accessories* ve *Location updates* işaretli olmalı (Info.plist'te tanımlı).
5. iPhone'a kurun, kurulumu bitirin; İzinler adımında konum için "Her Zaman" verin.
6. **R3 testi:** Ekran kilitli 1 saat → Geçmiş'te boşluk olmamalı. Ardından çok sayıda uygulama açarak iOS'un uygulamayı bellekten atmasını sağlayın; yüzük bağlıyken birkaç dakika içinde Geçmiş'e yeni olay düşmeli. Olmazsa Plan B: `CBCentralManager` (restore id `guvenyuzuk.central`) kullanan Swift köprüsü.
7. Uygulamayı uygulama değiştiricide kaydırarak kapatın → 2 sn sonra "Koruma durdu" bildirimi gelmeli.

Ücretsiz Apple ID ile 7 günde bir yeniden yükleme gerekir; ücretli hesapla TestFlight. Critical Alerts yetkisi Apple'dan gelince `kCriticalAlertsEntitled = true` (`local_notification_service.dart`) ve `com.apple.developer.usernotifications.critical-alerts` entitlement'ı eklenir.
