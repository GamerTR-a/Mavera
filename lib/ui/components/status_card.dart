import 'package:flutter/material.dart';

/// Etiket–değer satırlarından oluşan kart.
class StatusCard extends StatelessWidget {
  const StatusCard({super.key, required this.rows});
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
                    Flexible(
                      child: Text(
                        value,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Küçük gri bölüm başlığı ("YAKINLAR").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 0.8,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
}
