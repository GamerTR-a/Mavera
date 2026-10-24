import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../providers/providers.dart';
import '../../services/location/location_provider.dart';
import '../../services/permissions.dart';
import '../../services/system_channel.dart';
import '../components/disclosure_dialog.dart';
import '../components/permission_card.dart';
import '../components/status_card.dart';
import '../l10n.dart';

final permissionsServiceProvider = Provider<PermissionsService>(
  (ref) => PermissionsService(ref.watch(locationProvider), ref.watch(notificationsProvider)),
);

/// Ekran "İzinler ve arka plan".
class PermissionsScreen extends ConsumerWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.permTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const PermissionsList(showOptional: true),
            if (Platform.isAndroid) ...[
              SectionLabel(t.obBgTitle.toUpperCase()),
              const BackgroundSetup(),
            ],
            if (Platform.isIOS) ...[
              const SizedBox(height: 8),
              PermissionCard(title: t.permCriticalIos, reason: t.permCriticalIosWhy, state: PermState.partial),
              const SizedBox(height: 8),
              PermissionCard(
                title: t.permFocusIos,
                reason: t.permFocusIosWhy,
                state: PermState.partial,
                actionLabel: t.commonOpenSettings,
                onAction: () => unawaited(openAppSettings()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// İzin kartları listesi; uygulamaya dönülünce durumları tazeler.
class PermissionsList extends ConsumerStatefulWidget {
  const PermissionsList({super.key, this.showOptional = false, this.onChanged});
  final bool showOptional;
  final ValueChanged<PermissionsSnapshot>? onChanged;

  @override
  ConsumerState<PermissionsList> createState() => _PermissionsListState();
}

class _PermissionsListState extends ConsumerState<PermissionsList> with WidgetsBindingObserver {
  PermissionsSnapshot? _snap;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final s = await ref.read(permissionsServiceProvider).read();
    if (!mounted) return;
    setState(() => _snap = s);
    widget.onChanged?.call(s);
  }

  Future<void> _run(Future<void> Function() f) async {
    await f();
    await _refresh();
    final core = ref.read(appCoreProvider);
    await core.startRing();
    await core.refreshHealth();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final s = _snap;
    if (s == null) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    final p = ref.read(permissionsServiceProvider);
    final android = Platform.isAndroid;
    String? locNote;
    if (s.location == LocationAuth.whileInUse && !android) {
      locNote = t.permLocationPartial;
    } else if (s.location != LocationAuth.denied && !s.locationPrecise) {
      locNote = t.permLocationApprox;
    }
    final locDone = s.locationState == PermState.granted;
    Widget gap() => const SizedBox(height: 8);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PermissionCard(
          title: t.permBluetooth,
          reason: t.permBluetoothWhy,
          state: s.bluetooth,
          actionLabel: t.commonAllow,
          onAction: () => unawaited(_run(p.requestBluetooth)),
        ),
        gap(),
        PermissionCard(
          title: t.permNotifications,
          reason: t.permNotificationsWhy,
          state: s.notifications,
          actionLabel: t.commonAllow,
          onAction: () => unawaited(_run(p.requestNotifications)),
        ),
        gap(),
        PermissionCard(
          title: android ? t.permLocationAndroid : t.permLocation,
          reason: android ? t.permLocationAndroidWhy : t.permLocationWhy,
          state: s.locationState,
          note: locNote,
          actionLabel: s.location == LocationAuth.denied ? t.commonAllow : t.commonOpenSettings,
          onAction: locDone
              ? null
              : () => unawaited(_run(() => requestLocationWithDisclosure(context, ref))),
        ),
        if (android) ...[
          gap(),
          PermissionCard(
            title: t.permFullScreen,
            reason: t.permFullScreenWhy,
            state: s.fullScreen,
            actionLabel: t.commonOpenSettings,
            onAction: () => unawaited(_run(p.requestFullScreen)),
          ),
          gap(),
          PermissionCard(
            title: t.permDnd,
            reason: t.permDndWhy,
            state: s.dnd == PermState.granted ? PermState.granted : PermState.partial,
            actionLabel: t.commonOpenSettings,
            onAction: () => unawaited(_run(p.requestDnd)),
          ),
          if (widget.showOptional) ...[
            gap(),
            PermissionCard(
              title: t.permSms,
              reason: t.permSmsWhy,
              state: s.sms == PermState.granted ? PermState.granted : PermState.partial,
              actionLabel: t.commonAllow,
              onAction: () => unawaited(_run(() async {
                await requestSmsWithDisclosure(context, ref);
              })),
            ),
          ],
        ],
      ],
    );
  }
}

/// Ekran 3b: pil optimizasyonu + üreticiye özel adımlar (yalnızca Android).
class BackgroundSetup extends ConsumerStatefulWidget {
  const BackgroundSetup({super.key});

  @override
  ConsumerState<BackgroundSetup> createState() => _BackgroundSetupState();
}

class _BackgroundSetupState extends ConsumerState<BackgroundSetup> with WidgetsBindingObserver {
  bool? _exempt;
  String _brand = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final ok = await Permission.ignoreBatteryOptimizations.isGranted;
    final b = await PermissionsService.manufacturer();
    if (mounted) {
      setState(() {
        _exempt = ok;
        _brand = b;
      });
    }
  }

  /// Üreticiye özel, resimsiz kısa adımlar.
  static List<String>? stepsFor(String brand) {
    if (['xiaomi', 'redmi', 'poco'].any(brand.contains)) {
      return [
        'Ayarlar > Uygulamalar > Güven Yüzüğü',
        '"Otomatik başlatma"yı aç',
        '"Pil tasarrufu" > "Kısıtlama yok" seç',
      ];
    }
    if (brand.contains('samsung')) {
      return [
        'Ayarlar > Pil > Arka plan kullanım sınırları',
        '"Uyutulan uygulamalar" listesinden Güven Yüzüğü\'nü çıkar',
        '"Hiç uyutulmayan uygulamalar"a ekle',
      ];
    }
    if (['oppo', 'realme', 'oneplus'].any(brand.contains)) {
      return [
        'Ayarlar > Pil > Güven Yüzüğü',
        '"Arka plan etkinliğine izin ver"i aç',
        '"Otomatik başlat"ı aç',
      ];
    }
    if (['huawei', 'honor'].any(brand.contains)) {
      return [
        'Ayarlar > Pil > Uygulama başlatma',
        'Güven Yüzüğü için otomatik yönetimi kapat',
        'Otomatik başlat, ikincil başlat ve arka planda çalış seçeneklerini aç',
      ];
    }
    if (brand.contains('vivo')) {
      return [
        'Ayarlar > Pil > Arka plan güç tüketimi',
        'Güven Yüzüğü\'ne izin ver',
        'i Yönetici > Uygulama yöneticisi > Otomatik başlat\'ı aç',
      ];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final steps = stepsFor(_brand);
    final ok = _exempt ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PermissionCard(
          title: t.permBattery,
          reason: t.permBatteryWhy,
          state: ok ? PermState.granted : PermState.denied,
          actionLabel: t.obBgButton,
          onAction: () async {
            await Permission.ignoreBatteryOptimizations.request();
            await _refresh();
            await ref.read(appCoreProvider).refreshHealth();
          },
        ),
        if (steps != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.obBgBrandSteps, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (var i = 0; i < steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('${i + 1}. ${steps[i]}'),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => unawaited(SystemChannel.openManufacturerSettings()),
                    child: Text(t.commonOpenSettings),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
