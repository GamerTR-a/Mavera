import 'package:flutter/material.dart';

import '../../services/permissions.dart';
import '../../theme/app_colors.dart';

/// İzin kartı: ad, tek cümle neden, durum noktası ve eylem.
class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.title,
    required this.reason,
    required this.state,
    this.note,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String reason;
  final PermState state;
  final String? note;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final theme = Theme.of(context);
    final (color, icon, word) = switch (state) {
      PermState.granted => (c.safe, Icons.check_circle, 'verildi'),
      PermState.partial => (c.warning, Icons.error, 'eksik'),
      PermState.denied => (c.danger, Icons.cancel, 'verilmedi'),
    };
    return Card(
      color: state == PermState.partial ? AppColors.tint(c.warning, 0.12) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: state == PermState.partial ? BorderSide(color: c.warning) : BorderSide.none,
      ),
      child: Semantics(
        label: '$title, $word',
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(reason, style: theme.textTheme.bodySmall),
                    if (note != null) ...[
                      const SizedBox(height: 4),
                      Text(note ?? '', style: theme.textTheme.bodyMedium),
                    ],
                    if (state != PermState.granted && onAction != null) ...[
                      const SizedBox(height: 6),
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                        onPressed: onAction,
                        child: Text(actionLabel ?? ''),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(icon, color: color, semanticLabel: word),
            ],
          ),
        ),
      ),
    );
  }
}
