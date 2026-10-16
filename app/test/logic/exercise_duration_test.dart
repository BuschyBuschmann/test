// Dauer-Schätzung (Plan 8.4, N-7 nach O-17): alle Zweige, Pause des Physios
// bzw. 60 s, Dauer je Satz in Sekunden.
import 'package:curaone/logic/exercise_duration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dauer je Satz (duration_sec)', () {
    test('1 Satz, keine Pause: ⌈Dauer / 60⌉', () {
      expect(estimateMinutes(sets: 1, durationSec: 60), 1);
      expect(estimateMinutes(sets: 1, durationSec: 61), 2);
      expect(estimateMinutes(durationSec: 30), 1); // S = max(sets, 1)
    });

    test('mehrere Sätze mit Standardpause 60 s', () {
      // 3 × 30 s + 2 × 60 s = 210 s → 4 Min.
      expect(estimateMinutes(sets: 3, durationSec: 30), 4);
    });

    test('Pause des Physios', () {
      // 3 × 30 s + 2 × 30 s = 150 s → 3 Min.
      expect(estimateMinutes(sets: 3, durationSec: 30, pauseSec: 30), 3);
      // 3 × 30 s + 2 × 120 s = 330 s → 6 Min.
      expect(estimateMinutes(sets: 3, durationSec: 30, pauseSec: 120), 6);
    });

    test('mindestens 1 Minute', () {
      expect(estimateMinutes(sets: 1, durationSec: 1), 1);
    });

    test('Dauer hat Vorrang vor Wiederholungen', () {
      expect(estimateMinutes(sets: 1, reps: 100, durationSec: 30), 1);
    });
  });

  group('Sätze und Wiederholungen', () {
    test('4 s je Wiederholung', () {
      // 1 × 10 × 4 s = 40 s → 1 Min.
      expect(estimateMinutes(sets: 1, reps: 10), 1);
      // 3 × 10 × 4 s + 2 × 60 s = 240 s → 4 Min.
      expect(estimateMinutes(sets: 3, reps: 10), 4);
      // 3 × 15 × 4 s + 2 × 60 s = 300 s → 5 Min.
      expect(estimateMinutes(sets: 3, reps: 15), 5);
      // 300 s + 2 s mehr Pause → aufgerundet auf 6 Min.
      expect(estimateMinutes(sets: 3, reps: 15, pauseSec: 61), 6);
    });

    test('Pause des Physios geht ein', () {
      // 2 × 10 × 4 s + 1 × 20 s = 100 s → 2 Min.
      expect(estimateMinutes(sets: 2, reps: 10, pauseSec: 20), 2);
    });

    test('mindestens 1 Minute', () {
      expect(estimateMinutes(sets: 1, reps: 1), 1);
    });
  });

  group('Rückfälle', () {
    test('nur Sätze: Sätze × 1 Minute', () {
      expect(estimateMinutes(sets: 4), 4);
      expect(estimateMinutes(sets: 1), 1);
    });

    test('sonst 5 Minuten', () {
      expect(estimateMinutes(), 5);
      expect(estimateMinutes(reps: 12), 5);
      expect(estimateMinutes(pauseSec: 30), 5);
    });
  });
}
