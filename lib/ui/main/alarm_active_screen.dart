import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/message_composer.dart';
import '../../core/monitor_phase.dart';
import '../../providers/providers.dart';
import '../../services/alarm_dispatcher.dart';
import '../../theme/app_colors.dart';
import '../l10n.dart';

/// Ekran 11: alarm gönderildi.
class AlarmActiveScreen extends ConsumerStatefulWidget {
  const AlarmActiveScreen({super.key});

  @override
  ConsumerState<AlarmActiveScreen> createState() => _AlarmActiveScreenState();
}

class _AlarmActiveScreenState extends ConsumerState<AlarmActiveScreen> {
  AlarmActive? _last;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  Future<void> _confirmClose() async {
    final t = context.t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(t.alarmCloseConfirm, style: Theme.of(ctx).textTheme.titleMedium),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.commonCancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(t.alarmCloseYes)),
        ],
      ),
    );
    if (ok ?? false) {
      unawaited(HapticFeedback.lightImpact());
      ref.read(appCoreProvider).imFine();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final theme = Theme.of(context);
    final v = ref.watch(coreViewProvider);
    final phase = v.phase;
    if (phase is AlarmActive) _last = phase;
    final active = _last;
    final record = v.record ?? active?.record;
    final contacts = ref.watch(contactsProvider).value ?? const [];
    final now = clock.now();

    final (deliveryColor, deliveryText) = switch (v.delivery) {
      Delivered() => (c.safe, t.alarmDelivered),
      SmsSent() => (c.safe, t.alarmSmsSent),
      Retrying(:final attempt) || FailedNotified(:final attempt) => (c.warning, t.alarmRetrying(attempt)),
      Sending() || Idle() => (c.accent, record?.delivered ?? false ? t.alarmDelivered : t.alarmSending),
    };
    final liveUntil = record?.liveUntil;
    final liveText = liveUntil != null && liveUntil.isAfter(now)
        ? t.alarmLive(liveUntil.difference(now).inMinutes + 1)
        : t.alarmLiveWaiting;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.tint(c.warning, 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(t.alarmTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    if (record != null)
                      Text(
                        t.alarmSubtitle(MessageComposer.hhmm(record.triggeredAt), t.alarmReasonShort(record.reason)),
                        style: theme.textTheme.bodyMedium,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _StatusLine(color: deliveryColor, text: deliveryText),
              if (record?.smsSent ?? false) _StatusLine(color: c.safe, text: t.alarmSmsSent),
              _StatusLine(color: c.accent, text: liveText),
              const Divider(height: 32),
              Text(t.alarmContacts, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (contacts.isEmpty) Text(t.alarmNoContacts, style: theme.textTheme.bodySmall),
              for (final ct in contacts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(ct.name, style: theme.textTheme.bodyLarge)),
                      Semantics(
                        label: t.alarmCallSemantics(ct.name),
                        excludeSemantics: true,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.safe,
                            side: BorderSide(color: c.safe, width: 2),
                            backgroundColor: AppColors.tint(c.safe, 0.12),
                            minimumSize: const Size(110, 52),
                          ),
                          icon: const Icon(Icons.call),
                          label: Text(t.alarmCall),
                          onPressed: () => unawaited(launchUrl(Uri(scheme: 'tel', path: ct.phone))),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: c.safe,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(72),
                ),
                onPressed: _confirmClose,
                child: FittedBox(child: Text(t.alarmClose, style: const TextStyle(fontSize: 20))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(Icons.circle, size: 14, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
          ],
        ),
      );
}
