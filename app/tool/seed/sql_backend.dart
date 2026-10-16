// SQL-Ausgabe des Seed-Plans fuer das lokale Postgres mit Supabase-Nachbildung
// (supabase/tests/shim/). Nur fuer Wegwerf-Datenbanken: legt Konten direkt in auth.users der
// Nachbildung an (der echte Stack nutzt die Auth-Admin-API, supabase_backend.dart).
//
// Ablauf der Ausgabe: Sitzung service_role (wie der echte Seed, prueft damit die Rechte), fuer
// Funktionsaufrufe Sitzung authenticated mit JWT-Claims des Test-Physios.

import 'dart:convert';

import 'seed_backend.dart';
import 'seed_plan.dart';
import 'stable_ids.dart';

String sqlQuote(String s) {
  if (s.contains('\u0000')) throw ArgumentError('NUL im Text');
  return "'${s.replaceAll("'", "''")}'";
}

Object? _resolve(Object? v) {
  if (v is PhysioRef) return stableId('physio:${v.key}');
  if (v is Map) {
    return {for (final e in v.entries) e.key as String: _resolve(e.value)};
  }
  if (v is List) return [for (final e in v) _resolve(e)];
  return v;
}

String sqlLiteral(Object? v) {
  final r = _resolve(v);
  if (r == null) return 'NULL';
  if (r is bool) return r ? 'true' : 'false';
  if (r is num) return '$r';
  if (r is String) return sqlQuote(r);
  return '${sqlQuote(jsonEncode(r))}::jsonb';
}

class SqlScriptBackend implements SeedBackend {
  final StringBuffer out = StringBuffer();

  void _line(String s) => out.writeln(s);

  @override
  Future<void> resetTestData(String emailDomain) async {
    final suffix = '@${emailDomain.toLowerCase()}';
    // Endungsvergleich ohne LIKE-Platzhalterwirkung (Unterstrich/Prozent in der Domain)
    String isTestUser(String col) =>
        'right(lower($col), ${suffix.length}) = ${sqlQuote(suffix)}';
    const testPractices = 'SELECT id FROM public.practices WHERE is_test';
    const testPatients =
        'SELECT id FROM public.patients WHERE practice_id IN ($testPractices)';
    final testUsers =
        'SELECT u.id FROM auth.users u WHERE ${isTestUser('u.email')}';
    const testExercises =
        'SELECT id FROM public.exercises WHERE practice_id IN ($testPractices)';
    _line('-- Reset: nur Praxen mit is_test und Konten mit der Testdomain');
    _line('SET ROLE service_role;');
    // Schutzpruefung vor dem ersten Loeschen (in beide Richtungen, siehe SeedGuardException)
    _line(
      'DO \$guard\$\n'
      'DECLARE v text := \'\';\n'
      'BEGIN\n'
      '  IF EXISTS (SELECT 1 FROM public.physios ph\n'
      '              WHERE ph.practice_id IN ($testPractices)\n'
      '                AND ph.id NOT IN ($testUsers)) THEN\n'
      "    v := v || 'Physio in einer Testpraxis ohne Testkonto; ';\n"
      '  END IF;\n'
      '  IF EXISTS (SELECT 1 FROM public.physios ph\n'
      '              WHERE ph.id IN ($testUsers)\n'
      '                AND ph.practice_id NOT IN ($testPractices)) THEN\n'
      "    v := v || 'Testkonto ist Physio in einer Praxis ohne is_test; ';\n"
      '  END IF;\n'
      '  IF EXISTS (SELECT 1 FROM public.patients p\n'
      '              WHERE p.practice_id NOT IN ($testPractices)\n'
      '                AND (p.main_physio_id IN ($testUsers)\n'
      '                     OR p.auth_user_id IN ($testUsers))) THEN\n'
      "    v := v || 'Patient ausserhalb der Testpraxen hat ein Testkonto als Hauptphysio oder Konto; ';\n"
      '  END IF;\n'
      '  IF EXISTS (SELECT 1 FROM public.plan_items pi\n'
      '               JOIN public.plans pl ON pl.id = pi.plan_id\n'
      '              WHERE pi.exercise_id IN ($testExercises)\n'
      '                AND pl.patient_id NOT IN ($testPatients)) THEN\n'
      "    v := v || 'Plan ausserhalb der Testpraxen nutzt eine Uebung einer Testpraxis (RESTRICT); ';\n"
      '  END IF;\n'
      '  IF EXISTS (SELECT 1 FROM public.plan_templates t\n'
      '              WHERE (t.practice_id IS NULL OR t.practice_id NOT IN ($testPractices))\n'
      '                AND EXISTS (SELECT 1 FROM public.exercises e\n'
      '                             WHERE e.practice_id IN ($testPractices)\n'
      "                               AND strpos(t.payload::text, e.id::text) > 0)) THEN\n"
      "    v := v || 'Vorlage ausserhalb der Testpraxen verweist auf eine Uebung einer Testpraxis; ';\n"
      '  END IF;\n'
      "  IF v <> '' THEN\n"
      "    RAISE EXCEPTION 'Reset abgebrochen, nichts geloescht (Schutzpruefung): %', v;\n"
      '  END IF;\n'
      'END \$guard\$;',
    );
    for (final t in patientScopedTables) {
      _line('DELETE FROM public.$t WHERE patient_id IN ($testPatients);');
    }
    _line('DELETE FROM public.patients WHERE id IN ($testPatients);');
    _line('DELETE FROM auth.users WHERE ${isTestUser('email')};');
    for (final t in ['physios', 'exercises', 'plan_templates']) {
      _line('DELETE FROM public.$t WHERE practice_id IN ($testPractices);');
    }
    _line('DELETE FROM public.practices WHERE is_test;');
    _line('RESET ROLE;');
  }

  @override
  Future<void> createPhysioAccount(CreatePhysioAccount s) async {
    final id = stableId('physio:${s.key}');
    _line('SET ROLE service_role;');
    _line(
      'INSERT INTO auth.users (id, email) VALUES (${sqlQuote(id)}, ${sqlQuote(s.email)}) '
      'ON CONFLICT (id) DO NOTHING;',
    );
    _line(
      'INSERT INTO public.physios (id, practice_id, display_name) VALUES '
      '(${sqlQuote(id)}, ${sqlQuote(s.practiceId)}, ${sqlQuote(s.displayName)}) '
      'ON CONFLICT (id) DO UPDATE SET practice_id = EXCLUDED.practice_id, display_name = EXCLUDED.display_name;',
    );
    _line('RESET ROLE;');
  }

  @override
  Future<void> upsert(UpsertRows s) async {
    final cols = s.rows.first.keys.toList();
    final colList = cols.map((c) => '"$c"').join(', ');
    final json = jsonEncode([for (final r in s.rows) _resolve(r)]);
    final updates = cols
        .where((c) => c != 'id')
        .map((c) => '"$c" = EXCLUDED."$c"')
        .join(', ');
    _line('SET ROLE service_role;');
    _line(
      'INSERT INTO public.${s.table} ($colList) '
      'SELECT $colList FROM jsonb_populate_recordset(NULL::public.${s.table}, ${sqlQuote(json)}::jsonb) '
      'ON CONFLICT (${s.conflict}) DO UPDATE SET $updates;',
    );
    _line('RESET ROLE;');
  }

  @override
  Future<void> update(UpdateRows s) async {
    final set = s.values.entries
        .map((e) => '"${e.key}" = ${sqlLiteral(e.value)}')
        .join(', ');
    final where = s.where.entries
        .map((e) => '"${e.key}" = ${sqlLiteral(e.value)}')
        .join(' AND ');
    _line('SET ROLE service_role;');
    _line('UPDATE public.${s.table} SET $set WHERE $where;');
    _line('RESET ROLE;');
  }

  @override
  Future<Row?> physioRpc(PhysioRpc s) async {
    final uid = stableId('physio:${s.physioKey}');
    final claims = jsonEncode({'sub': uid, 'role': 'authenticated'});
    final args = s.params.entries
        .map((e) => '${e.key} => ${sqlLiteral(e.value)}')
        .join(', ');
    _line('RESET ROLE;');
    _line(
      "SELECT set_config('request.jwt.claims', ${sqlQuote(claims)}, false) \\gset",
    );
    _line('SET ROLE authenticated;');
    _line(
      "SELECT format('EINLADUNG %s %s', ${sqlQuote(s.subject)}, code) FROM public.${s.fn}($args);",
    );
    _line('RESET ROLE;');
    _line("SELECT set_config('request.jwt.claims', '', false) \\gset");
    // Lokal gibt es keine Antwortzeile; der Code erscheint in der psql-Ausgabe (nur Konsole).
    return {'code': '(siehe psql-Ausgabe)', 'expires_at': ''};
  }

  @override
  Future<void> close() async {}
}

/// Gesamtes SQL-Skript (mit `psql -1`, Einzeltransaktion, ausfuehren).
Future<String> renderSeedSql(SeedPlan plan) async {
  final b = SqlScriptBackend();
  b.out.writeln(
    '-- Testdaten-Seed (erzeugt von app/tool/seed/seed.dart --emit-sql).',
  );
  b.out.writeln(
    '-- NUR fuer eine Wegwerf-Datenbank mit Supabase-Nachbildung (supabase/tests/shim/).',
  );
  await runSeed(plan, b);
  return b.out.toString();
}
