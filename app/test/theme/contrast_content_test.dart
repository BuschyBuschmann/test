// V2-4: Kontraste der Inhaltsflächen (Design-Brief v2, 3.2) für Hell und
// Dunkel auf der Karte (92 %) im Worst Case über Schwarz, Weiß, Mandarine und
// Grau darunter: `ink`/`text`, `accent-text`, `success-text`, `error-text`,
// Kategorie-Töne ≥ 4,5:1; Bedienränder ≥ 3:1; bei Hohem Kontrast/Transparenz
// reduzieren Ränder ≥ 4,3:1. Schlägt unter den Schwellen fehl.
import 'dart:ui';

import 'package:curaone/theme/contrast.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ein Paar: Name, Vordergrund, Fläche (mit Alpha), Mindestkontrast und
/// optionaler Wert aus dem Brief.
class _Pair {
  const _Pair(this.name, this.fg, this.layer, this.min, [this.brief]);

  final String name;
  final Color fg;
  final Color layer;
  final double min;
  final double? brief;

  double get ratio => worstCaseContrast(fg, layer);
}

List<_Pair> _textPairs(CuraColors c) {
  final bool dark = c.isDark;
  return <_Pair>[
    _Pair('text-1', c.text1, c.card, 4.5, dark ? 11.5 : 14.3),
    _Pair('text-2', c.text2, c.card, 4.5, dark ? 7.7 : 6.6),
    _Pair('accent-text', c.accentText, c.card, 4.5, dark ? 6.3 : 5.2),
    _Pair('success-text', c.successText, c.card, 4.5, dark ? 7.1 : 5.2),
    _Pair('error-text', c.statusError, c.card, 4.5, dark ? 5.8 : 5.5),
    _Pair('cat-physio', c.catPhysio, c.card, 4.5, dark ? 6.5 : 5.1),
    _Pair('cat-arzt', c.catArzt, c.card, 4.5, dark ? 6.2 : 5.2),
    _Pair('cat-uebung', c.catUebung, c.card, 4.5),
    _Pair('cat-frist', c.catFrist, c.card, 4.5),
  ];
}

