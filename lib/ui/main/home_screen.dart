import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/health_check.dart';
import '../../core/message_composer.dart';
import '../../core/monitor_phase.dart';
import '../../core/sleep_schedule.dart';
import '../../data/settings_repository.dart';
import '../../providers/providers.dart';
import '../../services/ring/ring_transport.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../components/hold_to_confirm_button.dart';
import '../components/motion_wave.dart';
import '../components/shield.dart';
import '../components/status_card.dart';
import '../history/history_screen.dart';
import '../l10n.dart';
import '../settings/settings_screen.dart';
import 'health_actions.dart';
import 'pause_sheet.dart';

/// Ekran 9: "Şu an korunuyor muyum?"
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final v = ref.watch(coreViewProvider);
    final s = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final c = context.colors;
    final now = clock.now();

    final issue = v.issues.isEmpty ? null : v.issues.first;
    final last = v.lastSignalAt;
    final phase = v.phase;
    final paused = phase is Paused ? phase : null;
    final asleep = SleepSchedule.isAsleep(s.toMonitorSettings(), now);

    final mode = paused != null
        ? t.homeModePaused((paused.until.difference(now).inSeconds / 60).ceil())
        : (asleep ? t.homeModeSleep : t.homeModeNormal);
    final bat = v.ringBattery;
    final est = v.batteryRemaining;
    final batText = bat == null
        ? t.homeBatteryUnknown
        : (est == null ? t.homeBatteryPct(bat) : t.homeBatteryEstimate(bat, t.duration(est)));
    final ringText = switch (v.connection) {
      RingConnectionState.connected => t.homeRingConnected,
      RingConnectionState.searching || RingConnectionState.connecting => t.homeRingSearching,
      _ => t.homeRingDisconnected,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appTitle),
        actions: [
          IconButton(
            tooltip: t.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Dims.gutter),
          children: [
            const SizedBox(height: 8),
            Center(child: Shield(level: v.shield)),
            const SizedBox(height: 6),
            if (issue != null) ...[
              Text(issue.title, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              if (issue.action != HealthAction.none && issue.actionLabel != null)
                Center(
                  child: TextButton(
                    onPressed: () => runHealthAction(context, ref, issue.action),
                    child: Text(issue.actionLabel ?? ''),
                  ),
                ),
            ] else if (last != null)
              Text(
                t.homeRingOk(now.difference(last).inSeconds.clamp(0, 999)),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            MotionWave(
              values: v.recentMoves,
              pulse: v.heartbeatCount,
              color: phase is Counting ? c.warning : c.accent,
            ),
            if (phase is Counting)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  t.homeIdleFor(now.difference(v.lastMotionAt).inMinutes),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: c.warning, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 16),
            StatusCard(rows: [
              (t.homeMode, mode),
              (t.homeRing, ringText),
              (t.homeRingBattery, batText),
            ]),
            const SizedBox(height: 16),
            HoldToConfirmButton(
              label: t.homeHelp,
              hint: t.homeHelpHint,
              onConfirmed: () => ref.read(appCoreProvider).requestHelp(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(s.sleepEnabled ? Icons.bedtime : Icons.bedtime_outlined),
                    label: Text(s.sleepEnabled ? t.homeSleepOn : t.homeSleep, overflow: TextOverflow.ellipsis),
                    onPressed: () => unawaited(ref
                        .read(settingsProvider.notifier)
                        .update((x) => x.copyWith(sleepEnabled: !x.sleepEnabled))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(paused != null ? Icons.play_arrow : Icons.pause),
                    label: Text(paused != null ? t.homeResume : t.homePause, overflow: TextOverflow.ellipsis),
                    onPressed: () {
                      if (paused != null) {
                        ref.read(appCoreProvider).resume();
                      } else {
                        unawaited(showPauseSheet(context, ref));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const _RecentEvents(),
          ],
        ),
      ),
    );
  }
}

class _RecentEvents extends ConsumerWidget {
  const _RecentEvents();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final theme = Theme.of(context);
    final events = ref.watch(recentEventsProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(t.homeRecent, style: theme.textTheme.titleMedium)),
            TextButton(
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => const HistoryScreen())),
              child: Text(t.commonAll),
            ),
          ],
        ),
        if (events.isEmpty)
          Text(t.homeNoEvents, style: theme.textTheme.bodySmall)
        else
          for (final e in events)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text('${MessageComposer.hhmm(e.at)}  ${t.eventLabel(e.kind)}', style: theme.textTheme.bodyMedium),
            ),
      ],
    );
  }
}
