import 'dart:async';
import 'dart:math' as math;

import '../../core/constants.dart';
import 'ring_transport.dart';

/// Simüle hareket seviyesi.
enum SimMotion {
  active(120),
  calm(10),
  still(0);

  const SimMotion(this.moves);
  final int moves;
}

/// Donanımsız test için yüzük simülasyonu (yalnızca debug).
class SimulatedRingTransport implements RingTransport {
  final _stateCtrl = StreamController<RingConnectionState>.broadcast();
  final _linesCtrl = StreamController<String>.broadcast();
  final _rand = math.Random();

  RingConnectionState _state = RingConnectionState.disconnected;
  DateTime? _lastSignalAt;
  Timer? _hbTimer;
  Timer? _rawTimer;
  int _seq = 0;
  bool _running = false;

  SimMotion motion = SimMotion.active;
  int batteryPct = 80;
  bool _fast = false;

  @override
  String? savedId;
  @override
  void Function(String remoteId)? onPaired;

  @override
  Stream<RingConnectionState> get state => _stateCtrl.stream;
  @override
  RingConnectionState get currentState => _state;
  @override
  Stream<String> get lines => _linesCtrl.stream;
  @override
  DateTime? get lastSignalAt => _lastSignalAt;
  @override
  int? get rssi => _state == RingConnectionState.connected ? -55 : null;
  @override
  String? get deviceName => 'GuvenYuzuk (simüle)';
  @override
  bool get hasRx => true;

  bool get fast => _fast;
  bool get connected => _state == RingConnectionState.connected;

  /// "Zamanı hızlandır ×10": sinyal aralığı 3 sn.
  set fast(bool v) {
    _fast = v;
    if (connected) _startHeartbeat();
  }

  void _set(RingConnectionState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  void _emit(String line) {
    _lastSignalAt = DateTime.now();
    _linesCtrl.add(line);
  }

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    _set(RingConnectionState.searching);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    connect();
  }

  void connect() {
    if (!_running) return;
    _set(RingConnectionState.connected);
    if (savedId == null) {
      savedId = 'SIMULATED';
      onPaired?.call('SIMULATED');
    }
    _startHeartbeat();
    _heartbeat();
  }

  void disconnect() {
    _hbTimer?.cancel();
    _rawTimer?.cancel();
    _set(RingConnectionState.disconnected);
  }

  void _startHeartbeat() {
    _hbTimer?.cancel();
    final interval = _fast ? const Duration(seconds: 3) : K.heartbeatInterval;
    _hbTimer = Timer.periodic(interval, (_) => _heartbeat());
  }

  void _heartbeat() {
    if (!connected) return;
    final m = motion.moves == 0 ? 0 : motion.moves + _rand.nextInt(motion.moves ~/ 2 + 1);
    final mv = 3300 + batteryPct * 9;
    _emit('HB,$_seq,$m,${m * 3},$mv,$batteryPct,0');
    _seq = (_seq + 1) % 256;
  }

  void sendSos() {
    if (!connected) return;
    _emit('SOS,$_seq');
    _seq = (_seq + 1) % 256;
  }

  void sendTremor() {
    if (!connected) return;
    _emit('TRM,$_seq');
    _seq = (_seq + 1) % 256;
  }

  @override
  Future<void> send(String command) async {
    final c = command.trim();
    if (c == 'VER?') {
      _emit('VER,0.2');
    } else if (c == 'RAW,1') {
      _rawTimer?.cancel();
      _rawTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        final base = motion.moves == 0 ? 0 : motion.moves ~/ 2;
        _emit('RAW,${base + _rand.nextInt(base + 2)}');
      });
    } else if (c == 'RAW,0') {
      _rawTimer?.cancel();
    }
  }

  @override
  Future<void> stop() async {
    _running = false;
    disconnect();
  }

  @override
  Future<void> forgetAndRescan() async {
    await stop();
    savedId = null;
    await start();
  }
}
