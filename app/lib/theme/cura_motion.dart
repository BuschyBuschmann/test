// Motion-Tokens (Design-Brief v1 3.6, Plan 8.1): Dauern und Kurve als
// Konstanten und `CuraMotion.of(context)` mit Erkennung von „Bewegung
// reduzieren“. Reduziert gilt, wenn `MediaQuery.disableAnimations` (Android,
// Web) **oder** `accessibilityFeatures.reduceMotion` (iOS meldet „Bewegung
// reduzieren“ nur dort) gesetzt ist oder die Prüfumgebung es per
// [PreviewMotionOverride] erzwingt (`main_preview`, U2p).
import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// Erzwingt „Bewegung reduzieren“ unterhalb dieses Widgets. Nur für die
/// Prüfumgebung (`main_preview`): `reduceMotion` kommt aus dem
/// `platformDispatcher` und lässt sich dort nicht per `MediaQuery` überstimmen
/// (Plan 8.1).
class PreviewMotionOverride extends InheritedWidget {
  const PreviewMotionOverride({
    super.key,
    required this.reduceMotion,
    required super.child,
  });

  final bool reduceMotion;

  static bool? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PreviewMotionOverride>()
      ?.reduceMotion;

  @override
  bool updateShouldNotify(PreviewMotionOverride oldWidget) =>
      reduceMotion != oldWidget.reduceMotion;
}

@immutable
class CuraMotion {
  const CuraMotion({required this.reduced});

  /// Dauern und Kurve (Brief 3.6). Mit [duration] auf reduzierte Bewegung
  /// abbilden.
  static const Duration fastDuration = MotionTokens.fast;
  static const Duration baseDuration = MotionTokens.base;
  static const Duration slowDuration = MotionTokens.slow;
  static const Curve easing = MotionTokens.curve;

  /// Bewegung reduzieren ist aktiv.
  final bool reduced;

  Duration get fast => fastDuration;
  Duration get base => baseDuration;
  Duration get slow => slowDuration;
  Curve get curve => easing;

  /// Dauer für ein Ein-/Überblenden: bei reduzierter Bewegung höchstens
  /// `fast` (Brief 3.6).
  Duration duration(Duration wanted) {
    if (!reduced) return wanted;
    return wanted > fastDuration ? fastDuration : wanted;
  }

  /// Schiebung in dp: bei reduzierter Bewegung entfällt sie.
  double slide(double dp) => reduced ? 0 : dp;

  static CuraMotion of(BuildContext context) {
    final bool system =
        MediaQuery.disableAnimationsOf(context) ||
        (View.maybeOf(context)
                ?.platformDispatcher
                .accessibilityFeatures
                .reduceMotion ??
            false);
    final bool? preview = PreviewMotionOverride.maybeOf(context);
    return CuraMotion(reduced: preview ?? system);
  }
}
