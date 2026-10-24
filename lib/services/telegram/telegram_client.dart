import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../../core/models.dart';
import 'telegram_sender.dart';

/// `https://api.telegram.org` ile doğrudan konuşan istemci.
class TelegramClient implements TelegramSender {
  TelegramClient({http.Client? client, this.timeout = K.telegramTimeout})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  /// Log'a yazılabilecek, token'ı maskelenmiş URL.
  static String maskedUrl(String method) => 'https://api.telegram.org/bot***/$method';

  Future<Map<String, Object?>> _call(String token, String method, Map<String, String> fields) async {
    final uri = Uri.parse('https://api.telegram.org/bot$token/$method');
    http.Response res;
    try {
      res = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8'},
            body: fields,
            encoding: utf8,
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const TelegramException(0, 'zaman aşımı');
    } on Exception catch (e) {
      throw TelegramException(0, 'ağ hatası: ${e.runtimeType}');
    }
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      throw TelegramException(res.statusCode, 'geçersiz cevap');
    }
    if (decoded is! Map<String, Object?>) {
      throw TelegramException(res.statusCode, 'geçersiz cevap');
    }
    if (decoded['ok'] != true) {
      final code = (decoded['error_code'] as num?)?.toInt() ?? res.statusCode;
      final desc = decoded['description'] as String? ?? '';
      final params = decoded['parameters'];
      final retry = params is Map<String, Object?> ? (params['retry_after'] as num?)?.toInt() : null;
      throw TelegramException(code, desc, retryAfter: retry);
    }
    return decoded;
  }

  int _messageId(Map<String, Object?> r) {
    final result = r['result'];
    if (result is Map<String, Object?>) {
      return (result['message_id'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  static Map<String, String> _locationFields(Coord c) {
    final f = <String, String>{
      'latitude': c.lat.toStringAsFixed(6),
      'longitude': c.lon.toStringAsFixed(6),
    };
    final acc = c.accuracy;
    if (acc != null) {
      f['horizontal_accuracy'] = acc.clamp(0, K.maxHorizontalAccuracy).toStringAsFixed(0);
    }
    return f;
  }

  @override
  Future<String> getMe(String token) async {
    final r = await _call(token, 'getMe', const {});
    final result = r['result'];
    return result is Map<String, Object?> ? (result['username'] as String? ?? '') : '';
  }

  @override
  Future<int> sendMessage(String token, String chatId, String text) async {
    final r = await _call(token, 'sendMessage', {
      'chat_id': chatId,
      'text': text,
      'disable_web_page_preview': 'true',
    });
    return _messageId(r);
  }

  @override
  Future<int> sendLiveLocation(String token, String chatId, Coord c, {int livePeriod = 3600}) async {
    final r = await _call(token, 'sendLocation', {
      'chat_id': chatId,
      ..._locationFields(c),
      'live_period': '$livePeriod',
    });
    return _messageId(r);
  }

  /// Canlı olmayan tek konum (prova).
  Future<int> sendStaticLocation(String token, String chatId, Coord c) async {
    final r = await _call(token, 'sendLocation', {'chat_id': chatId, ..._locationFields(c)});
    return _messageId(r);
  }

  @override
  Future<void> editLiveLocation(String token, String chatId, int messageId, Coord c) async {
    try {
      await _call(token, 'editMessageLiveLocation', {
        'chat_id': chatId,
        'message_id': '$messageId',
        ..._locationFields(c),
      });
    } on TelegramException catch (e) {
      // Konum değişmediyse Telegram 400 "message is not modified" döner; hata değildir.
      if (!e.description.contains('not modified')) rethrow;
    }
  }

  @override
  Future<void> stopLiveLocation(String token, String chatId, int messageId) async {
    await _call(token, 'stopMessageLiveLocation', {'chat_id': chatId, 'message_id': '$messageId'});
  }
}
