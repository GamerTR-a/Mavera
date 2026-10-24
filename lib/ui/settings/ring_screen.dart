import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/ring_protocol.dart';
import '../../data/settings_repository.dart';
import '../../providers/providers.dart';
import '../../services/ring/ring_transport.dart';
import '../../theme/app_colors.dart';
import '../components/signal_bars.dart';
import '../l10n.dart';

/// Ekran 17: Yüzük.
class RingScreen extends ConsumerStatefulWidget {
  const RingScreen({super.key});

  @override
  ConsumerState<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends ConsumerState<RingScreen> {
  StreamSubscription<RingMessage>? _sub;
  final List<int> _raw = <int>[];
  bool _rawOn = false;

  @override
  void initState() {
    super.initState();
    final core = ref.read(appCoreProvider);
    _sub = core.messages.listen((m) {
      if (m is RawMessage) {
        setState(() {
          _raw.add(m.milliG);
          if (_raw.length > 13) _raw.removeAt(0);
        });
      }
    });
    if (ref.read(settingsProvider).firmwareSupportsCommands) {
      _rawOn = true;
      unawaited(core.setRaw(on: true));
    }
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    // Ekrandan çıkınca canlı akış kapatılır (pil).
    if (_rawOn) unawaited(ref.read(appCoreProvider).setRaw(on: false));
    super.dispose();
  }

  Future<void> _forget() async {
    final t = context.t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(t.ringForgetConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.commonCancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(t.ringForget)),
        ],
      ),
    );
    if (ok ?? false) await ref.read(appCoreProvider).forgetRing();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final theme = Theme.of(context);
    final v = ref.watch(coreViewProvider);
    final s = ref.watch(settingsProvider);
    final connected = v.connection == RingConnectionState.connected;
    final bat = v.ringBattery;
    final mv = v.ringMillivolts;
    final lastFull = v.lastFullAt;

    final useRaw = _rawOn && _raw.isNotEmpty;
    final values = useRaw
        ? _raw
        : (v.recentMoves.length <= 13 ? v.recentMoves : v.recentMoves.sublist(v.recentMoves.length - 13));
    final threshold = useRaw ? s.cfgThreshold.toDouble() : s.minMoves.toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(t.settingsRing)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: Icon(Icons.circle, color: connected ? c.safe : c.danger, size: 16),
                title: Text(connected ? t.homeRingConnected : t.homeRingDisconnected),
                subtitle: Text(SignalBars.barsFor(v.rssi) >= 3 ? t.ringSignalGood : t.ringSignalWeak),
                trailing: SignalBars(rssi: v.rssi),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.ringBattery, style: theme.textTheme.bodySmall),
                    Row(
                      children: [
                        Text(bat == null ? '–' : '%$bat',
                            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (bat ?? 0) / 100,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(6),
                            color: (bat ?? 100) < 20 ? c.warning : c.safe,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.ringVoltage(
                        mv == null ? '–' : (mv / 1000).toStringAsFixed(2),
                        lastFull == null ? t.ringNoCharge : DateFormat('d MMM HH:mm', 'tr').format(lastFull),
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(t.ringLiveMotion, style: theme.textTheme.bodySmall)),
                        Text(t.ringThreshold, style: theme.textTheme.bodySmall?.copyWith(color: c.danger)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: ExcludeSemantics(
                        child: BarChart(
                          BarChartData(
                            minY: 0,
                            maxY: [
                              threshold * 2,
                              ...values.map((e) => e.toDouble() * 1.1),
                              1.0,
                            ].reduce((a, b) => a > b ? a : b),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: const FlTitlesData(show: false),
                            extraLinesData: ExtraLinesData(horizontalLines: [
                              HorizontalLine(y: threshold, color: c.danger, strokeWidth: 1.5, dashArray: [5, 4]),
                            ]),
                            barGroups: [
                              for (var i = 0; i < values.length; i++)
                                BarChartGroupData(x: i, barRods: [
                                  BarChartRodData(
                                    toY: values[i].toDouble(),
                                    color: c.accent,
                                    width: 12,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(title: Text(t.ringFirmware), trailing: Text(s.firmwareVersion ?? '0.1')),
                  ListTile(title: Text(t.ringDeviceName), trailing: Text(v.deviceName ?? '–')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: c.danger),
              onPressed: () => unawaited(_forget()),
              child: Text(t.ringForget),
            ),
          ],
        ),
      ),
    );
  }
}
