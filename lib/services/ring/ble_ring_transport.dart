import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../core/constants.dart';
import '../../core/line_buffer.dart';
import '../../data/app_logger.dart';
import 'ring_transport.dart';

/// `flutter_blue_plus` ile Nordic UART üzerinden yüzüğe bağlanır.
///
/// Kayıtlı cihaz varsa `autoConnect` ile bağlanır (menzile girince Android/iOS
/// kendiliğinden bağlar); yoksa adı `GuvenYuzuk` olan cihazı tarar.
class BleRingTransport implements RingTransport {
  BleRingTransport();

  final _stateCtrl = StreamController<RingConnectionState>.broadcast();
  final _linesCtrl = StreamController<String>.broadcast();
  final _buffer = LineBuffer();

  RingConnectionState _state = RingConnectionState.disconnected;
  DateTime? _lastSignalAt;
  int? _rssi;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _rx;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<List<ScanResult>>? _scanSub;
  Timer? _rssiTimer;
  Timer? _retryTimer;
  bool _running = false;
  bool _setupBusy = false;
  bool _optionsSet = false;

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
  int? get rssi => _rssi;
  @override
  bool get hasRx => _rx != null;
  @override
  String? get deviceName {
    final d = _device;
    if (d == null) return null;
    final n = d.platformName.isNotEmpty ? d.platformName : d.advName;
    return n.isEmpty ? K.ringName : n;
  }

