// Tests des Testdaten-Seeds (Paket F2-2): Daten, Plan, Reihenfolge, SQL-Ausgabe, Kommandozeile.
// Ohne Netzwerk und ohne Datenbank. Der Lauf gegen Postgres steht in
// supabase/tests/seed/run_seed_local_pg.sh, DB-T40 in voller Form braucht den Stack (X2-8).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/seed/seed_backend.dart';
import '../../tool/seed/seed_cli.dart';
import '../../tool/seed/seed_plan.dart';
import '../../tool/seed/sql_backend.dart';
import '../../tool/seed/stable_ids.dart';

const String _dataPath = 'tool/seed/testdaten.json';
final DateTime _today = DateTime.utc(2026, 10, 16);

Map<String, dynamic> _loadData() =>
    jsonDecode(File(_dataPath).readAsStringSync()) as Map<String, dynamic>;

SeedPlan _plan({Map<String, dynamic>? data, DateTime? today}) =>
    buildSeedPlan(data ?? _loadData(), today: today ?? _today);

List<Row> _rows(SeedPlan p, String table) => [
  for (final s in p.steps)
    if (s is UpsertRows && s.table == table) ...s.rows,
];

/// Tiefe Kopie, damit Tests die Daten gefahrlos verändern können.
Map<String, dynamic> _copy() =>
    jsonDecode(jsonEncode(_loadData())) as Map<String, dynamic>;

Map<String, dynamic> _patient(Map<String, dynamic> d, String key) {
  for (final p in d['praxen'] as List<dynamic>) {
    for (final pat
        in (p as Map<String, dynamic>)['patienten'] as List<dynamic>) {
      if ((pat as Map<String, dynamic>)['key'] == key) return pat;
    }
  }
  throw StateError(key);
}

class _RecordingBackend implements SeedBackend {
  final List<String> calls = [];
  final List<UpsertRows> upserts = [];
  bool closed = false;

  @override
  Future<void> resetTestData(String emailDomain) async =>
      calls.add('reset:$emailDomain');
  @override
  Future<void> createPhysioAccount(CreatePhysioAccount step) async =>
      calls.add('physio:${step.email}');
  @override
  Future<void> upsert(UpsertRows step) async {
    calls.add('upsert:${step.table}');
    upserts.add(step);
  }

  @override
  Future<void> update(UpdateRows step) async =>
      calls.add('update:${step.table}');
  @override
  Future<Row?> physioRpc(PhysioRpc step) async {
    calls.add('rpc:${step.fn}:${step.physioKey}');
    return {'code': 'ABCDE12345', 'expires_at': '2026-10-30T00:00:00Z'};
  }

  @override
  Future<void> close() async => closed = true;
}

