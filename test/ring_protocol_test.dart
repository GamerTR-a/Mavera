import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mavera/core/line_buffer.dart';
import 'package:mavera/core/ring_protocol.dart';

void main() {
  group('RingProtocol.parse', () {
    test('geçerli satırlar', () {
      expect(
        RingProtocol.parse('HB,12,34,567,3900,80,3'),
        const Heartbeat(seq: 12, moves: 34, intensity: 567, millivolts: 3900, percent: 80, flags: 3),
      );
      final hb = RingProtocol.parse('HB,1,0,0,0,0,3') as Heartbeat;
      expect(hb.hadSos, isTrue);
      expect(hb.hadTremor, isTrue);
      expect(RingProtocol.parse('SOS,7'), const SosMessage(7));
      expect(RingProtocol.parse('TRM,8'), const TremorMessage(8));
      expect(RingProtocol.parse('VER,0.2'), const VersionMessage('0.2'));
      expect(RingProtocol.parse('RAW,123'), const RawMessage(123));
      expect(RingProtocol.parse('HB,1,2,3,4,5,6\r'), isA<Heartbeat>());
    });

    test('eksik / bozuk / bilinmeyen satırlar null', () {
      expect(RingProtocol.parse('HB,1,2,3'), isNull);
      expect(RingProtocol.parse('HB,a,2,3,4,5,6'), isNull);
      expect(RingProtocol.parse('HB,300,2,3,4,5,6'), isNull);
      expect(RingProtocol.parse('HB,1,-2,3,4,5,6'), isNull);
      expect(RingProtocol.parse('SOS'), isNull);
      expect(RingProtocol.parse('SOS,x'), isNull);
      expect(RingProtocol.parse('XYZ,1'), isNull);
      expect(RingProtocol.parse(''), isNull);
      expect(RingProtocol.parse('VER,'), isNull);
    });

    test('komutlar', () {
      expect(RingProtocol.ack(5), 'ACK,5\n');
      expect(RingProtocol.cfg(25, 30), 'CFG,25,30\n');
      expect(RingProtocol.raw(on: true), 'RAW,1\n');
      expect(RingProtocol.versionAtLeast('0.2', 0, 2), isTrue);
      expect(RingProtocol.versionAtLeast('0.1', 0, 2), isFalse);
      expect(RingProtocol.versionAtLeast('1.0', 0, 2), isTrue);
    });
  });

  group('LineBuffer', () {
    test('birleşik paketler (bir bildirimde iki satır)', () {
      final b = LineBuffer();
      expect(b.add(utf8.encode('SOS,1\nTRM,2\n')), ['SOS,1', 'TRM,2']);
    });

    test('bölünmüş paketler', () {
      final b = LineBuffer();
      expect(b.add(utf8.encode('HB,1,2,3')), isEmpty);
      expect(b.add(utf8.encode(',4,5,6\nSO')), ['HB,1,2,3,4,5,6']);
      expect(b.add(utf8.encode('S,3\n')), ['SOS,3']);
    });

    test('256 baytı aşan tampon temizlenir', () {
      final b = LineBuffer();
      b.add(List<int>.filled(300, 0x41));
      expect(b.add(utf8.encode('AAA\nSOS,1\n')), ['SOS,1']);
    });

    test('CRLF ve boş satırlar', () {
      final b = LineBuffer();
      expect(b.add(utf8.encode('SOS,1\r\n\n')), ['SOS,1']);
    });
  });
}
