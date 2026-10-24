import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants.dart';
import '../../core/events.dart';
import '../../core/message_composer.dart';
import '../../core/models.dart';
import '../../data/app_logger.dart';
import '../../data/event_log.dart';
import '../../providers/providers.dart';
import '../../theme/app_colors.dart';
import '../components/status_card.dart';
import '../l10n.dart';
import '../settings/timing_screen.dart';
import 'event_detail_sheet.dart';

/// Olay türünün nokta rengi.
Color eventColor(BuildContext context, String kind) {
  final c = context.colors;
  return switch (EventKind.byName(kind)) {
    EventKind.alarmSent ||
    EventKind.alarmDeliveredLate ||
    EventKind.preAlarmEscalated ||
    EventKind.manualHelp ||
    EventKind.smsSent ||
    EventKind.sos ||
    EventKind.tremor =>
      c.danger,
    EventKind.preAlarmCancelled || EventKind.lowBattery || EventKind.telegramCheckFailed => c.warning,
    EventKind.ringConnected || EventKind.resumed || EventKind.alarmClosed => c.safe,
    EventKind.sleepOn || EventKind.sleepOff => c.accent,
    _ => Theme.of(context).colorScheme.outline,
  };
}

/// Ekran 12: Geçmiş.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref, List<EventEntry> events) async {
    final t = context.t;
    final csv = EventLog.toCsv(events, t.eventLabel);
    try {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}${Platform.pathSeparator}guven_yuzugu_gecmis.csv');
      await f.writeAsString('﻿$csv');
      await SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'text/csv')]));
    } on Object catch (e) {
      AppLogger.e('CSV paylaşılamadı', e);
    }
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final t = context.t;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(t.historyClearConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.commonCancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(t.commonDelete)),
        ],
      ),
    );
    if (ok ?? false) await ref.read(eventLogProvider).clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final theme = Theme.of(context);
    final events = ref.watch(historyProvider).value ?? const <EventEntry>[];
    final now = clock.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final week = events.where((e) => e.at.isAfter(weekAgo)).toList();
    bool k(EventEntry e, EventKind kind) => e.kind == kind.name;
    final cancelled = week.where((e) => k(e, EventKind.preAlarmCancelled)).length;
    final escalated = week.where((e) => k(e, EventKind.preAlarmEscalated)).length;
    final alarms = week
        .where((e) => k(e, EventKind.alarmSent) || k(e, EventKind.alarmDeliveredLate))
        .length;

    final today = DateTime(now.year, now.month, now.day);
    String dayLabel(DateTime d) {
      final day = DateTime(d.year, d.month, d.day);
      if (day == today) return t.historyToday;
      if (day == today.subtract(const Duration(days: 1))) return t.historyYesterday;
      return DateFormat('d MMMM EEEE', 'tr').format(d).toUpperCase();
    }

    final children = <Widget>[];
    String? lastDay;
    for (final e in events) {
      final label = dayLabel(e.at);
      if (label != lastDay) {
        children.add(SectionLabel(label));
        lastDay = label;
      }
      children.add(ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(Icons.circle, size: 12, color: eventColor(context, e.kind)),
        minLeadingWidth: 16,
        title: Text('${MessageComposer.hhmm(e.at)}  ${t.eventLabel(e.kind)}', style: theme.textTheme.bodyLarge),
        subtitle: e.detail.isEmpty ? null : Text(e.detail),
        onTap: () => unawaited(showEventDetail(context, e)),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.historyTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (_) => unawaited(_clear(context, ref)),
            itemBuilder: (_) => [PopupMenuItem(value: 'clear', child: Text(t.historyClear))],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.historyWeek, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(t.historyWeekSummary(cancelled + escalated, cancelled, alarms)),
                          if (cancelled >= K.cancelSuggestThreshold)
                            TextButton(
                              style: TextButton.styleFrom(padding: EdgeInsets.zero),
                              onPressed: () => Navigator.of(context)
                                  .push(MaterialPageRoute<void>(builder: (_) => const TimingScreen())),
                              child: Text(t.historySuggest, style: TextStyle(color: context.colors.accent)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (events.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Text(t.historyEmpty, textAlign: TextAlign.center),
                    )
                  else ...[
                    ...children,
                    const SizedBox(height: 8),
                    Text(t.historyTapHint, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.ios_share),
                label: Text(t.historyExport),
                onPressed: events.isEmpty ? null : () => unawaited(_export(context, ref, events)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
