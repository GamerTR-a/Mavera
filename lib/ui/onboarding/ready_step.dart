import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_repository.dart';
import '../../theme/app_colors.dart';
import '../l10n.dart';

/// Ekran 8: Hazır. "Ana ekrana git" → `onboardingDone = true`, koruma başlar.
class ReadyStep extends ConsumerWidget {
  const ReadyStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final c = context.colors;
    final theme = Theme.of(context);
    final tips = [
      Platform.isIOS ? t.obReadyTipIos : t.obReadyTipAndroid,
      t.obReadyTipCharge,
      if (Platform.isAndroid) t.obReadyTipReboot,
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.tint(c.safe),
                      border: Border.all(color: c.safe, width: 3),
                    ),
                    child: Icon(Icons.check_rounded, color: c.safe, size: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(t.obReadyTitle, style: theme.textTheme.headlineSmall),
                  Text(t.obReadySub, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  for (final tip in tips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(leading: const Icon(Icons.lightbulb_outline), title: Text(tip)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.safe, foregroundColor: Colors.white),
            onPressed: () => ref.read(settingsProvider.notifier).update((s) => s.copyWith(onboardingDone: true)),
            child: Text(t.obReadyGo),
          ),
        ],
      ),
    );
  }
}
