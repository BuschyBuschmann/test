// Schema-Sprung 1 → 2 (Plan 3.5, Brief-Ergänzung 1, 10): Das Onboarding
// bekommt vor dem Namen den Look-Schritt. Nicht abgeschlossenes Onboarding:
// `step` + 1; `mannyLook` = `brille` für alle Bestandsdaten; wer das Onboarding
// abgeschlossen hat, wird nicht gefragt; „Alles löschen“ setzt zurück.
import 'dart:convert';
import 'dart:io';

import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/json_support.dart';
import 'package:curaone/logic/manny_look.dart';
import 'package:curaone/logic/migrations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

String _fixture(String name) => File('test/fixtures/$name').readAsStringSync();

Json _json(String raw) => jsonDecode(raw) as Json;

void main() {
  test('aktuelles Schema ist 3 (2 → 3 siehe migration_v3_test)', () {
    expect(kCurrentSchema, 3);
    expect(kLastOnboardingStep, 4);
    expect(kMigrations.keys, containsAll(<int>[1, 2]));
  });

  group('Fixture state_v1_onboarding_step2.json (unfertiges Onboarding)', () {
    // Alter Schritt 2 (Index 1, Datenschutz) wird Schritt 3 (Index 2).
    final String raw = _fixture('state_v1_onboarding_step2.json');

    test('Migration auf Dokumentebene: step + 1, Look brille, Schema 2', () {
      final Json out = migrateToCurrent(_json(raw));
      expect(out['schema'], kCurrentSchema);
      expect((out['onboarding']! as Json)['step'], 2);
      expect((out['onboarding']! as Json)['completed'], false);
      expect(out['mannyLook'], 'brille');
    });

    test('lädt als AppState mit Schritt 2, Name erhalten, Look brille', () {
      final AppState s = decodeDocument(raw, kToday);
      expect(s.onboarding.completed, isFalse);
      expect(s.onboarding.step, 2);
      expect(s.onboarding.name, 'Jakob');
      expect(s.mannyLook, MannyLook.brille);
      expect(s.consent, isNull);
    });

    test('alle alten Schritte 0..3 werden zu 1..4', () {
      for (int old = 0; old <= 3; old++) {
        final Json doc = _json(raw);
        (doc['onboarding']! as Json)['step'] = old;
        final AppState s = decodeDocument(jsonEncode(doc), kToday);
        expect(s.onboarding.step, old + 1, reason: 'alter Schritt $old');
        expect(s.mannyLook, MannyLook.brille);
      }
    });

    test('ein Wert außerhalb des alten Bereichs bleibt unlesbar', () {
      for (final int bad in <int>[-1, 4, 9]) {
        final Json doc = _json(raw);
        (doc['onboarding']! as Json)['step'] = bad;
        expect(
          () => decodeDocument(jsonEncode(doc), kToday),
          throwsA(isA<UnreadableDataException>()),
          reason: 'step $bad',
        );
      }
    });
  });

  group('Fixture state_v1_done.json (abgeschlossenes Onboarding)', () {
    final String raw = _fixture('state_v1_done.json');

    test('Schritt bleibt unverändert, Look brille, wird nicht gefragt', () {
      final Json out = migrateToCurrent(_json(raw));
      expect(out['schema'], kCurrentSchema);
      expect((out['onboarding']! as Json)['completed'], true);
      expect((out['onboarding']! as Json)['step'], 3);
      expect(out['mannyLook'], 'brille');
      final AppState s = decodeDocument(raw, kToday);
      expect(s.onboarding.completed, isTrue);
      expect(s, expectedV1());
      expect(s.mannyLook, MannyLook.brille);
    });
  });

  group('Fixture state_v2.json (Schema 2)', () {
    test('lädt ohne Migration, mannyLook „ohne“ bleibt erhalten', () {
      final AppState s = decodeDocument(_fixture('state_v2.json'), kToday);
      expect(s.mannyLook, MannyLook.ohne);
      expect(s.onboarding.completed, isTrue);
    });

    test('Roundtrip schreibt das aktuelle Schema und mannyLook', () {
      final AppState s = expectedV1().copyWith(mannyLook: MannyLook.ohne);
      final Json j = s.toJson();
      expect(j['schema'], kCurrentSchema);
      expect(j['mannyLook'], 'ohne');
      expect(decodeDocument(encodeDocument(s), kToday), s);
    });
  });

  group('mannyLook', () {
    test('Vorbelegung „Mit Brille“; ohne Feld im Schema-2-Dokument ebenso', () {
      expect(AppState.initial(kToday).mannyLook, MannyLook.brille);
      expect(MannyLook.defaultLook, MannyLook.brille);
      final Json j = AppState.initial(kToday).toJson()..remove('mannyLook');
      expect(AppState.fromJson(j, kToday).mannyLook, MannyLook.brille);
    });

    test('unbekannter Wert oder falscher Typ: unlesbar', () {
      for (final Object? bad in <Object?>['mit', 3, true, <String>[]]) {
        final Json j = AppState.initial(kToday).toJson()..['mannyLook'] = bad;
        expect(
          () => AppState.fromJson(j, kToday),
          throwsA(isA<UnreadableDataException>()),
          reason: '$bad',
        );
      }
    });

    test('Namen im Dokument: brille und ohne', () {
      expect(MannyLook.values.map((MannyLook l) => l.jsonName), <String>[
        'brille',
        'ohne',
      ]);
      for (final MannyLook l in MannyLook.values) {
        expect(MannyLook.fromJson(l.jsonName), l);
      }
    });

    test('Onboarding-Schritt reicht bis 4, 5 ist unlesbar', () {
      Json doc(int step) => AppState.initial(kToday).toJson()
        ..['onboarding'] = <String, Object?>{'completed': false, 'step': step};
      expect(AppState.fromJson(doc(4), kToday).onboarding.step, 4);
      expect(
        () => AppState.fromJson(doc(5), kToday),
        throwsA(isA<UnreadableDataException>()),
      );
    });
  });
}
