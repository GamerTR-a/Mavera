/// SMS yedeği soyutlaması. iOS'ta `available == false`.
abstract class SmsSender {
  bool get available;

  /// Tüm numaralara gönderir; hepsi başarılıysa `true`.
  Future<bool> send(List<String> phones, String text);
}
