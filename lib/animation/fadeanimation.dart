// ignore_for_file: prefer_const_constructors_in_immutables, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

/// Fades a widget in while sliding it down into place.
///
/// [delay] is a multiplier on a 500ms base delay, so staggering a list is just
/// a matter of passing an increasing delay per item.
class FadeAnimation extends StatelessWidget {
  final double delay;
  final Widget child;

  FadeAnimation({required this.delay, required this.child});

  static const _opacity = 'opacity';
  static const _translateY = 'translateY';

  @override
  Widget build(BuildContext context) {
    final tween = MovieTween()
      ..scene(
        begin: Duration.zero,
        duration: const Duration(milliseconds: 500),
      ).tween(_opacity, Tween(begin: 0.0, end: 1.0))
      ..scene(
        begin: Duration.zero,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      ).tween(_translateY, Tween(begin: -30.0, end: 0.0));

    return PlayAnimationBuilder<Movie>(
      delay: Duration(milliseconds: (500 * delay).round()),
      duration: tween.duration,
      tween: tween,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value.get(_opacity),
        child: Transform.translate(
          offset: Offset(0, value.get(_translateY)),
          child: child,
        ),
      ),
    );
  }
}
