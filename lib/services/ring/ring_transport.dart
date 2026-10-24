/// Yüzük bağlantı durumu.
enum RingConnectionState { bluetoothOff, unauthorized, searching, connecting, connected, disconnected }

/// Yüzükle konuşan taşıma katmanı (BLE ya da simülasyon).
abstract class RingTransport {
  Stream<RingConnectionState> get state;
  RingConnectionState get currentState;

  /// Tam satırlar (`\n` olmadan).
  Stream<String> get lines;
  DateTime? get lastSignalAt;
  int? get rssi;

  /// Bağlı cihazın adı (ör. "GuvenYuzuk").
  String? get deviceName;

  /// Yüzük RX karakteristiğine (komut) sahip mi (firmware ≥ 0.2).
  bool get hasRx;

  /// Kayıtlı cihaz kimliği; [start] öncesi ayarlanır.
  String? savedId;

  /// İlk kez bir yüzük bulunup bağlanınca kimliği kaydetmek için çağrılır.
  void Function(String remoteId)? onPaired;

  /// Kayıtlı cihaza bağlan, yoksa tara.
  Future<void> start();
  Future<void> stop();

  /// Komut gönderir; RX yoksa sessizce düşer.
  Future<void> send(String command);
  Future<void> forgetAndRescan();
}
