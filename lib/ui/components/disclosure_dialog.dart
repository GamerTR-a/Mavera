import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../providers/providers.dart';
import '../../services/permissions.dart';
import '../../theme/app_colors.dart';
import '../l10n.dart';

/// Sistem izin penceresinden önce gösterilen, göze çarpan açıklama
/// (Google Play "Prominent disclosure" gereksinimi). Kabul edilirse `true`.
Future<bool> showDisclosure(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String body,
}) async {
  final t = context.t;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: Icon(icon, color: ctx.colors.accent, size: 36),
      title: Text(title, textAlign: TextAlign.center),
      content: SingleChildScrollView(child: Text(body, style: Theme.of(ctx).textTheme.bodyLarge)),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.discDecline)),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(t.discAccept)),
      ],
    ),
  );
  return ok ?? false;
}

/// Konum açıklaması + izin isteği.
Future<void> requestLocationWithDisclosure(BuildContext context, WidgetRef ref) async {
  final t = context.t;
  final accepted = await showDisclosure(
    context,
    icon: Icons.location_on_outlined,
    title: t.discLocTitle,
    body: t.discLocBody,
  );
  if (!accepted) return;
  await PermissionsService(ref.read(locationProvider), ref.read(notificationsProvider)).requestLocation();
}

/// SMS açıklaması + izin isteği. İzin zaten varsa pencere gösterilmez.
/// İzin verildiyse `true`.
Future<bool> requestSmsWithDisclosure(BuildContext context, WidgetRef ref) async {
  if (await Permission.sms.isGranted) return true;
  if (!context.mounted) return false;
  final t = context.t;
  final accepted = await showDisclosure(
    context,
    icon: Icons.sms_outlined,
    title: t.discSmsTitle,
    body: t.discSmsBody,
  );
  if (!accepted) return false;
  return PermissionsService(ref.read(locationProvider), ref.read(notificationsProvider)).requestSms();
}
