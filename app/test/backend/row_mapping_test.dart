// Zeilen der Datenbank → Modelle der App (snake_case, Spalten einzeln).
import 'package:curaone/backend/row_mapping.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/framework.dart';
import 'package:curaone/logic/json_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Spaltenlisten nennen keine Spalten außerhalb der Grants', () {
    // patients: kein auth_user_id, create_params_hash, manny_look (Migration 03).
    for (final String forbidden in <String>[
      'auth_user_id',
      'create_params_hash',
      'manny_look',
      '*',
    ]) {
      expect(kPatientColumns.split(','), isNot(contains(forbidden)));
    }
    for (final String cols in <String>[
      kPatientColumns,
      kInjuryColumns,
      kPlanColumns,
      kPhaseColumns,
      kPlanItemColumns,
      kExerciseColumns,
      kTreaterColumns,
      kAppointmentColumns,
      kHistoryColumns,
    ]) {
      expect(cols.contains('*'), isFalse);
      expect(cols.contains(' '), isFalse);
    }
  });

  test('Patient, Verletzung', () {
    final PatientInfo p = patientFromRow(<String, Object?>{
      'id': 'p',
      'first_name': 'Lena',
      'last_name': null,
      'status': 'active',
      'bound_at': '2026-10-01T08:00:00+00:00',
    });
    expect(p.status, PatientStatus.active);
    expect(p.boundAt, DateTime.utc(2026, 10, 1, 8));
    final Injury i = injuryFromRow(<String, Object?>{
      'id': 'i',
      'label': 'Kreuzband',
      'reference_date': '2026-09-07',
      'started_on': '2026-09-07',
      'closed_on': null,
    });
    expect(i.referenceDate, const LocalDay(2026, 9, 7));
    expect(i.isActive, isTrue);
  });

  test('Plan aus Zeilen: numeric als int oder double, Freischaltung', () {
    final Plan plan = planFromRows(
      <String, Object?>{
        'id': 'pl',
        'injury_id': 'i',
        'current_phase_id': 'ph2',
        'version': 4,
        'closed': false,
      },
      <Json>[
        <String, Object?>{
          'id': 'ph2',
          'position': 1,
          'title': 'B',
          'planned_weeks': 3,
        },
        <String, Object?>{
          'id': 'ph1',
          'position': 0,
          'title': 'A',
          'planned_weeks': 2,
        },
      ],
      <Json>[
        <String, Object?>{
          'id': 'it1',
          'phase_id': 'ph1',
          'exercise_id': 'ex',
          'position': 0,
          'sets': 3,
          'reps': 10,
          'duration_sec': null,
          'weight_kg': 2.5,
          'pause_sec': 30,
          'load_note': 'langsam',
          'release': 'active',
          'release_on': null,
          'release_with_phase_id': null,
          'easier_variant_of': null,
        },
        <String, Object?>{
          'id': 'it2',
          'phase_id': 'ph2',
          'exercise_id': 'ex',
          'position': 1,
          'sets': null,
          'reps': null,
          'duration_sec': 45,
          'weight_kg': 3,
          'pause_sec': null,
          'load_note': null,
          'release': 'prepared',
          'release_on': '2026-11-01',
          'release_with_phase_id': null,
          'easier_variant_of': 'it1',
        },
      ],
    );
    expect(plan.version, 4);
    expect(plan.phases.map((Phase p) => p.id), <String>['ph1', 'ph2']);
    expect(plan.currentPhase!.id, 'ph2');
    expect(plan.items[0].weightKg, 2.5);
    expect(plan.items[1].weightKg, 3.0);
    expect(plan.items[1].durationSec, 45);
    expect(plan.items[1].releaseOn, const LocalDay(2026, 11, 1));
    expect(plan.items[1].easierVariantOf, 'it1');
  });

  test('Übung: Material, Orte (unbekannte Orte fallen weg)', () {
    final Exercise e = exerciseFromRow(<String, Object?>{
      'id': 'e',
      'name': 'Brücke',
      'description': 'Beschreibung',
      'is_example': true,
      'short_instruction': null,
      'materials': <Object?>['Matte'],
      'locations': <Object?>['home', 'mond'],
    });
    expect(e.isExample, isTrue);
    expect(e.materials, <String>['Matte']);
    expect(e.locations, <String>['home']);
  });

  test('Akte: Behandler, Termin, Krankengeschichte', () {
    expect(
      treaterFromRow(<String, Object?>{
        'id': 't',
        'role': 'Arzt',
        'name': 'Dr. A',
        'phone': '123',
        'email': null,
        'address': null,
        'note': null,
      }).phone,
      '123',
    );
    final Appointment a = appointmentFromRow(<String, Object?>{
      'id': 'a',
      'treater_id': null,
      'starts_at': '2026-10-12T09:00:00+00:00',
      'title': 'Kontrolle',
      'location': null,
      'created_by_role': 'patient',
    });
    expect(a.isOwn, isTrue);
    expect(a.startsAt, DateTime.utc(2026, 10, 12, 9));
    expect(
      historyFromRow(<String, Object?>{
        'id': 'h',
        'kind': 'op',
        'title': 'Operation',
        'occurred_on': '2026-09-08',
        'note': null,
      }).occurredOn,
      const LocalDay(2026, 9, 8),
    );
  });

  test('unbrauchbare Zeilen sind unlesbar', () {
    expect(
      () => patientFromRow(<String, Object?>{
        'id': 'p',
        'first_name': 'x',
        'status': 'kaputt',
      }),
      throwsA(isA<UnreadableDataException>()),
    );
    expect(
      () => appointmentFromRow(<String, Object?>{
        'id': 'a',
        'starts_at': '2026-10-12T09:00:00Z',
        'title': 't',
        'created_by_role': 'jemand',
      }),
      throwsA(isA<UnreadableDataException>()),
    );
    expect(
      () => planItemFromRow(<String, Object?>{
        'id': 'i',
        'phase_id': 'p',
        'exercise_id': 'e',
        'position': 0,
        'release': 'x',
      }),
      throwsA(isA<UnreadableDataException>()),
    );
  });
}
