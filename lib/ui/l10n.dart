import 'package:flutter/widgets.dart';

import '../core/alarm_reason.dart';
import '../core/events.dart';
import '../l10n/generated/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get t => AppLocalizations.of(this);
}

extension EventKindLabel on AppLocalizations {
  /// Olay türünün Türkçe adı.
  String eventLabel(String kind) => switch (EventKind.byName(kind)) {
        EventKind.preAlarmCancelled => evPreAlarmCancelled,
        EventKind.preAlarmEscalated => evPreAlarmEscalated,
        EventKind.alarmSent => evAlarmSent,
        EventKind.alarmDeliveredLate => evAlarmDeliveredLate,
        EventKind.smsSent => evSmsSent,
        EventKind.alarmClosed => evAlarmClosed,
        EventKind.sos => evSos,
        EventKind.tremor => evTremor,
        EventKind.manualHelp => evManualHelp,
        EventKind.ringConnected => evRingConnected,
        EventKind.ringDisconnected => evRingDisconnected,
        EventKind.lowBattery => evLowBattery,
        EventKind.paused => evPaused,
        EventKind.resumed => evResumed,
        EventKind.sleepOn => evSleepOn,
        EventKind.sleepOff => evSleepOff,
        EventKind.packetLoss => evPacketLoss,
        EventKind.telegramCheckFailed => evTelegramCheckFailed,
        EventKind.protectionGap => evProtectionGap,
        null => kind,
      };

  String preAlarmTitle(AlarmReason r) => switch (r) {
        Sos() => preAlarmTitleSos,
        Tremor() => preAlarmTitleTremor,
        Inactivity() || Manual() => preAlarmTitleInactivity,
      };

  String preAlarmReason(AlarmReason r) => switch (r) {
        Inactivity(:final minutes) => preAlarmReasonInactivity(minutes),
        Sos() => preAlarmReasonSos,
        Tremor() => preAlarmReasonTremor,
        Manual() => alarmReasonManual,
      };

  String alarmReasonShort(AlarmReason r) => switch (r) {
        Inactivity() => alarmReasonInactivity,
        Sos() => alarmReasonSos,
        Tremor() => alarmReasonTremor,
        Manual() => alarmReasonManual,
      };

  /// "3 gün" / "5 saat" / "20 dk".
  String duration(Duration d) {
    if (d.inHours >= 48) return durationDays((d.inHours / 24).round());
    if (d.inMinutes >= 90) return durationHours((d.inMinutes / 60).round());
    return commonMinutes(d.inMinutes);
  }
}
