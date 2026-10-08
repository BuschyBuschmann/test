import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/injury_type.dart';
import 'package:curaone/logic/path_generator.dart';
import 'package:curaone/logic/path_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

PathProgress progress(
  int daysAgo, {
  List<String> completed = const <String>[],
}) => computePathProgress(
  injuryDate: kToday.addDays(-daysAgo),
  today: kToday,
  completedUnitIds: completed,
);

void main() {
  group('Beispielpfad', () {
    test('Anzahl, Reihenfolge und IDs', () {
      final List<PathUnit> units = buildSamplePath();
      expect(units, hasLength(52));
      expect(units.first.id, 'w1-d1');
      expect(units.take(4).map((PathUnit u) => u.id), <String>[
        'w1-d1',
        'w1-d2',
        'w1-d3',
        'w1-goal',
      ]);
      final List<String> w4 = units
          .where((PathUnit u) => u.week == 4)
          .map((PathUnit u) => u.id)
          .toList();
      expect(w4, <String>['w4-d1', 'w4-d2', 'w4-d3', 'w4-goal', 'p1-end']);
      expect(
        units
            .where((PathUnit u) => u.kind == UnitKind.phaseEnd)
            .map((u) => u.id),
        <String>['p1-end', 'p2-end', 'p3-end'],
      );
      expect(units[units.length - 2].id, 'p3-end');
      expect(units.last.id, 'boss');
      expect(units.last.kind, UnitKind.boss);
      expect(units.map((PathUnit u) => u.id).toSet(), hasLength(52));
      expect(units.where((u) => u.kind == UnitKind.trainingDay), hasLength(36));
      expect(units.where((u) => u.kind == UnitKind.weekGoal), hasLength(12));
      expect(units[0].dayNumber, 1);
      expect(units[3].dayNumber, 0);
    });

    test('Phasen: Woche 1–4 → 1, 5–8 → 2, 9–12 → 3', () {
      expect(
        <int>[for (int w = 1; w <= 12; w++) phaseOfWeek(w)],
        <int>[
          1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, //
        ],
      );
      expect(kSamplePath.firstWhere((u) => u.id == 'p2-end').phase, 2);
    });

    test('Platzhalter-Kennzeichnung', () {
      expect(kSamplePathIsPlaceholder, isTrue);
    });
  });

  group('aktuelle Woche und Phase', () {
    test('Datum heute, vor 4/5/27/28/84/200 Tagen, Zukunft, unbekannt', () {
      int w(int daysAgo) => currentWeek(kToday.addDays(-daysAgo), kToday);
      expect(w(0), 1);
      expect(w(6), 1);
      expect(w(7), 2);
      expect(w(4), 1);
      expect(w(5), 1);
      expect(w(27), 4);
      expect(w(28), 5);
      expect(w(30), 5);
      expect(w(83), 12);
      expect(w(84), 12);
      expect(w(200), 12);
      expect(w(-3), 1); // Datum in der Zukunft
      expect(currentWeek(null, kToday), 1);
      expect(progress(28).phase, 2);
      expect(progress(27).phase, 1);
      expect(progress(200).phase, 3);
    });
  });

  group('Status', () {
    test('W = 5: Wochen 1–4 erledigt, erste Unit von Woche 5 aktuell', () {
      final PathProgress p = progress(30);
      expect(p.week, 5);
      expect(p.current!.id, 'w5-d1');
      for (int i = 0; i < p.units.length; i++) {
        final PathUnit u = p.units[i];
        if (u.week < 5) expect(p.statuses[i], UnitStatus.done, reason: u.id);
        if (u.id == 'w5-d1') expect(p.statuses[i], UnitStatus.current);
        if (u.week >= 5 && u.id != 'w5-d1') {
          expect(p.statuses[i], UnitStatus.locked, reason: u.id);
        }
      }
      expect(p.mannyIndex, p.currentIndex);
    });

    test(
      'Eintragen setzt die nächste Unit aktuell, auch wochenübergreifend',
      () {
        PathProgress p = progress(30, completed: <String>['w5-d1']);
        expect(p.current!.id, 'w5-d2');
        p = progress(
          30,
          completed: <String>['w5-d1', 'w5-d2', 'w5-d3', 'w5-goal'],
        );
        expect(p.current!.id, 'w6-d1');
        expect(p.week, 5); // K-1: Datumswoche bleibt
      },
    );

    test('Wochenende/Phasenende: p1-end ist erledigt, sobald W > 4', () {
      final PathProgress p = progress(28);
      expect(p.isDone('p1-end'), isTrue);
      expect(p.isDone('w5-d1'), isFalse);
      expect(p.isDone('unbekannt'), isFalse);
    });

    test('Endfall: alles bis vor Boss erledigt → keine aktuelle Unit', () {
      final PathProgress p = progress(
        200,
        completed: <String>[for (final PathUnit u in kSamplePath) u.id],
      );
      expect(p.currentIndex, isNull);
      expect(p.current, isNull);
      expect(p.units[p.mannyIndex].id, 'p3-end');
      expect(p.statuses.last, UnitStatus.done); // Boss nur, weil in completed
    });

    test('Boss ist nie aktuell und bleibt gesperrt', () {
      final PathProgress p = progress(
        200,
        completed: <String>[
          for (final PathUnit u in kSamplePath)
            if (u.kind != UnitKind.boss) u.id,
        ],
      );
      expect(p.currentIndex, isNull);
      expect(p.statuses.last, UnitStatus.locked);
      expect(p.units[p.mannyIndex].id, 'p3-end');
      for (int w = 1; w <= 12; w++) {
        final PathProgress q = progress((w - 1) * 7);
        expect(q.current?.kind, isNot(UnitKind.boss));
      }
    });

    test('Woche 12 ohne Fortschritt: aktuelle Unit w12-d1', () {
      expect(progress(200).current!.id, 'w12-d1');
    });

    test('Woche 1 (Datum heute): erste Unit aktuell, Manny auf Index 0', () {
      final PathProgress p = progress(0);
      expect(p.currentIndex, 0);
      expect(p.mannyIndex, 0);
    });
  });

  group('Hinweistexte (Ergänzung 1, 3.5)', () {
    final PathProgress p = progress(30); // W = 5
    PathUnit unit(String id) => kSamplePath.firstWhere((u) => u.id == id);
    String? hint(String id) => nodeHintText(
      unit(id),
      p.statuses[kSamplePath.indexWhere((u) => u.id == id)],
      p.week,
    );

    test('gesperrt in laufender Woche: „Kommt noch diese Woche“', () {
      expect(hint('w5-d2'), 'Kommt noch diese Woche');
      expect(hint('w5-goal'), 'Kommt noch diese Woche');
    });

    test('gesperrt in späterer Woche', () {
      expect(hint('w7-d1'), 'Kommt in Woche 7');
      expect(hint('w8-goal'), 'Kommt in Woche 8');
      expect(hint('p2-end'), 'Phasen-Abschluss kommt in Woche 8');
      expect(hint('boss'), 'Return to Sport kommt in Woche 12');
    });

    test('erledigt und aktuell', () {
      expect(hint('w3-d2'), 'Erledigt. Das hast du geschafft.');
      expect(hint('w5-d1'), isNull);
    });
  });

  group('Boss-Hinweis in Woche 12 (Nutzerentscheidung)', () {
    String? bossHint(int daysAgo) {
      final PathProgress p = progress(daysAgo);
      final int i = kSamplePath.indexWhere((u) => u.id == 'boss');
      return nodeHintText(kSamplePath[i], p.statuses[i], p.week);
    }

    test('laufende Woche 12: „Dein Ziel: zurück in deinen Sport.“', () {
      expect(bossHint(84), 'Dein Ziel: zurück in deinen Sport.');
      expect(bossHint(200), 'Dein Ziel: zurück in deinen Sport.');
    });

    test('andere Wochen unverändert; übrige Units in Woche 12 auch', () {
      expect(bossHint(30), 'Return to Sport kommt in Woche 12');
      expect(bossHint(0), 'Return to Sport kommt in Woche 12');
      final PathProgress p = progress(84);
      PathUnit u(String id) => kSamplePath.firstWhere((x) => x.id == id);
      String? h(String id) => nodeHintText(
        u(id),
        p.statuses[kSamplePath.indexWhere((x) => x.id == id)],
        p.week,
      );
      expect(h('w12-d2'), 'Kommt noch diese Woche');
      expect(h('p3-end'), 'Kommt noch diese Woche');
    });
  });

  group('Screenreader-Labels (A-14)', () {
    final PathProgress p = progress(30);
    String label(String id) {
      final int i = kSamplePath.indexWhere((u) => u.id == id);
      return unitSemanticsLabel(kSamplePath[i], p.statuses[i]);
    }

    test('Beispiele aus Ergänzung 1', () {
      expect(label('w5-d1'), 'Woche 5, Trainingstag 1, aktuell. Öffnet Heute.');
      expect(label('w7-d1'), 'Woche 7, Trainingstag 1, gesperrt.');
      expect(label('w3-d2'), 'Woche 3, Trainingstag 2, erledigt.');
      expect(label('boss'), 'Return to Sport, gesperrt.');
      expect(label('w5-goal'), 'Woche 5, Wochenziel, gesperrt.');
      expect(label('p2-end'), 'Woche 8, Phasen-Abschluss, gesperrt.');
    });
  });

  group('Kopfzeile (A-13, UI-25)', () {
    test('Kurznamen und Phasenzeile für alle Typen', () {
      expect(injuryShortName(InjuryType.acl), 'Kreuzband');
      expect(injuryShortName(InjuryType.ankle), 'Sprunggelenk');
      expect(injuryShortName(InjuryType.muscle), 'Muskelfaser');
      expect(injuryShortName(InjuryType.other), 'Reha');
      expect(injuryShortName(null), 'Reha');
      expect(phaseLine(2, InjuryType.acl), 'Phase 2 · Kreuzband');
    });

    test('Beispielpfad hängt nicht vom Verletzungstyp ab (N-3, UI-25)', () {
      // `computePathProgress` und `buildSamplePath` kennen keinen Typ: alle
      // vier Typen bekommen dieselben Units.
      expect(buildSamplePath(), kSamplePath);
      expect(kSamplePathIsPlaceholder, isTrue);
    });
  });

  test('LocalDay-unabhängig: currentWeek mit Datum nach Sommerzeitwechsel', () {
    // 2026-10-25 Sommerzeitende; 7 Kalendertage = Woche 2, nicht 1.
    expect(
      currentWeek(const LocalDay(2026, 10, 20), const LocalDay(2026, 10, 27)),
      2,
    );
  });
}
