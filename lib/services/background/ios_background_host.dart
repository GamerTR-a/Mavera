import 'background_host.dart';

/// iOS: ayrı bir servis yoktur. Info.plist `UIBackgroundModes`
/// (`bluetooth-central`, `location`) ve Bluetooth durum geri yükleme ile
/// uygulama yüzükten gelen her satırda birkaç saniyeliğine uyanır.
class IosBackgroundHost implements BackgroundHost {
  @override
  bool get timersRunInBackground => false;

  @override
  Future<void> start(String text, {bool foreground = false}) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<bool> isRunning() async => true;

  @override
  Future<void> update(String text) async {}

  @override
  Future<void> ensureForegroundCapabilities(String text) async {}
}