void main() {
  for (final CuraColors c in <CuraColors>[CuraColors.light, CuraColors.dark]) {
    final String theme = c.isDark ? 'Dunkel' : 'Hell';
    group('Karte 92 % ($theme)', () {
      test('Text- und Kategorie-Töne erreichen 4,5:1 im Worst Case (V2-4)', () {
        for (final _Pair p in _textPairs(c)) {
          expect(
            p.ratio,
            greaterThanOrEqualTo(p.min),
            reason: '${p.name}: ${p.ratio.toStringAsFixed(2)}',
          );
        }
      });

      test(
        'gemessene Werte entsprechen dem Brief (±0,1; Quelle rundet auf 8 Bit)',
        () {
          for (final _Pair p in _textPairs(c).where((p) => p.brief != null)) {
            expect(
              p.ratio,
              closeTo(p.brief!, 0.1),
              reason: '${p.name}: ${p.ratio.toStringAsFixed(2)}',
            );
          }
        },
      );

      test('Bedienrand border-control ≥ 3:1 im Worst Case', () {
        double r = double.infinity;
        for (final Color ground in kWorstCaseGrounds) {
          final Color layer = compose(c.card, ground);
          final double v = contrastRatio(
            compose(c.borderControl, layer),
            layer,
          );
          if (v < r) r = v;
        }
        expect(r, greaterThanOrEqualTo(3.0));
        if (!c.isDark) expect(r, closeTo(3.6, 0.1)); // Brief: 3,6:1
      });

      test('Fokusring und Gold-Symbol ≥ 3:1', () {
        expect(worstCaseContrast(c.focusRing, c.card), greaterThanOrEqualTo(3));
        expect(
          contrastRatio(c.onGold, c.gold),
          greaterThanOrEqualTo(3),
          reason: 'Symbole auf Gold',
        );
      });

      test(
        'Text auf Chips ≥ 4,5:1 (chip-success, chip-warn, chip-neutral)',
        () {
          expect(
            contrastRatio(c.chipSuccessText, c.chipSuccessFill),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contrastRatio(c.chipWarnText, c.chipWarnFill),
            greaterThanOrEqualTo(4.5),
          );
          // chip-neutral liegt auf der Karte; Text ist text-1.
          expect(
            worstCaseContrast(
              c.text1,
              compose(
                c.chipNeutralFill,
                compose(c.card, const Color(0xFF808080)),
              ),
            ),
            greaterThanOrEqualTo(4.5),
          );
          if (!c.isDark) {
            expect(
              contrastRatio(c.chipSuccessText, c.chipSuccessFill),
              closeTo(7.8, 0.06),
            );
            expect(
              contrastRatio(c.chipWarnText, c.chipWarnFill),
              closeTo(8.7, 0.06),
            );
          }
        },
      );

      test('Text auf opaken Flächen (Sheet, Dialog, Feld) ≥ 4,5:1', () {
        for (final Color fg in <Color>[
          c.text1,
          c.text2,
          c.accentText,
          c.successText,
          c.statusError,
          c.catPhysio,
          c.catArzt,
        ]) {
          expect(contrastRatio(fg, c.surfaceOpaque), greaterThanOrEqualTo(4.5));
        }
      });
    });

    group('Hoher Kontrast/Transparenz reduzieren ($theme)', () {
      final CuraColors hc = c.isDark
          ? CuraColors.darkHighContrast
          : CuraColors.lightHighContrast;

      test('Ränder ≥ 4,3:1 auf der opaken Karte', () {
        expect(
          contrastOver(hc.controlBorder, hc.cardFillTop),
          greaterThanOrEqualTo(4.3),
        );
        expect(
          contrastOver(hc.cardBorder, hc.cardFillTop),
          greaterThanOrEqualTo(4.3),
        );
        expect(
          contrastOver(hc.borderControlHc, hc.surfaceOpaque),
          greaterThanOrEqualTo(4.3),
        );
      });

      test('Text auf der opaken Karte ≥ 4,5:1', () {
        for (final Color fg in <Color>[hc.text1, hc.text2, hc.accentText]) {
          expect(contrastRatio(fg, hc.cardFillTop), greaterThanOrEqualTo(4.5));
        }
      });
    });
  }

  group('Akzent', () {
    final CuraColors c = CuraColors.light;

    test('on-accent auf Mandarine 6,55:1, auf #FFA063 8,48:1 (Brief)', () {
      expect(contrastRatio(c.onAccent, c.accent), closeTo(6.55, 0.02));
      expect(contrastRatio(c.onAccent, c.accentTop), closeTo(8.48, 0.02));
    });

    test('on-accent auf Pressed ≥ 4,5:1, Primärbutton ≥ 6,5:1 (V2-31)', () {
      expect(
        contrastRatio(c.onAccent, c.accentPressed),
        greaterThanOrEqualTo(4.5),
      );
      expect(contrastRatio(c.onAccent, c.accent), greaterThanOrEqualTo(6.5));
    });

    test('Mandarine ist als Text unzulässig (unter 4,5:1 auf der Karte)', () {
      for (final CuraColors t in <CuraColors>[CuraColors.light]) {
        expect(worstCaseContrast(t.accent, t.card), lessThan(4.5));
      }
    });
  });

  test('Die Prüfung schlägt an: Karte mit nur 80 % Deckung fällt (Hell)', () {
    final CuraColors c = CuraColors.light;
    final Color card80 = c.surfaceOpaque.withValues(alpha: 0.80);
    for (final Color fg in <Color>[
      c.accentText,
      c.successText,
      c.statusError,
      c.catPhysio,
      c.catArzt,
    ]) {
      expect(worstCaseContrast(fg, card80), lessThan(4.5));
    }
  });
}
