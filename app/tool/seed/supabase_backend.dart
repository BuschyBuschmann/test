// Ausfuehrung des Seed-Plans ueber die Supabase-API (lokaler Stack oder Projekt), hinter der
// Schnittstelle SeedGateway (seed_gateway.dart). Schluessel nur aus der Umgebung (seed_cli.dart).
//
// Reset: erst Schutzpruefung (ohne jede Aenderung), dann Loeschen. Alle Abfragen blaettern in
// Seiten von [pageSize] Zeilen (muss <= max_rows des Projekts sein, Standard 1000) und sind damit
// nicht an max_rows gebunden.

import 'dart:convert';

import 'seed_backend.dart';
import 'seed_gateway.dart';
import 'seed_plan.dart';

class SupabaseSeedBackend implements SeedBackend {
  SupabaseSeedBackend({
    required this.gateway,
    required this.physioPassword,
    this.pageSize = 100,
    this.inChunk = 100,
  });

  final SeedGateway gateway;
  final String physioPassword;
  final int pageSize;
  final int inChunk;
  final Map<String, String> _physioIds = {};
  final Map<String, String> _physioEmails = {};

  Object? _resolve(Object? v) {
    if (v is PhysioRef) {
      final id = _physioIds[v.key];
      if (id == null) {
        throw StateError('Physio "${v.key}" wurde noch nicht angelegt');
      }
      return id;
    }
    if (v is Map) {
      return {for (final e in v.entries) e.key as String: _resolve(e.value)};
    }
    if (v is List) return [for (final e in v) _resolve(e)];
    return v;
  }

  Iterable<List<T>> _chunks<T>(List<T> l) sync* {
    for (var i = 0; i < l.length; i += inChunk) {
      yield l.sublist(i, i + inChunk > l.length ? l.length : i + inChunk);
    }
  }

  /// Alle Zeilen, seitenweise (auch IN-Listen in Teilstuecken).
  Future<List<Row>> _all(
    String table,
    String columns, {
    Row? eq,
    String? inColumn,
    List<String>? inValues,
  }) async {
    final out = <Row>[];
    final parts = inColumn == null
        ? <List<String>?>[null]
        : [for (final c in _chunks(inValues!)) c];
    for (final part in parts) {
      for (var from = 0; ; from += pageSize) {
        final page = await gateway.selectPage(
          table,
          columns,
          eq: eq,
          inColumn: inColumn,
          inValues: part,
          from: from,
          to: from + pageSize - 1,
        );
        out.addAll(page);
        if (page.length < pageSize) break;
      }
    }
    return out;
  }

  List<String> _ids(List<Row> rows, [String col = 'id']) => [
    for (final r in rows) r[col]! as String,
  ];

  Future<List<AuthUserInfo>> _allUsers() async {
    const perPage = 200;
    final users = <AuthUserInfo>[];
    for (var page = 1; ; page++) {
      final batch = await gateway.listUsersPage(page, perPage);
      users.addAll(batch);
      if (batch.length < perPage) break;
    }
    return users;
  }

  /// Schutzpruefung vor dem ersten Loeschen: liefert alle Verletzungen (leer = unbedenklich).
  Future<List<String>> _guard({
    required Set<String> practiceIds,
    required Set<String> testUserIds,
    required Set<String> testPatientIds,
  }) async {
    final v = <String>[];
    if (practiceIds.isNotEmpty) {
      final physios = await _all(
        'physios',
        'id,practice_id',
        inColumn: 'practice_id',
        inValues: practiceIds.toList(),
      );
      final n = physios.where((r) => !testUserIds.contains(r['id'])).length;
      if (n > 0) v.add('$n Physio(s) in einer Testpraxis ohne Testkonto');
    }
    if (testUserIds.isNotEmpty) {
      final asPhysio = await _all(
        'physios',
        'id,practice_id',
        inColumn: 'id',
        inValues: testUserIds.toList(),
      );
      final n1 = asPhysio
          .where((r) => !practiceIds.contains(r['practice_id']))
          .length;
      if (n1 > 0) {
        v.add('$n1 Testkonto/-konten sind Physio in einer Praxis ohne is_test');
      }
      final foreign = <String>{};
      for (final col in const ['main_physio_id', 'auth_user_id']) {
        final rows = await _all(
          'patients',
          'id,practice_id',
          inColumn: col,
          inValues: testUserIds.toList(),
        );
        for (final r in rows) {
          if (!practiceIds.contains(r['practice_id'])) {
            foreign.add(r['id']! as String);
          }
        }
      }
      if (foreign.isNotEmpty) {
        v.add(
          '${foreign.length} Patient(en) ausserhalb der Testpraxen haben ein '
          'Testkonto als Hauptphysio oder als Konto',
        );
      }
    }
    if (practiceIds.isNotEmpty) {
      final exIds = _ids(
        await _all(
          'exercises',
          'id',
          inColumn: 'practice_id',
          inValues: practiceIds.toList(),
        ),
      );
      if (exIds.isNotEmpty) {
        final items = await _all(
          'plan_items',
          'id,plan_id',
          inColumn: 'exercise_id',
          inValues: exIds,
        );
        final planIds = {for (final r in items) r['plan_id']! as String};
        if (planIds.isNotEmpty) {
          final plans = await _all(
            'plans',
            'id,patient_id',
            inColumn: 'id',
            inValues: planIds.toList(),
          );
          final n = plans
              .where((r) => !testPatientIds.contains(r['patient_id']))
              .length;
          if (n > 0) {
            v.add(
              '$n Plan/Plaene ausserhalb der Testpraxen nutzen eine Uebung einer '
              'Testpraxis (Position, ON DELETE RESTRICT)',
            );
          }
        }
        final templates = await _all(
          'plan_templates',
          'id,practice_id,payload',
        );
        final n = templates.where((t) {
          if (practiceIds.contains(t['practice_id'])) return false;
          final text = jsonEncode(t['payload']);
          return exIds.any(text.contains);
        }).length;
        if (n > 0) {
          v.add(
            '$n Vorlage(n) ausserhalb der Testpraxen verweisen auf eine Uebung '
            'einer Testpraxis',
          );
        }
      }
    }
    return v;
  }

