import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sleep_schedule.dart';
import '../../data/settings_repository.dart';
import '../../theme/app_colors.dart';
import '../components/stepper_row.dart';
import '../l10n.dart';

/// Ekran 16: Uyku modu.
class SleepModeScreen extends ConsumerWidget {
  const SleepModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final s = ref.watch(settingsProvider);
    final repo = ref.read(settingsProvider.notifier);
    void upd(AppSettings Function(AppSettings) f) => unawaited(repo.update(f));

    Future<void> pickTime({required bool start}) async {
      final m = start ? s.sleepStart : s.sleepEnd;
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
        builder: (ctx, child) => MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox(),
        ),
      );
      if (picked == null) return;
      final v = picked.hour * 60 + picked.minute;
      upd((x) => start ? x.copyWith(sleepStart: v) : x.copyWith(sleepEnd: v));
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.settingsSleep)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: SwitchListTile(
                title: Text(t.sleepToggle),
                value: s.sleepEnabled,
                onChanged: (v) => upd((x) => x.copyWith(sleepEnabled: v)),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(t.sleepSchedule),
                    subtitle: Text(
                        '${SleepSchedule.format(s.sleepStart)} – ${SleepSchedule.format(s.sleepEnd)} · ${t.sleepEveryDay}'),
                    value: s.sleepScheduleEnabled,
                    onChanged: (v) => upd((x) => x.copyWith(sleepScheduleEnabled: v)),
                  ),
                  ListTile(
                    title: Text(t.sleepStart),
                    trailing: Text(SleepSchedule.format(s.sleepStart), style: Theme.of(context).textTheme.titleMedium),
                    onTap: () => unawaited(pickTime(start: true)),
                  ),
                  ListTile(
                    title: Text(t.sleepEnd),
                    trailing: Text(SleepSchedule.format(s.sleepEnd), style: Theme.of(context).textTheme.titleMedium),
                    onTap: () => unawaited(pickTime(start: false)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            StepperRow(
              title: t.sleepWait,
              subtitle: t.sleepWaitSub,
              value: t.commonMinutes(s.sleepMinutes),
              onMinus: s.sleepMinutes > 10 ? () => upd((x) => x.copyWith(sleepMinutes: x.sleepMinutes - 5)) : null,
              onPlus: s.sleepMinutes < 90 ? () => upd((x) => x.copyWith(sleepMinutes: x.sleepMinutes + 5)) : null,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.tint(context.colors.accent, 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: context.colors.accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t.sleepInfo)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
