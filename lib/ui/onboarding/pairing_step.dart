import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ring_protocol.dart';
import '../../data/settings_repository.dart';
import '../../providers/providers.dart';
import '../../services/ring/ring_transport.dart';
import '../../theme/app_colors.dart';
import '../components/signal_bars.dart';
import '../l10n.dart';

/// Ekran 4: Yüzüğü eşleştir. Devam: bağlı + "elini salla" ✓ (vurma atlanabilir).
class PairingStep extends ConsumerStatefulWidget {
  const PairingStep({super.key, required this.onCanContinue});
  final ValueChanged<bool> onCanContinue;

  @override
  ConsumerState<PairingStep> createState() => _PairingStepState();
}

class _PairingStepState extends ConsumerState<PairingStep> {
  StreamSubscription<RingMessage>? _sub;
  final List<int> _moves = <int>[];
  final List<int> _raw = <int>[];
  bool _waveDone = false;
  bool _tapDone = false;
  bool _tapSkipped = false;
  bool _rawOn = false;

  static const _waveTarget = 150;
  static const _rawTarget = 1500;

  @override
  void initState() {
    super.initState();
    final core = ref.read(appCoreProvider);
    unawaited(core.startRing());
    _sub = core.messages.listen(_onMessage);
  }

  void _onMessage(RingMessage m) {
    if (!mounted) return;
    setState(() {
      switch (m) {
        case Heartbeat(:final moves):
          _moves.add(moves);
          if (_moves.length > 3) _moves.removeAt(0);
        case RawMessage(:final milliG):
          _raw.add(milliG);
          if (_raw.length > 15) _raw.removeAt(0);
        case SosMessage():
          if (!_tapDone) HapticFeedback.heavyImpact();
          _tapDone = true;
        case VersionMessage():
          break;
        case TremorMessage():
          break;
      }
      if (_progress >= 1 && !_waveDone) {
        _waveDone = true;
        HapticFeedback.mediumImpact();
      }
    });
    _report();
  }

  double get _progress {
    final hb = _moves.fold<int>(0, (a, b) => a + b) / _waveTarget;
    final raw = _raw.fold<int>(0, (a, b) => a + b) / _rawTarget;
    return (hb > raw ? hb : raw).clamp(0.0, 1.0);
  }

  void _report() {
    final connected = ref.read(coreViewProvider).connection == RingConnectionState.connected;
    widget.onCanContinue(connected && _waveDone);
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    if (_rawOn) unawaited(ref.read(appCoreProvider).setRaw(on: false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final theme = Theme.of(context);
    final v = ref.watch(coreViewProvider);
    final connected = v.connection == RingConnectionState.connected;
    final fwOk = ref.watch(settingsProvider.select((s) => s.firmwareSupportsCommands));
    if (connected && fwOk && !_rawOn) {
      _rawOn = true;
      unawaited(ref.read(appCoreProvider).setRaw(on: true));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _report();
    });

    Widget status;
    switch (v.connection) {
      case RingConnectionState.bluetoothOff:
        status = Text(t.obPairBtOff, style: TextStyle(color: c.danger));
      case RingConnectionState.unauthorized:
        status = Text(t.obPairNoPerm, style: TextStyle(color: c.danger));
      case RingConnectionState.connected:
        status = Column(
          children: [
            Card(
              child: ListTile(
                leading: Icon(Icons.circle, color: c.safe, size: 16),
                title: Text(t.obPairFound, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SignalBars(rssi: v.rssi),
                const SizedBox(width: 8),
                Text(SignalBars.barsFor(v.rssi) >= 3 ? t.ringSignalGood : t.ringSignalWeak),
              ],
            ),
          ],
        );
      case RingConnectionState.searching:
      case RingConnectionState.connecting:
      case RingConnectionState.disconnected:
        status = Row(
          children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(width: 12),
            Text(t.obPairSearching, style: theme.textTheme.titleMedium),
          ],
        );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.obPairTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        status,
        if (connected) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Text(t.obPairWave, style: theme.textTheme.titleMedium)),
              if (_waveDone) Icon(Icons.check_circle, color: c.safe),
            ],
          ),
          Text(t.obPairWaveSub, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Semantics(
            label: '${t.obPairWave} %${(_progress * 100).round()}',
            excludeSemantics: true,
            child: LinearProgressIndicator(
              value: _waveDone ? 1 : _progress,
              minHeight: 14,
              borderRadius: BorderRadius.circular(7),
              color: c.safe,
              backgroundColor: AppColors.tint(c.safe, 0.18),
            ),
          ),
          const SizedBox(height: 28),
          Text(t.obPairTap, style: theme.textTheme.titleMedium),
          Text(t.obPairTapSub, style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                AnimatedContainer(
                  duration: Duration(milliseconds: 250 + i * 200),
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _tapDone ? c.accent : Colors.transparent,
                    border: Border.all(color: c.accent, width: 2),
                  ),
                ),
              const Spacer(),
              if (!_tapDone && !_tapSkipped)
                TextButton(onPressed: () => setState(() => _tapSkipped = true), child: Text(t.commonSkip)),
              if (_tapDone) Icon(Icons.check_circle, color: c.safe),
            ],
          ),
        ],
      ],
    );
  }
}
