import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// RSSI'den 1–4 sinyal çubuğu (> -60: 4, > -70: 3, > -80: 2, aksi 1).
class SignalBars extends StatelessWidget {
  const SignalBars({super.key, required this.rssi});
  final int? rssi;

  static int barsFor(int? rssi) {
    if (rssi == null) return 0;
    if (rssi > -60) return 4;
    if (rssi > -70) return 3;
    if (rssi > -80) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final n = barsFor(rssi);
    final c = context.colors.accent;
    return Semantics(
      label: 'Sinyal $n / 4',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 6,
              height: 8.0 + i * 5,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: i < n ? c : AppColors.tint(c, 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
