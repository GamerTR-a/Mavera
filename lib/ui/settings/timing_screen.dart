import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/monitor_settings.dart';
import '../../data/settings_repository.dart';
import '../components/stepper_row.dart';
import '../l10n.dart';

/// Ekran 15: Süreler.
class TimingScreen extends ConsumerWidget {
  const TimingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final s = ref.watch(settingsProvider);
    final repo = ref.read(settingsProvider.notifier);
    void upd(AppSettings Function(AppSettings) f) => unawaited(repo.update(f));

    String sub(int value, int rec, String fallback, String unit) =>
        value == rec ? t.commonRecommended : t.commonRecommendedValue('$rec $unit');

    final differs = s.abruptMinutes != AppSettings.recAbrupt ||
        s.gradualMinutes != AppSettings.recGradual ||
        s.preAlarmSeconds != AppSettings.recPreAlarm ||
        s.sosCancelSeconds != AppSettings.recSos ||
        s.sensitivity != Sensitivity.medium;

    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTiming)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            StepperRow(
              title: t.timingAbrupt,
              subtitle: sub(s.abruptMinutes, AppSettings.recAbrupt, '', 'dk'),
              recommended: s.abruptMinutes == AppSettings.recAbrupt,
              value: t.commonMinutes(s.abruptMinutes),
              onMinus: s.abruptMinutes > 1 ? () => upd((x) => x.copyWith(abruptMinutes: x.abruptMinutes - 1)) : null,
              onPlus: s.abruptMinutes < 15 ? () => upd((x) => x.copyWith(abruptMinutes: x.abruptMinutes + 1)) : null,
            ),
            const SizedBox(height: 8),
            StepperRow(
              title: t.timingGradual,
              subtitle: sub(s.gradualMinutes, AppSettings.recGradual, '', 'dk'),
              recommended: s.gradualMinutes == AppSettings.recGradual,
              value: t.commonMinutes(s.gradualMinutes),
              onMinus:
                  s.gradualMinutes > 3 ? () => upd((x) => x.copyWith(gradualMinutes: x.gradualMinutes - 1)) : null,
              onPlus:
                  s.gradualMinutes < 60 ? () => upd((x) => x.copyWith(gradualMinutes: x.gradualMinutes + 1)) : null,
            ),
            const SizedBox(height: 8),
            StepperRow(
              title: t.timingPreAlarm,
              subtitle: s.preAlarmSeconds == AppSettings.recPreAlarm
                  ? t.timingPreAlarmSub
                  : t.commonRecommendedValue('${AppSettings.recPreAlarm} sn'),
              value: t.commonSeconds(s.preAlarmSeconds),
              onMinus: s.preAlarmSeconds > 15
                  ? () => upd((x) => x.copyWith(preAlarmSeconds: x.preAlarmSeconds - 15))
                  : null,
              onPlus: s.preAlarmSeconds < 180
                  ? () => upd((x) => x.copyWith(preAlarmSeconds: x.preAlarmSeconds + 15))
                  : null,
            ),
            const SizedBox(height: 8),
            StepperRow(
              title: t.timingSos,
              subtitle: s.sosCancelSeconds == AppSettings.recSos
                  ? t.timingSosSub
                  : t.commonRecommendedValue('${AppSettings.recSos} sn'),
              value: t.commonSeconds(s.sosCancelSeconds),
              onMinus: s.sosCancelSeconds > 5
                  ? () => upd((x) => x.copyWith(sosCancelSeconds: x.sosCancelSeconds - 5))
                  : null,
              onPlus: s.sosCancelSeconds < 30
                  ? () => upd((x) => x.copyWith(sosCancelSeconds: x.sosCancelSeconds + 5))
                  : null,
            ),
            const SizedBox(height: 20),
            Text(t.timingSensitivity, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<Sensitivity>(
              segments: [
                ButtonSegment(value: Sensitivity.low, label: Text(t.timingLow)),
                ButtonSegment(value: Sensitivity.medium, label: Text(t.timingMedium)),
                ButtonSegment(value: Sensitivity.high, label: Text(t.timingHigh)),
              ],
              selected: {s.sensitivity},
              onSelectionChanged: (v) => upd((x) => x.copyWith(sensitivity: v.first)),
            ),
            const SizedBox(height: 16),
            Text(t.timingNote, style: Theme.of(context).textTheme.bodySmall),
            if (differs) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => upd((x) => x.copyWith(
                      abruptMinutes: AppSettings.recAbrupt,
                      gradualMinutes: AppSettings.recGradual,
                      preAlarmSeconds: AppSettings.recPreAlarm,
                      sosCancelSeconds: AppSettings.recSos,
                      sensitivity: Sensitivity.medium,
                    )),
                child: Text(t.commonResetRecommended),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
