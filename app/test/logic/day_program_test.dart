import 'package:curaone/logic/day_program.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

List<String> ids(List<DisplayedExercise> l) =>
    l.map((DisplayedExercise e) => e.id).toList();

void main() {
  final DayProgramState fresh = DayProgramState.fresh(kToday);

  group('deriveExercises', () {
    test('Ableitung je Zeitwahl: Anzahl und Summe 10/20/30', () {
      expect(deriveExercises(fresh, 10), hasLength(2));
      expect(deriveExercises(fresh, 20), hasLength(4));
      expect(deriveExercises(fresh, 30), hasLength(6));
      expect(totalMinutes(deriveExercises(fresh, 10)), 10);
      expect(totalMinutes(deriveExercises(fresh, 20)), 20);
      expect(totalMinutes(deriveExercises(fresh, 30)), 30);
    });

    test('Entfernen: Liste kürzer, Überschrift folgt (UI-26, B-6)', () {
      final DayProgramState d = removeExercise(fresh, 'ex-bruecke');
      final List<DisplayedExercise> l = deriveExercises(d, 20);
      expect(ids(l), isNot(contains('ex-bruecke')));
      expect(l, hasLength(3));
      expect(exercisesHeading(l), 'Übungen · ca. 13 Min');
      expect(
        exercisesHeading(deriveExercises(fresh, 20)),
        'Übungen · ca. 20 Min',
      );
      expect(
        exercisesHeading(deriveExercises(fresh, 10)),
        'Übungen · ca. 10 Min',
      );
    });

    test('Entfernen aller Übungen: Überschrift nur „Übungen“', () {
      DayProgramState d = fresh;
      for (final String id in ids(deriveExercises(fresh, 20))) {
        d = removeExercise(d, id);
      }
      expect(deriveExercises(d, 20), isEmpty);
      expect(exercisesHeading(deriveExercises(d, 20)), 'Übungen');
    });

    test('Tauschen ersetzt zyklisch, ID bleibt, Dauer bleibt', () {
      DayProgramState d = swapExercise(fresh, 'ex-kniebeuge');
      DisplayedExercise e = deriveExercises(d, 20).first;
      expect(e.id, 'ex-kniebeuge');
      expect(e.name, 'Aufstehen vom Stuhl');
      expect(e.minutes, 6);
      d = swapExercise(d, 'ex-kniebeuge');
      expect(deriveExercises(d, 20).first.name, 'Mini-Kniebeuge an der Wand');
      d = swapExercise(d, 'ex-kniebeuge');
      expect(
        deriveExercises(d, 20).first.name,
        'Kniebeuge am Stuhl',
      ); // zyklisch
      expect(totalMinutes(deriveExercises(d, 20)), 20);
    });

    test('Tauschen: unbekannte und eigene IDs bleiben wirkungslos', () {
      expect(swapExercise(fresh, 'gibt-es-nicht'), fresh);
      final DayProgramState withCustom = addCustom(
        fresh,
        const CustomExercise(
          id: 'custom-1',
          name: 'X',
          reps: '3 × 10',
          minutes: 5,
        ),
      );
      expect(swapExercise(withCustom, 'custom-1'), withCustom);
      expect(deriveExercises(withCustom, 20).last.canSwap, isFalse);
    });

    test('Eigene Übung steht am Ende und zählt in die Summe', () {
      final DayProgramState d = addCustom(
        fresh,
        const CustomExercise(
          id: 'custom-1',
          name: 'Eigene',
          reps: '2 × 8',
          minutes: 4,
        ),
      );
      final List<DisplayedExercise> l = deriveExercises(d, 10);
      expect(l.last.name, 'Eigene');
      expect(l.last.isCustom, isTrue);
      expect(totalMinutes(l), 14);
    });

    test('Zeitwechsel erhält Änderungen per ID', () {
      DayProgramState d = removeExercise(fresh, 'ex-wade');
      d = swapExercise(d, 'ex-kniebeuge');
      for (final int t in <int>[10, 20, 30]) {
        final List<DisplayedExercise> l = deriveExercises(d, t);
        expect(ids(l), isNot(contains('ex-wade')), reason: '$t');
        expect(l.first.name, 'Aufstehen vom Stuhl', reason: '$t');
      }
      // Entfernte ID einer größeren Zeitwahl bleibt gemerkt.
      d = removeExercise(d, 'ex-ausfall');
      expect(ids(deriveExercises(d, 20)), isNot(contains('ex-ausfall')));
      expect(ids(deriveExercises(d, 30)), isNot(contains('ex-ausfall')));
    });

    test(
      'Entfernen ist idempotent; unbekannte ID wirkungslos; eigene Übung',
      () {
        final DayProgramState once = removeExercise(fresh, 'ex-wade');
        expect(removeExercise(once, 'ex-wade'), once);
        expect(removeExercise(fresh, 'nix'), fresh);
        final DayProgramState c = addCustom(
          fresh,
          const CustomExercise(
            id: 'custom-1',
            name: 'X',
            reps: 'r',
            minutes: 1,
          ),
        );
        expect(removeExercise(c, 'custom-1').custom, isEmpty);
        expect(removeExercise(c, 'custom-1').removed, isEmpty);
      },
    );
  });

  group('CustomExercise.fromInput (N-16)', () {
    test('Name Pflicht, Vorgaben als Rückfall', () {
      expect(CustomExercise.fromInput(id: 'a', name: '   '), isNull);
      final CustomExercise e = CustomExercise.fromInput(
        id: 'a',
        name: ' Plank ',
      )!;
      expect(e.name, 'Plank');
      expect(e.reps, '3 × 10');
      expect(e.minutes, 5);
      final CustomExercise f = CustomExercise.fromInput(
        id: 'a',
        name: 'Plank',
        reps: ' 2 × 30 Sek. ',
        minutes: '8',
      )!;
      expect((f.reps, f.minutes), ('2 × 30 Sek.', 8));
      expect(
        CustomExercise.fromInput(id: 'a', name: 'P', minutes: 'abc')!.minutes,
        5,
      );
      expect(
        CustomExercise.fromInput(id: 'a', name: 'P', minutes: '0')!.minutes,
        5,
      );
      expect(
        CustomExercise.fromInput(id: 'a', name: 'P', minutes: '-3')!.minutes,
        5,
      );
    });
  });

  group('JSON', () {
    test('Roundtrip aller Felder', () {
      final DayProgramState d = DayProgramState(
        dayKey: kToday,
        removed: const <String>['ex-wade'],
        swaps: const <String, int>{'ex-kniebeuge': 2},
        custom: const <CustomExercise>[
          CustomExercise(id: 'custom-1', name: 'X', reps: '3 × 10', minutes: 5),
        ],
        done: true,
      );
      expect(DayProgramState.fromJson(d.toJson(), kToday), d);
    });
  });
}
