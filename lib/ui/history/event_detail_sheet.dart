import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models.dart';
import '../../theme/app_colors.dart';
import '../l10n.dart';
import 'history_screen.dart';

/// Olay detayı: saat, sebep, o anki hareket grafiği, gruba gidip gitmediği.
Future<void> showEventDetail(BuildContext context, EventEntry e) {
  final t = context.t;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final c = ctx.colors;
      final moves = e.movesSnapshot;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, size: 14, color: eventColor(ctx, e.kind)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t.eventLabel(e.kind), style: theme.textTheme.titleLarge)),
                ],
              ),
              const SizedBox(height: 4),
              Text(DateFormat('d MMMM y, HH:mm', 'tr').format(e.at), style: theme.textTheme.bodyMedium),
              if (e.detail.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(e.detail, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(e.sentToGroup ? Icons.send : Icons.block, size: 18),
                  const SizedBox(width: 6),
                  Text(e.sentToGroup ? t.historySentToGroup : t.historyNotSentToGroup),
                ],
              ),
              const SizedBox(height: 16),
              Text(t.historyMovesChart, style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (moves.isEmpty)
                Text(t.historyNoMoves, style: theme.textTheme.bodySmall)
              else
                SizedBox(
                  height: 140,
                  child: Semantics(
                    label: t.historyMovesChart,
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(),
                          rightTitles: AxisTitles(),
                          bottomTitles: AxisTitles(),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                        ),
                        barGroups: [
                          for (var i = 0; i < moves.length; i++)
                            BarChartGroupData(x: i, barRods: [
                              BarChartRodData(
                                toY: moves[i].toDouble(),
                                color: moves[i] >= 3 ? c.accent : c.warning,
                                width: 5,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ]),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
