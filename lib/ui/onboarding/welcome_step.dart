import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_repository.dart';
import '../../theme/app_colors.dart';
import '../l10n.dart';

/// Ekran 1: Hoş geldin — kişisel mesajla açılır.
class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final s = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.tint(c.accent, 0.35), width: 12),
                        ),
                      ),
                      Image.asset('assets/logo.png', width: 92, height: 92, semanticLabel: t.appTitle),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(t.obWelcomeHello(s.personName), style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 32),
                  Text(s.welcomeMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, height: 1.4)),
                  const SizedBox(height: 10),
                  Text(t.obWelcomeCaption, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          FilledButton.tonal(onPressed: onStart, child: Text(t.obWelcomeStart)),
        ],
      ),
    );
  }
}
