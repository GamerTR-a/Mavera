import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/alarm_reason.dart';
import '../../core/constants.dart';
import '../../data/settings_repository.dart';
import '../../providers/providers.dart';
import 'pre_alarm_screen.dart';

/// Prova: gerçek ön uyarı ekranının "PROVA" etiketli kopyası (15 sn; bildirim,
/// ses, titreşim dahil). "İyiyim" ile `true`, süre dolarsa `false` döner.
class RehearsalScreen extends ConsumerStatefulWidget {
  const RehearsalScreen({super.key});

  @override
  ConsumerState<RehearsalScreen> createState() => _RehearsalScreenState();
}

class _RehearsalScreenState extends ConsumerState<RehearsalScreen> {
  late final DateTime _deadline = clock.now().add(const Duration(seconds: K.rehearsalSeconds));
  Timer? _timer;
  int _ticks = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
    HapticFeedback.vibrate();
    unawaited(ref.read(appCoreProvider).startRehearsalNotification(_deadline));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _ticks++;
      if (_ticks % K.preAlarmRepeat.inSeconds == 0) {
        HapticFeedback.vibrate();
        unawaited(ref.read(appCoreProvider).refreshRehearsalNotification(_deadline));
      }
      if (!clock.now().isBefore(_deadline)) {
        _finish(false);
      } else {
        setState(() {});
      }
    });
  }

  void _finish(bool ok) {
    if (_done) return;
    _done = true;
    _timer?.cancel();
    unawaited(ref.read(appCoreProvider).stopRehearsalNotification());
    if (mounted) Navigator.of(context).pop(ok);
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(WakelockPlus.disable());
    if (!_done) unawaited(ref.read(appCoreProvider).stopRehearsalNotification());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = ref.watch(settingsProvider.select((s) => s.abruptMinutes));
    final remaining = _deadline.difference(clock.now()).inSeconds.clamp(0, K.rehearsalSeconds);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: PreAlarmView(
          reason: Inactivity(minutes: minutes, abrupt: true),
          remaining: remaining,
          total: K.rehearsalSeconds,
          rehearsal: true,
          onImFine: () => _finish(true),
        ),
      ),
    );
  }
}
