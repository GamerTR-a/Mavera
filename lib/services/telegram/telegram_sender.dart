import '../../core/models.dart';

/// Telegram Bot API hatası.
class TelegramException implements Exception {
  const TelegramException(this.code, this.description, {this.retryAfter});
  final int code;
  final String description;

  /// 429 cevabında beklenecek süre (sn).
  final int? retryAfter;

  /// Kullanıcıya gösterilecek Türkçe açıklama.
  String get userMessage {
    if (code == 401 || code == 404) return 'Token hatalı';
    if (code == 400 && description.toLowerCase().contains('chat not found')) {
      return 'Grup bulunamadı, bot gruba ekli mi?';
    }
    if (code == 403) return 'Bot gruptan çıkarılmış ya da yazma izni yok';
    if (code == 429) return 'Çok fazla istek, biraz sonra yeniden dene';
    if (code == 0) return 'İnternete ulaşılamıyor';
    return 'Telegram hatası ($code): $description';
  }

  @override
  String toString() => 'TelegramException($code, $description)';
}

/// Telegram Bot API soyutlaması.
abstract class TelegramSender {
  Future<String> getMe(String token);
  Future<int> sendMessage(String token, String chatId, String text);
  Future<int> sendLiveLocation(String token, String chatId, Coord c, {int livePeriod = 3600});
  Future<void> editLiveLocation(String token, String chatId, int messageId, Coord c);
  Future<void> stopLiveLocation(String token, String chatId, int messageId);
}
