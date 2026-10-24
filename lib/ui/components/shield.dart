import 'package:flutter/material.dart';

import '../../core/health_check.dart';
import '../../theme/app_colors.dart';
import '../l10n.dart';

/// Koruma kalkanı: yeşil ✓ / turuncu ! / kırmızı ×.
class Shield extends StatelessWidget {
  const Shield({super.key, required this.level, this.size = 88});
  final ShieldLevel level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.t;
    final (color, icon, label) = switch (level) {
      ShieldLevel.protected => (c.safe, Icons.check_rounded, t.shieldProtected),
      ShieldLevel.attention => (c.warning, Icons.priority_high_rounded, t.shieldAttention),
      ShieldLevel.unprotected => (c.danger, Icons.close_rounded, t.shieldUnprotected),
    };
    return Semantics(
      label: t.shieldSemantics(label),
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.tint(color),
              border: Border.all(color: color, width: 3),
            ),
            child: Icon(icon, color: color, size: size * 0.55),
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
