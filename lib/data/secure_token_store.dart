import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_logger.dart';

/// Telegram bot token'ının güvenli deposu.
///
/// KARAR: flutter_secure_storage 11'de `encryptedSharedPreferences` seçeneği
/// kaldırıldı; varsayılan Android seçenekleri zaten Keystore + AES-GCM ile şifreler.
/// iOS'ta `first_unlock`: kilitli ekranda arka planda okunabilir.
class SecureTokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _s = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _s;
  static const _key = 'telegram_bot_token';
  String? _cache;

  Future<String?> read() async {
    final c = _cache;
    if (c != null) return c;
    try {
      _cache = await _s.read(key: _key);
    } on Object catch (e) {
      AppLogger.e('Token okunamadı', e);
    }
    return _cache;
  }

  Future<void> write(String token) async {
    _cache = token.trim();
    await _s.write(key: _key, value: token.trim());
  }

  Future<bool> get hasToken async => (await read() ?? '').isNotEmpty;
}
