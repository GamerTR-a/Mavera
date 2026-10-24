import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models.dart';
import '../data/app_database.dart';
import '../data/contacts_repository.dart';
import '../data/event_log.dart';
import '../data/pending_alarm_store.dart';
import '../data/secure_token_store.dart';
import '../data/settings_repository.dart';
import '../services/app_core.dart';
import '../services/background/android_foreground_host.dart';
import '../services/background/background_host.dart';
import '../services/background/background_task_runner.dart';
import '../services/background/ios_background_host.dart';
import '../services/location/geolocator_location_provider.dart';
import '../services/location/location_provider.dart';
import '../services/notify/local_notification_service.dart';
import '../services/notify/notification_service.dart';
import '../services/ring/ble_ring_transport.dart';
import '../services/ring/switchable_ring_transport.dart';
import '../services/sms/android_sms_sender.dart';
import '../services/sms/noop_sms_sender.dart';
import '../services/sms/sms_sender.dart';
import '../services/telegram/telegram_client.dart';
import '../services/telegram/telegram_sender.dart';

// ---- main() içinde gerçek değerlerle değiştirilenler
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError());
final supportDirProvider = Provider<Directory>((ref) => throw UnimplementedError());

// ---- Servisler (testte sahteleri verilir)
final tokenStoreProvider = Provider<SecureTokenStore>((ref) => SecureTokenStore());
final contactsRepoProvider = Provider<ContactsRepository>((ref) => ContactsRepository(ref.watch(databaseProvider).db));
final eventLogProvider = Provider<EventLog>((ref) => EventLog(ref.watch(databaseProvider).db));
final pendingStoreProvider =
    Provider<PendingAlarmStore>((ref) => FilePendingAlarmStore(ref.watch(supportDirProvider)));
final telegramProvider = Provider<TelegramSender>((ref) => TelegramClient());
final locationProvider = Provider<LocationProvider>((ref) => GeolocatorLocationProvider());
final smsProvider = Provider<SmsSender>((ref) => Platform.isAndroid ? AndroidSmsSender() : NoopSmsSender());
final notificationsProvider = Provider<NotificationService>((ref) => LocalNotificationService());
final backgroundHostProvider =
    Provider<BackgroundHost>((ref) => Platform.isAndroid ? AndroidForegroundHost() : IosBackgroundHost());
final backgroundTaskProvider = Provider<BackgroundTaskRunner>(
    (ref) => Platform.isIOS ? IosBackgroundTaskRunner() : NoopBackgroundTaskRunner());
final transportProvider = Provider<SwitchableRingTransport>((ref) {
  final t = SwitchableRingTransport(BleRingTransport());
  ref.onDispose(() => unawaited(t.dispose()));
  return t;
});

/// Tek çekirdek denetleyici.
final appCoreProvider = Provider<AppCore>((ref) {
  final core = AppCore(
    settings: () => ref.read(settingsProvider),
    updateSettings: (f) => ref.read(settingsProvider.notifier).update(f),
    prefs: ref.watch(sharedPrefsProvider),
    tokens: ref.watch(tokenStoreProvider),
    contacts: ref.watch(contactsRepoProvider),
    eventLog: ref.watch(eventLogProvider),
    transport: ref.watch(transportProvider),
    telegram: ref.watch(telegramProvider),
    location: ref.watch(locationProvider),
    sms: ref.watch(smsProvider),
    notifications: ref.watch(notificationsProvider),
    background: ref.watch(backgroundHostProvider),
    backgroundTask: ref.watch(backgroundTaskProvider),
    pendingStore: ref.watch(pendingStoreProvider),
  );
  ref.listen<AppSettings>(settingsProvider, (prev, next) => unawaited(core.onSettingsChanged(prev, next)));
  ref.onDispose(() => unawaited(core.dispose()));
  return core;
});

/// UI'nın izlediği çekirdek görünümü; saniyede en az bir kez yenilenir.
class CoreViewNotifier extends Notifier<CoreView> {
  @override
  CoreView build() {
    final core = ref.watch(appCoreProvider);
    final sub = core.changes.listen((_) => state = core.view);
    ref.onDispose(sub.cancel);
    return core.view;
  }
}

final coreViewProvider = NotifierProvider<CoreViewNotifier, CoreView>(CoreViewNotifier.new);

/// Yakın kişiler.
class ContactsNotifier extends AsyncNotifier<List<EmergencyContact>> {
  ContactsRepository get _repo => ref.read(contactsRepoProvider);

  @override
  Future<List<EmergencyContact>> build() => ref.watch(contactsRepoProvider).all();

  Future<void> _reload() async {
    state = AsyncData(await _repo.all());
    await ref.read(appCoreProvider).contactsChanged();
  }

  Future<void> add(String name, String phone) async {
    await _repo.add(EmergencyContact(name: name, phone: phone));
    await _reload();
  }

  Future<void> edit(EmergencyContact c) async {
    await _repo.updateContact(c);
    await _reload();
  }

  Future<void> remove(int id) async {
    await _repo.remove(id);
    await _reload();
  }

  /// [newIndex], öğe çıkarıldıktan sonraki listeye göredir (`onReorderItem`).
  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = [...?state.value];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = AsyncData(list);
    await _repo.reorder(list);
    await _reload();
  }
}

final contactsProvider = AsyncNotifierProvider<ContactsNotifier, List<EmergencyContact>>(ContactsNotifier.new);

/// Olay geçmişi değiştikçe artan sayaç.
final eventsVersionProvider = StreamProvider<int>((ref) {
  var n = 0;
  return ref.watch(eventLogProvider).changes.map((_) => ++n);
});

final recentEventsProvider = FutureProvider<List<EventEntry>>((ref) {
  ref.watch(eventsVersionProvider);
  return ref.watch(eventLogProvider).recent(limit: 3);
});

final historyProvider = FutureProvider<List<EventEntry>>((ref) {
  ref.watch(eventsVersionProvider);
  return ref.watch(eventLogProvider).since(DateTime.now().subtract(const Duration(days: 30)));
});

/// Bot token'ının kayıtlı olup olmadığı (ekranda gösterilmez).
final hasTokenProvider = FutureProvider<bool>((ref) => ref.watch(tokenStoreProvider).hasToken);
