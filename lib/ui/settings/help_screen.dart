import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/app_logger.dart';
import '../../data/settings_repository.dart';
import '../l10n.dart';
import '../main/rehearsal_screen.dart';
import 'simulator_panel.dart';

/// Yardım ve tanılama.
class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  Future<void> _shareLog() async {
    try {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}${Platform.pathSeparator}guven_yuzugu_gunluk.txt');
      await f.writeAsString(AppLogger.tail().join('\n'));
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'text/plain')]));
    } on Object catch (e) {
      AppLogger.e('Günlük paylaşılamadı', e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final s = ref.watch(settingsProvider);
    final faqs = [
      (t.faqQ1, t.faqA1),
      (t.faqQ2, t.faqA2),
      (t.faqQ3, t.faqA3),
      (t.faqQ4, t.faqA4),
      (t.faqQ5, t.faqA5),
      (t.faqQ6, t.faqA6),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(t.settingsHelp)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(t.helpRehearsal),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<bool>(builder: (_) => const RehearsalScreen(), fullscreenDialog: true)),
              ),
            ),
            const SizedBox(height: 16),
            Text(t.helpFaq, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final (q, a) in faqs)
                    ExpansionTile(
                      title: Text(q),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [Text(a)],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(t.helpShareLog),
                onTap: () => unawaited(_shareLog()),
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(t.helpSimulated),
                      subtitle: Text(t.helpSimulatedSub),
                      value: s.simulatedRing,
                      onChanged: (v) =>
                          unawaited(ref.read(settingsProvider.notifier).update((x) => x.copyWith(simulatedRing: v))),
                    ),
                    if (s.simulatedRing)
                      ListTile(
                        leading: const Icon(Icons.tune),
                        title: Text(t.helpSimPanel),
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute<void>(builder: (_) => const SimulatorPanel())),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
