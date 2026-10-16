// Ausfuehrung des Seed-Plans ueber die Supabase-API (lokaler Stack oder Projekt), hinter der
// Schnittstelle SeedGateway (seed_gateway.dart). Schluessel nur aus der Umgebung (seed_cli.dart).
//
// Reset: erst Schutzpruefung (ohne jede Aenderung), dann Loeschen.
// Blaettern: PostgREST-Abfragen per Keyset (order id, id > letzte id), Ende erst bei leerer
// Seite. Eine vom Server gekappte Seite (max_rows < pageSize) fuehrt daher nie zu einem stillen
// Ende, und gleichzeitiges Loeschen verschiebt keine Offsets. GoTrue listUsers kennt nur Offset:
// die Konten werden so lange eingelesen, bis zwei vollstaendige Durchlaeufe dieselben Testkonten
// liefern; nach dem Loeschen prueft ein weiterer Durchlauf, dass keines uebrig ist.

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

  /// Alle Zeilen per Keyset-Blaettern (auch IN-Listen in Teilstuecken). Ende nur bei leerer Seite.
  Future<List<Row>> _all(
    String table,
    String columns, {
    Row? eq,
    String? inColumn,
    List<String>? inValues,
  }) async {
    if (!columns.split(',').contains('id')) {
      throw ArgumentError('columns muss id enthalten: $columns');
    }
    final out = <Row>[];
    final parts = inColumn == null
        ? <List<String>?>[null]
        : [for (final c in _chunks(inValues!)) c];
    for (final part in parts) {
      String? after;
      for (;;) {
        final page = await gateway.selectPage(
          table,
          columns,
          eq: eq,
          inColumn: inColumn,
          inValues: part,
          afterId: after,
          limit: pageSize,
        );
        if (page.isEmpty) break;
        out.addAll(page);
        final last = page.last['id'];
        if (last is! String || last == after) {
          throw StateError('Blaettern in $table: keine fortschreitende id');
        }
        after = last;
      }
    }
    return out;
  }

  List<String> _ids(List<Row> rows, [String col = 'id']) => [
    for (final r in rows) r[col]! as String,
  ];

  /// Alle Konten per Offset (nur so abrufbar); Ende = leere Seite.
  Future<List<AuthUserInfo>> _scanUsers() async {
    const perPage = 200;
    final users = <AuthUserInfo>[];
    for (var page = 1; ; page++) {
      final batch = await gateway.listUsersPage(page, perPage);
      if (batch.isEmpty) break;
      users.addAll(batch);
    }
    return users;
  }

  bool _isTestUser(AuthUserInfo u, String suffix) =>
      (u.email ?? '').toLowerCase().endsWith(suffix);

  /// Testkonten, stabil gegen gleichzeitiges Loeschen: wiederholt einlesen, bis zwei
  /// vollstaendige Durchlaeufe dieselbe Menge liefern (sonst haette ein Offset-Versatz Konten
  /// uebersprungen). Bricht nach [maxScans] Durchlaeufen laut ab.
  Future<List<AuthUserInfo>> _stableTestUsers(String suffix) async {
    const maxScans = 5;
    Set<String>? previous;
    for (var i = 0; i < maxScans; i++) {
      final users = [
        for (final u in await _scanUsers())
          if (_isTestUser(u, suffix)) u,
      ];
      final ids = {for (final u in users) u.id};
      if (previous != null &&
          previous.length == ids.length &&
          previous.containsAll(ids)) {
        return users;
      }
      previous = ids;
    }
    throw StateError(
      'Konten aendern sich waehrend des Einlesens (kein stabiler Durchlauf '
      'nach $maxScans Versuchen); Reset abgebrochen, nichts geloescht',
    );
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
          // UUIDs sind in JSON-Text beliebig geschrieben: ohne Gross-/Kleinschreibung vergleichen
          final text = jsonEncode(t['payload']).toLowerCase();
          return exIds.any((id) => text.contains(id.toLowerCase()));
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
    final testUsers = await _stableTestUsers(suffix);
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
    // Nachpruefung: kein Testkonto darf uebrig sein (laut abbrechen statt still weiterzumachen)
    final left = [
      for (final u in await _scanUsers())
        if (_isTestUser(u, suffix)) u,
    ];
    if (left.isNotEmpty) {
      throw StateError(
        'Reset unvollstaendig: ${left.length} Testkonto/-konten nach dem Loeschen '
        'noch vorhanden; Reset erneut ausfuehren',
      );
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
