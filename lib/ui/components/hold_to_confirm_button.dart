import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../theme/app_colors.dart';

/// Yanlışlıkla basılmasın diye [duration] boyunca basılı tutulan buton;
/// basılıyken bir halka dolar ve haptik adımlar verir.
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.hint,
    required this.onConfirmed,
    this.duration = K.helpHoldDuration,
  });

  final String label;
  final String hint;
  final VoidCallback onConfirmed;
  final Duration duration;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)
    ..addListener(_onTick)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        widget.onConfirmed();
        _c.reset();
      }
    });
  int _step = 0;

  void _onTick() {
    final step = (_c.value * 4).floor();
    if (step > _step) {
      _step = step;
      HapticFeedback.mediumImpact();
    }
  }

  void _start() {
    _step = 0;
    _c.forward(from: 0);
  }

  void _cancel() {
    if (_c.isAnimating) _c.reverse();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final danger = context.colors.danger;
    return Column(
      children: [
        Semantics(
          button: true,
          label: '${widget.label}. ${widget.hint}',
          onLongPress: widget.onConfirmed,
          excludeSemantics: true,
          child: GestureDetector(
            onTapDown: (_) => _start(),
            onTapUp: (_) => _cancel(),
            onTapCancel: _cancel,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.tint(danger, 0.12 + 0.2 * _c.value),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: danger, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        value: _c.value,
                        strokeWidth: 3,
                        color: danger,
                        backgroundColor: AppColors.tint(danger, 0.2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.label,
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: danger),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        ExcludeSemantics(
          child: Text(widget.hint, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
