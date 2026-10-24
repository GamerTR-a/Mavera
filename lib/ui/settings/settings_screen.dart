import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../data/settings_repository.dart';
import '../history/history_screen.dart';
import '../l10n.dart';
import 'contacts_telegram_screen.dart';
import 'help_screen.dart';
import 'permissions_screen.dart';
import 'ring_screen.dart';
import 'sleep_mode_screen.dart';
import 'timing_screen.dart';
import 'welcome_message_screen.dart';

final _versionProvider = FutureProvider<String>((ref) async => (await PackageInfo.fromPlatform()).version);

/// Ekran 13: Ayarlar listesi.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final fw = ref.watch(settingsProvider.select((s) => s.firmwareVersion)) ?? '–';
    final version = ref.watch(_versionProvider).value ?? '';
    void open(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    final items = <(String, IconData, Widget)>[
      (t.settingsContacts, Icons.people_outline, const ContactsTelegramScreen()),
      (t.settingsTiming, Icons.timer_outlined, const TimingScreen()),
      (t.settingsSleep, Icons.bedtime_outlined, const SleepModeScreen()),
      (t.settingsRing, Icons.radio_button_checked, const RingScreen()),
      (t.settingsPermissions, Icons.verified_user_outlined, const PermissionsScreen()),
      (t.settingsWelcome, Icons.favorite_border, const WelcomeMessageScreen()),
      (t.settingsHistory, Icons.history, const HistoryScreen()),
      (t.settingsHelp, Icons.help_outline, const HelpScreen()),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(t.settingsTitle)),
      body: SafeArea(
        child: ListView(
          children: [
            for (final (title, icon, page) in items) ...[
              ListTile(
                leading: Icon(icon),
                title: Text(title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => open(page),
              ),
              const Divider(height: 1, indent: 56),
            ],
            const SizedBox(height: 24),
            Text(
              t.settingsFooter(version, fw),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
