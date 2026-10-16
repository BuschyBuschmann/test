// Ausfuehrung des Seed-Plans ueber die Supabase-API (lokaler Stack oder Projekt).
//
// Der Service-Role-Schluessel kommt nur aus der Umgebung (siehe seed_cli.dart) und liegt hier
// nur im Speicher. Er wird nie ausgegeben oder gespeichert. Die Physio-Sitzungen fuer
// regenerate_invitation entstehen per E-Mail + Passwort; der Schluessel dient dort nur als
// apikey-Header, die Rolle bestimmt das Benutzer-JWT.

import 'package:supabase/supabase.dart';

import 'seed_backend.dart';
import 'seed_plan.dart';

class SupabaseSeedBackend implements SeedBackend {
  SupabaseSeedBackend({
    required this.url,
    required this.serviceRoleKey,
    required this.physioPassword,
  }) : admin = _client(url, serviceRoleKey);

  final String url;
  final String serviceRoleKey;
  final String physioPassword;
  final SupabaseClient admin;
  final Map<String, String> _physioIds = {};
  final Map<String, String> _physioEmails = {};
  final Map<String, SupabaseClient> _physioClients = {};

  static SupabaseClient _client(String url, String key) => SupabaseClient(
    url,
    key,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );

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

  static const int _chunk = 100;

  Iterable<List<T>> _chunks<T>(List<T> l) sync* {
    for (var i = 0; i < l.length; i += _chunk) {
      yield l.sublist(i, i + _chunk > l.length ? l.length : i + _chunk);
    }
  }

  List<String> _ids(List<dynamic> rows, [String col = 'id']) => [
    for (final r in rows) (r as Map)[col] as String,
  ];

  Future<List<User>> _allUsers() async {
    final users = <User>[];
    for (var page = 1; ; page++) {
      final batch = await admin.auth.admin.listUsers(page: page, perPage: 200);
      users.addAll(batch);
      if (batch.length < 200) break;
    }
    return users;
  }

  @override
  Future<void> resetTestData(String emailDomain) async {
    final suffix = '@$emailDomain';
    final practiceIds = _ids(
      await admin.from('practices').select('id').eq('is_test', true),
    );
    final testUsers = [
      for (final u in await _allUsers())
        if ((u.email ?? '').endsWith(suffix)) u,
    ];
    final testUserIds = {for (final u in testUsers) u.id};

    if (practiceIds.isNotEmpty) {
      // Schutz: in einer Test-Praxis darf kein Physio ohne Testkonto stehen
      final physios = _ids(
        await admin
            .from('physios')
            .select('id')
            .inFilter('practice_id', practiceIds),
      );
      final foreign = physios.where((id) => !testUserIds.contains(id)).toList();
      if (foreign.isNotEmpty) {
        throw StateError(
          'Reset abgebrochen: ${foreign.length} Physio(s) in einer Test-Praxis ohne Testkonto',
        );
      }
      final patientIds = _ids(
        await admin
            .from('patients')
            .select('id')
            .inFilter('practice_id', practiceIds),
      );
      for (final table in patientScopedTables) {
        for (final c in _chunks(patientIds)) {
          await admin.from(table).delete().inFilter('patient_id', c);
        }
      }
      for (final c in _chunks(patientIds)) {
        await admin.from('patients').delete().inFilter('id', c);
      }
    }
    for (final u in testUsers) {
      await admin.auth.admin.deleteUser(u.id); // physios per ON DELETE CASCADE
    }
    if (practiceIds.isNotEmpty) {
      for (final table in ['physios', 'exercises', 'plan_templates']) {
        await admin.from(table).delete().inFilter('practice_id', practiceIds);
      }
      await admin.from('practices').delete().inFilter('id', practiceIds);
    }
    _physioIds.clear();
  }

  @override
  Future<void> createPhysioAccount(CreatePhysioAccount step) async {
    final res = await admin.auth.admin.createUser(
      AdminUserAttributes(
        email: step.email,
        password: physioPassword,
        emailConfirm: true,
        userMetadata: const {'curaone_testdaten': true},
      ),
    );
    final id = res.user?.id;
    if (id == null) {
      throw StateError('Konto ${step.email} wurde nicht angelegt');
    }
    _physioIds[step.key] = id;
    _physioEmails[step.key] = step.email;
    await admin.from('physios').upsert({
      'id': id,
      'practice_id': step.practiceId,
      'display_name': step.displayName,
    }, onConflict: 'id');
  }

  @override
  Future<void> upsert(UpsertRows step) async {
    final rows = [
      for (final r in step.rows) _resolve(r) as Map<String, dynamic>,
    ];
    for (final c in _chunks(rows)) {
      await admin.from(step.table).upsert(c, onConflict: step.conflict);
    }
  }

  @override
  Future<void> update(UpdateRows step) async {
    var q = admin
        .from(step.table)
        .update(_resolve(step.values) as Map<String, dynamic>);
    for (final e in step.where.entries) {
      q = q.eq(e.key, _resolve(e.value)!);
    }
    await q;
  }

  Future<SupabaseClient> _physioClient(String key) async {
    final existing = _physioClients[key];
    if (existing != null) return existing;
    final email = _physioEmails[key];
    if (email == null) {
      throw StateError('Physio "$key" wurde noch nicht angelegt');
    }
    final c = _client(url, serviceRoleKey);
    await c.auth.signInWithPassword(email: email, password: physioPassword);
    _physioClients[key] = c;
    return c;
  }

  @override
  Future<Row?> physioRpc(PhysioRpc step) async {
    final client = await _physioClient(step.physioKey);
    final res = await client.rpc(
      step.fn,
      params: _resolve(step.params) as Map<String, dynamic>,
    );
    if (res is List && res.isNotEmpty) {
      return Map<String, Object?>.from(res.first as Map);
    }
    if (res is Map) return Map<String, Object?>.from(res);
    return null;
  }

  @override
  Future<void> close() async {
    for (final c in _physioClients.values) {
      await c.dispose();
    }
    await admin.dispose();
  }
}
