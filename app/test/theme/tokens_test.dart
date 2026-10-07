// UI-2 (U-Teil, „Token-Dump exakt“) und UI-67 (U-Teil, `scrim` 60/72 %):
// Die Tokens entsprechen exakt den Werten des Design-Briefs 3.1.
import 'dart:ui';

import 'package:curaone/theme/cura_colors.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hex ohne Alpha, deckend.
int _opaque(int rgb) => 0xFF000000 | rgb;

void main() {
  final CuraColors c = CuraColors.dark;

  test('UI-2: Grund, Haupttext und Akzent', () {
    expect(c.bg.toARGB32(), _opaque(0x0E131A));
    expect(c.text1.toARGB32(), _opaque(0xF2F0EB));
    expect(c.accent.toARGB32(), _opaque(0xD9622B));
  });

  test('Token-Dump: alle deckenden Farben aus Brief 3.1', () {
    final Map<String, (Color, int)> expected = <String, (Color, int)>{
      'surface-opaque': (c.surfaceOpaque, 0x1B2129),
      'text-2': (c.text2, 0xA9B0BC),
      'text-3': (c.text3, 0x9AA2AF),
      'accent-hi': (c.accentHi, 0xE8794A),
      'accent-pressed': (c.accentPressed, 0xDD7240),
      'on-accent': (c.onAccent, 0x0E131A),
      'focus-ring': (c.focusRing, 0xF2F0EB),
      'cat-physio': (c.catPhysio, 0x5B9DFF),
      'cat-arzt': (c.catArzt, 0xA98BFF),
      'cat-uebung': (c.catUebung, 0x3DDC97),
      'cat-frist': (c.catFrist, 0xFF5C70),
      'tri-gruen': (c.triGruen, 0x3DDC97),
      'tri-gelb': (c.triGelb, 0xF7E04A),
      'tri-orange': (c.triOrange, 0xFFA62B),
      'tri-rot': (c.triRot, 0xFF5C70),
      'status-error': (c.statusError, 0xFF5C70),
      'streak-freeze': (c.streakFreeze, 0x8FBBFF),
      'glow-ember': (c.glowEmber, 0xFF6A3D),
      'manny-body': (c.mannyBody, 0x34425F),
      'manny-belly': (c.mannyBelly, 0xF2F0EB),
    };
    for (final MapEntry<String, (Color, int)> e in expected.entries) {
      expect(e.value.$1.toARGB32(), _opaque(e.value.$2), reason: e.key);
    }
    // `status-error` ist gleich `tri-rot` und `cat-frist` (Brief 3.1).
    expect(c.statusError, c.triRot);
    expect(c.catFrist, c.triRot);
  });

  test('Token-Dump: Alpha-Tokens aus Brief 3.1', () {
    void alphaOf(String name, Color color, double alpha, int rgb) {
      expect(color.a, closeTo(alpha, 1e-9), reason: '$name alpha');
      expect(
        color.withValues(alpha: 1).toARGB32(),
        _opaque(rgb),
        reason: '$name rgb',
      );
    }

    alphaOf('surface-glass-top', c.surfaceGlassTop, 0.085, 0xFFFFFF);
    alphaOf('surface-glass-bottom', c.surfaceGlassBottom, 0.04, 0xFFFFFF);
    alphaOf('surface-float', c.surfaceFloat, 0.82, 0x18202A);
    alphaOf('border-hair', c.borderHair, 0.14, 0xFFFFFF);
    alphaOf('border-control', c.borderControl, 0.40, 0xFFFFFF);
    alphaOf('border-control-hc', c.borderControlHc, 0.45, 0xFFFFFF);
    alphaOf('accent-soft', c.accentSoft, 0.16, 0xD9622B);
    alphaOf('manny-outline', c.mannyOutline, 0.35, 0xFFFFFF);
  });

  test('UI-67: scrim ist Schwarz 60 %, bei hohem Kontrast 72 %', () {
    final CuraColors hc = CuraColors.darkHighContrast;
    expect(c.scrim.a, closeTo(0.60, 1e-9));
    expect(hc.scrim.a, closeTo(0.72, 1e-9));
    expect(c.scrim.withValues(alpha: 1).toARGB32(), _opaque(0x000000));
    expect(hc.scrim.withValues(alpha: 1).toARGB32(), _opaque(0x000000));
  });

  test('Hoher Kontrast: opake Flächen, Ränder -hc, kein Blur/Glow/Schein', () {
    final CuraColors hc = CuraColors.darkHighContrast;
    expect(hc.highContrast, isTrue);
    expect(hc.cardFillTop.toARGB32(), _opaque(0x1B2129));
    expect(hc.cardFillBottom.toARGB32(), _opaque(0x1B2129));
    expect(hc.floatFill.toARGB32(), _opaque(0x1B2129));
    expect(hc.cardBorder, c.borderControlHc);
    expect(hc.controlBorder, c.borderControlHc);
    expect(hc.blurEnabled, isFalse);
    expect(hc.glowEnabled, isFalse);
    expect(hc.shadowsEnabled, isFalse);
    // Normalfall: Glas, Blur, Glow und Schein an.
    expect(c.highContrast, isFalse);
    expect(c.blurEnabled && c.glowEnabled && c.shadowsEnabled, isTrue);
    expect(c.cardBorder, c.borderHair);
    expect(c.controlBorder, c.borderControl);
    expect(c.floatFill, c.surfaceFloat);
    // Sonstige Tokens bleiben gleich (nur Rollen ändern sich).
    expect(hc.accent, c.accent);
    expect(hc.text1, c.text1);
  });

  test('ThemeExtension: copyWith und lerp', () {
    final CuraColors changed = c.copyWith(accent: const Color(0xFF123456));
    expect(changed.accent.toARGB32(), _opaque(0x123456));
    expect(changed.bg, c.bg);
    expect(c.lerp(null, 0.5), same(c));
    expect(c.lerp(CuraColors.darkHighContrast, 0.2), same(c));
    expect(
      c.lerp(CuraColors.darkHighContrast, 0.8),
      CuraColors.darkHighContrast,
    );
  });

  test('Rollenregel: Status-Tokens sind nicht der Akzent (Brief 4)', () {
    final Set<int> status = <int>{
      c.statusError.toARGB32(),
      c.catFrist.toARGB32(),
      c.triRot.toARGB32(),
      c.triOrange.toARGB32(),
      c.triGelb.toARGB32(),
      c.triGruen.toARGB32(),
    };
    expect(status.contains(c.accent.toARGB32()), isFalse);
    expect(status.contains(c.accentHi.toARGB32()), isFalse);
  });
}
