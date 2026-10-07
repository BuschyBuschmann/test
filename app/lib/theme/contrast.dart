// WCAG-2.x-Kontrast (relative Luminanz, sRGB) für Test UI-3 und die
// Glow-Prüfung UI-7 (Plan 8.2). Reiner Rechencode auf `Color`.
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'cura_colors.dart';

double _linear(double channel) {
  return channel <= 0.04045
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

/// Relative Luminanz einer **deckenden** Farbe (Alpha wird ignoriert).
double relativeLuminance(Color c) {
  return 0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b);
}

/// Kontrastverhältnis zweier deckender Farben (1 … 21).
double contrastRatio(Color a, Color b) {
  final double la = relativeLuminance(a);
  final double lb = relativeLuminance(b);
  final double hi = math.max(la, lb);
  final double lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Alpha-Komposition von `top` über einer deckenden `bottom`-Farbe im
/// sRGB-Raum (wie die Darstellung). Ergebnis ist deckend.
Color compose(Color top, Color bottom) {
  final double a = top.a;
  return Color.from(
    alpha: 1,
    red: top.r * a + bottom.r * (1 - a),
    green: top.g * a + bottom.g * (1 - a),
    blue: top.b * a + bottom.b * (1 - a),
  );
}

/// Kontrast von `fg` über `bg`, wobei `fg` auch halbtransparent sein darf
/// (z. B. `border-control` Weiß 40 %): erst über `bg` komponieren.
double contrastOver(Color fg, Color bg) => contrastRatio(compose(fg, bg), bg);

/// Untergrund `bg` mit Glow-Alpha `glow` (`glow-ember` über `bg`).
Color backgroundWithGlow(CuraColors c, {double glow = 0}) {
  return compose(c.glowEmber.withValues(alpha: glow), c.bg);
}

/// Ungünstigste Stelle der Glas-Karte (Weiß 8,5 % über Untergrund) über einem
/// Glow-Alpha `glow` (Glow liegt unter dem Glas, Plan 2).
Color glassWithGlow(CuraColors c, {double glow = 0}) {
  return compose(c.surfaceGlassTop, backgroundWithGlow(c, glow: glow));
}

/// `surface-float` (82 %) über `bg` (ca. `#161E27`, Nav-Fläche).
Color floatOverBg(CuraColors c) => compose(c.surfaceFloat, c.bg);

/// Größter Glow-Alpha (0 … 1), bei dem `fg` auf `bg` bzw. Glas noch mindestens
/// `minRatio` erreicht (Zusatzbedingung für farbigen Text, N-19). `null`, wenn
/// schon ohne Glow darunter. Der Kontrast sinkt mit steigendem Glow monoton
/// (helle Schrift auf dunklem Grund), daher Intervallhalbierung.
double? maxGlowAlphaForContrast(
  Color fg,
  CuraColors c, {
  required bool onGlass,
  double minRatio = 4.5,
}) {
  double ratioAt(double glow) {
    final Color ground = onGlass
        ? glassWithGlow(c, glow: glow)
        : backgroundWithGlow(c, glow: glow);
    return contrastRatio(fg, ground);
  }

  if (ratioAt(0) < minRatio) return null;
  if (ratioAt(1) >= minRatio) return 1;
  double lo = 0;
  double hi = 1;
  for (int i = 0; i < 40; i++) {
    final double mid = (lo + hi) / 2;
    if (ratioAt(mid) >= minRatio) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return lo;
}
