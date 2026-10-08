// Streak S1–S24 (Plan 7.1). S25 steht in day_rollover_test.dart (und über den
// Controller in app_controller_test.dart), S18 dort ebenfalls mit Undo (hier
// der reine Zustandsvergleich).
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/streak.dart';
import 'package:flutter_test/flutter_test.dart';

const LocalDay t = LocalDay(2026, 10, 7);

/// Streak 5, letzter Trainingstag `t − gap`, noch nie ausgewertet.
StreakState s5(int gap, {int freezes = 2, LocalDay today = t}) => StreakState(
  count: 5,
  freezes: freezes,
  lastTrainingDay: today.addDays(-gap),
);

void expectActive(StreakState s, int count, int freezes) {
  final StreakView v = StreakEngine.view(s);
  expect(v.display, StreakDisplay.active);
  expect(v.count, count);
  expect(v.freezes, freezes);
}

void expectFrozen(StreakState s, int count, int freezes) {
  final StreakView v = StreakEngine.view(s);
  expect(v.display, StreakDisplay.frozen);
  expect(v.count, count);
  expect(v.freezes, freezes);
}

void expectReset(StreakState s, {int freezes = 0}) {
  final StreakView v = StreakEngine.view(s);
  expect(v.display, StreakDisplay.reset);
  expect(v.count, 0);
  expect(v.freezes, freezes);
}

