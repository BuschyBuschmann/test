// WCAG-2.x-Kontrast (relative Luminanz, sRGB) für die Tests V2-3 (Welt) und
// V2-4 (Inhaltsflächen) und die Matrix. Reiner Rechencode auf `Color`.
import 'dart:math' as math;
import 'dart:ui' show Color;

import 'world_tokens.dart';

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

/// Ungünstigste Untergründe unter einer halbtransparenten Fläche (Brief 3.1:
/// Schwarz, Weiß, Mandarine; 3.2 zusätzlich Grau).
const List<Color> kWorstCaseGrounds = <Color>[
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFFFF7A2E),
  Color(0xFF808080),
];

/// Kleinster Kontrast von [fg] gegen die Fläche [layer] (mit Alpha) über allen
/// [grounds] (Worst Case).
double worstCaseContrast(
  Color fg,
  Color layer, {
  List<Color> grounds = kWorstCaseGrounds,
}) {
  double worst = double.infinity;
  for (final Color g in grounds) {
    final double r = contrastRatio(fg, compose(layer, g));
    if (r < worst) worst = r;
  }
  return worst;
}

/// Kopf-Karte (Brief 3.1): weißer Text gegen `header-tint` über dem
/// ungünstigsten Untergrund (oberste Himmelsfarbe oder reines Weiß).
double worldHeaderContrast(WorldPalette p) {
  const Color white = Color(0xFFFFFFFF);
  return worstCaseContrast(
    white,
    p.headerTint,
    grounds: <Color>[p.skyTop, white],
  );
}

/// Label-Chip (Brief 3.1): `chip-world`-Text gegen die Chip-Fläche über
/// Schwarz, Weiß und Mandarine.
double worldChipContrast(WorldPalette p) => worstCaseContrast(
  p.chipText,
  p.chip,
  grounds: kWorstCaseGrounds.take(3).toList(),
);

/// Leiste (Brief 3.1/4.1): `nav-ink` gegen die Leiste (Ruhe oder Aktiv) über
/// dem Schleier (70 % `world-floor`) über Schwarz, Weiß und Mandarine.
double worldNavContrast(WorldPalette p, {required bool active, Color? ink}) {
  final Color glass = active ? p.navActive : p.navRest;
  double worst = double.infinity;
  for (final Color g in kWorstCaseGrounds.take(3)) {
    final Color veil = compose(
      p.floor.withValues(alpha: WorldGeometry.navVeilAlpha),
      g,
    );
    final double r = contrastRatio(ink ?? p.navInk, compose(glass, veil));
    if (r < worst) worst = r;
  }
  return worst;
}
