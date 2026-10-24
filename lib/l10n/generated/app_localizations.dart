import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('tr')];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güven Yüzüğü'**
  String get appTitle;

  /// No description provided for @commonContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get commonContinue;

  /// No description provided for @commonCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get commonDelete;

  /// No description provided for @commonOpenSettings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları aç'**
  String get commonOpenSettings;

  /// No description provided for @commonAllow.
  ///
  /// In tr, this message translates to:
  /// **'İzin ver'**
  String get commonAllow;

  /// No description provided for @commonDone.
  ///
  /// In tr, this message translates to:
  /// **'Yaptım'**
  String get commonDone;

  /// No description provided for @commonSkip.
  ///
  /// In tr, this message translates to:
  /// **'Atla'**
  String get commonSkip;

  /// No description provided for @commonClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get commonClose;

  /// No description provided for @commonAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get commonAll;

  /// No description provided for @commonRecommended.
  ///
  /// In tr, this message translates to:
  /// **'önerilen'**
  String get commonRecommended;

  /// No description provided for @commonRecommendedValue.
  ///
  /// In tr, this message translates to:
  /// **'önerilen: {value}'**
  String commonRecommendedValue(String value);

  /// No description provided for @commonResetRecommended.
  ///
  /// In tr, this message translates to:
  /// **'Önerilene dön'**
  String get commonResetRecommended;

  /// No description provided for @commonSeconds.
  ///
  /// In tr, this message translates to:
  /// **'{n} sn'**
  String commonSeconds(int n);

  /// No description provided for @commonMinutes.
  ///
  /// In tr, this message translates to:
  /// **'{n} dk'**
  String commonMinutes(int n);

  /// No description provided for @commonDecrease.
  ///
  /// In tr, this message translates to:
  /// **'Azalt'**
  String get commonDecrease;

  /// No description provided for @commonIncrease.
  ///
  /// In tr, this message translates to:
  /// **'Artır'**
  String get commonIncrease;

  /// No description provided for @shieldProtected.
  ///
  /// In tr, this message translates to:
  /// **'Koruma açık'**
  String get shieldProtected;

  /// No description provided for @shieldAttention.
  ///
  /// In tr, this message translates to:
  /// **'Dikkat'**
  String get shieldAttention;

  /// No description provided for @shieldUnprotected.
  ///
  /// In tr, this message translates to:
  /// **'Koruma yok'**
  String get shieldUnprotected;

  /// No description provided for @shieldSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Koruma durumu: {state}'**
  String shieldSemantics(String state);

  /// No description provided for @homeRingOk.
  ///
  /// In tr, this message translates to:
  /// **'Yüzük bağlı · son sinyal {n} sn önce'**
  String homeRingOk(int n);

  /// No description provided for @homeIdleFor.
  ///
  /// In tr, this message translates to:
  /// **'{n} dk\'dır hareketsiz'**
  String homeIdleFor(int n);

  /// No description provided for @homeMode.
  ///
  /// In tr, this message translates to:
  /// **'Mod'**
  String get homeMode;

  /// No description provided for @homeModeNormal.
  ///
  /// In tr, this message translates to:
  /// **'Normal'**
  String get homeModeNormal;

  /// No description provided for @homeModeSleep.
  ///
  /// In tr, this message translates to:
  /// **'Uyku'**
  String get homeModeSleep;

  /// No description provided for @homeModePaused.
  ///
  /// In tr, this message translates to:
  /// **'Duraklatıldı · {n} dk kaldı'**
  String homeModePaused(int n);

  /// No description provided for @homeRingBattery.
  ///
  /// In tr, this message translates to:
  /// **'Yüzük pili'**
  String get homeRingBattery;

  /// No description provided for @homeBatteryEstimate.
  ///
  /// In tr, this message translates to:
  /// **'%{pct} · yaklaşık {time}'**
  String homeBatteryEstimate(int pct, String time);

  /// No description provided for @homeBatteryPct.
  ///
  /// In tr, this message translates to:
  /// **'%{pct}'**
  String homeBatteryPct(int pct);

  /// No description provided for @homeBatteryUnknown.
  ///
  /// In tr, this message translates to:
  /// **'bilinmiyor'**
  String get homeBatteryUnknown;

  /// No description provided for @homeRing.
  ///
  /// In tr, this message translates to:
  /// **'Yüzük'**
  String get homeRing;

  /// No description provided for @homeRingConnected.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı'**
  String get homeRingConnected;

  /// No description provided for @homeRingSearching.
  ///
  /// In tr, this message translates to:
  /// **'Aranıyor'**
  String get homeRingSearching;

  /// No description provided for @homeRingDisconnected.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı değil'**
  String get homeRingDisconnected;

  /// No description provided for @homeHelp.
  ///
  /// In tr, this message translates to:
  /// **'Yardım çağır'**
  String get homeHelp;

  /// No description provided for @homeHelpHint.
  ///
  /// In tr, this message translates to:
  /// **'2 saniye basılı tut'**
  String get homeHelpHint;

  /// No description provided for @homeSleep.
  ///
  /// In tr, this message translates to:
  /// **'Uyku modu'**
  String get homeSleep;

  /// No description provided for @homeSleepOn.
  ///
  /// In tr, this message translates to:
  /// **'Uyku modu açık'**
  String get homeSleepOn;

  /// No description provided for @homePause.
  ///
  /// In tr, this message translates to:
  /// **'Duraklat'**
  String get homePause;

  /// No description provided for @homeResume.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get homeResume;

  /// No description provided for @homeRecent.
  ///
  /// In tr, this message translates to:
  /// **'Son olaylar'**
  String get homeRecent;

  /// No description provided for @homeNoEvents.
  ///
  /// In tr, this message translates to:
  /// **'Henüz olay yok'**
  String get homeNoEvents;

  /// No description provided for @homeProtectionOffOnboarding.
  ///
  /// In tr, this message translates to:
  /// **'Kurulum bitene kadar koruma kapalı.'**
  String get homeProtectionOffOnboarding;

  /// No description provided for @durationDays.
  ///
  /// In tr, this message translates to:
  /// **'{n} gün'**
  String durationDays(int n);

  /// No description provided for @durationHours.
  ///
  /// In tr, this message translates to:
  /// **'{n} saat'**
  String durationHours(int n);

  /// No description provided for @pauseTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ne kadar duraklatılsın?'**
  String get pauseTitle;

  /// No description provided for @pauseNote.
  ///
  /// In tr, this message translates to:
  /// **'Duş, şarj gibi yüzüğün çıkarıldığı anlar için. Süre bitince ya da yüzük tekrar hareket görünce koruma kendiliğinden geri gelir.'**
  String get pauseNote;

  /// No description provided for @pause30.
  ///
  /// In tr, this message translates to:
  /// **'30 dakika'**
  String get pause30;

  /// No description provided for @pause60.
  ///
  /// In tr, this message translates to:
  /// **'1 saat'**
  String get pause60;

  /// No description provided for @pause120.
  ///
  /// In tr, this message translates to:
  /// **'2 saat'**
  String get pause120;

  /// No description provided for @preAlarmTitleInactivity.
  ///
  /// In tr, this message translates to:
  /// **'Hareketsizlik algılandı'**
  String get preAlarmTitleInactivity;

  /// No description provided for @preAlarmTitleSos.
  ///
  /// In tr, this message translates to:
  /// **'Yardım isteğin alındı'**
  String get preAlarmTitleSos;

  /// No description provided for @preAlarmTitleTremor.
  ///
  /// In tr, this message translates to:
  /// **'Titreme algılandı'**
  String get preAlarmTitleTremor;

  /// No description provided for @preAlarmReasonInactivity.
  ///
  /// In tr, this message translates to:
  /// **'{n} dakikadır hiç hareket algılanmadı'**
  String preAlarmReasonInactivity(int n);

  /// No description provided for @preAlarmReasonSos.
  ///
  /// In tr, this message translates to:
  /// **'Yüzüğe üç kez vurdun'**
  String get preAlarmReasonSos;

  /// No description provided for @preAlarmReasonTremor.
  ///
  /// In tr, this message translates to:
  /// **'Uzun süreli titreme algılandı'**
  String get preAlarmReasonTremor;

  /// No description provided for @preAlarmSeconds.
  ///
  /// In tr, this message translates to:
  /// **'saniye'**
  String get preAlarmSeconds;

  /// No description provided for @preAlarmWillNotify.
  ///
  /// In tr, this message translates to:
  /// **'Cevap vermezsen yakınlarına haber verilecek'**
  String get preAlarmWillNotify;

  /// No description provided for @preAlarmImFine.
  ///
  /// In tr, this message translates to:
  /// **'İyiyim'**
  String get preAlarmImFine;

  /// No description provided for @preAlarmSendNow.
  ///
  /// In tr, this message translates to:
  /// **'Hemen haber ver'**
  String get preAlarmSendNow;

  /// No description provided for @preAlarmMotionHint.
  ///
  /// In tr, this message translates to:
  /// **'Hareket algılandı, iyiysen İyiyim\'e bas'**
  String get preAlarmMotionHint;

  /// No description provided for @preAlarmRehearsal.
  ///
  /// In tr, this message translates to:
  /// **'PROVA'**
  String get preAlarmRehearsal;

  /// No description provided for @preAlarmCountdownSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{n} saniye kaldı'**
  String preAlarmCountdownSemantics(int n);

  /// No description provided for @alarmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakınlarına haber verildi'**
  String get alarmTitle;

  /// No description provided for @alarmSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{time} · {reason}'**
  String alarmSubtitle(String time, String reason);

  /// No description provided for @alarmReasonInactivity.
  ///
  /// In tr, this message translates to:
  /// **'hareketsizlik'**
  String get alarmReasonInactivity;

  /// No description provided for @alarmReasonSos.
  ///
  /// In tr, this message translates to:
  /// **'yüzüğe vurma'**
  String get alarmReasonSos;

  /// No description provided for @alarmReasonTremor.
  ///
  /// In tr, this message translates to:
  /// **'titreme'**
  String get alarmReasonTremor;

  /// No description provided for @alarmReasonManual.
  ///
  /// In tr, this message translates to:
  /// **'yardım çağrısı'**
  String get alarmReasonManual;

  /// No description provided for @alarmDelivered.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj gruba ulaştı'**
  String get alarmDelivered;

  /// No description provided for @alarmSending.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj gönderiliyor…'**
  String get alarmSending;

  /// No description provided for @alarmRetrying.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bekleniyor, tekrar deneniyor ({n}. deneme)'**
  String alarmRetrying(int n);

  /// No description provided for @alarmSmsSent.
  ///
  /// In tr, this message translates to:
  /// **'SMS gönderildi'**
  String get alarmSmsSent;

  /// No description provided for @alarmLive.
  ///
  /// In tr, this message translates to:
  /// **'Canlı konum · {n} dk kaldı'**
  String alarmLive(int n);

  /// No description provided for @alarmLiveWaiting.
  ///
  /// In tr, this message translates to:
  /// **'Konum bekleniyor'**
  String get alarmLiveWaiting;

  /// No description provided for @alarmContacts.
  ///
  /// In tr, this message translates to:
  /// **'Yakınların'**
  String get alarmContacts;

  /// No description provided for @alarmNoContacts.
  ///
  /// In tr, this message translates to:
  /// **'Kişi eklenmemiş'**
  String get alarmNoContacts;

  /// No description provided for @alarmCall.
  ///
  /// In tr, this message translates to:
  /// **'Ara'**
  String get alarmCall;

  /// No description provided for @alarmCallSemantics.
  ///
  /// In tr, this message translates to:
  /// **'{name} kişisini ara'**
  String alarmCallSemantics(String name);

  /// No description provided for @alarmClose.
  ///
  /// In tr, this message translates to:
  /// **'İyiyim, alarmı kapat'**
  String get alarmClose;

  /// No description provided for @alarmCloseConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Yakınlarına iyi olduğun bildirilsin mi?'**
  String get alarmCloseConfirm;

  /// No description provided for @alarmCloseYes.
  ///
  /// In tr, this message translates to:
  /// **'Evet, kapat'**
  String get alarmCloseYes;

  /// No description provided for @historyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get historyTitle;

  /// No description provided for @historyWeek.
  ///
  /// In tr, this message translates to:
  /// **'Bu hafta'**
  String get historyWeek;

  /// No description provided for @historyWeekSummary.
  ///
  /// In tr, this message translates to:
  /// **'{a} ön uyarı · {b} iptal · {c} alarm'**
  String historyWeekSummary(int a, int b, int c);

  /// No description provided for @historySuggest.
  ///
  /// In tr, this message translates to:
  /// **'Süreleri uzatmak ister misin?'**
  String get historySuggest;

  /// No description provided for @historyToday.
  ///
  /// In tr, this message translates to:
  /// **'BUGÜN'**
  String get historyToday;

  /// No description provided for @historyYesterday.
  ///
  /// In tr, this message translates to:
  /// **'DÜN'**
  String get historyYesterday;

  /// No description provided for @historyTapHint.
  ///
  /// In tr, this message translates to:
  /// **'Bir olaya dokun: o anki hareket grafiği'**
  String get historyTapHint;

  /// No description provided for @historyEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Son 30 günde olay yok'**
  String get historyEmpty;

  /// No description provided for @historyExport.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktar (CSV)'**
  String get historyExport;

  /// No description provided for @historyClear.
  ///
  /// In tr, this message translates to:
  /// **'Geçmişi sil'**
  String get historyClear;

  /// No description provided for @historyClearConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Tüm geçmiş silinsin mi? Bu geri alınamaz.'**
  String get historyClearConfirm;

  /// No description provided for @historySentToGroup.
  ///
  /// In tr, this message translates to:
  /// **'Gruba gitti'**
  String get historySentToGroup;

  /// No description provided for @historyNotSentToGroup.
  ///
  /// In tr, this message translates to:
  /// **'Gruba gitmedi'**
  String get historyNotSentToGroup;

  /// No description provided for @historyMovesChart.
  ///
  /// In tr, this message translates to:
  /// **'O anki hareket (son sinyaller)'**
  String get historyMovesChart;

  /// No description provided for @historyNoMoves.
  ///
  /// In tr, this message translates to:
  /// **'Hareket verisi yok'**
  String get historyNoMoves;

  /// No description provided for @evPreAlarmCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Ön uyarı, iptal edildi'**
  String get evPreAlarmCancelled;

  /// No description provided for @evPreAlarmEscalated.
  ///
  /// In tr, this message translates to:
  /// **'Ön uyarı, alarma döndü'**
  String get evPreAlarmEscalated;

  /// No description provided for @evAlarmSent.
  ///
  /// In tr, this message translates to:
  /// **'Alarm gönderildi'**
  String get evAlarmSent;

  /// No description provided for @evAlarmDeliveredLate.
  ///
  /// In tr, this message translates to:
  /// **'Alarm gecikmeyle gitti'**
  String get evAlarmDeliveredLate;

  /// No description provided for @evSmsSent.
  ///
  /// In tr, this message translates to:
  /// **'SMS gönderildi'**
  String get evSmsSent;

  /// No description provided for @evAlarmClosed.
  ///
  /// In tr, this message translates to:
  /// **'Alarm kapatıldı'**
  String get evAlarmClosed;

  /// No description provided for @evSos.
  ///
  /// In tr, this message translates to:
  /// **'SOS (üç vuruş)'**
  String get evSos;

  /// No description provided for @evTremor.
  ///
  /// In tr, this message translates to:
  /// **'Titreme'**
  String get evTremor;

  /// No description provided for @evManualHelp.
  ///
  /// In tr, this message translates to:
  /// **'Yardım çağrıldı'**
  String get evManualHelp;

  /// No description provided for @evRingConnected.
  ///
  /// In tr, this message translates to:
  /// **'Yüzük bağlandı'**
  String get evRingConnected;

  /// No description provided for @evRingDisconnected.
  ///
  /// In tr, this message translates to:
  /// **'Yüzük bağlantısı koptu'**
  String get evRingDisconnected;

  /// No description provided for @evLowBattery.
  ///
  /// In tr, this message translates to:
  /// **'Yüzük pili azaldı'**
  String get evLowBattery;

  /// No description provided for @evPaused.
  ///
  /// In tr, this message translates to:
  /// **'Duraklatıldı'**
  String get evPaused;

  /// No description provided for @evResumed.
  ///
  /// In tr, this message translates to:
  /// **'Koruma devam etti'**
  String get evResumed;

  /// No description provided for @evSleepOn.
  ///
  /// In tr, this message translates to:
  /// **'Uyku modu açıldı'**
  String get evSleepOn;

  /// No description provided for @evSleepOff.
  ///
  /// In tr, this message translates to:
  /// **'Uyku modu kapandı'**
  String get evSleepOff;

  /// No description provided for @evPacketLoss.
  ///
  /// In tr, this message translates to:
  /// **'Sinyal kaybı'**
  String get evPacketLoss;

  /// No description provided for @evTelegramCheckFailed.
  ///
  /// In tr, this message translates to:
  /// **'Telegram kontrolü başarısız'**
  String get evTelegramCheckFailed;

  /// No description provided for @evProtectionGap.
  ///
  /// In tr, this message translates to:
  /// **'Koruma kesildi'**
  String get evProtectionGap;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @settingsContacts.
  ///
  /// In tr, this message translates to:
  /// **'Yakınlar ve Telegram'**
  String get settingsContacts;

  /// No description provided for @settingsTiming.
  ///
  /// In tr, this message translates to:
  /// **'Süreler'**
  String get settingsTiming;

  /// No description provided for @settingsSleep.
  ///
  /// In tr, this message translates to:
  /// **'Uyku modu'**
  String get settingsSleep;

  /// No description provided for @settingsRing.
  ///
  /// In tr, this message translates to:
  /// **'Yüzük'**
  String get settingsRing;

  /// No description provided for @settingsPermissions.
  ///
  /// In tr, this message translates to:
  /// **'İzinler ve arka plan'**
  String get settingsPermissions;

  /// No description provided for @settingsWelcome.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel mesaj'**
  String get settingsWelcome;

  /// No description provided for @settingsHelp.
  ///
  /// In tr, this message translates to:
  /// **'Yardım ve tanılama'**
  String get settingsHelp;

  /// No description provided for @settingsHistory.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get settingsHistory;

  /// No description provided for @settingsFooter.
  ///
  /// In tr, this message translates to:
  /// **'Güven Yüzüğü {version} · yüzük {fw}'**
  String settingsFooter(String version, String fw);

  /// No description provided for @contactsSection.
  ///
  /// In tr, this message translates to:
  /// **'YAKINLAR'**
  String get contactsSection;

  /// No description provided for @contactsAdd.
  ///
  /// In tr, this message translates to:
  /// **'+ Kişi ekle'**
  String get contactsAdd;

  /// No description provided for @contactsAddFromPhone.
  ///
  /// In tr, this message translates to:
  /// **'+ Kişilerden ekle'**
  String get contactsAddFromPhone;

  /// No description provided for @contactsAddManual.
  ///
  /// In tr, this message translates to:
  /// **'Elle ekle'**
  String get contactsAddManual;

  /// No description provided for @contactsName.
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get contactsName;

  /// No description provided for @contactsPhone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get contactsPhone;

  /// No description provided for @contactsEdit.
  ///
  /// In tr, this message translates to:
  /// **'Kişiyi düzenle'**
  String get contactsEdit;

  /// No description provided for @contactsDeleteConfirm.
  ///
  /// In tr, this message translates to:
  /// **'{name} listeden çıkarılsın mı?'**
  String contactsDeleteConfirm(String name);

  /// No description provided for @contactsHint.
  ///
  /// In tr, this message translates to:
  /// **'Telegram grubunda en az iki kişi olsun, biri görmezse diğeri görür'**
  String get contactsHint;

  /// No description provided for @contactsOrderTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alarmda aranacak sıra'**
  String get contactsOrderTitle;

  /// No description provided for @contactsReorderHint.
  ///
  /// In tr, this message translates to:
  /// **'Sırayı değiştirmek için sürükle'**
  String get contactsReorderHint;

  /// No description provided for @telegramSection.
  ///
  /// In tr, this message translates to:
  /// **'TELEGRAM'**
  String get telegramSection;

  /// No description provided for @telegramToken.
  ///
  /// In tr, this message translates to:
  /// **'Bot token'**
  String get telegramToken;

  /// No description provided for @telegramChatId.
  ///
  /// In tr, this message translates to:
  /// **'Grup chat ID'**
  String get telegramChatId;

  /// No description provided for @telegramName.
  ///
  /// In tr, this message translates to:
  /// **'Mesajdaki isim'**
  String get telegramName;

  /// No description provided for @telegramTokenSafe.
  ///
  /// In tr, this message translates to:
  /// **'token güvenli depoda'**
  String get telegramTokenSafe;

  /// No description provided for @telegramTokenEmpty.
  ///
  /// In tr, this message translates to:
  /// **'girilmedi'**
  String get telegramTokenEmpty;

  /// No description provided for @telegramTest.
  ///
  /// In tr, this message translates to:
  /// **'Test mesajı gönder'**
  String get telegramTest;

  /// No description provided for @telegramTestOk.
  ///
  /// In tr, this message translates to:
  /// **'Test mesajı gruba ulaştı'**
  String get telegramTestOk;

  /// No description provided for @telegramLastCheck.
  ///
  /// In tr, this message translates to:
  /// **'Son kontrol {date}, {result}'**
  String telegramLastCheck(String date, String result);

  /// No description provided for @telegramCheckOk.
  ///
  /// In tr, this message translates to:
  /// **'başarılı'**
  String get telegramCheckOk;

  /// No description provided for @telegramCheckFail.
  ///
  /// In tr, this message translates to:
  /// **'başarısız'**
  String get telegramCheckFail;

  /// No description provided for @telegramNeverChecked.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kontrol edilmedi'**
  String get telegramNeverChecked;

  /// No description provided for @telegramPreparerNote.
  ///
  /// In tr, this message translates to:
  /// **'Bunu senin için hazırlayan kişi doldurabilir'**
  String get telegramPreparerNote;

  /// No description provided for @smsSection.
  ///
  /// In tr, this message translates to:
  /// **'SMS YEDEĞİ'**
  String get smsSection;

  /// No description provided for @smsOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get smsOff;

  /// No description provided for @smsFallback.
  ///
  /// In tr, this message translates to:
  /// **'Telegram {n} sn\'de gitmezse'**
  String smsFallback(int n);

  /// No description provided for @smsAlways.
  ///
  /// In tr, this message translates to:
  /// **'Her zaman'**
  String get smsAlways;

  /// No description provided for @smsTest.
  ///
  /// In tr, this message translates to:
  /// **'Test SMS\'i gönder'**
  String get smsTest;

  /// No description provided for @smsTestPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Test SMS\'i yalnızca kendi numarana gönder'**
  String get smsTestPrompt;

  /// No description provided for @smsTestNumber.
  ///
  /// In tr, this message translates to:
  /// **'Kendi numaran'**
  String get smsTestNumber;

  /// No description provided for @smsTestSent.
  ///
  /// In tr, this message translates to:
  /// **'Test SMS\'i gönderildi'**
  String get smsTestSent;

  /// No description provided for @smsTestFailed.
  ///
  /// In tr, this message translates to:
  /// **'SMS gönderilemedi'**
  String get smsTestFailed;

  /// No description provided for @smsSwitch.
  ///
  /// In tr, this message translates to:
  /// **'SMS yedeği'**
  String get smsSwitch;

  /// No description provided for @smsSwitchNote.
  ///
  /// In tr, this message translates to:
  /// **'İnternet yoksa bu kişilere SMS gider'**
  String get smsSwitchNote;

  /// No description provided for @timingAbrupt.
  ///
  /// In tr, this message translates to:
  /// **'Ani durmada'**
  String get timingAbrupt;

  /// No description provided for @timingGradual.
  ///
  /// In tr, this message translates to:
  /// **'Yavaş durmada'**
  String get timingGradual;

  /// No description provided for @timingPreAlarm.
  ///
  /// In tr, this message translates to:
  /// **'Ön uyarı'**
  String get timingPreAlarm;

  /// No description provided for @timingPreAlarmSub.
  ///
  /// In tr, this message translates to:
  /// **'iptal süresi'**
  String get timingPreAlarmSub;

  /// No description provided for @timingSos.
  ///
  /// In tr, this message translates to:
  /// **'SOS iptali'**
  String get timingSos;

  /// No description provided for @timingSosSub.
  ///
  /// In tr, this message translates to:
  /// **'3 vuruş sonrası'**
  String get timingSosSub;

  /// No description provided for @timingSensitivity.
  ///
  /// In tr, this message translates to:
  /// **'Hareket hassasiyeti'**
  String get timingSensitivity;

  /// No description provided for @timingLow.
  ///
  /// In tr, this message translates to:
  /// **'Düşük'**
  String get timingLow;

  /// No description provided for @timingMedium.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get timingMedium;

  /// No description provided for @timingHigh.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek'**
  String get timingHigh;

  /// No description provided for @timingNote.
  ///
  /// In tr, this message translates to:
  /// **'Ani: aktifken bir anda durursa. Yavaş: hareket azalarak durursa.'**
  String get timingNote;

  /// No description provided for @sleepToggle.
  ///
  /// In tr, this message translates to:
  /// **'Uyku modu'**
  String get sleepToggle;

  /// No description provided for @sleepSchedule.
  ///
  /// In tr, this message translates to:
  /// **'Zamanlama'**
  String get sleepSchedule;

  /// No description provided for @sleepEveryDay.
  ///
  /// In tr, this message translates to:
  /// **'her gün'**
  String get sleepEveryDay;

  /// No description provided for @sleepStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get sleepStart;

  /// No description provided for @sleepEnd.
  ///
  /// In tr, this message translates to:
  /// **'Bitiş'**
  String get sleepEnd;

  /// No description provided for @sleepWait.
  ///
  /// In tr, this message translates to:
  /// **'Uykuda bekleme'**
  String get sleepWait;

  /// No description provided for @sleepWaitSub.
  ///
  /// In tr, this message translates to:
  /// **'her iki süre'**
  String get sleepWaitSub;

  /// No description provided for @sleepInfo.
  ///
  /// In tr, this message translates to:
  /// **'Kriz uykuda da olabilir, bu yüzden koruma kapanmaz, sadece daha sabırlı olur.'**
  String get sleepInfo;

  /// No description provided for @ringConnection.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı'**
  String get ringConnection;

  /// No description provided for @ringBattery.
  ///
  /// In tr, this message translates to:
  /// **'Pil'**
  String get ringBattery;

  /// No description provided for @ringVoltage.
  ///
  /// In tr, this message translates to:
  /// **'{v} V · son şarj {when}'**
  String ringVoltage(String v, String when);

  /// No description provided for @ringNoCharge.
  ///
  /// In tr, this message translates to:
  /// **'bilinmiyor'**
  String get ringNoCharge;

  /// No description provided for @ringLiveMotion.
  ///
  /// In tr, this message translates to:
  /// **'Canlı hareket'**
  String get ringLiveMotion;

  /// No description provided for @ringThreshold.
  ///
  /// In tr, this message translates to:
  /// **'eşik'**
  String get ringThreshold;

  /// No description provided for @ringFirmware.
  ///
  /// In tr, this message translates to:
  /// **'Firmware'**
  String get ringFirmware;

  /// No description provided for @ringDeviceName.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz adı'**
  String get ringDeviceName;

  /// No description provided for @ringForget.
  ///
  /// In tr, this message translates to:
  /// **'Yüzüğü unut ve yeniden eşleştir'**
  String get ringForget;

  /// No description provided for @ringForgetConfirm.
  ///
  /// In tr, this message translates to:
  /// **'Yüzük unutulsun ve yeniden aransın mı? Eşleşene kadar koruma olmaz.'**
  String get ringForgetConfirm;

  /// No description provided for @ringSignalGood.
  ///
  /// In tr, this message translates to:
  /// **'sinyal iyi'**
  String get ringSignalGood;

  /// No description provided for @ringSignalWeak.
  ///
  /// In tr, this message translates to:
  /// **'sinyal zayıf'**
  String get ringSignalWeak;

  /// No description provided for @permTitle.
  ///
  /// In tr, this message translates to:
  /// **'İzinler ve arka plan'**
  String get permTitle;

  /// No description provided for @permBluetooth.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth'**
  String get permBluetooth;

  /// No description provided for @permBluetoothWhy.
  ///
  /// In tr, this message translates to:
  /// **'yüzükle konuşmak için'**
  String get permBluetoothWhy;

  /// No description provided for @permNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get permNotifications;

  /// No description provided for @permNotificationsWhy.
  ///
  /// In tr, this message translates to:
  /// **'sessizdeyken de uyarabilmek için'**
  String get permNotificationsWhy;

  /// No description provided for @permLocation.
  ///
  /// In tr, this message translates to:
  /// **'Konum · Her Zaman'**
  String get permLocation;

  /// No description provided for @permLocationWhy.
  ///
  /// In tr, this message translates to:
  /// **'acil durumda bulunabilmen için'**
  String get permLocationWhy;

  /// No description provided for @permLocationPartial.
  ///
  /// In tr, this message translates to:
  /// **'Şu an: sadece uygulama açıkken'**
  String get permLocationPartial;

  /// No description provided for @permLocationApprox.
  ///
  /// In tr, this message translates to:
  /// **'Hassas konum kapalı'**
  String get permLocationApprox;

  /// No description provided for @permFullScreen.
  ///
  /// In tr, this message translates to:
  /// **'Tam ekran uyarı'**
  String get permFullScreen;

  /// No description provided for @permFullScreenWhy.
  ///
  /// In tr, this message translates to:
  /// **'kilit ekranında uyarabilmek için'**
  String get permFullScreenWhy;

  /// No description provided for @permDnd.
  ///
  /// In tr, this message translates to:
  /// **'Rahatsız Etmeyin\'i geçme'**
  String get permDnd;

  /// No description provided for @permDndWhy.
  ///
  /// In tr, this message translates to:
  /// **'isteğe bağlı: sessiz modda da çalabilmek için'**
  String get permDndWhy;

  /// No description provided for @permBattery.
  ///
  /// In tr, this message translates to:
  /// **'Pil optimizasyonu'**
  String get permBattery;

  /// No description provided for @permBatteryWhy.
  ///
  /// In tr, this message translates to:
  /// **'telefon uygulamayı kapatmasın'**
  String get permBatteryWhy;

  /// No description provided for @permSms.
  ///
  /// In tr, this message translates to:
  /// **'SMS'**
  String get permSms;

  /// No description provided for @permSmsWhy.
  ///
  /// In tr, this message translates to:
  /// **'internet yoksa yakınlarına SMS için'**
  String get permSmsWhy;

  /// No description provided for @permLocationAndroid.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get permLocationAndroid;

  /// No description provided for @permLocationAndroidWhy.
  ///
  /// In tr, this message translates to:
  /// **'acil durumda yakınlarının seni bulabilmesi için'**
  String get permLocationAndroidWhy;

  /// No description provided for @discAccept.
  ///
  /// In tr, this message translates to:
  /// **'Kabul et'**
  String get discAccept;

  /// No description provided for @discDecline.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi değil'**
  String get discDecline;

  /// No description provided for @discLocTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konumun ne zaman kullanılır?'**
  String get discLocTitle;

  /// No description provided for @discLocBody.
  ///
  /// In tr, this message translates to:
  /// **'Güven Yüzüğü, bir acil durum alarmı gönderildiğinde konumunu alır ve yalnızca senin seçtiğin yakınlarınla (Telegram grubu ve açıksa SMS yedeği) paylaşır.\n\nKriz anında telefonu tutamayabileceğin için alarm, ekran kilitliyken ve uygulama arka plandayken de çalışır; konum bu durumda da alınır. Alarm açıkken konumun en fazla 1 saat canlı paylaşılır.\n\nSürekli takip yapılmaz. Alarm kapanınca konum paylaşımı durur, konum hiçbir sunucuya gönderilmez.'**
  String get discLocBody;

  /// No description provided for @discSmsTitle.
  ///
  /// In tr, this message translates to:
  /// **'SMS yedeği'**
  String get discSmsTitle;

  /// No description provided for @discSmsBody.
  ///
  /// In tr, this message translates to:
  /// **'İnternet olmadığı için acil durum mesajı Telegram\'a ulaşamazsa, Güven Yüzüğü yalnızca senin eklediğin yakın kişilere konumunu içeren kısa bir SMS gönderir. Alarmı kapattığında da \"iyi olduğunu bildirdi\" SMS\'i gider.\n\nUygulama SMS\'lerini okumaz ve başka hiçbir amaçla SMS göndermez. SMS\'ler kendi hattından, operatör ücretinle gönderilir.\n\nBunun için SMS gönderme izni istenecek.'**
  String get discSmsBody;

  /// No description provided for @obReadyTipReboot.
  ///
  /// In tr, this message translates to:
  /// **'Telefon yeniden başlarsa uygulamayı bir kez aç; konum paylaşımı böyle hazır olur'**
  String get obReadyTipReboot;

  /// No description provided for @permManufacturer.
  ///
  /// In tr, this message translates to:
  /// **'Üretici ayarları'**
  String get permManufacturer;

  /// No description provided for @permCriticalIos.
  ///
  /// In tr, this message translates to:
  /// **'Kritik Uyarılar'**
  String get permCriticalIos;

  /// No description provided for @permCriticalIosWhy.
  ///
  /// In tr, this message translates to:
  /// **'Apple onayı gelene kadar Zamana Duyarlı bildirim kullanılır.'**
  String get permCriticalIosWhy;

  /// No description provided for @permFocusIos.
  ///
  /// In tr, this message translates to:
  /// **'Odak modları'**
  String get permFocusIos;

  /// No description provided for @permFocusIosWhy.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar > Odak\'ta her mod için Güven Yüzüğü\'ne izin ver.'**
  String get permFocusIosWhy;

  /// No description provided for @welcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel mesaj'**
  String get welcomeTitle;

  /// No description provided for @welcomeHint.
  ///
  /// In tr, this message translates to:
  /// **'Hoş geldin ekranında görünen mesaj'**
  String get welcomeHint;

  /// No description provided for @welcomePreview.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme'**
  String get welcomePreview;

  /// No description provided for @welcomeSaved.
  ///
  /// In tr, this message translates to:
  /// **'Kaydedildi'**
  String get welcomeSaved;

  /// No description provided for @helpRehearsal.
  ///
  /// In tr, this message translates to:
  /// **'Prova alarmı'**
  String get helpRehearsal;

  /// No description provided for @helpFaq.
  ///
  /// In tr, this message translates to:
  /// **'Sık sorulanlar'**
  String get helpFaq;

  /// No description provided for @helpShareLog.
  ///
  /// In tr, this message translates to:
  /// **'Teknik günlüğü paylaş'**
  String get helpShareLog;

  /// No description provided for @helpSimulated.
  ///
  /// In tr, this message translates to:
  /// **'Simüle yüzük'**
  String get helpSimulated;

  /// No description provided for @helpSimulatedSub.
  ///
  /// In tr, this message translates to:
  /// **'Yalnızca geliştirme: BLE yerine sahte yüzük'**
  String get helpSimulatedSub;

  /// No description provided for @helpSimPanel.
  ///
  /// In tr, this message translates to:
  /// **'Simülasyon paneli'**
  String get helpSimPanel;

  /// No description provided for @faqQ1.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı kapatabilir miyim?'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In tr, this message translates to:
  /// **'Hayır. Son uygulamalardan kaydırarak kapatma; koruma arka planda çalışmalı. Android\'de bildirim çubuğunda \"Koruma açık\" yazısı görünür.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In tr, this message translates to:
  /// **'Yüzüğü ne sıklıkla şarj etmeliyim?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In tr, this message translates to:
  /// **'Her gün kısa bir süre. Şarj ederken Duraklat\'ı kullan, böylece yanlış uyarı gelmez.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In tr, this message translates to:
  /// **'Telefon ne kadar uzakta olabilir?'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşık 10 metre. Daha uzakta bağlantı kopar; 3 dakika sonra sana haber verilir, gruba alarm gitmez.'**
  String get faqA3;

  /// No description provided for @faqQ4.
  ///
  /// In tr, this message translates to:
  /// **'Telefon sessizdeyken uyarı duyulur mu?'**
  String get faqQ4;

  /// No description provided for @faqA4.
  ///
  /// In tr, this message translates to:
  /// **'Android\'de \"Rahatsız Etmeyin\'i geçme\" izni verilirse evet. iPhone\'da Odak modlarında uygulamaya izin ver.'**
  String get faqA4;

  /// No description provided for @faqQ5.
  ///
  /// In tr, this message translates to:
  /// **'Yanlış alarm olursa ne olur?'**
  String get faqQ5;

  /// No description provided for @faqA5.
  ///
  /// In tr, this message translates to:
  /// **'Her alarmdan önce sana sorulur. İyiyim\'e basarsan gruba hiçbir şey gitmez. Çok sık oluyorsa Süreler\'den bekleme süresini uzat.'**
  String get faqA5;

  /// No description provided for @faqQ6.
  ///
  /// In tr, this message translates to:
  /// **'Telefonum uygulamayı kapatıyor'**
  String get faqQ6;

  /// No description provided for @faqA6.
  ///
  /// In tr, this message translates to:
  /// **'İzinler ve arka plan ekranından pil optimizasyonunu kapat ve üretici ayarlarındaki adımları uygula.'**
  String get faqA6;

  /// No description provided for @simActive.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get simActive;

  /// No description provided for @simCalm.
  ///
  /// In tr, this message translates to:
  /// **'Sakin'**
  String get simCalm;

  /// No description provided for @simStill.
  ///
  /// In tr, this message translates to:
  /// **'Hareketsiz'**
  String get simStill;

  /// No description provided for @simSos.
  ///
  /// In tr, this message translates to:
  /// **'SOS gönder'**
  String get simSos;

  /// No description provided for @simTremor.
  ///
  /// In tr, this message translates to:
  /// **'Titreme gönder'**
  String get simTremor;

  /// No description provided for @simDisconnect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı kopar'**
  String get simDisconnect;

  /// No description provided for @simConnect.
  ///
  /// In tr, this message translates to:
  /// **'Bağla'**
  String get simConnect;

  /// No description provided for @simBattery.
  ///
  /// In tr, this message translates to:
  /// **'Pil %{n}'**
  String simBattery(int n);

  /// No description provided for @simFast.
  ///
  /// In tr, this message translates to:
  /// **'Zamanı hızlandır ×10'**
  String get simFast;

  /// No description provided for @obWelcomeHello.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba {name}'**
  String obWelcomeHello(String name);

  /// No description provided for @obWelcomeCaption.
  ///
  /// In tr, this message translates to:
  /// **'senin için yazılmış mesaj'**
  String get obWelcomeCaption;

  /// No description provided for @obWelcomeStart.
  ///
  /// In tr, this message translates to:
  /// **'Başlayalım'**
  String get obWelcomeStart;

  /// No description provided for @obHowTitle.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl çalışır'**
  String get obHowTitle;

  /// No description provided for @obHow1.
  ///
  /// In tr, this message translates to:
  /// **'Yüzük elinin hareketini izler'**
  String get obHow1;

  /// No description provided for @obHow2.
  ///
  /// In tr, this message translates to:
  /// **'Hareket aniden durursa önce sana sorar'**
  String get obHow2;

  /// No description provided for @obHow3.
  ///
  /// In tr, this message translates to:
  /// **'Cevap vermezsen yakınlarına haber gider'**
  String get obHow3;

  /// No description provided for @obPermTitle.
  ///
  /// In tr, this message translates to:
  /// **'İzinler gerekiyor'**
  String get obPermTitle;

  /// No description provided for @obPermNote.
  ///
  /// In tr, this message translates to:
  /// **'Kurulum bitene kadar koruma kapalı.'**
  String get obPermNote;

  /// No description provided for @obBgTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arka planda çalışma'**
  String get obBgTitle;

  /// No description provided for @obBgSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Telefonun pil tasarrufu uygulamayı kapatmasın'**
  String get obBgSubtitle;

  /// No description provided for @obBgButton.
  ///
  /// In tr, this message translates to:
  /// **'Pil optimizasyonunu kapat'**
  String get obBgButton;

  /// No description provided for @obBgBrandSteps.
  ///
  /// In tr, this message translates to:
  /// **'Telefonuna özel adımlar'**
  String get obBgBrandSteps;

  /// No description provided for @obPairTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yüzüğü eşleştir'**
  String get obPairTitle;

  /// No description provided for @obPairSearching.
  ///
  /// In tr, this message translates to:
  /// **'Yüzük aranıyor'**
  String get obPairSearching;

  /// No description provided for @obPairFound.
  ///
  /// In tr, this message translates to:
  /// **'GüvenYüzük bulundu'**
  String get obPairFound;

  /// No description provided for @obPairWave.
  ///
  /// In tr, this message translates to:
  /// **'Elini salla'**
  String get obPairWave;

  /// No description provided for @obPairWaveSub.
  ///
  /// In tr, this message translates to:
  /// **'yüzük seni hissediyor mu, görelim'**
  String get obPairWaveSub;

  /// No description provided for @obPairTap.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi yüzüğe 3 kez vur'**
  String get obPairTap;

  /// No description provided for @obPairTapSub.
  ///
  /// In tr, this message translates to:
  /// **'acil durumda yardım böyle istenir'**
  String get obPairTapSub;

  /// No description provided for @obPairBtOff.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth kapalı. Açınca yüzük aranacak.'**
  String get obPairBtOff;

  /// No description provided for @obPairNoPerm.
  ///
  /// In tr, this message translates to:
  /// **'Bluetooth izni yok. İzinler adımına dön.'**
  String get obPairNoPerm;

  /// No description provided for @obTelegramTitle.
  ///
  /// In tr, this message translates to:
  /// **'Telegram'**
  String get obTelegramTitle;

  /// No description provided for @obContactsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yakın kişiler'**
  String get obContactsTitle;

  /// No description provided for @obContactsEmptyWarn.
  ///
  /// In tr, this message translates to:
  /// **'Hiç kişi eklemedin. Alarm yine gruba gider ama \"Ara\" butonları olmaz. Devam edilsin mi?'**
  String get obContactsEmptyWarn;

  /// No description provided for @obRehearsalTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir prova yapalım'**
  String get obRehearsalTitle;

  /// No description provided for @obRehearsalSub.
  ///
  /// In tr, this message translates to:
  /// **'Gerçek an geldiğinde bu ekranı tanıyor ol'**
  String get obRehearsalSub;

  /// No description provided for @obRehearsalStart.
  ///
  /// In tr, this message translates to:
  /// **'Provayı başlat'**
  String get obRehearsalStart;

  /// No description provided for @obRehearsalDone.
  ///
  /// In tr, this message translates to:
  /// **'Prova tamamlandı'**
  String get obRehearsalDone;

  /// No description provided for @obRehearsalTest.
  ///
  /// In tr, this message translates to:
  /// **'Gruba [TEST] mesajı gönder'**
  String get obRehearsalTest;

  /// No description provided for @obRehearsalTestSub.
  ///
  /// In tr, this message translates to:
  /// **'isteğe bağlı'**
  String get obRehearsalTestSub;

  /// No description provided for @obRehearsalTestSent.
  ///
  /// In tr, this message translates to:
  /// **'[TEST] mesajı gönderildi'**
  String get obRehearsalTestSent;

  /// No description provided for @obReadyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Koruma açık'**
  String get obReadyTitle;

  /// No description provided for @obReadySub.
  ///
  /// In tr, this message translates to:
  /// **'Artık yalnız değilsin'**
  String get obReadySub;

  /// No description provided for @obReadyTipAndroid.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı son uygulamalardan kaydırarak kapatma'**
  String get obReadyTipAndroid;

  /// No description provided for @obReadyTipIos.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı yukarı kaydırarak kapatma'**
  String get obReadyTipIos;

  /// No description provided for @obReadyTipCharge.
  ///
  /// In tr, this message translates to:
  /// **'Yüzüğü her gün kısa bir süre şarj et'**
  String get obReadyTipCharge;

  /// No description provided for @obReadyGo.
  ///
  /// In tr, this message translates to:
  /// **'Ana ekrana git'**
  String get obReadyGo;

  /// No description provided for @obStepOf.
  ///
  /// In tr, this message translates to:
  /// **'Adım {n} / {total}'**
  String obStepOf(int n, int total);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
