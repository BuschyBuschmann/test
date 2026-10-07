// Plan 6.2: Versionierung, Migration, Lesetoleranz, Roundtrip.
import 'dart:convert';
import 'dart:io';

import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/json_support.dart';
import 'package:curaone/logic/migrations.dart';
import 'package:curaone/logic/streak.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

Map<String, Object?> minimalDoc() => <String, Object?>{
  'schema': 1,
  'onboarding': <String, Object?>{'completed': false, 'step': 0},
};

AppState decode(Object? doc, {LocalDay? today}) =>
    decodeDocument(jsonEncode(doc), today ?? kToday);

void expectUnreadable(String raw) {
  expect(
    () => decodeDocument(raw, kToday),
    throwsA(isA<UnreadableDataException>()),
    reason: raw,
  );
}

void main() {
  final String fixtureRaw = File('test/fixtures/state_v1.json')
      .readAsStringSync();

  group('Fixture je Schemaversion', () {
    test('state_v1.json lädt und ergibt das erwartete AppState', () {
      expect(decodeDocument(fixtureRaw, kToday), expectedV1());
    });

    test(
      'Schema-Konstante: genau ein Fixture je Version 1..kCurrentSchema',
      () {
        for (int v = 1; v <= kCurrentSchema; v++) {
          expect(File('test/fixtures/state_v$v.json').existsSync(), isTrue);
        }
      },
    );
  });

  group('Migrationskette', () {
    // Synthetisches Schema 1 → 2 (kommt in der echten Kette nicht vor): prüft
    // den Mechanismus für künftige Versionen.
    final Map<int, Json Function(Json)> chain = <int, Json Function(Json)>{
      1: (Json j) {
        final Json o = Map<String, Object?>.of(j);
        o['schema'] = 2;
        final Json onboarding = Map<String, Object?>.of(
          o['onboarding']! as Map<String, Object?>,
        );
        onboarding['name'] = onboarding.remove('vorname') ?? '';
        o['onboarding'] = onboarding;
        return o;
      },
    };

    test('ältere Version wird Schritt für Schritt migriert', () {
      final AppState s = decodeDocument(
        jsonEncode(<String, Object?>{
          'schema': 1,
          'onboarding': <String, Object?>{
            'completed': false,
            'step': 1,
            'vorname': 'Lena',
          },
        }),
        kToday,
        currentSchema: 2,
        migrations: chain,
      );
      expect(s.onboarding.name, 'Lena');
      expect(s.onboarding.step, 1);
    });

    test('mehrstufig: 1 → 2 → 3', () {
      final Map<int, Json Function(Json)> two = <int, Json Function(Json)>{
        1: (Json j) => <String, Object?>{...j, 'schema': 2},
        2: (Json j) => <String, Object?>{...j, 'schema': 3, 'neu': 1},
      };
      final Json out = migrateToCurrent(
        minimalDoc(),
        currentSchema: 3,
        migrations: two,
      );
      expect(out['schema'], 3);
      expect(out['neu'], 1);
    });

    test('fehlende Migration → unlesbar', () {
      expect(
        () =>
            decodeDocument(jsonEncode(minimalDoc()), kToday, currentSchema: 2),
        throwsA(isA<UnreadableDataException>()),
      );
    });

    test('Migration, die das Schema nicht erhöht → unlesbar', () {
      expect(
        () => migrateToCurrent(
          minimalDoc(),
          currentSchema: 2,
          migrations: <int, Json Function(Json)>{1: (Json j) => j},
        ),
        throwsA(isA<UnreadableDataException>()),
      );
    });
  });

  group('Lesetoleranz', () {
    test('minimales Dokument: fehlende optionale Felder → Standard', () {
      final AppState s = decode(minimalDoc());
      expect(s, AppState.initial(kToday));
      expect(s.streak.freezes, 2);
      expect(s.prefs.timeChoice, 20);
      expect(s.day.dayKey, kToday);
      expect(s.consent, isNull);
      expect(s.celebration, isNull);
    });

    test('einzelnes fehlendes Feld in einem Block → Standardwert', () {
      final Map<String, Object?> doc = minimalDoc()
        ..['streak'] = <String, Object?>{
          'count': 4,
          'lastTrainingDay': '2026-10-06',
        }
        ..['prefs'] = <String, Object?>{}
        ..['day'] = <String, Object?>{'done': true};
      final AppState s = decode(doc);
      expect(s.streak.count, 4);
      expect(s.streak.freezes, 2);
      expect(s.prefs.timeChoice, 20);
      expect(s.day.done, isTrue);
      expect(s.day.dayKey, kToday);
    });

    test('`null` bei optionalen Feldern gilt wie fehlend', () {
      final Map<String, Object?> doc = minimalDoc()
        ..['consent'] = null
        ..['celebration'] = null
        ..['streak'] = <String, Object?>{
          'lastTrainingDay': null,
          'freezes': null,
        };
      final AppState s = decode(doc);
      expect(s.streak.lastTrainingDay, isNull);
      expect(s.streak.freezes, 2);
    });

    test('zusätzliche Felder werden ignoriert', () {
      final Map<String, Object?> doc =
          jsonDecode(fixtureRaw) as Map<String, Object?>;
      doc['irgendwas'] = <String, Object?>{'a': 1};
      (doc['onboarding']! as Map<String, Object?>)['neuesFeld'] = 'x';
      (doc['manny']! as Map<String, Object?>)['lastShown'] = <String, Object?>{
        'greeting': '2026-10-06',
        'fact': '2026-10-07',
        'zukunftsAnlass': '2026-10-07',
      };
      expect(decode(doc), expectedV1());
    });

    test('Roundtrip toJson/fromJson aller Felder (n2)', () {
      final AppState s = expectedV1();
      expect(decode(s.toJson()), s);
      expect(decodeDocument(encodeDocument(s), kToday), s);
      final AppState init = AppState.initial(kToday);
      expect(decode(init.toJson()), init);
    });

    test(
      'Roundtrip: Streak mit coveredInGap, uncoveredInGap, evaluatedThrough',
      () {
        final StreakState st = expectedV1().streak.copyWith(uncoveredInGap: 1);
        final AppState s = expectedV1().copyWith(streak: st);
        final AppState back = decode(s.toJson());
        expect(back.streak.coveredInGap, 1);
        expect(back.streak.uncoveredInGap, 1);
        expect(back.streak.evaluatedThrough, const LocalDay(2026, 10, 6));
      },
    );

    test('toJson schreibt das Schema und die Schlüssel aus Plan 6.1', () {
      final Json j = AppState.initial(kToday).toJson();
      expect(j.keys.toSet(), <String>{
        'schema', 'onboarding', 'consent', 'streak', 'path', 'day', 'prefs',
        'manny', 'celebration', //
      });
      expect(j['schema'], kCurrentSchema);
      expect((j['streak']! as Map<String, Object?>).keys.toSet(), <String>{
        'count', 'freezes', 'lastTrainingDay', 'evaluatedThrough',
        'coveredInGap', 'uncoveredInGap', 'resetNoticePending', //
      });
      expect((j['day']! as Map<String, Object?>).keys.toSet(), <String>{
        'dayKey',
        'removed',
        'swaps',
        'custom',
        'done',
      });
      expect(j.containsKey('lastSeenDay'), isFalse);
    });

    test('Consent-Zeitstempel wird als UTC-ISO-8601 geschrieben', () {
      final Json c = expectedV1().toJson()['consent']! as Json;
      expect(c['acceptedAt'], '2026-09-08T08:12:30.123Z');
    });
  });

  group('unlesbar (N-12)', () {
    test('kein JSON', () {
      expectUnreadable('{kaputt');
      expectUnreadable('');
      expectUnreadable('null');
      expectUnreadable('[1,2]');
      expectUnreadable('"text"');
      expectUnreadable('42');
    });

    test('schema fehlt, falscher Typ, 0, negativ, > kCurrentSchema', () {
      expectUnreadable('{"onboarding":{"completed":false,"step":0}}');
      expectUnreadable(
        '{"schema":"1","onboarding":{"completed":false,"step":0}}',
      );
      expectUnreadable(
        '{"schema":1.0,"onboarding":{"completed":false,"step":0}}',
      );
      expectUnreadable(
        '{"schema":0,"onboarding":{"completed":false,"step":0}}',
      );
      expectUnreadable(
        '{"schema":-1,"onboarding":{"completed":false,"step":0}}',
      );
      expectUnreadable(
        '{"schema":99,"onboarding":{"completed":false,"step":0}}',
      );
    });

    test('fehlende Pflichtfelder', () {
      expectUnreadable('{"schema":1}');
      expectUnreadable('{"schema":1,"onboarding":{}}');
      expectUnreadable('{"schema":1,"onboarding":{"completed":true}}');
      expectUnreadable('{"schema":1,"onboarding":{"step":1}}');
      expectUnreadable('{"schema":1,"onboarding":null}');
    });

    test('falsche Typen', () {
      expectUnreadable('{"schema":1,"onboarding":{"completed":"ja","step":0}}');
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":"0"}}',
      );
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0,"name":5}}',
      );
      expectUnreadable('{"schema":1,"onboarding":[]}');
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0},"streak":{"count":"x"}}',
      );
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0},"day":{"removed":"x"}}',
      );
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0},"day":{"swaps":{"a":"b"}}}',
      );
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0},"day":{"custom":[1]}}',
      );
    });

    test('ungültiges Datum und unbekannte Aufzählung', () {
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0,"injuryDate":"2026-02-30"}}',
      );
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0,"injuryDate":"morgen"}}',
      );
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0,"injuryType":"hirn"}}',
      );
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0},"day":{"dayKey":"2026-13-01"}}',
      );
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0},"consent":{"acceptedAt":"gestern"}}',
      );
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0},"celebration":{"streak":1}}',
      );
    });

    test('Wertebereiche', () {
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":4}}',
      );
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":-1}}',
      );
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0},"prefs":{"timeChoice":15}}',
      );
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0},"streak":{"freezes":3}}',
      );
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0},"streak":{"count":-1}}',
      );
    });
  });

  group('LocalDay in JSON', () {
    test('Datum wird als YYYY-MM-DD geschrieben', () {
      final Json j = expectedV1().toJson();
      expect((j['onboarding']! as Json)['injuryDate'], '2026-09-07');
      expect((j['day']! as Json)['dayKey'], '2026-10-07');
    });
  });
  group('R-U1 MINOR-5: Lesestrenge', () {
    String consentDoc(String ts) =>
        '{"schema":1,"onboarding":{"completed":false,"step":0},'
        '"consent":{"acceptedAt":"$ts","version":"prototype-0"}}';

    test(
      '(a) ungültige Zeitstempel sind unlesbar (statt still umgerechnet)',
      () {
        for (final String bad in <String>[
          '2026-13-45T99:00:00Z',
          '+999999-01-01T00:00:00Z',
          '2026-02-30T10:00:00Z',
          '2026-10-07T24:00:00Z',
          '2026-10-07T10:61:00Z',
          '2026-10-07',
          '2026-10-07T10:00:00', // ohne Z
          'gestern',
        ]) {
          expectUnreadable(consentDoc(bad));
        }
      },
    );

    test('(a) gültige Zeitstempel (mit/ohne Bruchteil) werden gelesen', () {
      expect(
        decodeDocument(
          consentDoc('2026-10-07T08:12:30Z'),
          kToday,
        ).consent!.acceptedAt,
        DateTime.utc(2026, 10, 7, 8, 12, 30),
      );
      expect(
        decodeDocument(
          consentDoc('2026-10-07T08:12:30.123Z'),
          kToday,
        ).consent!.acceptedAt,
        DateTime.utc(2026, 10, 7, 8, 12, 30, 123),
      );
      expect(
        decodeDocument(
          consentDoc('2026-10-07T08:12:30.123456Z'),
          kToday,
        ).consent!.acceptedAt,
        DateTime.utc(2026, 10, 7, 8, 12, 30, 123, 456),
      );
    });

    test('(b) Streak > 0 ohne lastTrainingDay ist unlesbar (T6)', () {
      expectUnreadable(
        '{"schema":1,"onboarding":{"completed":false,"step":0},'
        '"streak":{"count":5}}',
      );
      // Streak 0 ohne Datum ist der Normalfall.
      expect(
        decodeDocument(
          '{"schema":1,"onboarding":{"completed":false,"step":0},'
          '"streak":{"count":0}}',
          kToday,
        ).streak.count,
        0,
      );
    });

    test('(b) completed: true ohne Name, Typ, Datum oder Einwilligung ist unlesbar', () {
      final Map<String, Object?> good =
          jsonDecode(fixtureRaw) as Map<String, Object?>;
      Map<String, Object?> variant(void Function(Map<String, Object?>) edit) {
        final Map<String, Object?> d =
            jsonDecode(fixtureRaw) as Map<String, Object?>;
        edit(d);
        return d;
      }

      expect(decode(good), expectedV1());
      for (final Map<String, Object?> bad in <Map<String, Object?>>[
        variant((d) => d['consent'] = null),
        variant(
          (d) => (d['onboarding']! as Map<String, Object?>)['name'] = '  ',
        ),
        variant(
          (d) =>
              (d['onboarding']! as Map<String, Object?>)['injuryType'] = null,
        ),
        variant(
          (d) =>
              (d['onboarding']! as Map<String, Object?>)['injuryDate'] = null,
        ),
      ]) {
        expectUnreadable(jsonEncode(bad));
      }
      // Nicht abgeschlossenes Onboarding darf unvollständig sein.
      expect(decode(minimalDoc()).onboarding.completed, isFalse);
    });

    test(
      '(c) Fehler einer Migrationsfunktion werden zu UnreadableDataException',
      () {
        for (final Json Function(Json) broken in <Json Function(Json)>[
          (Json j) => throw StateError('kaputt'),
          (Json j) => (j['gibtsNicht']! as Map<String, Object?>),
          (Json j) => throw const FormatException('x'),
        ]) {
          expect(
            () => decodeDocument(
              jsonEncode(minimalDoc()),
              kToday,
              currentSchema: 2,
              migrations: <int, Json Function(Json)>{1: broken},
            ),
            throwsA(isA<UnreadableDataException>()),
          );
        }
      },
    );
  });
}
