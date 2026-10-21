// V2-4-Vorbedingung („Token-Dump exakt“): Die Tokens der Inhaltsflächen
// entsprechen den Werten aus Design-Brief v2, 3.2 (Hell und Dunkel), dazu
// Hoher Kontrast/Transparenz reduzieren (3.5) und Scrim.
import 'dart:ui';

import 'package:curaone/theme/cura_colors.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hex ohne Alpha, deckend.
int _opaque(int rgb) => 0xFF000000 | rgb;

void alphaOf(String name, Color color, double alpha, int rgb) {
  expect(color.a, closeTo(alpha, 1e-9), reason: '$name alpha');
  expect(
    color.withValues(alpha: 1).toARGB32(),
    _opaque(rgb),
    reason: '$name rgb',
  );
}

void main() {
  final CuraColors light = CuraColors.light;
  final CuraColors dark = CuraColors.dark;

  test('Brief 3.2: Text, Akzent, Orange als Text, Erfolg, Fehler (Hell)', () {
    expect(light.text1.toARGB32(), _opaque(0x211B16));
    expect(light.text2.toARGB32(), _opaque(0x5A5048));
    expect(light.accent.toARGB32(), _opaque(0xFF7A2E));
    expect(light.accentTop.toARGB32(), _opaque(0xFFA063));
    expect(light.onAccent.toARGB32(), _opaque(0x211B16));
    expect(light.accentText.toARGB32(), _opaque(0xA83F0B));
    expect(light.successText.toARGB32(), _opaque(0x1B6E47));
    expect(light.statusError.toARGB32(), _opaque(0xB3261E));
    expect(light.catPhysio.toARGB32(), _opaque(0x2A62B0));
    expect(light.catArzt.toARGB32(), _opaque(0x6B49C9));
    expect(light.catUebung.toARGB32(), _opaque(0x1B6E47));
    expect(light.catFrist.toARGB32(), _opaque(0xB3261E));
    expect(light.gold.toARGB32(), _opaque(0xFFC23D));
    expect(light.onGold.toARGB32(), _opaque(0x8A3A0C));
    expect(light.chipSuccessFill.toARGB32(), _opaque(0xDDF3E6));
    expect(light.chipSuccessText.toARGB32(), _opaque(0x14532D));
    expect(light.chipWarnFill.toARGB32(), _opaque(0xFFE3DD));
    expect(light.chipWarnText.toARGB32(), _opaque(0x7A1A12));
  });

  test('Brief 3.2: Text, Akzent, Orange als Text, Erfolg, Fehler (Dunkel)', () {
    expect(dark.text1.toARGB32(), _opaque(0xF5EFE8));
    expect(dark.text2.toARGB32(), _opaque(0xCFC5BB));
    expect(dark.accent.toARGB32(), _opaque(0xFF7A2E));
    expect(dark.accentTop.toARGB32(), _opaque(0xFFA063));
    expect(dark.onAccent.toARGB32(), _opaque(0x211B16));
    expect(dark.accentText.toARGB32(), _opaque(0xFF9A62));
    expect(dark.successText.toARGB32(), _opaque(0x5FD39A));
    expect(dark.statusError.toARGB32(), _opaque(0xFF8A80));
    expect(dark.catPhysio.toARGB32(), _opaque(0x8DB8FF));
    expect(dark.catArzt.toARGB32(), _opaque(0xB9A4FF));
    expect(dark.catUebung.toARGB32(), _opaque(0x5FD39A));
    expect(dark.catFrist.toARGB32(), _opaque(0xFF8A80));
    expect(dark.gold, light.gold);
    expect(dark.onGold, light.onGold);
  });

  test('Brief 3.2: Karte 92 %, Rand, Chip-Neutral, Fokus', () {
    alphaOf('card hell', light.card, 0.92, 0xFFFFFF);
    alphaOf('card dunkel', dark.card, 0.92, 0x241D18);
    expect(light.surfaceOpaque.toARGB32(), _opaque(0xFFFFFF));
    expect(dark.surfaceOpaque.toARGB32(), _opaque(0x241D18));
    alphaOf('border-control hell', light.borderControl, 0.55, 0x211B16);
    alphaOf('border-control dunkel', dark.borderControl, 0.45, 0xF5EFE8);
    alphaOf('chip-neutral hell', light.chipNeutralFill, 0.07, 0x211B16);
    alphaOf('chip-neutral dunkel', dark.chipNeutralFill, 0.10, 0xFFFFFF);
    // Fokusring: ink-1/text-1 mit Außenrand in der Gegenfarbe.
    expect(light.focusRing, light.text1);
    expect(dark.focusRing, dark.text1);
    expect(light.focusRingOuter.toARGB32(), _opaque(0xFFFFFF));
    expect(dark.focusRingOuter.toARGB32(), _opaque(0x241D18));
    // Grund unter der Welt: world-floor.
    expect(light.bg.toARGB32(), _opaque(0xF7F2EB));
    expect(dark.bg.toARGB32(), _opaque(0x1C1620));
  });

  test('Orange ist nie Statusfarbe: Status-Töne sind nicht der Akzent', () {
    for (final CuraColors c in <CuraColors>[light, dark]) {
      final Set<int> status = <int>{
        c.statusError.toARGB32(),
        c.catFrist.toARGB32(),
        c.triRot.toARGB32(),
        c.successText.toARGB32(),
      };
      expect(status.contains(c.accent.toARGB32()), isFalse);
      expect(status.contains(c.accentText.toARGB32()), isFalse);
      expect(status.contains(c.accentTop.toARGB32()), isFalse);
    }
    // `status-error` ist gleich `cat-frist` (Brief 3.2).
    expect(light.statusError, light.catFrist);
    expect(dark.statusError, dark.catFrist);
  });

  test('Scrim: ink-1 45 %, bei hohem Kontrast 72 % (Annahme)', () {
    final CuraColors hc = CuraColors.lightHighContrast;
    alphaOf('scrim', light.scrim, 0.45, 0x211B16);
    alphaOf('scrim hc', hc.scrim, 0.72, 0x211B16);
    alphaOf('scrim dunkel', dark.scrim, 0.45, 0x211B16);
  });

  test('Hoher Kontrast/Transparenz reduzieren: opak, Rand, kein Blur', () {
    for (final (CuraColors n, CuraColors hc) in <(CuraColors, CuraColors)>[
      (light, CuraColors.lightHighContrast),
      (dark, CuraColors.darkHighContrast),
    ]) {
      expect(hc.highContrast, isTrue);
      expect(hc.cardFillTop, n.surfaceOpaque, reason: 'card 100 %');
      expect(hc.cardFillBottom, n.surfaceOpaque);
      expect(hc.floatFill, n.surfaceOpaque);
      expect(hc.cardBorder, n.borderControlHc);
      expect(hc.controlBorder, n.borderControlHc);
      expect(hc.blurEnabled, isFalse);
      expect(hc.worldDecorEnabled, isFalse);
      expect(hc.shadowsEnabled, isFalse);
      // Normalfall: Glas, Blur, Welt-Dekor und Schein an.
      expect(n.highContrast, isFalse);
      expect(n.blurEnabled && n.worldDecorEnabled && n.shadowsEnabled, isTrue);
      expect(n.cardBorder, n.borderHair);
      expect(n.controlBorder, n.borderControl);
      expect(n.cardFillTop, n.card);
      // Sonstige Tokens bleiben gleich (nur Rollen ändern sich).
      expect(hc.accent, n.accent);
      expect(hc.text1, n.text1);
    }
  });

  test('Akzentfüllung: Verlauf #FFA063 → #FF7A2E', () {
    final LinearGradient g = light.accentFill;
    expect(g.colors.first.toARGB32(), _opaque(0xFFA063));
    expect(g.colors.last.toARGB32(), _opaque(0xFF7A2E));
  });

  test('ThemeExtension: copyWith, lerp, variant', () {
    final CuraColors changed = light.copyWith(accent: const Color(0xFF123456));
    expect(changed.accent.toARGB32(), _opaque(0x123456));
    expect(changed.bg, light.bg);
    expect(light.lerp(null, 0.5), same(light));
    expect(light.lerp(CuraColors.darkHighContrast, 0.2), same(light));
    expect(
      light.lerp(CuraColors.darkHighContrast, 0.8),
      CuraColors.darkHighContrast,
    );
    expect(CuraColors.variant(Brightness.light), same(light));
    expect(CuraColors.variant(Brightness.dark), same(dark));
    expect(
      CuraColors.variant(Brightness.dark, highContrast: true),
      same(CuraColors.darkHighContrast),
    );
    expect(
      CuraColors.variant(Brightness.light, highContrast: true),
      same(CuraColors.lightHighContrast),
    );
  });
}
