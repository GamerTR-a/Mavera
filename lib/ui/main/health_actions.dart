import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/health_check.dart';
import '../../providers/providers.dart';
import '../../services/system_channel.dart';
import '../settings/contacts_telegram_screen.dart';
import '../settings/permissions_screen.dart';
import '../settings/ring_screen.dart';

/// Kalkanın altındaki çözüm butonunun yaptığı iş.
void runHealthAction(BuildContext context, WidgetRef ref, HealthAction a) {
  final core = ref.read(appCoreProvider);
  void push(Widget w) => unawaited(Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w)));
  switch (a) {
    case HealthAction.none:
    case HealthAction.onboarding:
      break;
    case HealthAction.systemSettings:
    case HealthAction.locationSettings:
      unawaited(openAppSettings());
    case HealthAction.bluetoothSettings:
      unawaited(Platform.isAndroid ? SystemChannel.openBluetoothSettings() : openAppSettings());
    case HealthAction.ringHelp:
      push(const RingScreen());
    case HealthAction.telegramSettings:
    case HealthAction.contacts:
      push(const ContactsTelegramScreen());
    case HealthAction.restartService:
      unawaited(core.restartBackground());
    case HealthAction.backgroundSetup:
      push(const PermissionsScreen());
    case HealthAction.resume:
      core.resume();
  }
}
