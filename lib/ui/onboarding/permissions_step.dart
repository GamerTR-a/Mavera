import 'package:flutter/material.dart';

import '../l10n.dart';
import '../settings/permissions_screen.dart';

/// Ekran 3: İzinler. Devam: Bluetooth + Bildirim verilmiş, konum en az "kullanılırken".
class PermissionsStep extends StatelessWidget {
  const PermissionsStep({super.key, required this.onCanContinue});
  final ValueChanged<bool> onCanContinue;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.obPermTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        PermissionsList(onChanged: (s) => onCanContinue(s.coreGranted)),
      ],
    );
  }
}
