// UI-7 (U-Teil): Alpha-Funktion und Geometrie des Glows (Brief 3.2, E-1).
import 'package:curaone/theme/glow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const GlowGeometry g = GlowGeometry(390, 844);

  test('Geometrie: Mitten, Radien und Spitzen (0,24 / 0,14)', () {
    expect(g.topLeft.centerX, -30);
    expect(g.topLeft.centerY, 40);
    expect(g.topLeft.radius, 260);
    expect(g.topLeft.peak, 0.24);
    expect(g.bottomRight.centerX, 390 + 50);
    expect(g.bottomRight.centerY, 844 - 24);
    expect(g.bottomRight.radius, 300);
    expect(g.bottomRight.peak, 0.14);
  });

  test('Alpha-Funktion: Spitze in der Mitte, linear, null ab 70 % Radius', () {
    final GlowSpot s = g.topLeft;
    expect(s.alphaAtDistance(0), closeTo(0.24, 1e-12));
    expect(s.zeroDistance, closeTo(182, 1e-12));
    expect(s.alphaAtDistance(91), closeTo(0.12, 1e-12));
    expect(s.alphaAtDistance(182), 0);
    expect(s.alphaAtDistance(500), 0);
    // monoton fallend
    double last = 1;
    for (double d = 0; d <= 200; d += 5) {
      final double a = s.alphaAtDistance(d);
      expect(a, lessThanOrEqualTo(last));
      last = a;
    }
    // Unten rechts: Spitze 0,14, Null bei 210.
    expect(g.bottomRight.alphaAtDistance(0), closeTo(0.14, 1e-12));
    expect(g.bottomRight.zeroDistance, closeTo(210, 1e-12));
  });

  test('Alter Abstandswert 70 dp liegt bei höchstens 0,15 (Brief 3.2)', () {
    expect(g.topLeft.alphaAtDistance(70), lessThanOrEqualTo(0.15));
    expect(g.topLeft.alphaAtDistance(91), lessThanOrEqualTo(0.12));
  });

  test('Komposition beider Verläufe: 1 − (1 − a1)(1 − a2)', () {
    expect(composeAlpha(<double>[0.24, 0.14]), closeTo(1 - 0.76 * 0.86, 1e-12));
    expect(composeAlpha(<double>[]), 0);
    expect(composeAlpha(<double>[0, 0]), 0);
    // Gesamt-Alpha an einem Punkt nahe der Mitte oben links ≈ Spitze.
    expect(g.alphaAt(-30, 40), closeTo(0.24, 1e-3));
    // In der Bildschirmmitte praktisch kein Glow.
    expect(g.alphaAt(195, 422), 0);
  });

  test('Rechteck: nächstgelegener Punkt je Fleck (Errata E-1, Punkt 5)', () {
    // Rechteck enthält die Mitte: volle Spitze.
    expect(g.topLeft.alphaForRect(-50, 20, 50, 60), closeTo(0.24, 1e-12));
    // Rechteck rechts davon: Abstand 70 zur nächsten Kante.
    expect(
      g.topLeft.alphaForRect(40, 30, 200, 50),
      closeTo(g.topLeft.alphaAtDistance(70), 1e-12),
    );
    // Rechteck weit weg: null.
    expect(g.alphaForRect(100, 300, 290, 600), 0);
    // Vom Rechteck aus gesehen ist der Wert nie kleiner als in dessen Mitte.
    expect(
      g.alphaForRect(0, 0, 100, 100),
      greaterThanOrEqualTo(g.alphaAt(50, 50)),
    );
  });

  test('Schwellen nach Untergrund: 24 / 16 / 12 %', () {
    expect(maxGlowAlphaFor(GlowBackdrop.bg), 0.24);
    expect(maxGlowAlphaFor(GlowBackdrop.glass), 0.16);
    expect(maxGlowAlphaFor(GlowBackdrop.coloredOnGlass), 0.12);
  });
}
