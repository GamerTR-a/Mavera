import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models.dart';
import '../../data/app_logger.dart';
import '../../data/settings_repository.dart';
import '../../providers/providers.dart';
import '../../services/alarm_dispatcher.dart';
import '../../theme/app_colors.dart';
import '../components/disclosure_dialog.dart';
import '../components/status_card.dart';
import '../l10n.dart';

/// Ekran 14: Yakınlar ve Telegram.
class ContactsTelegramScreen extends ConsumerWidget {
  const ContactsTelegramScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.settingsContacts)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionLabel(t.contactsSection),
            const ContactsEditor(),
            SectionLabel(t.telegramSection),
            const TelegramForm(showName: true),
            if (Platform.isAndroid) ...[
              SectionLabel(t.smsSection),
              const SmsSettings(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sürüklenerek sıralanabilen kişi listesi + ekleme.
class ContactsEditor extends ConsumerWidget {
  const ContactsEditor({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref) async {
    try {
      final c = await FlutterNativeContactPicker().selectPhoneNumber();
      if (c == null) return;
      final phone = c.selectedPhoneNumber ?? (c.phoneNumbers?.isNotEmpty ?? false ? c.phoneNumbers?.first : null);
      if (!context.mounted) return;
      await _edit(context, ref, initialName: c.fullName ?? '', initialPhone: phone ?? '');
    } on Object catch (e) {
      AppLogger.w('Kişi seçici: $e');
      if (context.mounted) await _edit(context, ref);
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    EmergencyContact? existing,
    String initialName = '',
    String initialPhone = '',
  }) async {
    final t = context.t;
    final name = TextEditingController(text: existing?.name ?? initialName);
    final phone = TextEditingController(text: existing?.phone ?? initialPhone);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? t.contactsAddManual : t.contactsEdit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: t.contactsName),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              decoration: InputDecoration(labelText: t.contactsPhone),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          if (existing != null)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('delete'),
              child: Text(t.commonDelete, style: TextStyle(color: ctx.colors.danger)),
            ),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.commonCancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop('save'), child: Text(t.commonSave)),
        ],
      ),
    );
    final n = ref.read(contactsProvider.notifier);
    if (result == 'delete' && existing?.id != null) {
      await n.remove(existing?.id ?? 0);
    } else if (result == 'save' && name.text.trim().isNotEmpty && phone.text.trim().isNotEmpty) {
      if (existing == null) {
        await n.add(name.text, phone.text);
      } else {
        await n.edit(existing.copyWith(name: name.text, phone: phone.text));
      }
    }
    name.dispose();
    phone.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final list = ref.watch(contactsProvider).value ?? const <EmergencyContact>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (list.isNotEmpty)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (a, b) => unawaited(ref.read(contactsProvider.notifier).reorder(a, b)),
            children: [
              for (var i = 0; i < list.length; i++)
                Padding(
                  key: ValueKey(list[i].id ?? i),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      title: Text('${i + 1} · ${list[i].name}'),
                      subtitle: Text(list[i].phone),
                      onTap: () => unawaited(_edit(context, ref, existing: list[i])),
                      trailing: ReorderableDragStartListener(
                        index: i,
                        child: Semantics(
                          label: t.contactsReorderHint,
                          child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.drag_handle)),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        Wrap(
          spacing: 8,
          children: [
            TextButton(onPressed: () => unawaited(_pick(context, ref)), child: Text(t.contactsAddFromPhone)),
            TextButton(onPressed: () => unawaited(_edit(context, ref)), child: Text(t.contactsAddManual)),
          ],
        ),
        Text(t.contactsHint, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Bot token, chat ID ve test mesajı.
class TelegramForm extends ConsumerStatefulWidget {
  const TelegramForm({super.key, this.showName = false, this.onResult});
  final bool showName;
  final ValueChanged<bool>? onResult;

  @override
  ConsumerState<TelegramForm> createState() => _TelegramFormState();
}

class _TelegramFormState extends ConsumerState<TelegramForm> {
  final _token = TextEditingController();
  late final TextEditingController _chat = TextEditingController(text: ref.read(settingsProvider).chatId);
  late final TextEditingController _name = TextEditingController(text: ref.read(settingsProvider).personName);
  bool _busy = false;
  String? _error;
  bool? _ok;

  @override
  void dispose() {
    _token.dispose();
    _chat.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    setState(() {
      _busy = true;
      _error = null;
      _ok = null;
    });
    final core = ref.read(appCoreProvider);
    final store = ref.read(tokenStoreProvider);
    final newToken = _token.text.trim();
    if (newToken.isNotEmpty) await store.write(newToken);
    final name = _name.text.trim();
    await ref.read(settingsProvider.notifier).update((s) => s.copyWith(
          chatId: _chat.text.trim(),
          personName: name.isEmpty ? null : name,
        ));
    ref.invalidate(hasTokenProvider);
    final err = await core.sendTelegramTest();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
      _ok = err == null;
      if (err == null) _token.clear();
    });
    widget.onResult?.call(err == null);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final s = ref.watch(settingsProvider);
    final hasToken = ref.watch(hasTokenProvider).value ?? false;
    final theme = Theme.of(context);
    final last = s.lastTelegramCheckAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _token,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: t.telegramToken,
            hintText: hasToken ? '••••••••••••' : null,
            helperText: hasToken ? t.telegramTokenSafe : t.telegramTokenEmpty,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _chat,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))],
          decoration: InputDecoration(labelText: t.telegramChatId, hintText: '-100 1234 5678'),
        ),
        if (widget.showName) ...[
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: InputDecoration(labelText: t.telegramName)),
        ],
        const SizedBox(height: 16),
        FilledButton.tonal(
          onPressed: _busy ? null : _test,
          child: _busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(t.telegramTest),
        ),
        const SizedBox(height: 8),
        if (_ok ?? false)
          Row(children: [
            Icon(Icons.check_circle, color: c.safe),
            const SizedBox(width: 8),
            Expanded(child: Text(t.telegramTestOk)),
          ]),
        if (_error != null)
          Row(children: [
            Icon(Icons.error, color: c.danger),
            const SizedBox(width: 8),
            Expanded(child: Text(_error ?? '', style: TextStyle(color: c.danger))),
          ]),
        if (_ok == null && _error == null)
          Text(
            last == null
                ? t.telegramNeverChecked
                : t.telegramLastCheck(
                    DateFormat('d MMM HH:mm', 'tr').format(last),
                    (s.lastTelegramCheckOk ?? false) ? t.telegramCheckOk : t.telegramCheckFail,
                  ),
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}

