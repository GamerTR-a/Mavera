import 'sms_sender.dart';

/// iOS: uygulamalar arka planda SMS gönderemez.
class NoopSmsSender implements SmsSender {
  @override
  bool get available => false;

  @override
  Future<bool> send(List<String> phones, String text) async => false;
}
