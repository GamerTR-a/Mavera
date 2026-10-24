import 'package:flutter/material.dart';

import '../l10n.dart';
import '../settings/permissions_screen.dart';

/// Ekran 3b (yalnızca Android): arka planda çalışma. "Yaptım" ile geçilir.
class BackgroundStep extends StatelessWidget {
  const BackgroundStep({super.key, required this.onCanContinue});
  final ValueChanged<bool> onCanContinue;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.obBgTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(t.obBgSubtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        const BackgroundSetup(),
      ],
    );
  }
}
