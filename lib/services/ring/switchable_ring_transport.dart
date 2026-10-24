import 'dart:async';

import 'ring_transport.dart';

/// Gerçek BLE ile simülasyon arasında çalışma anında geçiş yapan sarmalayıcı.
/// Monitor tek bir akış görür; altta hangi taşıyıcının çalıştığını bilmez.
class SwitchableRingTransport implements RingTransport {
  SwitchableRingTransport(this._inner) {
    _attach();
  }

  RingTransport _inner;
  final _stateCtrl = StreamController<RingConnectionState>.broadcast();
  final _linesCtrl = StreamController<String>.broadcast();
  StreamSubscription<RingConnectionState>? _s1;
  StreamSubscription<String>? _s2;
  bool _started = false;

  RingTransport get inner => _inner;

  void _attach() {
    _s1 = _inner.state.listen(_stateCtrl.add);
    _s2 = _inner.lines.listen(_linesCtrl.add);
  }

  /// Altta çalışan taşıyıcıyı değiştirir.
  Future<void> swap(RingTransport next) async {
    final wasStarted = _started;
    await _inner.stop();
    await _s1?.cancel();
    await _s2?.cancel();
    next.onPaired = _inner.onPaired;
    _inner = next;
    _attach();
    _stateCtrl.add(next.currentState);
    if (wasStarted) await next.start();
  }

  @override
  String? get savedId => _inner.savedId;
  @override
  set savedId(String? v) => _inner.savedId = v;
  @override
  void Function(String remoteId)? get onPaired => _inner.onPaired;
  @override
  set onPaired(void Function(String remoteId)? f) => _inner.onPaired = f;

  @override
  Stream<RingConnectionState> get state => _stateCtrl.stream;
  @override
  RingConnectionState get currentState => _inner.currentState;
  @override
  Stream<String> get lines => _linesCtrl.stream;
  @override
  DateTime? get lastSignalAt => _inner.lastSignalAt;
  @override
  int? get rssi => _inner.rssi;
  @override
  String? get deviceName => _inner.deviceName;
  @override
  bool get hasRx => _inner.hasRx;

  @override
  Future<void> start() {
    _started = true;
    return _inner.start();
  }

  @override
  Future<void> stop() {
    _started = false;
    return _inner.stop();
  }

  @override
  Future<void> send(String command) => _inner.send(command);

  @override
  Future<void> forgetAndRescan() => _inner.forgetAndRescan();

  Future<void> dispose() async {
    await _inner.stop();
    await _s1?.cancel();
    await _s2?.cancel();
    await _stateCtrl.close();
    await _linesCtrl.close();
  }
}
