import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:sneakers_app/theme/brand_tokens.dart';

/// Motion helpers.
///
/// Two jobs. First, every animation reads its duration from [BrandTokens]
/// rather than a literal — ad-hoc `Duration(milliseconds: 500)` scattered
/// across files is how an app ends up feeling incoherent. Second, and more
/// importantly, reduced-motion is honoured in one place instead of each widget
/// remembering to check.
extension MotionContext on BuildContext {
  /// True when the OS asks for reduced motion.
  ///
  /// This is an accessibility setting, not a preference — vestibular disorders
  /// make large parallax and slide transitions genuinely unpleasant. It also
  /// suppresses animation in widget tests, which is why they do not need to
  /// pump animation frames.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}

extension MotionEffects on Widget {
  /// Fade + rise entrance, staggered by [index].
  ///
  /// Returns the widget untouched under reduced motion — not a zero-duration
  /// animation, which still schedules frames and still leaves pending timers.
  Widget enter(BuildContext context, {int index = 0}) {
    if (context.reduceMotion) return this;
    return animate()
        .fadeIn(
          delay: Duration(milliseconds: BrandTokens.staggerStepMs * index),
          duration: BrandTokens.motionBase,
        )
        .slideY(begin: 0.06, curve: BrandTokens.motionEmphasized);
  }

  /// A brief attention pulse — used when a value changes under the user rather
  /// than because of a navigation.
  Widget pulse(BuildContext context, {Object? trigger}) {
    if (context.reduceMotion) return this;
    return animate(key: ValueKey(trigger))
        .scaleXY(
          begin: 1,
          end: 1.22,
          duration: BrandTokens.motionFast,
          curve: Curves.easeOut,
        )
        .then()
        .scaleXY(end: 1, duration: BrandTokens.motionFast, curve: Curves.easeIn);
  }
}
