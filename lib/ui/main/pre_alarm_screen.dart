import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/alarm_reason.dart';
import '../../core/constants.dart';
import '../../core/monitor_phase.dart';
import '../../providers/providers.dart';
import '../../theme/app_colors.dart';
import '../components/countdown_ring.dart';
import '../l10n.dart';

/// Ön uyarı görünümü (gerçek ve prova aynı görünümü kullanır).
class PreAlarmView extends StatelessWidget {
  const PreAlarmView({
    super.key,
    required this.reason,
    required this.remaining,
    required this.total,
    required this.onImFine,
    this.onSendNow,
    this.motionSeen = false,
    this.rehearsal = false,
  });

  final AlarmReason reason;
  final int remaining;
  final int total;
  final bool motionSeen;
  final bool rehearsal;
  final VoidCallback onImFine;
  final VoidCallback? onSendNow;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final theme = Theme.of(context);
    return Container(
      color: AppColors.tint(c.danger, 0.10),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (rehearsal)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.danger,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(t.preAlarmRehearsal,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        t.preAlarmTitle(reason),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(t.preAlarmReason(reason), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 16),
                      CountdownRing(remaining: remaining, total: total),
                      const SizedBox(height: 16),
                      Text(t.preAlarmWillNotify, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                      if (motionSeen) ...[
                        const SizedBox(height: 10),
                        Text(
                          t.preAlarmMotionHint,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(color: c.safe, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: t.preAlarmImFine,
                  excludeSemantics: true,
                  child: FilledButton(
                    autofocus: true,
                    style: FilledButton.styleFrom(
                      backgroundColor: c.safe,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(120),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onImFine();
                    },
                    child: FittedBox(
                      child: Text(t.preAlarmImFine, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (onSendNow != null)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: c.danger, minimumSize: const Size.fromHeight(52)),
                  onPressed: onSendNow,
                  child: Text(t.preAlarmSendNow, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ekran 10: gerçek ön uyarı. Kök navigator üzerinde tam ekran açılır.
class PreAlarmScreen extends ConsumerStatefulWidget {
  const PreAlarmScreen({super.key});

  @override
  ConsumerState<PreAlarmScreen> createState() => _PreAlarmScreenState();
}

class _PreAlarmScreenState extends ConsumerState<PreAlarmScreen> {
  Timer? _buzz;
  PreAlarm? _last;

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
    HapticFeedback.vibrate();
    _buzz = Timer.periodic(K.preAlarmRepeat, (_) => HapticFeedback.vibrate());
  }

  @override
  void dispose() {
    _buzz?.cancel();
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(coreViewProvider.select((v) => v.phase));
    final p = phase is PreAlarm ? phase : _last;
    if (phase is PreAlarm) _last = phase;
    final core = ref.read(appCoreProvider);
    if (p == null) return const Scaffold();
    final now = clock.now();
    final total = p.deadline.difference(p.startedAt).inSeconds;
    final remaining = p.deadline.difference(now).inSeconds.clamp(0, total);
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: PreAlarmView(
          reason: p.reason,
          remaining: remaining,
          total: total,
          motionSeen: p.motionSeen,
          onImFine: core.imFine,
          onSendNow: core.sendNow,
        ),
      ),
    );
  }
}
