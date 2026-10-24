/// Uygulamanın arka planda yaşamasını sağlayan platform katmanı.
abstract class BackgroundHost {
  /// Korumayı arka planda başlatır (Android: ön plan servisi).
  /// [foreground]: uygulama şu an kullanıcıya görünür mü.
  Future<void> start(String text, {bool foreground = false});
  Future<void> stop();
  Future<bool> isRunning();
  Future<void> update(String text);

  /// Uygulama ön plana gelince çağrılır; yalnızca ön planda açılabilen
  /// yetenekleri (Android: konum tipli servis) etkinleştirir.
  Future<void> ensureForegroundCapabilities(String text);

  /// Platform 1 sn'lik zamanlayıcıyı arka planda da çalıştırabiliyor mu.
  bool get timersRunInBackground;
}