/// SMS yedeği ayarı (yalnızca Android).
class SmsSettings extends ConsumerWidget {
  const SmsSettings({super.key});

  Future<void> _testSms(BuildContext context, WidgetRef ref) async {
    final t = context.t;
    final ctrl = TextEditingController();
    final phone = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.smsTest),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.smsTestPrompt),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: t.smsTestNumber),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.commonCancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: Text(t.smsTest)),
        ],
      ),
    );
    ctrl.dispose();
    if (phone == null || phone.isEmpty || !context.mounted) return;
    if (!await requestSmsWithDisclosure(context, ref)) return;
    final ok = await ref.read(appCoreProvider).sendTestSms(phone);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? t.smsTestSent : t.smsTestFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final s = ref.watch(settingsProvider);
    Future<void> set(SmsMode m) async {
      if (m != SmsMode.off && !await requestSmsWithDisclosure(context, ref)) return;
      await ref.read(settingsProvider.notifier).update((x) => x.copyWith(smsMode: m));
    }

    return Card(
      child: Column(
        children: [
          RadioGroup<SmsMode>(
            groupValue: s.smsMode,
            onChanged: (m) {
              if (m != null) unawaited(set(m));
            },
            child: Column(
              children: [
                RadioListTile<SmsMode>(value: SmsMode.off, title: Text(t.smsOff)),
                RadioListTile<SmsMode>(value: SmsMode.fallback, title: Text(t.smsFallback(s.smsFallbackSeconds))),
                RadioListTile<SmsMode>(value: SmsMode.always, title: Text(t.smsAlways)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => unawaited(_testSms(context, ref)), child: Text(t.smsTest)),
            ),
          ),
        ],
      ),
    );
  }
}
