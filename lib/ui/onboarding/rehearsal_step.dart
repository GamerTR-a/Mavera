import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../theme/app_colors.dart';
import '../l10n.dart';
import '../main/rehearsal_screen.dart';

/// Ekran 7: Prova. Devam: prova tamamlandı.
class RehearsalStep extends ConsumerStatefulWidget {
  const RehearsalStep({super.key, required this.onCanContinue});
  final ValueChanged<bool> onCanContinue;

  @override
  ConsumerState<RehearsalStep> createState() => _RehearsalStepState();
}

class _RehearsalStepState extends ConsumerState<RehearsalStep> {
  bool _sendTest = false;
  bool _done = false;
  String? _testResult;

  Future<void> _start() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RehearsalScreen(), fullscreenDialog: true),
    );
    if (!mounted) return;
    if (ok ?? false) {
      setState(() => _done = true);
      widget.onCanContinue(true);
      if (_sendTest) {
        final err = await ref.read(appCoreProvider).sendRehearsalMessage();
        if (mounted) setState(() => _testResult = err ?? context.t.obRehearsalTestSent);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.obRehearsalTitle, style: theme.textTheme.headlineSmall),
        Text(t.obRehearsalSub, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.tint(c.danger, 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.tint(c.danger, 0.5)),
          ),
          child: Column(
            children: [
              Text(t.preAlarmTitleInactivity, style: theme.textTheme.titleMedium),
              Text(t.preAlarmRehearsal, style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              if (_done)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: c.safe, size: 32),
                    const SizedBox(width: 8),
                    Text(t.obRehearsalDone, style: theme.textTheme.titleMedium),
                  ],
                )
              else
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: c.danger),
                  onPressed: () => unawaited(_start()),
                  child: Text(t.obRehearsalStart),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: SwitchListTile(
            title: Text(t.obRehearsalTest),
            subtitle: Text(t.obRehearsalTestSub),
            value: _sendTest,
            onChanged: _done ? null : (v) => setState(() => _sendTest = v),
          ),
        ),
        if (_testResult != null) ...[
          const SizedBox(height: 8),
          Text(_testResult ?? ''),
        ],
      ],
    );
  }
}
