import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/settings_repository.dart';
import '../../providers/providers.dart';
import '../../services/alarm_dispatcher.dart';
import '../components/disclosure_dialog.dart';
import '../l10n.dart';
import '../settings/contacts_telegram_screen.dart';

/// Ekran 6: Yakın kişiler. Devam: ≥ 1 kişi (0 ise uyarıyla geçilebilir).
class ContactsStep extends ConsumerWidget {
  const ContactsStep({super.key, required this.onCanContinue});
  final ValueChanged<bool> onCanContinue;

  /// Kişi yoksa onay ister; geçilebilirse `true`.
  static Future<bool> confirmIfEmpty(BuildContext context, WidgetRef ref) async {
    final list = ref.read(contactsProvider).value ?? const [];
    if (list.isNotEmpty) return true;
    final t = context.t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(t.obContactsEmptyWarn),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.commonCancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(t.commonContinue)),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final s = ref.watch(settingsProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.obContactsTitle, style: Theme.of(context).textTheme.headlineSmall),
        Text(t.contactsOrderTitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 16),
        const ContactsEditor(),
        if (Platform.isAndroid) ...[
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              title: Text(t.smsSwitch),
              subtitle: Text(t.smsSwitchNote),
              value: s.smsMode != SmsMode.off,
              onChanged: (v) => unawaited(() async {
                if (v && !await requestSmsWithDisclosure(context, ref)) return;
                await ref
                    .read(settingsProvider.notifier)
                    .update((x) => x.copyWith(smsMode: v ? SmsMode.fallback : SmsMode.off));
              }()),
            ),
          ),
        ],
      ],
    );
  }
}
