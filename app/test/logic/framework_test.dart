// Framework-Modelle (Plan 8.2): JSON-Roundtrip für den Zwischenspeicher,
// Lesetoleranz, Hilfen.
import 'dart:convert';

import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/framework.dart';
import 'package:curaone/logic/json_support.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/framework_builders.dart';

Json _roundtrip(Json j) => jsonDecode(jsonEncode(j)) as Json;

void main() {
  test('Roundtrip: toJson → JSON-Text → fromJson → toJson ist gleich', () {
    final Framework f = sampleFramework();
    final Json once = _roundtrip(f.toJson());
    final Framework back = Framework.fromJson(once);
    expect(_roundtrip(back.toJson()), once);
    expect(back.plan!.items.length, 4);
    expect(back.exercises.length, 4);
    expect(back.patient.boundAt, DateTime.utc(2026, 10, 1, 8));
  });

  test('ohne Verletzung und Plan: Leerzustand', () {
    final Framework f = Framework(
      patient: const PatientInfo(id: 'p', firstName: 'A'),
      injury: null,
      plan: null,
      exercises: const <Exercise>[],
      treaters: const <Treater>[],
      appointments: const <Appointment>[],
      history: const <HistoryEntry>[],
    );
    final Framework back = Framework.fromJson(_roundtrip(f.toJson()));
    expect(back.injury, isNull);
    expect(back.plan, isNull);
  });

  test('Plan sortiert Phasen und Positionen; aktuelle Phase mit Rückfall', () {
    final Plan p = plan(
      phases: <Phase>[phase('b', 5), phase('a', 1)],
      items: <PlanItem>[item('y', position: 9), item('x', position: 2)],
      currentPhaseId: null,
    );
    expect(p.phases.map((Phase e) => e.id), <String>['a', 'b']);
    expect(p.items.map((PlanItem e) => e.id), <String>['x', 'y']);
    expect(p.currentPhase!.id, 'a'); // null → erste Phase
    expect(plan(phases: <Phase>[], items: <PlanItem>[]).currentPhase, isNull);
    expect(p.itemsOfPhase('ph1').length, 2);
    expect(p.itemById('x')!.position, 2);
    expect(p.phaseById('zz'), isNull);
  });

  test('Positionen: Dauer je Satz, Freischaltung, leichtere Variante', () {
    final PlanItem i = PlanItem.fromJson(<String, Object?>{
      'id': 'i',
      'phaseId': 'p',
      'exerciseId': 'e',
      'position': 0,
      'durationSec': 45,
      'weightKg': 2,
      'release': 'prepared',
      'releaseOn': '2026-10-20',
      'easierVariantOf': 'j',
    });
    expect(i.durationSec, 45);
    expect(i.weightKg, 2.0);
    expect(i.release, Release.prepared);
    expect(i.releaseOn, const LocalDay(2026, 10, 20));
    expect(i.easierVariantOf, 'j');
  });

  test('unbekannte Werte und falsche Typen sind unlesbar', () {
    expect(
      () => PlanItem.fromJson(<String, Object?>{
        'id': 'i',
        'phaseId': 'p',
        'exerciseId': 'e',
        'position': 0,
        'release': 'irgendwas',
      }),
      throwsA(isA<UnreadableDataException>()),
    );
    expect(
      () => Phase.fromJson(<String, Object?>{
        'id': 'p',
        'position': 0,
        'title': 't',
        'plannedWeeks': 0,
      }),
      throwsA(isA<UnreadableDataException>()),
    );
    expect(
      () => Appointment.fromJson(<String, Object?>{
        'id': 'a',
        'startsAt': 'gestern',
        'title': 't',
        'author': 'physio',
      }),
      throwsA(isA<UnreadableDataException>()),
    );
    expect(
      () => PatientInfo.fromJson(<String, Object?>{
        'id': 'a',
        'firstName': 'x',
        'status': 'seltsam',
      }),
      throwsA(isA<UnreadableDataException>()),
    );
  });

  test('Termin: eigener Termin erkennbar', () {
    final Appointment own = Appointment(
      id: 'a',
      startsAt: DateTime.utc(2026, 1, 1),
      title: 'x',
      author: AppointmentAuthor.patient,
    );
    expect(own.isOwn, isTrue);
    expect(
      Appointment(
        id: 'a',
        startsAt: DateTime.utc(2026, 1, 1),
        title: 'x',
        author: AppointmentAuthor.physio,
      ).isOwn,
      isFalse,
    );
  });

  test('Schmerzschwelle der Kürzung ist 6 (E-28)', () {
    expect(kPainShorteningThreshold, 6);
  });

  test('Status-Namen der Datenbank', () {
    for (final PatientStatus s in PatientStatus.values) {
      expect(PatientStatus.fromDb(s.dbName), s);
    }
    expect(PatientStatus.fromDb('x'), isNull);
  });
}
