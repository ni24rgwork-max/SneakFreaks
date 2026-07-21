import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:sneakers_app/theme/motion.dart';

/// Holographic sheen for rare cards.
///
/// A physical foil card shifts colour as you tilt it; that parallax is most of
/// why holo cards feel valuable. This reads the accelerometer and moves the
/// gradient's origin to match, so the effect responds to the device rather than
/// looping on a timer.
///
/// Falls back to a static sheen when there is no accelerometer (simulators,
/// desktop, most test environments) and renders nothing at all under reduced
/// motion — a shifting rainbow is exactly the kind of effect that setting
/// exists to suppress.
class CardFoil extends StatefulWidget {
  const CardFoil({
    super.key,
    this.intensity = 0.3,
    this.borderRadius = BorderRadius.zero,
  });

  final double intensity;
  final BorderRadius borderRadius;

  @override
  State<CardFoil> createState() => _CardFoilState();
}

class _CardFoilState extends State<CardFoil> {
  StreamSubscription<AccelerometerEvent>? _sub;
  double _x = 0;
  double _y = 0;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    try {
      _sub = accelerometerEventStream().listen(
        (e) {
          if (!mounted) return;
          setState(() {
            // Low-pass filter: raw accelerometer values are noisy enough that
            // the sheen would jitter visibly if applied directly.
            _x = _x * 0.85 + (e.x / 9.8).clamp(-1.0, 1.0) * 0.15;
            _y = _y * 0.85 + (e.y / 9.8).clamp(-1.0, 1.0) * 0.15;
          });
        },
        onError: (_) {
          // No sensor on this platform — the static sheen still looks fine.
          _sub?.cancel();
          _sub = null;
        },
        cancelOnError: true,
      );
    } catch (_) {
      _sub = null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return const SizedBox.shrink();

    final dx = (-_x * 1.6).clamp(-1.0, 1.0);
    final dy = (_y * 1.6).clamp(-1.0, 1.0);

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(dx - 1, dy - 1),
            end: Alignment(dx + 1, dy + 1),
            colors: [
              Colors.transparent,
              const Color(0xFF7DF9FF).withValues(alpha: widget.intensity * 0.5),
              const Color(0xFFFF7DE9).withValues(alpha: widget.intensity * 0.6),
              const Color(0xFFFFE97D).withValues(alpha: widget.intensity * 0.5),
              Colors.transparent,
            ],
            stops: const [0.0, 0.32, 0.5, 0.68, 1.0],
          ),
        ),
      ),
    );
  }
}
