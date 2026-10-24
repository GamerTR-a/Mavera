/// Yüzükten gelen bir satırın ayrıştırılmış hâli.
sealed class RingMessage {
  const RingMessage();
}

/// 30 sn'de bir gelen durum sinyali (`HB`).
class Heartbeat extends RingMessage {
  const Heartbeat({
    required this.seq,
    required this.moves,
    required this.intensity,
    required this.millivolts,
    required this.percent,
    required this.flags,
  });

  final int seq;
  final int moves;
  final int intensity;
  final int millivolts;
  final int percent;
  final int flags;

  /// Bu periyotta SOS olduysa (bit0).
  bool get hadSos => flags & 0x1 != 0;

  /// Bu periyotta titreme olduysa (bit1).
  bool get hadTremor => flags & 0x2 != 0;

  @override
  bool operator ==(Object other) =>
      other is Heartbeat &&
      other.seq == seq &&
      other.moves == moves &&
      other.intensity == intensity &&
      other.millivolts == millivolts &&
      other.percent == percent &&
      other.flags == flags;

  @override
  int get hashCode => Object.hash(seq, moves, intensity, millivolts, percent, flags);
}

/// Yüzüğe üç kez vuruldu.
class SosMessage extends RingMessage {
  const SosMessage(this.seq);
  final int seq;

  @override
  bool operator ==(Object other) => other is SosMessage && other.seq == seq;

  @override
  int get hashCode => seq.hashCode;
}

/// 20 sn kesintisiz ritmik titreme.
class TremorMessage extends RingMessage {
  const TremorMessage(this.seq);
  final int seq;

  @override
  bool operator ==(Object other) => other is TremorMessage && other.seq == seq;

  @override
  int get hashCode => seq.hashCode;
}

/// `VER?` komutunun cevabı.
class VersionMessage extends RingMessage {
  const VersionMessage(this.version);
  final String version;

  @override
  bool operator ==(Object other) => other is VersionMessage && other.version == version;

  @override
  int get hashCode => version.hashCode;
}

/// `RAW,1` açıkken saniyede 5 kez gelen anlık hareket değeri.
class RawMessage extends RingMessage {
  const RawMessage(this.milliG);
  final int milliG;

  @override
  bool operator ==(Object other) => other is RawMessage && other.milliG == milliG;

  @override
  int get hashCode => milliG.hashCode;
}

/// Yüzük satır protokolü ayrıştırıcısı ve komut üreticisi.
abstract final class RingProtocol {
  /// Tek bir satırı (sonundaki `\n` olmadan) ayrıştırır.
  /// Bilinmeyen ya da bozuk satırlar için `null` döner.
  static RingMessage? parse(String line) {
    final parts = line.trim().split(',');
    if (parts.isEmpty) return null;
    switch (parts[0]) {
      case 'HB':
        if (parts.length < 7) return null;
        final v = <int>[];
        for (var i = 1; i <= 6; i++) {
          final n = int.tryParse(parts[i].trim());
          if (n == null || n < 0) return null;
          v.add(n);
        }
        if (v[0] > 255) return null;
        return Heartbeat(
          seq: v[0],
          moves: v[1],
          intensity: v[2],
          millivolts: v[3],
          percent: v[4].clamp(0, 100),
          flags: v[5],
        );
      case 'SOS':
        if (parts.length < 2) return null;
        final seq = int.tryParse(parts[1].trim());
        return seq == null ? null : SosMessage(seq);
      case 'TRM':
        if (parts.length < 2) return null;
        final seq = int.tryParse(parts[1].trim());
        return seq == null ? null : TremorMessage(seq);
      case 'VER':
        if (parts.length < 2 || parts[1].trim().isEmpty) return null;
        return VersionMessage(parts[1].trim());
      case 'RAW':
        if (parts.length < 2) return null;
        final mg = int.tryParse(parts[1].trim());
        return mg == null ? null : RawMessage(mg);
      default:
        return null;
    }
  }

  static String ack(int seq) => 'ACK,$seq\n';
  static String cfg(int thresholdMilliG, int intervalS) => 'CFG,$thresholdMilliG,$intervalS\n';
  static String buzz(int ms) => 'BUZ,$ms\n';
  static const versionQuery = 'VER?\n';
  static String raw({required bool on}) => on ? 'RAW,1\n' : 'RAW,0\n';

  /// `a.b` biçimindeki sürümün en az [major].[minor] olup olmadığı.
  static bool versionAtLeast(String? version, int major, int minor) {
    if (version == null) return false;
    final p = version.split('.');
    final ma = int.tryParse(p.isNotEmpty ? p[0] : '') ?? 0;
    final mi = int.tryParse(p.length > 1 ? p[1] : '') ?? 0;
    return ma > major || (ma == major && mi >= minor);
  }
}
