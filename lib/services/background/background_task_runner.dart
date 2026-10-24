import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../data/app_logger.dart';

/// iOS'ta alarm gönderimi için ek arka plan süresi ister
/// (`UIApplication.beginBackgroundTask`). Android'de ön plan servisi yeterlidir.
abstract class BackgroundTaskRunner {
  Future<int?> begin();
  Future<void> end(int? id);
}

class NoopBackgroundTaskRunner implements BackgroundTaskRunner {
  @override
  Future<int?> begin() async => null;
  @override
  Future<void> end(int? id) async {}
}

class IosBackgroundTaskRunner implements BackgroundTaskRunner {
  static const _channel = MethodChannel(Channels.backgroundTask);

  @override
  Future<int?> begin() async {
    try {
      return await _channel.invokeMethod<int>('begin');
    } on PlatformException catch (e) {
      AppLogger.w('beginBackgroundTask: ${e.message}');
      return null;
    }
  }

  @override
  Future<void> end(int? id) async {
    if (id == null) return;
    try {
      await _channel.invokeMethod<void>('end', {'id': id});
    } on PlatformException catch (e) {
      AppLogger.w('endBackgroundTask: ${e.message}');
    }
  }
}
