import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../data/settings_repository.dart';
import '../l10n.dart';

/// Kişisel mesaj düzenleme + önizleme.
class WelcomeMessageScreen extends ConsumerStatefulWidget {
  const WelcomeMessageScreen({super.key});

  @override
  ConsumerState<WelcomeMessageScreen> createState() => _WelcomeMessageScreenState();
}

class _WelcomeMessageScreenState extends ConsumerState<WelcomeMessageScreen> {
  late final TextEditingController _c = TextEditingController(text: ref.read(settingsProvider).welcomeMessage);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _c.text.trim();
    await ref.read(settingsProvider.notifier).update(
          (s) => s.copyWith(welcomeMessage: text.isEmpty ? AppSettings.defaultWelcome : text),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.t.welcomeSaved)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final name = ref.watch(settingsProvider.select((s) => s.personName));
    return Scaffold(
      appBar: AppBar(title: Text(t.welcomeTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _c,
              maxLength: K.welcomeMaxLength,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(helperText: t.welcomeHint),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _save, child: Text(t.commonSave)),
            const SizedBox(height: 24),
            Text(t.welcomePreview, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(t.obWelcomeHello(name), style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text(_c.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
                    const SizedBox(height: 8),
                    Text(t.obWelcomeCaption, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