void main() {
  group('stableId', () {
    test(
      'ist deterministisch, formal eine UUID v4 und trägt das Seed-Präfix',
      () {
        final a = stableId('patient:lena');
        expect(stableId('patient:lena'), a);
        expect(
          a,
          matches(
            RegExp(
              r'^5eed[0-9a-f]{4}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
        expect(stableId('patient:jonas'), isNot(a));
        expect(stableId('practice:nord'), stableId('practice:nord'));
      },
    );

    test(
      'Beispielwerte sind fest (Änderung würde alle Seed-IDs verschieben)',
      () {
        expect(
          stableId('patient:lena'),
          '5eedab2b-db5d-4e43-ba45-c9b40b32a2a6',
        );
        expect(
          stableId('practice:nord'),
          '5eed43b3-6bbb-4b9c-80f7-25d634adb2d7',
        );
        expect(
          stableId('patient:jonas'),
          '5eedb316-fc26-4390-b920-ed9b492deac8',
        );
      },
    );
  });

  group('Testdaten', () {
    late SeedPlan plan;
    setUp(() => plan = _plan());

    test('Umfang laut Plan 10: 2 Praxen, je 2 Physios, 5 Patienten mit Hauptphysio', () {
      expect(_rows(plan, 'practices'), hasLength(2));
      expect(plan.physios, hasLength(4));
      for (final practice in _rows(plan, 'practices')) {
        expect(
          plan.physios.where((p) => p.practiceId == practice['id']),
          hasLength(2),
        );
      }
      final patients = _rows(plan, 'patients');
      expect(patients, hasLength(5));
      final physioPractice = {
        for (final p in plan.physios) p.key: p.practiceId,
      };
      for (final p in patients) {
        final ref = p['main_physio_id']! as PhysioRef;
        expect(
          physioPractice[ref.key],
          p['practice_id'],
          reason: 'Hauptphysio aus derselben Praxis',
        );
        expect(p['status'], 'invited');
      }
    });

    test('alles ist als Testdaten gekennzeichnet und erfunden', () {
      for (final p in _rows(plan, 'practices')) {
        expect(p['is_test'], isTrue);
        expect(p['name'], contains('Testdaten'));
      }
      for (final p in plan.physios) {
        expect(p.email, endsWith('@test.curaone.invalid'));
      }
      for (final p in _rows(plan, 'patients')) {
        expect(p['last_name'], 'Testperson');
      }
      for (final e in _rows(
        plan,
        'exercises',
      ).where((e) => e['practice_id'] == null)) {
        expect(e['is_example'], isTrue);
        expect(
          e['description'] as String,
          startsWith('Beispielübung (Testdaten)'),
        );
      }
      final json = File(_dataPath).readAsStringSync();
      expect(
        json,
        isNot(
          matches(RegExp(r'@(?!test\.curaone\.invalid)[a-z0-9.-]+\.[a-z]{2,}')),
        ),
      );
      expect(
        json,
        isNot(matches(RegExp(r'eyJ[A-Za-z0-9_-]{20,}'))),
        reason: 'kein JWT in den Daten',
      );
    });

    test('Katalog mit Baukasten-Feldern, ohne Bilder; Beispielvorlagen', () {
      final catalog = _rows(
        plan,
        'exercises',
      ).where((e) => e['practice_id'] == null).toList();
      expect(catalog, hasLength(15));
      expect(
        catalog.every((e) => (e['short_instruction'] as String).isNotEmpty),
        isTrue,
      );
      expect(catalog.every((e) => (e['locations'] as List).isNotEmpty), isTrue);
      expect(catalog.any((e) => (e['materials'] as List).isNotEmpty), isTrue);
      expect(catalog.any((e) => e['pause_sec'] != null), isTrue);
      expect(plan.rowCounts.containsKey('exercise_images'), isFalse);
      final templates = _rows(plan, 'plan_templates');
      expect(templates, hasLength(3));
      expect(
        templates.every(
          (t) => t['practice_id'] == null && t['is_example'] == true,
        ),
        isTrue,
      );
      // payload im Format von app.copy_template_into_plan
      final knie = templates.firstWhere(
        (t) => (t['name'] as String).startsWith('Knie'),
      );
      final phases = (knie['payload']! as Map)['phases'] as List;
      expect(phases, hasLength(3));
      final items1 = ((phases[1] as Map)['items']) as List;
      expect(
        items1.any(
          (i) =>
              (i as Map)['release_with_phase'] == 2 &&
              i['release'] == 'prepared',
        ),
        isTrue,
      );
      expect(items1.any((i) => (i as Map)['easier_variant_of'] == 1), isTrue);
    });

    test(
      'genau ein Patient mit abgeschlossener früherer Verletzung samt Verlauf',
      () {
        final closed = _rows(
          plan,
          'injuries',
        ).where((i) => i['closed_on'] != null).toList();
        expect(closed, hasLength(1));
        final closedPlan = _rows(
          plan,
          'plans',
        ).singleWhere((p) => p['injury_id'] == closed.single['id']);
        expect(closedPlan['closed'], isTrue);
        expect(closed.single['patient_id'], closedPlan['patient_id']);
        expect(
          _rows(
            plan,
            'training_sessions',
          ).where((s) => s['plan_id'] == closedPlan['id']),
          isNotEmpty,
        );
        final active = _rows(
          plan,
          'injuries',
        ).where((i) => i['closed_on'] == null).toList();
        expect(active, hasLength(5));
        expect(
          _rows(plan, 'plans').where((p) => p['closed'] == false),
          hasLength(5),
        );
      },
    );

    test(
      'Positionen "vorbereitet" nach Datum und nach Phase, leichtere Variante',
      () {
        final items = _rows(plan, 'plan_items');
        final prepared = items
            .where((i) => i['release'] == 'prepared')
            .toList();
        expect(
          prepared.any(
            (i) =>
                i['release_on'] != null && i['release_with_phase_id'] == null,
          ),
          isTrue,
        );
        expect(
          prepared.any(
            (i) =>
                i['release_on'] == null && i['release_with_phase_id'] != null,
          ),
          isTrue,
        );
        for (final i in items.where((i) => i['release'] == 'active')) {
          expect(i['release_on'], isNull);
          expect(i['release_with_phase_id'], isNull);
        }
        expect(
          plan.steps.whereType<UpdateRows>().where(
            (u) => u.table == 'plan_items',
          ),
          isNotEmpty,
        );
      },
    );

    test('Patienten stehen in mindestens drei verschiedenen Phasen', () {
      final phasePos = {
        for (final p in _rows(plan, 'phases')) p['id']: p['position'],
      };
      final current = <Object?>{
        for (final u in plan.steps.whereType<UpdateRows>().where(
          (u) => u.table == 'plans',
        ))
          phasePos[u.values['current_phase_id']],
      };
      expect(current.length, greaterThanOrEqualTo(3));
    });

    test('Training: 14 Tage, abgehakt und übersprungen, beide Modi, Streak zählt Folgetage', () {
      final sessions = _rows(plan, 'training_sessions');
      final lena = stableId('patient:lena');
      final days =
          (sessions
              .where((s) => s['patient_id'] == lena)
              .map((s) => s['local_day'] as String)
              .toList()
            ..sort());
      expect(days.first, dayString(_today, -14));
      expect(days.last, dayString(_today, -1));
      expect(sessions.map((s) => s['mode']).toSet(), {'guided', 'checklist'});
      final results = _rows(plan, 'exercise_results');
      expect(results.where((r) => r['status'] == 'skipped'), isNotEmpty);
      expect(results.where((r) => r['status'] == 'done'), isNotEmpty);
      for (final s in sessions) {
        expect(
          DateTime.parse(s['local_day'] as String).isBefore(_today),
          isTrue,
          reason: 'nur vergangene Tage',
        );
        expect(
          s.containsKey('injury_id'),
          isFalse,
          reason: 'injury_id setzt der Trigger',
        );
        final rs = results
            .where((r) => r['training_session_id'] == s['id'])
            .toList();
        expect(rs.length, (s['items'] as List).length);
        if (s['mode'] == 'checklist') {
          expect(s['started_at'], isNull);
        } else {
          expect(
            DateTime.parse(s['ended_at'] as String)
                .isAfter(DateTime.parse(s['started_at'] as String)),
            isTrue,
          );
        }
      }
      // streak_after: 1 nach Lücke, sonst Vortag + 1
      final byKey = {
        for (final s in sessions)
          '${s['plan_id']}|${s['local_day']}': s['streak_after'] as int,
      };
      for (final s in sessions) {
        final prev = dayString(
          DateTime.parse('${s['local_day']}T00:00:00Z'),
          -1,
        );
        expect(s['streak_after'], (byKey['${s['plan_id']}|$prev'] ?? 0) + 1);
      }
    });

    test('Akte und Termine: Termine gehören dem Hauptphysio (bearbeitbar)', () {
      final patients = {for (final p in _rows(plan, 'patients')) p['id']: p};
      expect(_rows(plan, 'treaters'), isNotEmpty);
      expect(_rows(plan, 'history_entries'), isNotEmpty);
      final appointments = _rows(plan, 'appointments');
      expect(appointments.map((a) => a['patient_id']).toSet(), hasLength(5));
      for (final a in appointments) {
        expect(a['created_by_role'], 'physio');
        expect(
          (a['created_by']! as PhysioRef).key,
          (patients[a['patient_id']]!['main_physio_id']! as PhysioRef).key,
        );
        expect(
          DateTime.parse(a['starts_at'] as String).isAfter(_today),
          isTrue,
        );
      }
    });

    test('alle IDs eindeutig; Verweise zwischen den Zeilen sind in sich stimmig (Fremdschlüssel)', () {
      final byTable = <String, Map<Object?, Row>>{};
      for (final s in plan.steps.whereType<UpsertRows>()) {
        final m = byTable.putIfAbsent(s.table, () => {});
        for (final r in s.rows) {
          expect(
            m.containsKey(r['id']),
            isFalse,
            reason: 'doppelte ID in ${s.table}',
          );
          m[r['id']] = r;
        }
      }
      final allIds = [for (final m in byTable.values) ...m.keys];
      expect(
        allIds.toSet().length,
        allIds.length,
        reason: 'IDs auch tabellenübergreifend eindeutig',
      );
      Row ref(String table, Object? id, String from) {
        final r = byTable[table]?[id];
        expect(
          r,
          isNotNull,
          reason: '$from verweist auf fehlende Zeile in $table',
        );
        return r!;
      }

      for (final p in byTable['patients']!.values) {
        ref('practices', p['practice_id'], 'patient');
      }
      for (final i in byTable['injuries']!.values) {
        ref('patients', i['patient_id'], 'injury');
      }
      for (final pl in byTable['plans']!.values) {
        final inj = ref('injuries', pl['injury_id'], 'plan');
        expect(inj['patient_id'], pl['patient_id']);
        expect(pl['closed'], inj['closed_on'] != null);
      }
      for (final ph in byTable['phases']!.values) {
        ref('plans', ph['plan_id'], 'phase');
      }
      for (final it in byTable['plan_items']!.values) {
        final ph = ref('phases', it['phase_id'], 'item');
        expect(ph['plan_id'], it['plan_id']);
        final ex = ref('exercises', it['exercise_id'], 'item');
        final plan = ref('plans', it['plan_id'], 'item');
        final patient = ref('patients', plan['patient_id'], 'plan');
        expect(
          ex['practice_id'] == null ||
              ex['practice_id'] == patient['practice_id'],
          isTrue,
        );
        if (it['release_with_phase_id'] != null) {
          expect(
            ref('phases', it['release_with_phase_id'], 'item')['plan_id'],
            it['plan_id'],
          );
        }
        final prepared = it['release'] == 'prepared';
        expect(
          prepared
              ? (it['release_on'] == null) !=
                    (it['release_with_phase_id'] == null)
              : true,
          isTrue,
        );
      }
      for (final s in byTable['training_sessions']!.values) {
        final pl = ref('plans', s['plan_id'], 'session');
        expect(pl['patient_id'], s['patient_id']);
        expect(
          ref('phases', s['phase_id'], 'session')['plan_id'],
          s['plan_id'],
        );
      }
      for (final r in byTable['exercise_results']!.values) {
        final s = ref('training_sessions', r['training_session_id'], 'result');
        expect(s['patient_id'], r['patient_id']);
        expect(s['local_day'], r['local_day']);
        ref('plan_items', r['plan_item_id'], 'result');
      }
      for (final a in byTable['appointments']!.values) {
        if (a['treater_id'] != null) {
          expect(
            ref('treaters', a['treater_id'], 'appointment')['patient_id'],
            a['patient_id'],
          );
        }
      }
    });

    test('Zeilen eines Schritts haben dieselben Spalten (Voraussetzung für Bulk-Upsert)', () {
      for (final s in plan.steps.whereType<UpsertRows>()) {
        final keys = s.rows.first.keys.toSet();
        for (final r in s.rows) {
          expect(r.keys.toSet(), keys, reason: s.table);
        }
      }
    });

    test('Reihenfolge: Eltern vor Kindern, Einladungen am Ende, Physio-Konten nach Praxen', () {
      final order = [
        for (final s in plan.steps)
          s is UpsertRows ? s.table : s.runtimeType.toString(),
      ];
      int idx(String t) => order.indexOf(t);
      expect(idx('practices'), 0);
      expect(idx('CreatePhysioAccount'), lessThan(idx('patients')));
      for (final pair in const [
        ['patients', 'injuries'],
        ['injuries', 'plans'],
        ['plans', 'phases'],
        ['phases', 'plan_items'],
        ['exercises', 'plan_items'],
        ['plan_items', 'training_sessions'],
        ['training_sessions', 'exercise_results'],
        ['treaters', 'appointments'],
      ]) {
        expect(
          idx(pair[0]),
          lessThan(idx(pair[1])),
          reason: '${pair[0]} vor ${pair[1]}',
        );
      }
      expect(plan.steps.last, isA<PhysioRpc>());
      expect(plan.steps.whereType<PhysioRpc>(), hasLength(5));
    });

    test(
      'Plan ist deterministisch; anderer Bezugstag verschiebt nur Datumswerte',
      () {
        String dump(SeedPlan p) => jsonEncode([
          for (final s in p.steps)
            if (s is UpsertRows) {'t': s.table, 'rows': s.rows, 'sql': ''},
        ], toEncodable: (o) => o.toString());
        expect(dump(_plan()), dump(_plan()));
        final later = _plan(today: DateTime.utc(2026, 11, 2));
        expect(
          _rows(later, 'patients').map((p) => p['id']),
          _rows(plan, 'patients').map((p) => p['id']),
        );
        expect(
          _rows(later, 'plan_items').map((p) => p['id']),
          _rows(plan, 'plan_items').map((p) => p['id']),
        );
        expect(
          _rows(later, 'training_sessions').first['local_day'],
          isNot(_rows(plan, 'training_sessions').first['local_day']),
        );
      },
    );
  });

  group('Validierung der Testdaten', () {
    void expectInvalid(
      String name,
      void Function(Map<String, dynamic> d) mutate, [
      String? fragment,
    ]) {
      test(name, () {
        final d = _copy();
        mutate(d);
        expect(
          () => buildSeedPlan(d, today: _today),
          throwsA(
            isA<SeedDataException>().having(
              (e) => e.message,
              'message',
              contains(fragment ?? ''),
            ),
          ),
        );
      });
    }

    expectInvalid(
      'echte Domain statt .invalid',
      (d) => (d['meta'] as Map)['email_domain'] = 'example.com',
      '.invalid',
    );
    expectInvalid(
      'Praxisname ohne Kennzeichnung',
      (d) => ((d['praxen'] as List).first as Map)['name'] = 'Praxis Nord',
      'Testdaten',
    );
    expectInvalid('unbekannte Übung', (d) {
      final plan = _patient(d, 'lena')['plan'] as Map;
      (((plan['phasen'] as List).first as Map)['positionen'] as List)
              .first['uebung'] =
          'gibt_es_nicht';
    }, 'gibt_es_nicht');
    expectInvalid('Übung einer fremden Praxis', (d) {
      final plan = _patient(d, 'lena')['plan'] as Map;
      (((plan['phasen'] as List).first as Map)['positionen'] as List)
              .first['uebung'] =
          'sued_eigene';
    }, 'sued_eigene');
    expectInvalid(
      'Hauptphysio aus anderer Praxis',
      (d) => _patient(d, 'lena')['hauptphysio'] = 'sued_1',
      'Hauptphysio',
    );
    expectInvalid('zwei Freigaben an einer Position', (d) {
      final plan = _patient(d, 'lena')['plan'] as Map;
      final pos = ((plan['phasen'] as List)[1] as Map)['positionen'] as List;
      (pos.firstWhere((p) => (p as Map)['key'] == 'beinpresse')
              as Map)['freigabe_am_tag'] =
          3;
    }, 'zwei Freigaben');
    expectInvalid('Variante verweist auf Variante', (d) {
      final plan = _patient(d, 'lena')['plan'] as Map;
      final pos = ((plan['phasen'] as List)[1] as Map)['positionen'] as List;
      (pos.firstWhere((p) => (p as Map)['key'] == 'ausfallschritt')
              as Map)['leichter'] =
          'kniebeuge';
    }, 'Variante');
    expectInvalid('übersprungene Position gehört nicht zur Einheit', (d) {
      final t = (_patient(d, 'lena')['training'] as List).first as Map;
      ((t['uebersprungen'] as List).first as Map)['positionen'] = ['bruecke'];
    }, 'bruecke');
    expectInvalid(
      'Training heute statt bis gestern',
      (d) =>
          ((_patient(d, 'lena')['training'] as List).first as Map)['bis'] = 0,
      'gestern',
    );
    expectInvalid(
      'doppelter Patientenschlüssel',
      (d) => _patient(d, 'jonas')['key'] = 'lena',
      'doppelt',
    );
    expectInvalid(
      'Katalogübung mit unbekanntem Ort',
      (d) => ((d['katalog'] as List).first as Map)['orte'] = ['mars'],
      'Ort',
    );
    expectInvalid(
      'Uhrzeit ungültig',
      (d) => ((_patient(d, 'lena')['termine'] as List).first as Map)['zeit'] =
          '25:99',
      'HH:MM',
    );
  });

  group('Ablauf mit Aufzeichnungs-Backend', () {
    test('Reset zuerst, dann die Schritte in Planreihenfolge; Codes kommen aus den Einladungen', () async {
      final plan = _plan();
      final b = _RecordingBackend();
      final report = await runSeed(plan, b);
      expect(b.calls.first, 'reset:test.curaone.invalid');
      expect(
        b.calls.skip(1).where((c) => c.startsWith('physio:')),
        hasLength(4),
      );
      expect(b.calls.last, startsWith('rpc:regenerate_invitation:'));
      expect(report.invitations, hasLength(5));
      expect(report.invitations.first.subject, contains('Testperson'));
      expect(report.rowCounts['training_sessions'], greaterThan(40));
    });

    test('reset: false überspringt den Reset', () async {
      final b = _RecordingBackend();
      await runSeed(_plan(), b, reset: false);
      expect(b.calls.any((c) => c.startsWith('reset')), isFalse);
    });

    test('Reset-Reihenfolge der Tabellen hält Fremdschlüssel ein', () {
      int i(String t) => patientScopedTables.indexOf(t);
      expect(i('exercise_results'), lessThan(i('training_sessions')));
      expect(i('training_sessions'), lessThan(i('plans')));
      expect(i('plans'), lessThan(i('injuries')));
      expect(i('appointments'), lessThan(i('treaters')));
      expect(
        patientScopedTables,
        isNot(contains('patients')),
        reason: 'Patienten löscht der Reset danach',
      );
    });
  });

  group('SQL-Ausgabe (lokales Postgres mit Nachbildung)', () {
    late String sql;
    setUp(() async => sql = await renderSeedSql(_plan()));

    test('Reset trifft nur Testpraxen und Testkonten, vor dem Anlegen', () {
      final reset = sql.substring(
        0,
        sql.indexOf('INSERT INTO public.practices'),
      );
      expect(reset, contains('WHERE is_test'));
      expect(reset, contains("email LIKE '%@test.curaone.invalid'"));
      expect(reset, contains('DELETE FROM public.practices WHERE is_test;'));
      expect(
        RegExp(
          r'DELETE FROM public\.\w+ WHERE (?!patient_id IN|id IN|practice_id IN|is_test)',
        ).hasMatch(reset),
        isFalse,
        reason: 'jeder Löschbefehl ist auf Testdaten eingegrenzt',
      );
      expect(
        reset.indexOf('DELETE FROM public.patients'),
        lessThan(reset.indexOf('DELETE FROM public.practices')),
      );
    });

    test(
      'läuft als service_role bzw. als Test-Physio und endet ohne Rollenrest',
      () {
        expect(sql, contains('SET ROLE service_role;'));
        expect(sql, contains('SET ROLE authenticated;'));
        expect(sql, contains('regenerate_invitation'));
        expect(
          sql.trimRight(),
          endsWith("SELECT set_config('request.jwt.claims', '', false) \\gset"),
        );
      },
    );

    test(
      'enthält keine Schlüssel, keine Passwörter, keine echten Adressen',
      () {
        expect(sql, isNot(matches(RegExp(r'eyJ[A-Za-z0-9_-]{20,}'))));
        expect(sql.toLowerCase(), isNot(contains('password')));
        expect(sql.toLowerCase(), isNot(contains('apikey')));
        expect(
          RegExp(r'[\w.]+@[\w.]+')
              .allMatches(sql)
              .map((m) => m[0]!)
              .where(
                (e) =>
                    !e.endsWith('@test.curaone.invalid') && !e.startsWith('%@'),
              ),
          isEmpty,
        );
      },
    );

    test('Quoting: Apostroph und JSON bleiben gültig', () {
      expect(sqlQuote("O'Brien"), "'O''Brien'");
      expect(sqlLiteral(null), 'NULL');
      expect(sqlLiteral(true), 'true');
      expect(sqlLiteral(3), '3');
      expect(sqlLiteral({'a': "x'y"}), "'{\"a\":\"x''y\"}'::jsonb");
      expect(() => sqlQuote('a\u0000b'), throwsArgumentError);
    });
  });

  group('Kommandozeile', () {
    Future<(int, String, String)> run(
      List<String> args,
      Map<String, String> env, {
      BackendFactory? factory,
    }) async {
      final out = StringBuffer();
      final err = StringBuffer();
      final code = await runSeedCli(
        args,
        env,
        out: out,
        err: err,
        defaultDataPath: _dataPath,
        backendFactory: factory,
        now: _today,
      );
      return (code, out.toString(), err.toString());
    }

    const secret = 'SERVICE-KEY-NUR-IM-TEST-12345678901234567890';
    final env = {
      'SUPABASE_URL': 'http://127.0.0.1:54321',
      'SUPABASE_SERVICE_ROLE_KEY': secret,
    };

    test('fehlende Umgebung: klare Meldung, Exit 2, kein Backend', () async {
      var created = false;
      final (code, out, err) = await run(
        ['--target', 'local'],
        {},
        factory: (u, k, p) {
          created = true;
          return _RecordingBackend();
        },
      );
      expect(code, 2);
      expect(created, isFalse);
      expect(err, contains('SUPABASE_URL'));
      expect(err, contains('SUPABASE_SERVICE_ROLE_KEY'));
      expect(out, isEmpty);
    });

    test('nur eine Variable fehlt: genau diese wird genannt', () async {
      final (code, _, err) = await run(
        ['--target', 'local'],
        {'SUPABASE_URL': 'http://localhost:54321'},
      );
      expect(code, 2);
      expect(err, contains('SUPABASE_SERVICE_ROLE_KEY'));
      expect(err, isNot(contains('fehlen: SUPABASE_URL')));
    });

    test('ohne --target Exit 2; unbekannte Option Exit 2', () async {
      expect((await run([], env)).$1, 2);
      expect((await run(['--target', 'local', '--unsinn'], env)).$1, 2);
      expect((await run(['--target', 'mond'], env)).$1, 2);
    });

    test('--target local mit entfernter URL wird abgelehnt', () async {
      final (code, _, err) = await run(
        ['--target', 'local'],
        {...env, 'SUPABASE_URL': 'https://abc.supabase.co'},
      );
      expect(code, 2);
      expect(err, contains('localhost'));
    });

    test('--target remote verlangt https und --confirm-remote', () async {
      final remote = {...env, 'SUPABASE_URL': 'https://abc.supabase.co'};
      final (c1, _, e1) = await run(['--target', 'remote'], remote);
      expect(c1, 2);
      expect(e1, contains('--confirm-remote'));
      final (c2, _, e2) = await run(
        ['--target', 'remote', '--confirm-remote'],
        {...env, 'SUPABASE_URL': 'http://abc.example'},
      );
      expect(c2, 2);
      expect(e2, contains('https'));
    });

    test('Lauf mit Aufzeichnungs-Backend: Exit 0, Codes und Konten auf der Konsole, kein Schlüssel', () async {
      final b = _RecordingBackend();
      String? seenKey;
      String? seenPassword;
      final (code, out, err) = await run(
        ['--target', 'local'],
        env,
        factory: (u, k, p) {
          seenKey = k;
          seenPassword = p;
          return b;
        },
      );
      expect(code, 0, reason: err);
      expect(seenKey, secret);
      expect(
        seenPassword,
        hasLength(20),
        reason: 'ohne CURAONE_SEED_PASSWORD wird ein Zufallspasswort erzeugt',
      );
      expect(out, contains('ABCDE12345'));
      expect(out, contains('nord1@test.curaone.invalid'));
      expect(out, contains('Lena (Testperson)'));
      expect(out, isNot(contains(secret)));
      expect(err, isNot(contains(secret)));
      expect(b.closed, isTrue);
      expect(b.calls.first, startsWith('reset'));
    });

    test('CURAONE_SEED_PASSWORD wird verwendet und nicht ausgegeben', () async {
      String? seen;
      final (code, out, _) = await run(
        ['--target', 'local'],
        {...env, 'CURAONE_SEED_PASSWORD': 'mein-test-passwort'},
        factory: (u, k, p) {
          seen = p;
          return _RecordingBackend();
        },
      );
      expect(code, 0);
      expect(seen, 'mein-test-passwort');
      expect(out, isNot(contains('mein-test-passwort')));
    });

    test('zu kurzes Passwort bricht ab', () async {
      final (code, _, err) = await run(
        ['--target', 'local'],
        {...env, 'CURAONE_SEED_PASSWORD': 'kurz'},
      );
      expect(code, 2);
      expect(err, contains('zu kurz'));
    });

    test('Fehler im Backend: Exit 1, Schlüssel wird aus der Meldung entfernt, Backend geschlossen', () async {
      final b = _FailingBackend('Zugriff mit $secret verweigert');
      final (code, _, err) = await run(
        ['--target', 'local'],
        env,
        factory: (u, k, p) => b,
      );
      expect(code, 1);
      expect(err, contains('Seed fehlgeschlagen'));
      expect(err, isNot(contains(secret)));
      expect(b.closed, isTrue);
    });

    test('--reset-only ruft nur den Reset auf', () async {
      final b = _RecordingBackend();
      final (code, out, _) = await run(
        ['--target', 'local', '--reset-only'],
        env,
        factory: (u, k, p) => b,
      );
      expect(code, 0);
      expect(b.calls, ['reset:test.curaone.invalid']);
      expect(out, contains('Reset abgeschlossen'));
    });

    test(
      '--dry-run und --emit-sql brauchen weder Umgebung noch Backend',
      () async {
        final (c1, o1, _) = await run(['--dry-run'], {});
        expect(c1, 0);
        expect(o1, contains('patients'));
        expect(o1, contains('Test-Physios'));
        final (c2, o2, _) = await run(['--emit-sql'], {});
        expect(c2, 0);
        expect(o2, contains('INSERT INTO public.practices'));
      },
    );

    test('--help liefert die Hilfe mit Exit 0', () async {
      final (code, out, _) = await run(['--help'], {});
      expect(code, 0);
      expect(out, contains('--confirm-remote'));
    });

    test('--today wird geprüft und verschiebt den Bezugstag', () async {
      expect((await run(['--dry-run', '--today', 'gestern'], {})).$1, 2);
      final (_, a, _) = await run(['--emit-sql', '--today', '2026-01-10'], {});
      final (_, b, _) = await run(['--emit-sql', '--today', '2026-01-11'], {});
      expect(a, isNot(b));
    });
  });

  group('Repository-Hygiene', () {
    test('keine Schlüssel oder Passwörter in tool/seed', () {
      final files = Directory('tool/seed').listSync().whereType<File>();
      expect(files, isNotEmpty);
      for (final f in files) {
        final text = f.readAsStringSync();
        expect(
          text,
          isNot(matches(RegExp(r'eyJ[A-Za-z0-9_-]{30,}'))),
          reason: f.path,
        );
        expect(
          text,
          isNot(matches(RegExp(r'sb_secret_[A-Za-z0-9_-]{10,}'))),
          reason: f.path,
        );
        expect(
          text,
          isNot(
            matches(
              RegExp(
                r'(service_role_key|SERVICE_ROLE_KEY)\s*=\s*[\x27"][^\x27"$]+[\x27"]',
              ),
            ),
          ),
          reason: f.path,
        );
      }
    });

    test('pubspec: supabase nur als Dev-Abhängigkeit mit fester Version', () {
      final text = File('pubspec.yaml').readAsStringSync();
      final dev = text.substring(
        text.indexOf('dev_dependencies:'),
        text.indexOf('flutter:\n  uses-material-design'),
      );
      expect(dev, matches(RegExp(r'\n  supabase: \d+\.\d+\.\d+\n')));
      final deps = text.substring(
        text.indexOf('dependencies:'),
        text.indexOf('dev_dependencies:'),
      );
      expect(deps, isNot(contains('supabase')));
    });
  });
}

class _FailingBackend extends _RecordingBackend {
  _FailingBackend(this.message);
  final String message;
  @override
  Future<void> resetTestData(String emailDomain) async =>
      throw StateError(message);
}
