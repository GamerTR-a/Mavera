import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mavera/core/alarm_record.dart';
import 'package:mavera/core/events.dart';
import 'package:mavera/core/models.dart';
import 'package:mavera/core/monitor.dart';
import 'package:mavera/l10n/generated/app_localizations.dart';
import 'package:mavera/services/location/location_provider.dart';
import 'package:mavera/services/sms/sms_sender.dart';
import 'package:mavera/services/telegram/telegram_sender.dart';
import 'package:mavera/theme/app_theme.dart';

class FakeSink implements AlarmSink {
  final dispatched = <AlarmRecord>[];
  int closes = 0;
  int extra = 0;

  @override
  void dispatch(AlarmRecord r) => dispatched.add(r);
  @override
  void close({required bool byUser}) => closes++;
  @override
  void extraSos() => extra++;
}

class FakeEvents implements MonitorEvents {
  final logs = <EventKind>[];
  final notified = <AppNotificationKind>[];
  final cancelled = <AppNotificationKind>[];
  final sentToGroup = <EventKind>[];

  @override
  void log(EventKind k, String detail, {bool sentToGroup = false}) {
    logs.add(k);
    if (sentToGroup) this.sentToGroup.add(k);
  }

  @override
  void notify(AppNotification n) => notified.add(n.kind);
  @override
  void cancel(AppNotification n) => cancelled.add(n.kind);
}

class FakeTelegram implements TelegramSender {
  bool failing = false;
  int failCode = 0;
  final messages = <String>[];
  final liveSent = <Coord>[];
  final liveEdits = <Coord>[];
  final stopped = <int>[];
  int calls = 0;

  void _maybeFail() {
    calls++;
    if (failing) throw TelegramException(failCode, 'fail');
  }

  @override
  Future<String> getMe(String token) async {
    _maybeFail();
    return 'bot';
  }

  @override
  Future<int> sendMessage(String token, String chatId, String text) async {
    _maybeFail();
    messages.add(text);
    return messages.length;
  }

  @override
  Future<int> sendLiveLocation(String token, String chatId, Coord c, {int livePeriod = 3600}) async {
    _maybeFail();
    liveSent.add(c);
    return 99;
  }

  @override
  Future<void> editLiveLocation(String token, String chatId, int messageId, Coord c) async {
    _maybeFail();
    liveEdits.add(c);
  }

  @override
  Future<void> stopLiveLocation(String token, String chatId, int messageId) async {
    _maybeFail();
    stopped.add(messageId);
  }
}

class FakeLocation implements LocationProvider {
  FakeLocation([this.coord = const Coord(41.0082, 28.9784, accuracy: 12)]);
  Coord? coord;
  // ignore: close_sinks
  final live$ = StreamController<Coord>.broadcast();

  @override
  Future<Coord?> current({Duration timeout = const Duration(seconds: 8)}) async => coord;
  @override
  Stream<Coord> live() => live$.stream;
  @override
  Future<bool> precise() async => true;
  @override
  Future<void> request() async {}
  @override
  Future<LocationAuth> status() async => LocationAuth.always;
}

class FakeSms implements SmsSender {
  FakeSms({this.available = true});
  @override
  final bool available;
  final sends = <String>[];

  @override
  Future<bool> send(List<String> phones, String text) async {
    sends.add(text);
    return true;
  }
}

/// Testlerde Türkçe yerelleştirme ve tema ile sarar.
Widget wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );
