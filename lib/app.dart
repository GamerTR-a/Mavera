import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/monitor_phase.dart';
import 'data/settings_repository.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers/providers.dart';
import 'theme/app_theme.dart';
import 'ui/main/alarm_active_screen.dart';
import 'ui/main/home_screen.dart';
import 'ui/main/pre_alarm_screen.dart';
import 'ui/onboarding/onboarding_flow.dart';

enum _AlarmRoute { pre, alarm }

/// MaterialApp, tema, l10n ve ön uyarı / alarm tam ekran rotaları.
class GuvenApp extends ConsumerStatefulWidget {
  const GuvenApp({super.key});

  @override
  ConsumerState<GuvenApp> createState() => _GuvenAppState();
}

class _GuvenAppState extends ConsumerState<GuvenApp> with WidgetsBindingObserver {
  final _navKey = GlobalKey<NavigatorState>();
  _AlarmRoute? _shown;
  Route<void>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sync(ref.read(coreViewProvider).phase);
      // İlk "resumed" olayı gözlemci eklenmeden önce gelmiş olabilir.
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(ref.read(appCoreProvider).onLifecycle(AppLifecycleState.resumed));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(ref.read(appCoreProvider).onLifecycle(state));
  }

  /// Faz `PreAlarm` / `AlarmActive` iken kök navigator üzerinde tam ekran rota açar;
  /// faz değişince kapatır.
  void _sync(MonitorPhase phase) {
    final nav = _navKey.currentState;
    if (nav == null) return;
    final want = switch (phase) {
      PreAlarm() => _AlarmRoute.pre,
      AlarmActive() => _AlarmRoute.alarm,
      _ => null,
    };
    if (want == _shown) return;
    final old = _route;
    if (old != null && old.isActive) nav.removeRoute(old);
    _route = null;
    _shown = want;
    if (want == null) return;
    final route = PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => want == _AlarmRoute.pre ? const PreAlarmScreen() : const AlarmActiveScreen(),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    );
    _route = route;
    unawaited(nav.push(route));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Type>(
      coreViewProvider.select((v) => v.phase.runtimeType),
      (_, _) => _sync(ref.read(coreViewProvider).phase),
    );
    return MaterialApp(
      navigatorKey: _navKey,
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const RootGate(),
    );
  }
}

/// `onboardingDone ? HomeScreen : OnboardingFlow`.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(settingsProvider.select((s) => s.onboardingDone));
    return done ? const HomeScreen() : const OnboardingFlow();
  }
}