  @override
  Future<void> resetTestData(String emailDomain) async {
    final suffix = '@${emailDomain.toLowerCase()}';
    final practiceIds = _ids(
      await _all('practices', 'id', eq: {'is_test': true}),
    );
    final testUsers = [
      for (final u in await _allUsers())
        if ((u.email ?? '').toLowerCase().endsWith(suffix)) u,
    ];
    final testUserIds = {for (final u in testUsers) u.id};
    final patientIds = practiceIds.isEmpty
        ? <String>[]
        : _ids(
            await _all(
              'patients',
              'id',
              inColumn: 'practice_id',
              inValues: practiceIds,
            ),
          );

    final violations = await _guard(
      practiceIds: practiceIds.toSet(),
      testUserIds: testUserIds,
      testPatientIds: patientIds.toSet(),
    );
    if (violations.isNotEmpty) {
      throw SeedGuardException(violations);
    }

    for (final table in patientScopedTables) {
      for (final c in _chunks(patientIds)) {
        await gateway.deleteRows(table, 'patient_id', c);
      }
    }
    for (final c in _chunks(patientIds)) {
      await gateway.deleteRows('patients', 'id', c);
    }
    for (final u in testUsers) {
      await gateway.deleteUser(u.id); // physios per ON DELETE CASCADE
    }
    if (practiceIds.isNotEmpty) {
      for (final table in const ['physios', 'exercises', 'plan_templates']) {
        for (final c in _chunks(practiceIds)) {
          await gateway.deleteRows(table, 'practice_id', c);
        }
      }
      for (final c in _chunks(practiceIds)) {
        await gateway.deleteRows('practices', 'id', c);
      }
    }
    _physioIds.clear();
    _physioEmails.clear();
  }

  @override
  Future<void> createPhysioAccount(CreatePhysioAccount step) async {
    final id = await gateway.createUser(step.email, physioPassword);
    _physioIds[step.key] = id;
    _physioEmails[step.key] = step.email;
    await gateway.upsertRows('physios', [
      {
        'id': id,
        'practice_id': step.practiceId,
        'display_name': step.displayName,
      },
    ], 'id');
  }

  @override
  Future<void> upsert(UpsertRows step) async {
    final rows = [
      for (final r in step.rows) _resolve(r)! as Map<String, Object?>,
    ];
    for (final c in _chunks(rows)) {
      await gateway.upsertRows(step.table, c, step.conflict);
    }
  }

  @override
  Future<void> update(UpdateRows step) async {
    await gateway.updateRows(
      step.table,
      _resolve(step.values)! as Row,
      _resolve(step.where)! as Row,
    );
  }

  @override
  Future<Row?> physioRpc(PhysioRpc step) async {
    final email = _physioEmails[step.physioKey];
    if (email == null) {
      throw StateError('Physio "${step.physioKey}" wurde noch nicht angelegt');
    }
    return gateway.rpcAsUser(
      email,
      physioPassword,
      step.fn,
      _resolve(step.params)! as Row,
    );
  }

  @override
  Future<void> close() => gateway.close();
}
