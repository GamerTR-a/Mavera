// Play Store ekran görüntülerini üretir (1080×1920 PNG):
//   flutter test tool/store_screenshots_test.dart
// Çıktı: store/screenshot_1_ana_ekran.png, store/screenshot_2_on_uyari.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mavera/core/alarm_reason.dart';
import 'package:mavera/core/health_check.dart';
import 'package:mavera/core/models.dart';
import 'package:mavera/core/monitor_phase.dart';
import 'package:mavera/data/settings_repository.dart';
import 'package:mavera/l10n/generated/app_localizations.dart';
import 'package:mavera/providers/providers.dart';
import 'package:mavera/services/alarm_dispatcher.dart';
import 'package:mavera/services/app_core.dart';
import 'package:mavera/services/ring/ring_transport.dart';
import 'package:mavera/theme/app_theme.dart';
import 'package:mavera/ui/main/home_screen.dart';
import 'package:mavera/ui/main/pre_alarm_screen.dart';

const _fonts = r'C:\flutter\bin\cache\artifacts\material_fonts';
const _brand = Color(0xFF0F2346);
const _brand2 = Color(0xFF23467F);

/// Telefon ekranının mantıksal boyutu (yaklaşık 9:18 bir Android telefon).
const _screenW = 360.0;
const _screenH = 740.0;

class _Settings extends SettingsRepository {
  @override
  AppSettings build() => const AppSettings(onboardingDone: true);
}

class _View extends CoreViewNotifier {
  @override
  CoreView build() {
    final now = DateTime.now();
    return CoreView(
      phase: const Watching(),
      lastMotionAt: now,
      ringBattery: 64,
      ringMillivolts: 3920,
      recentMoves: const [
        80, 95, 120, 60, 40, 70, 110, 130, 90, 50, 30, 45, 85, 120, 140, 100, 70, 55, 65, 90,
        115, 125, 95, 60, 35, 50, 75, 105, 130, 110, 80, 60, 70, 95, 120, 100, 85, 65, 90, 110,
      ],
      connection: RingConnectionState.connected,
      rssi: -55,
      lastSignalAt: now.subtract(const Duration(seconds: 12)),
      deviceName: 'GuvenYuzuk',
      delivery: const Idle(),
      record: null,
      shield: ShieldLevel.protected,
      issues: const [],
      batteryRemaining: const Duration(days: 3),
      lastFullAt: null,
      heartbeatCount: 0,
    );
  }
}

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(Future.value(ByteData.sublistView(File('$_fonts\\$f').readAsBytesSync())));
  }
  await loader.load();
}

/// Uygulamanın kendi teması ve Türkçe yerelleştirmesiyle bir ekran.
Widget _app(Widget home, {List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      ),
    );

/// Lacivert zemin + başlık + telefon ekranı.
Widget _frame({required String title, required String subtitle, required Widget screen}) => Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_brand, _brand2],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(26, 34, 26, 0),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 13.5, color: Color(0xFFD6E0F2), height: 1.35),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1730),
                    borderRadius: BorderRadius.circular(44),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 30, offset: Offset(0, 12))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: SizedBox(
                      width: _screenW,
                      height: _screenH,
                      child: MediaQuery(
                        data: const MediaQueryData(size: Size(_screenW, _screenH), padding: EdgeInsets.only(top: 10)),
                        child: screen,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );

Future<void> _shoot(WidgetTester tester, Widget w, String file) async {
  final key = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(key: key, child: w));
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
  await tester.runAsync(() async {
    final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) throw StateError('render yok');
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('png yok');
    Directory('store').createSync(recursive: true);
    File('store/$file').writeAsBytesSync(data.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    await _loadFont('Roboto', [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
      'roboto-black.ttf',
    ]);
    await _loadFont('MaterialIcons', ['materialicons-regular.otf']);
    // Yazı tipi adı vermeyen metinler (buton stilleri) testte yer tutucu fonta düşer;
    // telefonda olduğu gibi Roboto görünsün.
    await _loadFont('FlutterTest', ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-black.ttf']);
  });

  testWidgets('mağaza görselleri', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final today = DateTime.now();
    DateTime at(int h, int m) => DateTime(today.year, today.month, today.day, h, m);

    await _shoot(
      tester,
      _frame(
        title: 'Şu an korunuyor musun?\nTek bakışta gör.',
        subtitle: 'Yüzük elinin hareketini izler. Koruma durumu, pil ve son olaylar tek ekranda.',
        screen: _app(
          const HomeScreen(),
          overrides: [
            settingsProvider.overrideWith(_Settings.new),
            coreViewProvider.overrideWith(_View.new),
            recentEventsProvider.overrideWith((ref) async => [
                  EventEntry(at: at(14, 2), kind: 'preAlarmCancelled', detail: '', movesSnapshot: const [], sentToGroup: false),
                  EventEntry(at: at(9, 15), kind: 'ringConnected', detail: '', movesSnapshot: const [], sentToGroup: false),
                ]),
          ],
        ),
      ),
      'screenshot_1_ana_ekran.png',
    );

    await _shoot(
      tester,
      _frame(
        title: 'Önce sana sorar.\nTek dokunuşla iptal.',
        subtitle: 'Hareket aniden durursa uyarı gelir. Cevap vermezsen yakınlarına konumunla haber gider.',
        screen: _app(
          Scaffold(
            body: PreAlarmView(
              reason: const Inactivity(minutes: 3, abrupt: true),
              remaining: 42,
              total: 60,
              onImFine: () {},
              onSendNow: () {},
            ),
          ),
        ),
      ),
      'screenshot_2_on_uyari.png',
    );
  });
}
