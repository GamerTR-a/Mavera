import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../data/app_logger.dart';
import 'sms_sender.dart';

/// Kotlin `SmsPlugin` üzerinden `SmsManager` ile SMS gönderir.
class AndroidSmsSender implements SmsSender {
  static const _channel = MethodChannel(Channels.sms);

  @override
  bool get available => true;

  @override
  Future<bool> send(List<String> phones, String text) async {
    if (phones.isEmpty) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('send', {'phones': phones, 'text': text});
      return ok ?? false;
    } on PlatformException catch (e) {
      AppLogger.w('SMS gönderilemedi: ${e.code} ${e.message}');
      return false;
    }
  }
}