  void _set(RingConnectionState s) {
    if (_state == s) return;
    _state = s;
    _stateCtrl.add(s);
  }

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    try {
      if (Platform.isIOS && !_optionsSet) {
        // R3: iOS bellekten atsa bile Bluetooth olayıyla yeniden başlatabilsin.
        await FlutterBluePlus.setOptions(restoreState: true, showPowerAlert: false);
        _optionsSet = true;
      }
      if (!await FlutterBluePlus.isSupported) {
        AppLogger.w('Bu cihaz BLE desteklemiyor');
        _set(RingConnectionState.bluetoothOff);
        return;
      }
    } on Object catch (e) {
      AppLogger.w('BLE başlatılamadı: $e');
    }
    await _adapterSub?.cancel();
    _adapterSub = FlutterBluePlus.adapterState.listen(_onAdapter, onError: (Object e) {
      AppLogger.w('Adaptör durumu: $e');
      _set(RingConnectionState.unauthorized);
    });
  }

  void _onAdapter(BluetoothAdapterState s) {
    switch (s) {
      case BluetoothAdapterState.on:
        unawaited(_connectOrScan());
      case BluetoothAdapterState.off:
      case BluetoothAdapterState.turningOff:
        _set(RingConnectionState.bluetoothOff);
        unawaited(_teardown());
      case BluetoothAdapterState.unauthorized:
        _set(RingConnectionState.unauthorized);
      case BluetoothAdapterState.unavailable:
        _set(RingConnectionState.bluetoothOff);
      case BluetoothAdapterState.unknown:
      case BluetoothAdapterState.turningOn:
        break;
    }
  }

  Future<void> _connectOrScan() async {
    if (!_running) return;
    final id = savedId;
    if (id != null && id.isNotEmpty) {
      await _connect(BluetoothDevice.fromId(id));
    } else {
      await _scan();
    }
  }

  Future<void> _scan() async {
    if (!_running || FlutterBluePlus.isScanningNow) return;
    _set(RingConnectionState.searching);
    await _scanSub?.cancel();
    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final name = r.advertisementData.advName.isNotEmpty ? r.advertisementData.advName : r.device.platformName;
        final nus = r.advertisementData.serviceUuids.any((g) => g.str128.toUpperCase() == K.nusService);
        if (name == K.ringName || nus) {
          _rssi = r.rssi;
          unawaited(FlutterBluePlus.stopScan());
          unawaited(_connect(r.device, firstPairing: true));
          return;
        }
      }
    }, onError: (Object e) => AppLogger.w('Tarama: $e'));
    try {
      await FlutterBluePlus.startScan(withKeywords: const [K.ringName], timeout: K.scanWindow);
    } on Object catch (e) {
      AppLogger.w('Tarama başlatılamadı: $e');
      _set(RingConnectionState.unauthorized);
      _running = false;
      return;
    }
    _retryTimer?.cancel();
    _retryTimer = Timer(K.scanWindow + K.scanPause, () {
      if (_running && _device == null) unawaited(_scan());
    });
  }

  Future<void> _connect(BluetoothDevice d, {bool firstPairing = false}) async {
    if (!_running) return;
    _device = d;
    _set(RingConnectionState.connecting);
    await _connSub?.cancel();
    _connSub = d.connectionState.listen((s) {
      if (s == BluetoothConnectionState.connected) {
        unawaited(_onConnected(d, firstPairing: firstPairing));
      } else if (s == BluetoothConnectionState.disconnected) {
        _onDisconnected();
      }
    });
    try {
      // KARAR: Kişisel/kâr amacı gütmeyen kullanım → FlutterBluePlus "nonprofit" lisansı.
      // autoConnect ile mtu birlikte kullanılamaz; MTU bağlantıdan sonra istenir.
      await d.connect(license: License.nonprofit, autoConnect: true, mtu: null);
    } on Object catch (e) {
      AppLogger.w('Bağlanılamadı: $e');
      _scheduleReconnect();
    }
  }

  Future<void> _onConnected(BluetoothDevice d, {required bool firstPairing}) async {
    if (_setupBusy) return;
    _setupBusy = true;
    try {
      if (Platform.isAndroid) {
        try {
          await d.requestMtu(K.desiredMtu);
        } on Object catch (e) {
          AppLogger.w('MTU istenemedi: $e');
        }
      }
      final services = await d.discoverServices();
      BluetoothCharacteristic? tx;
      BluetoothCharacteristic? rx;
      for (final s in services) {
        if (s.uuid.str128.toUpperCase() != K.nusService) continue;
        for (final c in s.characteristics) {
          final u = c.uuid.str128.toUpperCase();
          if (u == K.nusTx) tx = c;
          if (u == K.nusRx) rx = c;
        }
      }
      if (tx == null) {
        AppLogger.w('Yüzükte NUS TX karakteristiği yok');
        await d.disconnect();
        return;
      }
      _rx = rx;
      _buffer.clear();
      await _notifySub?.cancel();
      final sub = tx.onValueReceived.listen(_onBytes);
      _notifySub = sub;
      d.cancelWhenDisconnected(sub);
      await tx.setNotifyValue(true);
      _lastSignalAt = DateTime.now();
      _set(RingConnectionState.connected);
      AppLogger.i('Yüzük bağlandı (${d.remoteId.str.substring(0, 5)}…)');
      if (firstPairing || savedId == null) {
        savedId = d.remoteId.str;
        onPaired?.call(d.remoteId.str);
      }
      _rssiTimer?.cancel();
      _rssiTimer = Timer.periodic(K.rssiInterval, (_) => unawaited(_readRssi()));
      unawaited(_readRssi());
    } on Object catch (e) {
      AppLogger.w('Yüzük kurulumu başarısız: $e');
      _scheduleReconnect();
    } finally {
      _setupBusy = false;
    }
  }

  Future<void> _readRssi() async {
    final d = _device;
    if (d == null || !d.isConnected) return;
    try {
      _rssi = await d.readRssi();
    } on Object catch (_) {
      // RSSI isteğe bağlıdır.
    }
  }

  void _onBytes(List<int> bytes) {
    _lastSignalAt = DateTime.now();
    for (final l in _buffer.add(bytes)) {
      _linesCtrl.add(l);
    }
  }

  void _onDisconnected() {
    _rx = null;
    _rssiTimer?.cancel();
    if (_state == RingConnectionState.connected || _state == RingConnectionState.connecting) {
      _set(RingConnectionState.disconnected);
      AppLogger.i('Yüzük bağlantısı koptu');
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_running) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(K.reconnectDelay, () {
      final d = _device;
      if (!_running) return;
      if (d != null && d.isConnected) return;
      unawaited(_connectOrScan());
    });
  }

  @override
  Future<void> send(String command) async {
    final rx = _rx;
    if (rx == null) return;
    try {
      final noResp = rx.properties.writeWithoutResponse && !rx.properties.write;
      await rx.write(command.codeUnits, withoutResponse: noResp);
    } on Object catch (e) {
      AppLogger.w('Komut gönderilemedi: $e');
    }
  }

  Future<void> _teardown() async {
    _rssiTimer?.cancel();
    _retryTimer?.cancel();
    await _notifySub?.cancel();
    _notifySub = null;
    _rx = null;
    try {
      await FlutterBluePlus.stopScan();
    } on Object catch (_) {}
  }

  @override
  Future<void> stop() async {
    _running = false;
    await _teardown();
    await _scanSub?.cancel();
    await _connSub?.cancel();
    await _adapterSub?.cancel();
    final d = _device;
    if (d != null) {
      try {
        await d.disconnect();
      } on Object catch (_) {}
    }
    _set(RingConnectionState.disconnected);
  }

  @override
  Future<void> forgetAndRescan() async {
    await stop();
    savedId = null;
    _device = null;
    _rssi = null;
    await start();
  }
}
