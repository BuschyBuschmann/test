// V2-3: Kontraste der Welt (Design-Brief v2, 3.1) aus den Tokens berechnet:
// Kopf-Karte (weißer Text), Label-Chip, Leiste in Ruhe und Aktiv je Welt gegen
// Schwarz, Weiß und Mandarine; schlägt unter 4,5:1 fehl. Dazu die Werte der
// Brief-Tabelle (Quelle der Rechnung: `mockups/v2-src/gen3.py`) und die
// Zwischenzustände der Überblendung.
import 'dart:ui';

import 'package:curaone/logic/world_time.dart';
import 'package:curaone/theme/contrast.dart';
import 'package:curaone/theme/world_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Brief 3.1, Tabelle „Kontrast je Welt“: Kopf-Karte, Label-Chip, Leiste Ruhe
/// (Label), Leiste Aktiv (Label).
const Map<WorldPhase, List<double>> _table = <WorldPhase, List<double>>{
  WorldPhase.morning: <double>[5.2, 8.6, 10.1, 14.4],
  WorldPhase.midday: <double>[4.6, 9.1, 10.1, 14.4],
  WorldPhase.evening: <double>[5.3, 8.6, 10.1, 14.4],
  WorldPhase.night: <double>[4.8, 7.0, 9.5, 13.8],
};

void main() {
  for (final WorldPhase phase in WorldPhase.values) {
    group('Welt ${phase.name}', () {
      final WorldPalette p = WorldPalette.of(phase);

      test('Kopf-Karte, Chip und Leiste erreichen 4,5:1 (V2-3)', () {
        expect(worldHeaderContrast(p), greaterThanOrEqualTo(4.5));
        expect(worldChipContrast(p), greaterThanOrEqualTo(4.5));
        expect(worldNavContrast(p, active: false), greaterThanOrEqualTo(4.5));
        expect(worldNavContrast(p, active: true), greaterThanOrEqualTo(4.5));
      });

      test('Werte entsprechen der Tabelle im Brief (±0,1; Quelle rundet auf 8 Bit)', () {
        final List<double> t = _table[phase]!;
        expect(worldHeaderContrast(p), closeTo(t[0], 0.1));
        expect(worldChipContrast(p), closeTo(t[1], 0.1));
        expect(worldNavContrast(p, active: false), closeTo(t[2], 0.1));
        expect(worldNavContrast(p, active: true), closeTo(t[3], 0.1));
      });
    });
  }

  test('Überblendung: 4,5:1 auch in jedem Zwischenzustand (alle Grenzen)', () {
    for (int i = 0; i < kWorldPhaseOrder.length; i++) {
      final WorldPhase from = kWorldPhaseOrder[i];
      final WorldPhase to = kWorldPhaseOrder[(i + 1) % kWorldPhaseOrder.length];
      for (int step = 0; step <= 20; step++) {
        final double t = step / 20;
        final WorldPalette p = WorldPalette.forMix(WorldMix(from, to, t));
        final String where = '${from.name}→${to.name} t=$t';
        expect(
          worldHeaderContrast(p),
          greaterThanOrEqualTo(4.5),
          reason: 'Kopf-Karte $where',
        );
        expect(
          worldChipContrast(p),
          greaterThanOrEqualTo(4.5),
          reason: 'Chip $where',
        );
        expect(
          worldNavContrast(p, active: false),
          greaterThanOrEqualTo(4.5),
          reason: 'Leiste Ruhe $where',
        );
        expect(
          worldNavContrast(p, active: true),
          greaterThanOrEqualTo(4.5),
          reason: 'Leiste Aktiv $where',
        );
      }
    }
  });

  test('A1: Chip und Leiste springen in der Fenstermitte; Chip, Leiste und '
      'Kopf-Karte halten 4,5:1 bei t = 0,49 und 0,51 (Abend→Nacht, '
      'Nacht→Morgen)', () {
    for (final (WorldPhase, WorldPhase) pair in <(WorldPhase, WorldPhase)>[
      (WorldPhase.evening, WorldPhase.night),
      (WorldPhase.night, WorldPhase.morning),
    ]) {
      for (final double t in <double>[0.49, 0.51]) {
        final WorldPalette p = WorldPalette.forMix(
          WorldMix(pair.$1, pair.$2, t),
        );
        final String where = '${pair.$1.name}→${pair.$2.name} t=$t';
        expect(
          worldChipContrast(p),
          greaterThanOrEqualTo(4.5),
          reason: 'Chip $where',
        );
        expect(
          worldNavContrast(p, active: false),
          greaterThanOrEqualTo(4.5),
          reason: 'Leiste Ruhe $where',
        );
        expect(
          worldNavContrast(p, active: true),
          greaterThanOrEqualTo(4.5),
          reason: 'Leiste Aktiv $where',
        );
        expect(
          worldHeaderContrast(p),
          greaterThanOrEqualTo(4.5),
          reason: 'Kopf-Karte (Weiß) $where',
        );
      }
    }
  });

  test('A1: Kopf-Karte (Weiß) fällt in keiner Mischung unter 4,5:1 '
      '(Schritt 0,01, alle Grenzen)', () {
    double worst = double.infinity;
    String at = '';
    for (int i = 0; i < kWorldPhaseOrder.length; i++) {
      final WorldPhase from = kWorldPhaseOrder[i];
      final WorldPhase to = kWorldPhaseOrder[(i + 1) % kWorldPhaseOrder.length];
      for (int step = 0; step <= 100; step++) {
        final double t = step / 100;
        final double r = worldHeaderContrast(
          WorldPalette.forMix(WorldMix(from, to, t)),
        );
        if (r < worst) {
          worst = r;
          at = '${from.name}→${to.name} t=$t';
        }
      }
    }
    expect(worst, greaterThanOrEqualTo(4.5), reason: 'Minimum $worst bei $at');
  });

  test('Die Prüfung schlägt an: zu schwache Kopf-Karte fällt unter 4,5', () {
    const Color white = Color(0xFFFFFFFF);
    final Color weakTint = const Color(0xFF23303A).withValues(alpha: 0.30);
    expect(
      worstCaseContrast(white, weakTint, grounds: const <Color>[white]),
      lessThan(4.5),
    );
    // Dieselbe Tönung mit den Tokenwerten (66 %) besteht.
    expect(
      worstCaseContrast(
        white,
        WorldPalette.midday.headerTint,
        grounds: <Color>[WorldPalette.midday.skyTop, white],
      ),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('Kontrastfunktionen: Grenzwerte', () {
    const Color black = Color(0xFF000000);
    const Color white = Color(0xFFFFFFFF);
    expect(contrastRatio(white, black), closeTo(21, 1e-9));
    expect(contrastRatio(white, white), closeTo(1, 1e-9));
    expect(contrastRatio(black, white), closeTo(21, 1e-9));
  });
}
