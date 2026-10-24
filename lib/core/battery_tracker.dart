import 'constants.dart';

/// Yüzük pilinin geçmişini tutar; kalan süre tahmini ve son şarj zamanı verir.
class BatteryTracker {
  final List<(DateTime, int)> _samples = <(DateTime, int)>[];
  DateTime? _lastFullAt;
  bool _wasFull = false;

  /// Pilin %95'i ilk geçtiği an (son şarj).
  DateTime? get lastFullAt => _lastFullAt;

  void add(DateTime at, int pct) {
    if (pct >= K.ringBatteryFullPct) {
      if (!_wasFull) _lastFullAt = at;
      _wasFull = true;
    } else if (pct < K.ringBatteryFullPct - 5) {
      _wasFull = false;
    }
    if (_samples.isNotEmpty && _samples.last.$2 < pct - 2) {
      // Şarj edildi: eski düşüş verisi geçersiz.
      _samples.clear();
    }
    _samples.add((at, pct));
    final cutoff = at.subtract(K.batteryHistoryWindow);
    _samples.removeWhere((s) => s.$1.isBefore(cutoff));
  }

  /// Kalan tahmini süre; yeterli veri yoksa `null`.
  Duration? estimateRemaining() {
    if (_samples.length < 2) return null;
    final first = _samples.first;
    final last = _samples.last;
    final span = last.$1.difference(first.$1);
    if (span < K.batteryMinHistory) return null;
    final drop = first.$2 - last.$2;
    if (drop <= 0) return null;
    final perHour = drop / (span.inMinutes / 60);
    final hours = last.$2 / perHour;
    return Duration(minutes: (hours * 60).round());
  }
}
