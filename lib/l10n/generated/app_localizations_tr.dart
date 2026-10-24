// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Güven Yüzüğü';

  @override
  String get commonContinue => 'Devam';

  @override
  String get commonCancel => 'Vazgeç';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonOpenSettings => 'Ayarları aç';

  @override
  String get commonAllow => 'İzin ver';

  @override
  String get commonDone => 'Yaptım';

  @override
  String get commonSkip => 'Atla';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonAll => 'Tümü';

  @override
  String get commonRecommended => 'önerilen';

  @override
  String commonRecommendedValue(String value) {
    return 'önerilen: $value';
  }

  @override
  String get commonResetRecommended => 'Önerilene dön';

  @override
  String commonSeconds(int n) {
    return '$n sn';
  }

  @override
  String commonMinutes(int n) {
    return '$n dk';
  }

  @override
  String get commonDecrease => 'Azalt';

  @override
  String get commonIncrease => 'Artır';

  @override
  String get shieldProtected => 'Koruma açık';

  @override
  String get shieldAttention => 'Dikkat';

  @override
  String get shieldUnprotected => 'Koruma yok';

  @override
  String shieldSemantics(String state) {
    return 'Koruma durumu: $state';
  }

  @override
  String homeRingOk(int n) {
    return 'Yüzük bağlı · son sinyal $n sn önce';
  }

  @override
  String homeIdleFor(int n) {
    return '$n dk\'dır hareketsiz';
  }

  @override
  String get homeMode => 'Mod';

  @override
  String get homeModeNormal => 'Normal';

  @override
  String get homeModeSleep => 'Uyku';

  @override
  String homeModePaused(int n) {
    return 'Duraklatıldı · $n dk kaldı';
  }

  @override
  String get homeRingBattery => 'Yüzük pili';

  @override
  String homeBatteryEstimate(int pct, String time) {
    return '%$pct · yaklaşık $time';
  }

  @override
  String homeBatteryPct(int pct) {
    return '%$pct';
  }

  @override
  String get homeBatteryUnknown => 'bilinmiyor';

  @override
  String get homeRing => 'Yüzük';

  @override
  String get homeRingConnected => 'Bağlı';

  @override
  String get homeRingSearching => 'Aranıyor';

  @override
  String get homeRingDisconnected => 'Bağlı değil';

  @override
  String get homeHelp => 'Yardım çağır';

  @override
  String get homeHelpHint => '2 saniye basılı tut';

  @override
  String get homeSleep => 'Uyku modu';

  @override
  String get homeSleepOn => 'Uyku modu açık';

  @override
  String get homePause => 'Duraklat';

  @override
  String get homeResume => 'Devam et';

  @override
  String get homeRecent => 'Son olaylar';

  @override
  String get homeNoEvents => 'Henüz olay yok';

  @override
  String get homeProtectionOffOnboarding =>
      'Kurulum bitene kadar koruma kapalı.';

  @override
  String durationDays(int n) {
    return '$n gün';
  }

  @override
  String durationHours(int n) {
    return '$n saat';
  }

  @override
  String get pauseTitle => 'Ne kadar duraklatılsın?';

  @override
  String get pauseNote =>
      'Duş, şarj gibi yüzüğün çıkarıldığı anlar için. Süre bitince ya da yüzük tekrar hareket görünce koruma kendiliğinden geri gelir.';

  @override
  String get pause30 => '30 dakika';

  @override
  String get pause60 => '1 saat';

  @override
  String get pause120 => '2 saat';

  @override
  String get preAlarmTitleInactivity => 'Hareketsizlik algılandı';

  @override
  String get preAlarmTitleSos => 'Yardım isteğin alındı';

  @override
  String get preAlarmTitleTremor => 'Titreme algılandı';

  @override
  String preAlarmReasonInactivity(int n) {
    return '$n dakikadır hiç hareket algılanmadı';
  }

  @override
  String get preAlarmReasonSos => 'Yüzüğe üç kez vurdun';

  @override
  String get preAlarmReasonTremor => 'Uzun süreli titreme algılandı';

  @override
  String get preAlarmSeconds => 'saniye';

  @override
  String get preAlarmWillNotify =>
      'Cevap vermezsen yakınlarına haber verilecek';

  @override
  String get preAlarmImFine => 'İyiyim';

  @override
  String get preAlarmSendNow => 'Hemen haber ver';

  @override
  String get preAlarmMotionHint => 'Hareket algılandı, iyiysen İyiyim\'e bas';

  @override
  String get preAlarmRehearsal => 'PROVA';

  @override
  String preAlarmCountdownSemantics(int n) {
    return '$n saniye kaldı';
  }

  @override
  String get alarmTitle => 'Yakınlarına haber verildi';

  @override
  String alarmSubtitle(String time, String reason) {
    return '$time · $reason';
  }

  @override
  String get alarmReasonInactivity => 'hareketsizlik';

  @override
  String get alarmReasonSos => 'yüzüğe vurma';

  @override
  String get alarmReasonTremor => 'titreme';

  @override
  String get alarmReasonManual => 'yardım çağrısı';

  @override
  String get alarmDelivered => 'Mesaj gruba ulaştı';

  @override
  String get alarmSending => 'Mesaj gönderiliyor…';

  @override
  String alarmRetrying(int n) {
    return 'İnternet bekleniyor, tekrar deneniyor ($n. deneme)';
  }

  @override
  String get alarmSmsSent => 'SMS gönderildi';

  @override
  String alarmLive(int n) {
    return 'Canlı konum · $n dk kaldı';
  }

  @override
  String get alarmLiveWaiting => 'Konum bekleniyor';

  @override
  String get alarmContacts => 'Yakınların';

  @override
  String get alarmNoContacts => 'Kişi eklenmemiş';

  @override
  String get alarmCall => 'Ara';

  @override
  String alarmCallSemantics(String name) {
    return '$name kişisini ara';
  }

  @override
  String get alarmClose => 'İyiyim, alarmı kapat';

  @override
  String get alarmCloseConfirm => 'Yakınlarına iyi olduğun bildirilsin mi?';

  @override
  String get alarmCloseYes => 'Evet, kapat';

  @override
  String get historyTitle => 'Geçmiş';

  @override
  String get historyWeek => 'Bu hafta';

  @override
  String historyWeekSummary(int a, int b, int c) {
    return '$a ön uyarı · $b iptal · $c alarm';
  }

  @override
  String get historySuggest => 'Süreleri uzatmak ister misin?';

  @override
  String get historyToday => 'BUGÜN';

  @override
  String get historyYesterday => 'DÜN';

  @override
  String get historyTapHint => 'Bir olaya dokun: o anki hareket grafiği';

  @override
  String get historyEmpty => 'Son 30 günde olay yok';

  @override
  String get historyExport => 'Dışa aktar (CSV)';

  @override
  String get historyClear => 'Geçmişi sil';

  @override
  String get historyClearConfirm => 'Tüm geçmiş silinsin mi? Bu geri alınamaz.';

  @override
  String get historySentToGroup => 'Gruba gitti';

  @override
  String get historyNotSentToGroup => 'Gruba gitmedi';

  @override
  String get historyMovesChart => 'O anki hareket (son sinyaller)';

  @override
  String get historyNoMoves => 'Hareket verisi yok';

  @override
  String get evPreAlarmCancelled => 'Ön uyarı, iptal edildi';

  @override
  String get evPreAlarmEscalated => 'Ön uyarı, alarma döndü';

  @override
  String get evAlarmSent => 'Alarm gönderildi';

  @override
  String get evAlarmDeliveredLate => 'Alarm gecikmeyle gitti';

  @override
  String get evSmsSent => 'SMS gönderildi';

  @override
  String get evAlarmClosed => 'Alarm kapatıldı';

  @override
  String get evSos => 'SOS (üç vuruş)';

  @override
  String get evTremor => 'Titreme';

  @override
  String get evManualHelp => 'Yardım çağrıldı';

  @override
  String get evRingConnected => 'Yüzük bağlandı';

  @override
  String get evRingDisconnected => 'Yüzük bağlantısı koptu';

  @override
  String get evLowBattery => 'Yüzük pili azaldı';

  @override
  String get evPaused => 'Duraklatıldı';

  @override
  String get evResumed => 'Koruma devam etti';

  @override
  String get evSleepOn => 'Uyku modu açıldı';

  @override
  String get evSleepOff => 'Uyku modu kapandı';

  @override
  String get evPacketLoss => 'Sinyal kaybı';

  @override
  String get evTelegramCheckFailed => 'Telegram kontrolü başarısız';

  @override
  String get evProtectionGap => 'Koruma kesildi';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsContacts => 'Yakınlar ve Telegram';

  @override
  String get settingsTiming => 'Süreler';

  @override
  String get settingsSleep => 'Uyku modu';

  @override
  String get settingsRing => 'Yüzük';

  @override
  String get settingsPermissions => 'İzinler ve arka plan';

  @override
  String get settingsWelcome => 'Kişisel mesaj';

  @override
  String get settingsHelp => 'Yardım ve tanılama';

  @override
  String get settingsHistory => 'Geçmiş';

  @override
  String settingsFooter(String version, String fw) {
    return 'Güven Yüzüğü $version · yüzük $fw';
  }

  @override
  String get contactsSection => 'YAKINLAR';

  @override
  String get contactsAdd => '+ Kişi ekle';

  @override
  String get contactsAddFromPhone => '+ Kişilerden ekle';

  @override
  String get contactsAddManual => 'Elle ekle';

  @override
  String get contactsName => 'Ad';

  @override
  String get contactsPhone => 'Telefon';

  @override
  String get contactsEdit => 'Kişiyi düzenle';

  @override
  String contactsDeleteConfirm(String name) {
    return '$name listeden çıkarılsın mı?';
  }

  @override
  String get contactsHint =>
      'Telegram grubunda en az iki kişi olsun, biri görmezse diğeri görür';

  @override
  String get contactsOrderTitle => 'Alarmda aranacak sıra';

  @override
  String get contactsReorderHint => 'Sırayı değiştirmek için sürükle';

  @override
  String get telegramSection => 'TELEGRAM';

  @override
  String get telegramToken => 'Bot token';

  @override
  String get telegramChatId => 'Grup chat ID';

  @override
  String get telegramName => 'Mesajdaki isim';

  @override
  String get telegramTokenSafe => 'token güvenli depoda';

  @override
  String get telegramTokenEmpty => 'girilmedi';

  @override
  String get telegramTest => 'Test mesajı gönder';

  @override
  String get telegramTestOk => 'Test mesajı gruba ulaştı';

  @override
  String telegramLastCheck(String date, String result) {
    return 'Son kontrol $date, $result';
  }

  @override
  String get telegramCheckOk => 'başarılı';

  @override
  String get telegramCheckFail => 'başarısız';

  @override
  String get telegramNeverChecked => 'Henüz kontrol edilmedi';

  @override
  String get telegramPreparerNote =>
      'Bunu senin için hazırlayan kişi doldurabilir';

  @override
  String get smsSection => 'SMS YEDEĞİ';

  @override
  String get smsOff => 'Kapalı';

  @override
  String smsFallback(int n) {
    return 'Telegram $n sn\'de gitmezse';
  }

  @override
  String get smsAlways => 'Her zaman';

  @override
  String get smsTest => 'Test SMS\'i gönder';

  @override
  String get smsTestPrompt => 'Test SMS\'i yalnızca kendi numarana gönder';

  @override
  String get smsTestNumber => 'Kendi numaran';

  @override
  String get smsTestSent => 'Test SMS\'i gönderildi';

  @override
  String get smsTestFailed => 'SMS gönderilemedi';

  @override
  String get smsSwitch => 'SMS yedeği';

  @override
  String get smsSwitchNote => 'İnternet yoksa bu kişilere SMS gider';

  @override
  String get timingAbrupt => 'Ani durmada';

  @override
  String get timingGradual => 'Yavaş durmada';

  @override
  String get timingPreAlarm => 'Ön uyarı';

  @override
  String get timingPreAlarmSub => 'iptal süresi';

  @override
  String get timingSos => 'SOS iptali';

  @override
  String get timingSosSub => '3 vuruş sonrası';

  @override
  String get timingSensitivity => 'Hareket hassasiyeti';

  @override
  String get timingLow => 'Düşük';

  @override
  String get timingMedium => 'Orta';

  @override
  String get timingHigh => 'Yüksek';

  @override
  String get timingNote =>
      'Ani: aktifken bir anda durursa. Yavaş: hareket azalarak durursa.';

  @override
  String get sleepToggle => 'Uyku modu';

  @override
  String get sleepSchedule => 'Zamanlama';

  @override
  String get sleepEveryDay => 'her gün';

  @override
  String get sleepStart => 'Başlangıç';

  @override
  String get sleepEnd => 'Bitiş';

  @override
  String get sleepWait => 'Uykuda bekleme';

  @override
  String get sleepWaitSub => 'her iki süre';

  @override
  String get sleepInfo =>
      'Kriz uykuda da olabilir, bu yüzden koruma kapanmaz, sadece daha sabırlı olur.';

  @override
  String get ringConnection => 'Bağlantı';

  @override
  String get ringBattery => 'Pil';

  @override
  String ringVoltage(String v, String when) {
    return '$v V · son şarj $when';
  }

  @override
  String get ringNoCharge => 'bilinmiyor';

  @override
  String get ringLiveMotion => 'Canlı hareket';

  @override
  String get ringThreshold => 'eşik';

  @override
  String get ringFirmware => 'Firmware';

  @override
  String get ringDeviceName => 'Cihaz adı';

  @override
  String get ringForget => 'Yüzüğü unut ve yeniden eşleştir';

  @override
  String get ringForgetConfirm =>
      'Yüzük unutulsun ve yeniden aransın mı? Eşleşene kadar koruma olmaz.';

  @override
  String get ringSignalGood => 'sinyal iyi';

  @override
  String get ringSignalWeak => 'sinyal zayıf';

  @override
  String get permTitle => 'İzinler ve arka plan';

  @override
  String get permBluetooth => 'Bluetooth';

  @override
  String get permBluetoothWhy => 'yüzükle konuşmak için';

  @override
  String get permNotifications => 'Bildirimler';

  @override
  String get permNotificationsWhy => 'sessizdeyken de uyarabilmek için';

  @override
  String get permLocation => 'Konum · Her Zaman';

  @override
  String get permLocationWhy => 'acil durumda bulunabilmen için';

  @override
  String get permLocationPartial => 'Şu an: sadece uygulama açıkken';

  @override
  String get permLocationApprox => 'Hassas konum kapalı';

  @override
  String get permFullScreen => 'Tam ekran uyarı';

  @override
  String get permFullScreenWhy => 'kilit ekranında uyarabilmek için';

  @override
  String get permDnd => 'Rahatsız Etmeyin\'i geçme';

  @override
  String get permDndWhy => 'isteğe bağlı: sessiz modda da çalabilmek için';

  @override
  String get permBattery => 'Pil optimizasyonu';

  @override
  String get permBatteryWhy => 'telefon uygulamayı kapatmasın';

  @override
  String get permSms => 'SMS';

  @override
  String get permSmsWhy => 'internet yoksa yakınlarına SMS için';

  @override
  String get permLocationAndroid => 'Konum';

  @override
  String get permLocationAndroidWhy =>
      'acil durumda yakınlarının seni bulabilmesi için';

  @override
  String get discAccept => 'Kabul et';

  @override
  String get discDecline => 'Şimdi değil';

  @override
  String get discLocTitle => 'Konumun ne zaman kullanılır?';

  @override
  String get discLocBody =>
      'Güven Yüzüğü, bir acil durum alarmı gönderildiğinde konumunu alır ve yalnızca senin seçtiğin yakınlarınla (Telegram grubu ve açıksa SMS yedeği) paylaşır.\n\nKriz anında telefonu tutamayabileceğin için alarm, ekran kilitliyken ve uygulama arka plandayken de çalışır; konum bu durumda da alınır. Alarm açıkken konumun en fazla 1 saat canlı paylaşılır.\n\nSürekli takip yapılmaz. Alarm kapanınca konum paylaşımı durur, konum hiçbir sunucuya gönderilmez.';

  @override
  String get discSmsTitle => 'SMS yedeği';

  @override
  String get discSmsBody =>
      'İnternet olmadığı için acil durum mesajı Telegram\'a ulaşamazsa, Güven Yüzüğü yalnızca senin eklediğin yakın kişilere konumunu içeren kısa bir SMS gönderir. Alarmı kapattığında da \"iyi olduğunu bildirdi\" SMS\'i gider.\n\nUygulama SMS\'lerini okumaz ve başka hiçbir amaçla SMS göndermez. SMS\'ler kendi hattından, operatör ücretinle gönderilir.\n\nBunun için SMS gönderme izni istenecek.';

  @override
  String get obReadyTipReboot =>
      'Telefon yeniden başlarsa uygulamayı bir kez aç; konum paylaşımı böyle hazır olur';

  @override
  String get permManufacturer => 'Üretici ayarları';

  @override
  String get permCriticalIos => 'Kritik Uyarılar';

  @override
  String get permCriticalIosWhy =>
      'Apple onayı gelene kadar Zamana Duyarlı bildirim kullanılır.';

  @override
  String get permFocusIos => 'Odak modları';

  @override
  String get permFocusIosWhy =>
      'Ayarlar > Odak\'ta her mod için Güven Yüzüğü\'ne izin ver.';

  @override
  String get welcomeTitle => 'Kişisel mesaj';

  @override
  String get welcomeHint => 'Hoş geldin ekranında görünen mesaj';

  @override
  String get welcomePreview => 'Önizleme';

  @override
  String get welcomeSaved => 'Kaydedildi';

  @override
  String get helpRehearsal => 'Prova alarmı';

  @override
  String get helpFaq => 'Sık sorulanlar';

  @override
  String get helpShareLog => 'Teknik günlüğü paylaş';

  @override
  String get helpSimulated => 'Simüle yüzük';

  @override
  String get helpSimulatedSub => 'Yalnızca geliştirme: BLE yerine sahte yüzük';

  @override
  String get helpSimPanel => 'Simülasyon paneli';

  @override
  String get faqQ1 => 'Uygulamayı kapatabilir miyim?';

  @override
  String get faqA1 =>
      'Hayır. Son uygulamalardan kaydırarak kapatma; koruma arka planda çalışmalı. Android\'de bildirim çubuğunda \"Koruma açık\" yazısı görünür.';

  @override
  String get faqQ2 => 'Yüzüğü ne sıklıkla şarj etmeliyim?';

  @override
  String get faqA2 =>
      'Her gün kısa bir süre. Şarj ederken Duraklat\'ı kullan, böylece yanlış uyarı gelmez.';

  @override
  String get faqQ3 => 'Telefon ne kadar uzakta olabilir?';

  @override
  String get faqA3 =>
      'Yaklaşık 10 metre. Daha uzakta bağlantı kopar; 3 dakika sonra sana haber verilir, gruba alarm gitmez.';

  @override
  String get faqQ4 => 'Telefon sessizdeyken uyarı duyulur mu?';

  @override
  String get faqA4 =>
      'Android\'de \"Rahatsız Etmeyin\'i geçme\" izni verilirse evet. iPhone\'da Odak modlarında uygulamaya izin ver.';

  @override
  String get faqQ5 => 'Yanlış alarm olursa ne olur?';

  @override
  String get faqA5 =>
      'Her alarmdan önce sana sorulur. İyiyim\'e basarsan gruba hiçbir şey gitmez. Çok sık oluyorsa Süreler\'den bekleme süresini uzat.';

  @override
  String get faqQ6 => 'Telefonum uygulamayı kapatıyor';

  @override
  String get faqA6 =>
      'İzinler ve arka plan ekranından pil optimizasyonunu kapat ve üretici ayarlarındaki adımları uygula.';

  @override
  String get simActive => 'Aktif';

  @override
  String get simCalm => 'Sakin';

  @override
  String get simStill => 'Hareketsiz';

  @override
  String get simSos => 'SOS gönder';

  @override
  String get simTremor => 'Titreme gönder';

  @override
  String get simDisconnect => 'Bağlantıyı kopar';

  @override
  String get simConnect => 'Bağla';

  @override
  String simBattery(int n) {
    return 'Pil %$n';
  }

  @override
  String get simFast => 'Zamanı hızlandır ×10';

  @override
  String obWelcomeHello(String name) {
    return 'Merhaba $name';
  }

  @override
  String get obWelcomeCaption => 'senin için yazılmış mesaj';

  @override
  String get obWelcomeStart => 'Başlayalım';

  @override
  String get obHowTitle => 'Nasıl çalışır';

  @override
  String get obHow1 => 'Yüzük elinin hareketini izler';

  @override
  String get obHow2 => 'Hareket aniden durursa önce sana sorar';

  @override
  String get obHow3 => 'Cevap vermezsen yakınlarına haber gider';

  @override
  String get obPermTitle => 'İzinler gerekiyor';

  @override
  String get obPermNote => 'Kurulum bitene kadar koruma kapalı.';

  @override
  String get obBgTitle => 'Arka planda çalışma';

  @override
  String get obBgSubtitle => 'Telefonun pil tasarrufu uygulamayı kapatmasın';

  @override
  String get obBgButton => 'Pil optimizasyonunu kapat';

  @override
  String get obBgBrandSteps => 'Telefonuna özel adımlar';

  @override
  String get obPairTitle => 'Yüzüğü eşleştir';

  @override
  String get obPairSearching => 'Yüzük aranıyor';

  @override
  String get obPairFound => 'GüvenYüzük bulundu';

  @override
  String get obPairWave => 'Elini salla';

  @override
  String get obPairWaveSub => 'yüzük seni hissediyor mu, görelim';

  @override
  String get obPairTap => 'Şimdi yüzüğe 3 kez vur';

  @override
  String get obPairTapSub => 'acil durumda yardım böyle istenir';

  @override
  String get obPairBtOff => 'Bluetooth kapalı. Açınca yüzük aranacak.';

  @override
  String get obPairNoPerm => 'Bluetooth izni yok. İzinler adımına dön.';

  @override
  String get obTelegramTitle => 'Telegram';

  @override
  String get obContactsTitle => 'Yakın kişiler';

  @override
  String get obContactsEmptyWarn =>
      'Hiç kişi eklemedin. Alarm yine gruba gider ama \"Ara\" butonları olmaz. Devam edilsin mi?';

  @override
  String get obRehearsalTitle => 'Bir prova yapalım';

  @override
  String get obRehearsalSub => 'Gerçek an geldiğinde bu ekranı tanıyor ol';

  @override
  String get obRehearsalStart => 'Provayı başlat';

  @override
  String get obRehearsalDone => 'Prova tamamlandı';

  @override
  String get obRehearsalTest => 'Gruba [TEST] mesajı gönder';

  @override
  String get obRehearsalTestSub => 'isteğe bağlı';

  @override
  String get obRehearsalTestSent => '[TEST] mesajı gönderildi';

  @override
  String get obReadyTitle => 'Koruma açık';

  @override
  String get obReadySub => 'Artık yalnız değilsin';

  @override
  String get obReadyTipAndroid =>
      'Uygulamayı son uygulamalardan kaydırarak kapatma';

  @override
  String get obReadyTipIos => 'Uygulamayı yukarı kaydırarak kapatma';

  @override
  String get obReadyTipCharge => 'Yüzüğü her gün kısa bir süre şarj et';

  @override
  String get obReadyGo => 'Ana ekrana git';

  @override
  String obStepOf(int n, int total) {
    return 'Adım $n / $total';
  }
}
