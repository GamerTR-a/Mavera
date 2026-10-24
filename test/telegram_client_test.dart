import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mavera/core/models.dart';
import 'package:mavera/services/telegram/telegram_client.dart';
import 'package:mavera/services/telegram/telegram_sender.dart';

void main() {
  test('form kodlama: Türkçe karakter ve emoji korunur', () async {
    late http.Request captured;
    final client = TelegramClient(
      client: MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode({'ok': true, 'result': {'message_id': 42}}), 200,
            headers: {'content-type': 'application/json'});
      }),
    );
    const text = '🚨 ACİL DURUM – Meryem\nŞöyle ğüıçö';
    final id = await client.sendMessage('123:abc', '-100', text);
    expect(id, 42);
    expect(captured.url.toString(), 'https://api.telegram.org/bot123:abc/sendMessage');
    expect(captured.bodyFields['text'], text);
    expect(captured.bodyFields['chat_id'], '-100');
    expect(captured.bodyFields['disable_web_page_preview'], 'true');
  });

  test('canlı konum alanları', () async {
    late http.Request captured;
    final client = TelegramClient(
      client: MockClient((req) async {
        captured = req;
        return http.Response(jsonEncode({'ok': true, 'result': {'message_id': 7}}), 200);
      }),
    );
    await client.sendLiveLocation('t', '-1', const Coord(41.0082, 28.9784, accuracy: 4000));
    expect(captured.bodyFields['latitude'], '41.008200');
    expect(captured.bodyFields['horizontal_accuracy'], '1500');
    expect(captured.bodyFields['live_period'], '3600');
  });

  test('ok=false → TelegramException', () async {
    final client = TelegramClient(
      client: MockClient((req) async => http.Response(
          jsonEncode({'ok': false, 'error_code': 400, 'description': 'Bad Request: chat not found'}), 400)),
    );
    await expectLater(
      client.sendMessage('t', '1', 'x'),
      throwsA(isA<TelegramException>()
          .having((e) => e.code, 'code', 400)
          .having((e) => e.userMessage, 'msg', 'Grup bulunamadı, bot gruba ekli mi?')),
    );
  });

  test('401 → "Token hatalı"', () async {
    final client = TelegramClient(
      client: MockClient(
          (req) async => http.Response(jsonEncode({'ok': false, 'error_code': 401, 'description': 'Unauthorized'}), 401)),
    );
    await expectLater(
      client.getMe('t'),
      throwsA(isA<TelegramException>().having((e) => e.userMessage, 'msg', 'Token hatalı')),
    );
  });

  test('429 → retry_after okunur', () async {
    final client = TelegramClient(
      client: MockClient((req) async => http.Response(
          jsonEncode({
            'ok': false,
            'error_code': 429,
            'description': 'Too Many Requests',
            'parameters': {'retry_after': 17},
          }),
          429)),
    );
    await expectLater(
      client.sendMessage('t', '1', 'x'),
      throwsA(isA<TelegramException>().having((e) => e.retryAfter, 'retryAfter', 17)),
    );
  });

  test('ağ hatası → code 0', () async {
    final client = TelegramClient(client: MockClient((req) async => throw http.ClientException('offline')));
    await expectLater(
      client.sendMessage('t', '1', 'x'),
      throwsA(isA<TelegramException>().having((e) => e.code, 'code', 0)),
    );
  });

  test('maskeli URL token içermez', () {
    expect(TelegramClient.maskedUrl('sendMessage'), isNot(contains('123')));
  });
}
