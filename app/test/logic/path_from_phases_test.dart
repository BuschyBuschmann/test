// Pfad aus Physio-Phasen (Plan 8.3, Regeln 1–11 aus v1.2 6.3).
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/framework.dart';
import 'package:curaone/logic/path_from_phases.dart';
import 'package:curaone/logic/path_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/framework_builders.dart';

const LocalDay ref = LocalDay(2026, 9, 1);

PhasePath build(
  List<Phase> phases, {
  String? current,
  List<String> done = const <String>[],
  LocalDay? today,
}) => buildPathFromPhases(
  phases: phases,
  currentPhaseId: current,
  completedUnitIds: done,
  referenceDate: ref,
  today: today ?? ref,
);

void main() {
  group('Aufbau und IDs (Regeln 1 und 2)', () {
    test('eine Phase mit einer Woche: 3 Tage, Wochenziel, Abschluss, Boss', () {
      final PhasePath p = build(<Phase>[
        phase('p1', 0, weeks: 1),
      ], current: 'p1');
      expect(p.units.map((PathUnit u) => u.id), <String>[
        'p1-w1-d1',
        'p1-w1-d2',
        'p1-w1-d3',
        'p1-w1-goal',
        'p1-end',
        'boss',
      ]);
      expect(p.units.map((PathUnit u) => u.kind), <UnitKind>[
        UnitKind.trainingDay,
        UnitKind.trainingDay,
        UnitKind.trainingDay,
        UnitKind.weekGoal,
        UnitKind.phaseEnd,
        UnitKind.boss,
      ]);
      expect(p.units.first.dayNumber, 1);
      expect(p.units[2].dayNumber, 3);
    });

    test('Anzahl Units: Wochen × 4 + Abschlüsse + Boss', () {
      for (final List<int> weeks in <List<int>>[
        <int>[1],
        <int>[4],
        <int>[12],
        <int>[1, 4, 12],
      ]) {
        final List<Phase> phases = <Phase>[
          for (int i = 0; i < weeks.length; i++)
            phase('p$i', i, weeks: weeks[i]),
        ];
        final PhasePath p = build(phases, current: 'p0');
        final int total = weeks.fold(0, (int a, int b) => a + b);
        expect(p.units.length, total * 4 + weeks.length + 1, reason: '$weeks');
        expect(p.totalWeeks, total);
        expect(p.units.last.id, 'boss');
        expect(
          p.units.map((PathUnit u) => u.id).toSet().length,
          p.units.length,
        );
      }
    });

    test('Wochen zählen je Phase, PathUnit.week über alle Phasen', () {
      final PhasePath p = build(<Phase>[
        phase('a', 0, weeks: 2),
        phase('b', 1, weeks: 1),
      ], current: 'a');
      final PathUnit b1 = p.units.firstWhere((PathUnit u) => u.id == 'b-w1-d1');
      expect(b1.week, 3);
      expect(b1.phase, 2);
      expect(p.units.firstWhere((PathUnit u) => u.id == 'a-end').week, 2);
    });

    test('Phasen werden nach position sortiert', () {
      final PhasePath p = build(<Phase>[
        phase('z', 5, weeks: 1),
        phase('a', 1, weeks: 1),
      ], current: 'a');
      expect(p.units.first.id, 'a-w1-d1');
      expect(p.phasePosition, 1);
    });
  });

  group('Status (Regeln 3–8)', () {
    final List<Phase> three = <Phase>[
      phase('a', 0, weeks: 1),
      phase('b', 1, weeks: 1),
      phase('c', 2, weeks: 1),
    ];

    test(
      'Anfang: erste Unit der aktuellen Phase ist aktuell, Rest gesperrt',
      () {
        final PhasePath p = build(three, current: 'a');
        expect(p.statuses.first, PhaseUnitStatus.current);
        expect(p.currentIndex, 0);
        expect(p.mannyIndex, 0);
        expect(
          p.statuses
              .skip(1)
              .every((PhaseUnitStatus s) => s == PhaseUnitStatus.locked),
          isTrue,
        );
        expect(p.unitToComplete, 'a-w1-d1');
      },
    );

    test('Erledigt nur über completedUnitIds; aktuelle Unit rückt vor', () {
      final PhasePath p = build(three, current: 'a', done: <String>['a-w1-d1']);
      expect(p.statuses[0], PhaseUnitStatus.done);
      expect(p.statuses[1], PhaseUnitStatus.current);
      expect(p.mannyIndex, 1);
    });

    test('ohne Datumsautomatismus: später Tag erledigt nichts', () {
      final PhasePath p = build(three, current: 'a', today: ref.addDays(300));
      expect(p.statuses.first, PhaseUnitStatus.current);
    });

    test(
      'Regel 5: aktuelle Phase vollständig erledigt → keine aktuelle Unit',
      () {
        final PhasePath p = build(
          three,
          current: 'a',
          done: <String>['a-w1-d1', 'a-w1-d2', 'a-w1-d3', 'a-w1-goal', 'a-end'],
        );
        expect(p.currentIndex, isNull);
        expect(p.current, isNull);
        expect(p.unitToComplete, isNull);
        // Manny sitzt auf der letzten erledigten Unit der Phase (a-end).
        expect(p.units[p.mannyIndex].id, 'a-end');
        // Spätere Phasen bleiben gesperrt.
        expect(
          p.statuses[p.units.indexWhere((PathUnit u) => u.id == 'b-w1-d1')],
          PhaseUnitStatus.locked,
        );
      },
    );

    test(
      'Regel 6: Vorschalten – offene Units früherer Phasen sind ausgelassen',
      () {
        final PhasePath p = build(
          three,
          current: 'c',
          done: <String>['a-w1-d1'],
        );
        PhaseUnitStatus s(String id) =>
            p.statuses[p.units.indexWhere((PathUnit u) => u.id == id)];
        expect(s('a-w1-d1'), PhaseUnitStatus.done);
        expect(s('a-w1-d2'), PhaseUnitStatus.skipped);
        expect(s('a-end'), PhaseUnitStatus.skipped);
        expect(s('b-w1-d1'), PhaseUnitStatus.skipped);
        expect(s('c-w1-d1'), PhaseUnitStatus.current);
        expect(s('boss'), PhaseUnitStatus.locked);
      },
    );

    test(
      'Regel 7: Zurückschalten – Erledigtes bleibt, spätere Phasen gesperrt',
      () {
        final PhasePath p = build(
          three,
          current: 'a',
          done: <String>['a-w1-d1', 'b-w1-d1'],
        );
        PhaseUnitStatus s(String id) =>
            p.statuses[p.units.indexWhere((PathUnit u) => u.id == id)];
        expect(s('b-w1-d1'), PhaseUnitStatus.done);
        expect(s('b-w1-d2'), PhaseUnitStatus.locked);
        expect(s('a-w1-d2'), PhaseUnitStatus.current);
      },
    );

    test('Regel 8: Boss ist nie aktuell, auch wenn alles erledigt ist', () {
      final List<String> all = <String>[
        for (final Phase ph in three) ...<String>[
          '${ph.id}-w1-d1',
          '${ph.id}-w1-d2',
          '${ph.id}-w1-d3',
          '${ph.id}-w1-goal',
          '${ph.id}-end',
        ],
      ];
      final PhasePath p = build(three, current: 'c', done: all);
      expect(p.currentIndex, isNull);
      expect(p.statuses.last, PhaseUnitStatus.locked);
    });

    test(
      'Regel 9: unbekannte IDs werden ignoriert, neue Wochen sind offen',
      () {
        final PhasePath p = build(
          <Phase>[phase('a', 0, weeks: 2)],
          current: 'a',
          done: <String>['a-w9-d1', 'x-w1-d1', 'a-w1-d1'],
        );
        expect(
          p.statuses
              .where((PhaseUnitStatus s) => s == PhaseUnitStatus.done)
              .length,
          1,
        );
        expect(p.units[p.currentIndex!].id, 'a-w1-d2');
      },
    );

    test('unbekannte oder fehlende aktuelle Phase → erste Phase', () {
      expect(build(three, current: null).phasePosition, 1);
      expect(build(three, current: 'gibt-es-nicht').phasePosition, 1);
    });
  });

  group('Kopfzeile (Regel 10)', () {
    final List<Phase> phases = <Phase>[
      phase('a', 0, weeks: 4, title: 'Schutz'),
      phase('b', 1, weeks: 8, title: 'Aufbau'),
    ];

    test(
      'Woche = Kalenderwoche seit reference_date, begrenzt auf 1..Summe',
      () {
        int week(int days) =>
            build(phases, current: 'a', today: ref.addDays(days)).week;
        expect(week(0), 1);
        expect(week(6), 1);
        expect(week(7), 2);
        expect(week(27), 4);
        expect(week(28), 5);
        expect(week(200), 12); // Summe 12
        expect(week(-5), 1); // Datum in der Zukunft
      },
    );

    test('Phase P · Titel aus der aktuellen Phase', () {
      final PhasePath p = build(phases, current: 'b');
      expect(p.phasePosition, 2);
      expect(p.phaseTitle, 'Aufbau');
    });

    test('Leerzustand ohne Phasen', () {
      final PhasePath p = build(<Phase>[]);
      expect(p.isEmpty, isTrue);
      expect(p.units, isEmpty);
      expect(p.currentIndex, isNull);
      expect(p.phaseTitle, isNull);
      expect(p.week, 0);
    });
  });

  test('buildPathFromPlan nimmt Phasen, aktuelle Phase und Bezugsdatum', () {
    final Plan pl = plan(currentPhaseId: 'ph2');
    final Framework f = sampleFramework(plan0: pl);
    final PhasePath p = buildPathFromPlan(
      plan: pl,
      injury: f.injury!,
      completedUnitIds: const <String>[],
      today: const LocalDay(2026, 9, 7),
    );
    expect(p.phasePosition, 2);
    expect(p.week, 1);
  });
}
