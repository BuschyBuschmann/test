// „Heute“ aus dem Plan (Plan 8.4, 6.7): Freigabe, Füllregel, Tauschen; die
// gemeinsamen Fixtures „Mitternacht/Zeitzone“ (a), (b) nur lesend.
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/framework.dart';
import 'package:curaone/logic/plan_today.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/framework_builders.dart';
import '../support/local_day_fixtures.dart';

void main() {
  const LocalDay today = LocalDay(2026, 10, 7);

  group('isReleased', () {
    test('active ist immer freigegeben', () {
      final Plan p = plan();
      expect(isReleased(item('a'), p, today), isTrue);
    });

    test('prepared mit release_on: ab dem Tag freigegeben (inklusive)', () {
      final Plan p = plan();
      final PlanItem it = item(
        'a',
        release: Release.prepared,
        releaseOn: const LocalDay(2026, 10, 7),
      );
      expect(isReleased(it, p, const LocalDay(2026, 10, 6)), isFalse);
      expect(isReleased(it, p, const LocalDay(2026, 10, 7)), isTrue);
      expect(isReleased(it, p, const LocalDay(2026, 10, 8)), isTrue);
    });

    test('prepared mit release_with_phase_id: Phase ≤ aktuelle Phase', () {
      final Plan p = plan(
        phases: <Phase>[phase('ph1', 0), phase('ph2', 1), phase('ph3', 2)],
        currentPhaseId: 'ph2',
      );
      PlanItem with_(String phaseId) => item(
        'x',
        phaseId: 'ph2',
        release: Release.prepared,
        releaseWithPhaseId: phaseId,
      );
      expect(isReleased(with_('ph1'), p, today), isTrue);
      expect(isReleased(with_('ph2'), p, today), isTrue);
      expect(isReleased(with_('ph3'), p, today), isFalse);
      expect(isReleased(with_('unbekannt'), p, today), isFalse);
    });

    test('prepared ohne Bedingung (nicht erlaubt) gilt nicht als frei', () {
      expect(
        isReleased(item('x', release: Release.prepared), plan(), today),
        isFalse,
      );
    });

    test('Fixture (a): Berlin 00:30 am Tag D, release_on = D → freigegeben', () {
      final Map<String, dynamic> f = readLocalDayFixture(
        'a_berlin_0030_release_on_d.json',
      );
      final Map<String, dynamic> c = f['case'] as Map<String, dynamic>;
      final LocalDay day = localDayAt(
        c['utc_instant'] as String,
        c['utc_offset'] as String,
      );
      expect(day.toString(), c['local_day']);
      // UTC-Datum liegt noch einen Tag davor (Zeitzonen-Falle).
      expect(c['offset_days'], 1);

      final Map<String, dynamic> i = f['item'] as Map<String, dynamic>;
      final PlanItem it = item(
        'x',
        release: Release.prepared,
        releaseOn: LocalDay.parse(i['release_on'] as String),
      );
      final Map<String, dynamic> expected = f['expect'] as Map<String, dynamic>;
      expect(isReleased(it, plan(), day), expected['is_released']);
      // Mit dem UTC-Datum statt des lokalen Tages wäre sie fälschlich gesperrt:
      expect(
        isReleased(it, plan(), LocalDay.parse(c['utc_date'] as String)),
        isFalse,
      );
    });

    test('Fixture (b): Berlin 23:30 am Tag D−1 → noch nicht freigegeben', () {
      final Map<String, dynamic> f = readLocalDayFixture(
        'b_berlin_2330_day_before.json',
      );
      final Map<String, dynamic> c = f['case'] as Map<String, dynamic>;
      final LocalDay day = localDayAt(
        c['utc_instant'] as String,
        c['utc_offset'] as String,
      );
      expect(day.toString(), c['local_day']);
      final Map<String, dynamic> i = f['item'] as Map<String, dynamic>;
      final PlanItem it = item(
        'x',
        release: Release.prepared,
        releaseOn: LocalDay.parse(i['release_on'] as String),
      );
      expect(
        isReleased(it, plan(), day),
        (f['expect'] as Map<String, dynamic>)['is_released'],
      );
    });
  });

  group('Füllregel (Zeitwahl)', () {
    // Schätzungen: a 3×10 → 4 Min., b 2×30 s + 30 s Pause → 2 Min.,
    // c 1 Satz 5 Min. (nur Dauer fehlt), d: 5 Min. Rückfall.
    Plan filled() => plan(
      items: <PlanItem>[
        item('a', position: 0, sets: 3, reps: 10), // 4
        item('b', position: 1, sets: 2, durationSec: 30, pauseSec: 30), // 2
        item('c', position: 2), // 5
        item('d', position: 3, sets: 4), // 4
        item('e', position: 4, phaseId: 'ph2'), // andere Phase
      ],
    );

    test('nimmt der Reihe nach auf, solange die Summe ≤ Zeitwahl bleibt', () {
      final TodayPlan t = buildTodayPlan(
        plan: filled(),
        localDay: today,
        timeChoice: 10,
      );
      expect(t.items.map((PlanItem i) => i.id), <String>['a', 'b']);
      expect(t.totalMinutes, 6);
      final TodayPlan t20 = buildTodayPlan(
        plan: filled(),
        localDay: today,
        timeChoice: 20,
      );
      expect(t20.items.map((PlanItem i) => i.id), <String>['a', 'b', 'c', 'd']);
      expect(t20.totalMinutes, 15);
    });

    test('Füllung endet an der ersten Position, die nicht mehr passt', () {
      final Plan p = plan(
        items: <PlanItem>[
          item('a', position: 0, sets: 6), // 6
          item('b', position: 1, sets: 6), // 6 → 12 > 10, Schluss
          item(
            'c',
            position: 2,
            sets: 1,
          ), // 1 passt, wird aber nicht mehr geprüft
        ],
      );
      final TodayPlan t = buildTodayPlan(
        plan: p,
        localDay: today,
        timeChoice: 10,
      );
      expect(t.items.map((PlanItem i) => i.id), <String>['a']);
    });

    test(
      'mindestens eine Übung, auch wenn sie länger ist als die Zeitwahl',
      () {
        final Plan p = plan(
          items: <PlanItem>[
            item('a', sets: 40),
            item('b', position: 1, sets: 1),
          ],
        );
        final TodayPlan t = buildTodayPlan(
          plan: p,
          localDay: today,
          timeChoice: 10,
        );
        expect(t.items.map((PlanItem i) => i.id), <String>['a']);
        expect(t.totalMinutes, 40);
      },
    );

    test('nur freigegebene Positionen der aktuellen Phase', () {
      final Plan p = plan(
        items: <PlanItem>[
          item(
            'x',
            position: 0,
            release: Release.prepared,
            releaseOn: const LocalDay(2026, 10, 8),
          ),
          item('a', position: 1, sets: 1),
          item('f', position: 2, phaseId: 'ph2'),
        ],
      );
      final TodayPlan t = buildTodayPlan(
        plan: p,
        localDay: today,
        timeChoice: 30,
      );
      expect(t.items.map((PlanItem i) => i.id), <String>['a']);
      final TodayPlan tomorrow = buildTodayPlan(
        plan: p,
        localDay: const LocalDay(2026, 10, 8),
        timeChoice: 30,
      );
      expect(tomorrow.items.map((PlanItem i) => i.id), <String>['x', 'a']);
    });

    test('Reihenfolge des Physios (position), nicht der Liste', () {
      final Plan p = plan(
        items: <PlanItem>[
          item('b', position: 5, sets: 1),
          item('a', position: 1, sets: 1),
        ],
      );
      final TodayPlan t = buildTodayPlan(
        plan: p,
        localDay: today,
        timeChoice: 30,
      );
      expect(t.items.map((PlanItem i) => i.id), <String>['a', 'b']);
    });

    test('ohne Phasen oder Positionen leer', () {
      expect(
        buildTodayPlan(
          plan: plan(phases: <Phase>[], items: <PlanItem>[]),
          localDay: today,
          timeChoice: 20,
        ).isEmpty,
        isTrue,
      );
      expect(
        buildTodayPlan(
          plan: plan(items: <PlanItem>[]),
          localDay: today,
          timeChoice: 20,
        ).items,
        isEmpty,
      );
    });

    test('Zeitwahlen', () {
      expect(kPlanTimeChoices, <int>[10, 20, 30]);
    });
  });

  group('Tauschen', () {
    final Plan p = plan(
      items: <PlanItem>[
        item('a', position: 0, sets: 1),
        item('b', position: 1, sets: 1),
        item('c', position: 2, sets: 1),
        item(
          'x',
          position: 3,
          release: Release.prepared,
          releaseOn: const LocalDay(2026, 12, 1),
        ),
        item('y', position: 4, phaseId: 'ph2'),
      ],
    );

    test('Kandidaten: übrige freigegebene Positionen der aktuellen Phase', () {
      final List<PlanItem> c = swapCandidates(
        plan: p,
        localDay: today,
        listedItemIds: <String>['a', 'b'],
      );
      expect(c.map((PlanItem i) => i.id), <String>['c']);
    });

    test('keine Kandidaten → Tauschen wird nicht angeboten', () {
      expect(
        swapCandidates(
          plan: p,
          localDay: today,
          listedItemIds: <String>['a', 'b', 'c'],
        ),
        isEmpty,
      );
    });

    test('swapListed ersetzt an gleicher Stelle', () {
      expect(swapListed(<String>['a', 'b'], 'a', 'c'), <String>['c', 'b']);
      expect(swapListed(<String>['a', 'b'], 'z', 'c'), <String>['a', 'b']);
    });
  });

  test('totalMinutesOf summiert die Schätzungen', () {
    expect(
      totalMinutesOf(<PlanItem>[
        item('a', sets: 3, reps: 10),
        item('b', sets: 2),
      ]),
      6,
    );
  });
}