void main() {
  test('S1 neu: 3 Tage ohne Training → 0, Freezes 2, reset', () {
    final StreakState s = StreakEngine.evaluate(const StreakState(), t);
    expectReset(s, freezes: 2);
    expect(s.resetNoticePending, isFalse);
    expectReset(StreakEngine.evaluate(s, t.addDays(3)), freezes: 2);
  });

  test('S2 L = T−1 → aktiv 5, Freezes 2', () {
    expectActive(StreakEngine.evaluate(s5(1), t), 5, 2);
  });

  test('S3 eintragen, nochmal eintragen → 6; zweites ändert nichts', () {
    final StreakState once = StreakEngine.logTraining(s5(1), t);
    expectActive(once, 6, 2);
    expect(StreakEngine.logTraining(once, t), once);
  });

  test('S4 L = T−2, Freezes 2 → eingefroren, 5, Freezes 1', () {
    expectFrozen(StreakEngine.evaluate(s5(2), t), 5, 1);
  });

  test('S5 L = T−2, Freezes 0 → eingefroren, 5, Freezes 0', () {
    expectFrozen(StreakEngine.evaluate(s5(2, freezes: 0), t), 5, 0);
  });

  test('S6 L = T−3, Freezes 0 → reset, Nachricht fällig', () {
    final StreakState s = StreakEngine.evaluate(s5(3, freezes: 0), t);
    expectReset(s);
    expect(s.resetNoticePending, isTrue);
  });

  test('S7 L = T−3, Freezes 2 → eingefroren, 5, Freezes 0', () {
    expectFrozen(StreakEngine.evaluate(s5(3), t), 5, 0);
  });

  test('S8 L = T−3, Freezes 1 → eingefroren, 5, Freezes 0', () {
    expectFrozen(StreakEngine.evaluate(s5(3, freezes: 1), t), 5, 0);
  });

  test('S9 L = T−4, Freezes 1 → reset, Freezes 0', () {
    final StreakState s = StreakEngine.evaluate(s5(4, freezes: 1), t);
    expectReset(s);
    expect(s.resetNoticePending, isTrue);
  });

  test('S10 L = T−4, Freezes 2 → eingefroren, 5, Freezes 0', () {
    expectFrozen(StreakEngine.evaluate(s5(4), t), 5, 0);
  });

  test('S11 Ergebnis von S4, eintragen → aktiv 6, Freezes 1', () {
    final StreakState frozen = StreakEngine.evaluate(s5(2), t);
    final StreakState s = StreakEngine.logTraining(frozen, t);
    expectActive(s, 6, 1);
    expect(s.coveredInGap, 0);
    expect(s.uncoveredInGap, 0);
    expect(s.lastTrainingDay, t);
  });

  test(
    'S12 zweimal am selben Tag auswerten → identisch, kein Doppelverbrauch',
    () {
      for (final int gap in <int>[1, 2, 3, 4, 7]) {
        final StreakState a = StreakEngine.evaluate(s5(gap), t);
        expect(StreakEngine.evaluate(a, t), a, reason: 'gap $gap');
      }
    },
  );

  test('S13 tageweise auswerten = einmal bei T (alle Lückenlängen)', () {
    for (final int freezes in <int>[0, 1, 2]) {
      for (int gap = 1; gap <= 9; gap++) {
        final StreakState once = StreakEngine.evaluate(
          s5(gap, freezes: freezes),
          t,
        );
        StreakState stepwise = s5(gap, freezes: freezes);
        for (int d = gap; d >= 0; d--) {
          stepwise = StreakEngine.evaluate(stepwise, t.addDays(-d));
        }
        expect(stepwise, once, reason: 'freezes $freezes gap $gap');
      }
    }
  });

  test('S14 Reset (count 0), eintragen → 1, aktiv', () {
    final StreakState reset = StreakEngine.evaluate(s5(5, freezes: 0), t);
    expectReset(reset);
    expectActive(StreakEngine.logTraining(reset, t), 1, 0);
  });

  test(
    'S15 Sommerzeitende: L = 2026-10-24, T = 2026-10-26 → 1 verpasster Tag',
    () {
      final StreakState s = StreakEngine.evaluate(
        const StreakState(count: 5, lastTrainingDay: LocalDay(2026, 10, 24)),
        const LocalDay(2026, 10, 26),
      );
      expect(s.coveredInGap + s.uncoveredInGap, 1);
      expectFrozen(s, 5, 1);
    },
  );

  test('S16 L = T+1 (Uhr zurückgestellt): auswerten/eintragen unverändert', () {
    final StreakState s = s5(-1);
    expect(StreakEngine.evaluate(s, t), s);
    expect(StreakEngine.logTraining(s, t), s);
  });

  test('S17 count 0, L = T−5 → keine Freezes verbraucht, kein eingefroren', () {
    final StreakState s = StreakEngine.evaluate(
      StreakState(lastTrainingDay: t.addDays(-5)),
      t,
    );
    expectReset(s, freezes: 2);
    expect(s.coveredInGap, 0);
    expect(s.resetNoticePending, isFalse);
  });

  test('S18 Zustand frozen: Schnappschuss vor Eintragen bleibt identisch', () {
    final StreakState frozen = StreakEngine.evaluate(s5(2), t);
    final StreakState snapshot = frozen;
    final StreakState after = StreakEngine.logTraining(frozen, t);
    expect(after, isNot(snapshot));
    expect(snapshot, StreakEngine.evaluate(s5(2), t));
    expectFrozen(snapshot, 5, 1);
  });

  test('S19 ohne vorheriges evaluate: eintragen wertet intern aus', () {
    final StreakState s = StreakEngine.logTraining(s5(2), t);
    expectActive(s, 6, 1);
  });

  test(
    'S20 Sommerzeitbeginn: L = 2026-03-28, T = 2026-03-30 → 1 verpasster Tag',
    () {
      final StreakState s = StreakEngine.evaluate(
        const StreakState(count: 5, lastTrainingDay: LocalDay(2026, 3, 28)),
        const LocalDay(2026, 3, 30),
      );
      expect(s.coveredInGap + s.uncoveredInGap, 1);
    },
  );

  test('S21 Schalttag: L = 2028-02-28, T = 2028-03-01 → 1 verpasster Tag', () {
    final StreakState s = StreakEngine.evaluate(
      const StreakState(count: 5, lastTrainingDay: LocalDay(2028, 2, 28)),
      const LocalDay(2028, 3, 1),
    );
    expect(s.coveredInGap + s.uncoveredInGap, 1);
  });

  test(
    'S22 Jahreswechsel: L = 2026-12-31, T = 2027-01-02 → 1 verpasster Tag',
    () {
      final StreakState s = StreakEngine.evaluate(
        const StreakState(count: 5, lastTrainingDay: LocalDay(2026, 12, 31)),
        const LocalDay(2027, 1, 2),
      );
      expect(s.coveredInGap + s.uncoveredInGap, 1);
    },
  );

  test('S23 L = T−7, Freezes 2: 2 gedeckt, Reset am 4. verpassten Tag', () {
    final StreakState s = StreakEngine.evaluate(s5(7), t);
    expectReset(s);
    expect(s.coveredInGap, 2);
    expect(s.uncoveredInGap, 2);
    expect(s.resetNoticePending, isTrue);
    // Folgetag: keine Änderung, keine zweite Nachricht.
    final StreakState next = StreakEngine.evaluate(s, t.addDays(1));
    expect(next.count, 0);
    expect(next.freezes, 0);
    expect(next.coveredInGap, 2);
    expect(next.uncoveredInGap, 2);
    expect(next.resetNoticePending, isTrue);
    // Nach Anzeige der Nachricht bleibt sie weg.
    final StreakState shown = next.copyWith(resetNoticePending: false);
    expect(
      StreakEngine.evaluate(shown, t.addDays(5)).resetNoticePending,
      isFalse,
    );
  });

  test(
    'S24 JSON-Roundtrip mit coveredInGap, uncoveredInGap, evaluatedThrough',
    () {
      final StreakState s = StreakState(
        count: 7,
        freezes: 1,
        lastTrainingDay: t.addDays(-3),
        evaluatedThrough: t.addDays(-1),
        coveredInGap: 1,
        uncoveredInGap: 1,
        resetNoticePending: true,
      );
      expect(StreakState.fromJson(s.toJson()), s);
      expect(
        StreakState.fromJson(const StreakState().toJson()),
        const StreakState(),
      );
    },
  );

  test('Uhr zurück nach Auswertung: kein Verbrauch, Eintragen zählt nicht', () {
    final StreakState evaluated = StreakEngine.evaluate(s5(2), t);
    // Uhr einen Tag zurück (auf den ausgewerteten, verpassten Tag).
    expect(StreakEngine.evaluate(evaluated, t.addDays(-1)), evaluated);
    expect(StreakEngine.logTraining(evaluated, t.addDays(-1)), evaluated);
    expect(StreakEngine.logTraining(evaluated, t.addDays(-3)), evaluated);
  });

  test('Nach Reset verbrauchen weitere Auswertungen nichts (Regel 7)', () {
    final StreakState reset = StreakEngine.evaluate(s5(5, freezes: 0), t);
    final StreakState later = StreakEngine.evaluate(reset, t.addDays(10));
    expect(later.freezes, 0);
    expect(later.count, 0);
    expect(later.uncoveredInGap, reset.uncoveredInGap);
  });
}
