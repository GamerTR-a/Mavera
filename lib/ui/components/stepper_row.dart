import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../l10n.dart';

/// Kart + "− değer +" satırı.
class StepperRow extends StatelessWidget {
  const StepperRow({
    super.key,
    required this.title,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.subtitle,
    this.recommended = false,
  });

  final String title;
  final String? subtitle;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  /// Değer önerilen değerse alt yazı yeşil "önerilen" olur.
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyLarge),
                  if (subtitle != null)
                    Text(
                      subtitle ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(color: recommended ? c.safe : null),
                    ),
                ],
              ),
            ),
            IconButton.outlined(
              tooltip: context.t.commonDecrease,
              onPressed: onMinus,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 64,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton.outlined(
              tooltip: context.t.commonIncrease,
              onPressed: onPlus,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
