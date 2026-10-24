import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../l10n.dart';

/// Duraklatma süresi seçimi: 30 dk / 1 saat / 2 saat.
Future<void> showPauseSheet(BuildContext context, WidgetRef ref) {
  final t = context.t;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      void pick(Duration d) {
        ref.read(appCoreProvider).pause(d);
        Navigator.of(ctx).pop();
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.pauseTitle, style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(t.pauseNote, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: () => pick(const Duration(minutes: 30)), child: Text(t.pause30)),
              const SizedBox(height: 8),
              FilledButton.tonal(onPressed: () => pick(const Duration(hours: 1)), child: Text(t.pause60)),
              const SizedBox(height: 8),
              FilledButton.tonal(onPressed: () => pick(const Duration(hours: 2)), child: Text(t.pause120)),
            ],
          ),
        ),
      );
    },
  );
}
