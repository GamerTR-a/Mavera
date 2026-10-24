import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/app_logger.dart';
import 'data/settings_repository.dart';
import 'providers/providers.dart';

/// Servisler ilk widget çizilmeden önce başlatılır: uygulama arka planda,
/// ekran kapalıyken ya da sistem tarafından (açılış, Bluetooth olayı)
/// başlatıldığında da çekirdek UI olmadan çalışır.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr');
  Intl.defaultLocale = 'tr';

  final support = await getApplicationSupportDirectory();
  await AppLogger.init(support);
  FlutterError.onError = (d) {
    AppLogger.e('Flutter hatası', d.exception, d.stack);
    FlutterError.presentError(d);
  };
  PlatformDispatcher.instance.onError = (e, st) {
    AppLogger.e('Yakalanmamış hata', e, st);
    return true;
  };

  final prefs = await SharedPreferences.getInstance();
  final db = await AppDatabase.open();
  final container = ProviderContainer(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      supportDirProvider.overrideWithValue(support),
    ],
  );

  try {
    await container.read(appCoreProvider).start();
    AppLogger.i('Çekirdek başladı');
  } on Object catch (e, st) {
    AppLogger.e('Çekirdek başlatılamadı', e, st);
  }

  runApp(UncontrolledProviderScope(container: container, child: const GuvenApp()));
}
