import 'package:flutter/material.dart';

import '../l10n.dart';
import '../settings/contacts_telegram_screen.dart';

/// Ekran 5: Telegram. Devam: test mesajı gruba ulaştı.
class TelegramStep extends StatelessWidget {
  const TelegramStep({super.key, required this.onCanContinue});
  final ValueChanged<bool> onCanContinue;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.obTelegramTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(t.telegramPreparerNote, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        TelegramForm(onResult: onCanContinue),
      ],
    );
  }
}
