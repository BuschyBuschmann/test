// Glow-Geometrie und Alpha-Funktion als reiner Code (Plan 8.2, Brief 3.2 und
// Errata E-1), geteilt von Painter (`GlowBackground`, U2a) und Tests.
// Bewusst ohne Flutter-Import: nur Zahlen.
import 'dart:math' as math;

import 'tokens.dart';

/// Ein Lichtfleck: Mitte, Radius und Spitzen-Deckkraft (dp bzw. Anteil 0..1).
class GlowSpot {
  const GlowSpot({
    required this.centerX,
    required this.centerY,
    required this.radius,
    required this.peak,
  });

  final double centerX;
  final double centerY;
  final double radius;
  final double peak;

  /// Abstand, bei dem der Verlauf null erreicht (70 % des Radius).
  double get zeroDistance => GlowTokens.zeroStop * radius;

  /// `alpha(d) = peak × max(0, 1 − d / (0,7 × r))`.
  double alphaAtDistance(double distance) {
    return peak * math.max(0, 1 - distance / zeroDistance);
  }

  double alphaAt(double x, double y) {
    return alphaAtDistance(_distance(x, y));
  }

  double _distance(double x, double y) {
    final double dx = x - centerX;
    final double dy = y - centerY;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Alpha am dem Mittelpunkt nächstgelegenen Punkt eines Rechtecks
  /// (Prüfregel Errata E-1, Punkt 5): der Maximalwert des Flecks über dem
  /// Rechteck.
  double alphaForRect(double left, double top, double right, double bottom) {
    final double x = centerX.clamp(left, right).toDouble();
    final double y = centerY.clamp(top, bottom).toDouble();
    return alphaAt(x, y);
  }
}

/// Die beiden Lichtflecke eines Screens der Größe `width × height` (dp).
class GlowGeometry {
  const GlowGeometry(this.width, this.height);

  final double width;
  final double height;

  /// Oben links: Mitte (−30, 40), Radius 260, Spitze 0,24.
  GlowSpot get topLeft => const GlowSpot(
    centerX: GlowTokens.topLeftCenterX,
    centerY: GlowTokens.topLeftCenterY,
    radius: GlowTokens.topLeftRadius,
    peak: GlowTokens.topLeftPeak,
  );

  /// Unten rechts: Mitte (Breite + 50, Höhe − 24), Radius 300, Spitze 0,14.
  GlowSpot get bottomRight => GlowSpot(
    centerX: width + GlowTokens.bottomRightOffsetX,
    centerY: height - GlowTokens.bottomRightOffsetY,
    radius: GlowTokens.bottomRightRadius,
    peak: GlowTokens.bottomRightPeak,
  );

  List<GlowSpot> get spots => <GlowSpot>[topLeft, bottomRight];

  /// Gesamt-Alpha an einem Punkt: Komposition beider Verläufe,
  /// `1 − (1 − a1)(1 − a2)`.
  double alphaAt(double x, double y) {
    return composeAlpha(<double>[
      topLeft.alphaAt(x, y),
      bottomRight.alphaAt(x, y),
    ]);
  }

  /// Gesamt-Alpha für ein Text-Rechteck: je Fleck der nächstgelegene Punkt,
  /// danach Komposition (konservativ, Errata E-1).
  double alphaForRect(double left, double top, double right, double bottom) {
    return composeAlpha(<double>[
      topLeft.alphaForRect(left, top, right, bottom),
      bottomRight.alphaForRect(left, top, right, bottom),
    ]);
  }
}

/// `1 − Π(1 − aᵢ)`.
double composeAlpha(Iterable<double> alphas) {
  double rest = 1;
  for (final double a in alphas) {
    rest *= 1 - a;
  }
  return 1 - rest;
}

/// Untergrund eines Textes für die Glow-Regel (Errata E-1).
enum GlowBackdrop { bg, glass, coloredOnGlass }

/// Höchstzulässiger Glow-Alpha für einen Text auf dem jeweiligen Untergrund:
/// `bg` 24 %, `text-1/2/3` auf Glas 16 %, farbiger Text und `accent-hi` auf
/// Glas 12 %.
double maxGlowAlphaFor(GlowBackdrop backdrop) {
  switch (backdrop) {
    case GlowBackdrop.bg:
      return GlowTokens.maxOnBg;
    case GlowBackdrop.glass:
      return GlowTokens.maxTextOnGlass;
    case GlowBackdrop.coloredOnGlass:
      return GlowTokens.maxColoredOnGlass;
  }
}
