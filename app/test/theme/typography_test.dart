// UI-5 (U-Teil): kein Stil unter 13 sp oder Gewicht 400; Tabelle aus
// Brief 3.3, Variationen und optische Größe (Plan 8.1).

import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_typography.dart';
import 'package:curaone/theme/tokens.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

double _axis(TextStyle s, String tag) =>
    s.fontVariations!.firstWhere((FontVariation v) => v.axis == tag).value;

void main() {
  final CuraTypography t = CuraTypography.light;

  test('UI-5: alle Stile mindestens 13 sp und Gewicht 400', () {
    expect(t.all.length, 19);
    for (final MapEntry<String, TextStyle> e in t.all.entries) {
      expect(e.value.fontSize, greaterThanOrEqualTo(13), reason: e.key);
      expect(
        e.value.fontWeight!.value,
        greaterThanOrEqualTo(400),
        reason: e.key,
      );
    }
    // Sprechblase mindestens 14 sp (Brief 5.6).
    expect(t.bubble.fontSize, 14.5);
  });

  test('Brief v2 3.3: Familie, Größe/Zeilenhöhe, Gewicht je Stil', () {
    // name: (Familie, Größe, Zeilenhöhe, Gewicht)
    final Map<String, (String, double, double, int)> expected =
        <String, (String, double, double, int)>{
          'display': ('BricolageGrotesque', 36, 38, 800),
          'titleHeader': ('BricolageGrotesque', 30, 32, 800),
          'title': ('BricolageGrotesque', 24, 28, 800),
          'heading': ('BricolageGrotesque', 20, 23, 800),
          'counter': ('BricolageGrotesque', 52, 52, 800),
          'counterUnit': ('BricolageGrotesque', 30, 30, 800),
          'numeral': ('BricolageGrotesque', 28, 30, 800),
          'numeralSmall': ('BricolageGrotesque', 18, 24, 800),
          'numeralLarge': ('BricolageGrotesque', 24, 28, 800),
          'button': ('BricolageGrotesque', 18, 24, 800),
          'body': ('DMSans', 16, 24, 400),
          'bodyStrong': ('DMSans', 16, 24, 700),
          'secondary': ('DMSans', 14, 20, 500),
          'label': ('DMSans', 13, 16, 700),
          'caption': ('DMSans', 13, 16, 600),
          'chip': ('DMSans', 13, 16, 700),
          'bubble': ('DMSans', 14.5, 20, 400),
          'segment': ('DMSans', 16, 24, 400),
          'segmentSelected': ('DMSans', 16, 24, 700),
        };
    expect(t.all.keys.toSet(), expected.keys.toSet());
    for (final MapEntry<String, TextStyle> e in t.all.entries) {
      final (String family, double size, double line, int weight) =
          expected[e.key]!;
      expect(e.value.fontFamily, family, reason: e.key);
      expect(e.value.fontSize, size, reason: e.key);
      expect(
        e.value.height! * e.value.fontSize!,
        closeTo(line, 1e-9),
        reason: e.key,
      );
      expect(e.value.fontWeight!.value, weight, reason: e.key);
    }
  });

  test('Titel und Zahlen: Bricolage mit Gewicht 700–800 (Brief 3.3)', () {
    for (final String name in <String>[
      'display',
      'titleHeader',
      'title',
      'heading',
      'counter',
      'numeral',
      'numeralSmall',
      'button',
    ]) {
      final TextStyle s = t.all[name]!;
      expect(s.fontFamily, 'BricolageGrotesque', reason: name);
      expect(s.fontWeight!.value, greaterThanOrEqualTo(700), reason: name);
    }
  });

  test('Gewicht per fontWeight und FontVariation, opsz = Größe (begrenzt)', () {
    for (final MapEntry<String, TextStyle> e in t.all.entries) {
      final TextStyle s = e.value;
      expect(_axis(s, 'wght'), s.fontWeight!.value.toDouble(), reason: e.key);
      final bool bricolage = s.fontFamily == 'BricolageGrotesque';
      final double min = bricolage ? 12 : 9;
      final double max = bricolage ? 96 : 40;
      expect(_axis(s, 'opsz'), s.fontSize!.clamp(min, max), reason: e.key);
      expect(
        s.fontVariations!.any((FontVariation v) => v.axis == 'wdth'),
        bricolage,
        reason: e.key,
      );
      if (bricolage) expect(_axis(s, 'wdth'), 100, reason: e.key);
    }
  });

  test('opticalSize begrenzt auf die Achse', () {
    expect(opticalSizeFor(const TypeSpec('DMSans', 80, 90, 400)), 40);
    expect(
      opticalSizeFor(const TypeSpec('BricolageGrotesque', 10, 12, 500)),
      12,
    );
    expect(opticalSizeFor(const TypeSpec('DMSans', 16, 24, 400)), 16);
  });

  test('label: Laufweite 0,06 em; Segmentfarben nach A-23', () {
    expect(t.label.letterSpacing, closeTo(0.06 * 13, 1e-9));
    expect(t.segment.color, CuraColors.light.text2);
    expect(t.segmentSelected.color, CuraColors.light.text1);
    expect(CuraTypography.dark.segment.color, CuraColors.dark.text2);
    // übrige Stile tragen keine Farbe
    expect(t.body.color, isNull);
  });

  test('ThemeExtension: copyWith und lerp', () {
    final CuraTypography changed = t.copyWith(
      body: const TextStyle(fontSize: 20),
    );
    expect(changed.body.fontSize, 20);
    expect(changed.title, t.title);
    expect(t.lerp(null, 0.5), same(t));
    expect(t.lerp(changed, 0).body.fontSize, 16);
    expect(t.lerp(changed, 1).body.fontSize, 20);
  });
}
