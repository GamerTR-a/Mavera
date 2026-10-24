import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Son 40 sinyalin hareket değerlerini ince bir dalga olarak çizer;
/// her yeni sinyalde ([pulse] değişince) hafifçe "atar".
class MotionWave extends StatefulWidget {
  const MotionWave({super.key, required this.values, required this.pulse, required this.color, this.height = 48});
  final List<int> values;
  final int pulse;
  final Color color;
  final double height;

  @override
  State<MotionWave> createState() => _MotionWaveState();
}

class _MotionWaveState extends State<MotionWave> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void didUpdateWidget(MotionWave old) {
    super.didUpdateWidget(old);
    if (old.pulse != widget.pulse) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final beat = math.sin(_c.value * math.pi);
          return CustomPaint(
            size: Size(double.infinity, widget.height),
            painter: _WavePainter(widget.values, widget.color, 1 + beat * 0.25),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.values, this.color, this.amp);
  final List<int> values;
  final Color color;
  final double amp;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final mid = size.height / 2;
    final path = Path();
    final n = math.max(values.length, 2);
    final peak = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final maxV = math.max(peak, 60);
    for (var i = 0; i <= 160; i++) {
      final x = size.width * i / 160;
      final idx = math.min((i / 160 * (n - 1)).floor(), math.max(values.length - 1, 0));
      final v = values.isEmpty ? 0 : values[idx];
      final a = (v / maxV).clamp(0.05, 1.0) * (size.height / 2 - 2) * amp.clamp(0, 1.2);
      final y = mid + math.sin(i / 160 * math.pi * 8) * a;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.values != values || old.amp != amp || old.color != color;
}
