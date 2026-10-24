import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../l10n.dart';

/// Ön uyarı geri sayım halkası + büyük saniye.
class CountdownRing extends StatelessWidget {
  const CountdownRing({super.key, required this.remaining, required this.total, this.size = 120});
  final int remaining;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    final danger = context.colors.danger;
    final frac = total <= 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);
    return Semantics(
      label: context.t.preAlarmCountdownSemantics(remaining),
      liveRegion: true,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: frac,
              strokeWidth: 10,
              color: danger,
              backgroundColor: AppColors.tint(danger, 0.18),
            ),
            Center(
              child: FittedBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$remaining', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
                    Text(context.t.preAlarmSeconds, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
