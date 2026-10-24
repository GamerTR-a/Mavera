import 'dart:io';

import 'package:flutter/services.dart';

import '../core/constants.dart';
import '../data/app_logger.dart';

/// Kotlin `MainActivity`/`MaveraApplication` tarafındaki yardımcı yöntemler.
abstract final class SystemChannel {
  static const _ch = MethodChannel(Channels.system);

  /// Android 14+: `NotificationManager.canUseFullScreenIntent()`.
  static Future<bool> canUseFullScreenIntent() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _ch.invokeMethod<bool>('canUseFullScreenIntent') ?? true;
    } on PlatformException catch (e) {
      AppLogger.w('canUseFullScreenIntent: ${e.message}');
      return true;
    }
  }

  /// Üreticiye özel otomatik başlatma / arka plan ayarını açar;
  /// açılamazsa uygulama ayrıntılarına düşer.
  static Future<void> openManufacturerSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _ch.invokeMethod<void>('openManufacturerSettings');
    } on PlatformException catch (e) {
      AppLogger.w('Üretici ayarı açılamadı: ${e.message}');
    }
  }

  /// Bluetooth ayarlarını açar.
  static Future<void> openBluetoothSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _ch.invokeMethod<void>('openBluetoothSettings');
    } on PlatformException catch (e) {
      AppLogger.w('Bluetooth ayarı açılamadı: ${e.message}');
    }
  }
}
