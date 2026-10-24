import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../l10n.dart';

/// Ekran 2: Nasıl çalışır — üç numaralı kart.
class HowItWorksStep extends StatelessWidget {
  const HowItWorksStep({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.colors;
    final items = [
      (Icons.back_hand_outlined, t.obHow1),
      (Icons.notifications_active_outlined, t.obHow2),
      (Icons.groups_outlined, t.obHow3),
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.obHowTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.tint(c.accent, 0.15),
                      child: Text('${i + 1}', style: TextStyle(color: c.accent, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(items[i].$2, style: Theme.of(context).textTheme.bodyLarge)),
                    Icon(items[i].$1, color: c.accent),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
