// Echte Umsetzung von SeedGateway ueber das Paket `supabase`.
//
// Der Service-Role-Schluessel liegt nur im Speicher und wird nie ausgegeben. Die Physio-Sitzungen
// entstehen per E-Mail + Passwort; der Schluessel dient dort nur als apikey-Header, die Rolle
// bestimmt das Benutzer-JWT. Gegen einen Stack bisher nicht ausgefuehrt (X2-8).

import 'package:supabase/supabase.dart';

import 'seed_gateway.dart';
import 'seed_plan.dart';

class SupabaseGateway implements SeedGateway {
  SupabaseGateway({required this.url, required this.serviceRoleKey})
    : admin = _client(url, serviceRoleKey);

  final String url;
  final String serviceRoleKey;
  final SupabaseClient admin;
  final Map<String, SupabaseClient> _userClients = {};

  static SupabaseClient _client(String url, String key) => SupabaseClient(
    url,
    key,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );

  @override
  Future<List<Row>> selectPage(
    String table,
    String columns, {
    Row? eq,
    String? inColumn,
    List<String>? inValues,
    String? afterId,
    required int limit,
  }) async {
    var q = admin.from(table).select(columns);
    if (eq != null) {
      for (final e in eq.entries) {
        q = q.eq(e.key, e.value!);
      }
    }
    if (inColumn != null) {
      q = q.inFilter(inColumn, inValues!);
    }
    if (afterId != null) {
      q = q.gt('id', afterId);
    }
    final res = await q.order('id').limit(limit);
    return [for (final r in res) Map<String, Object?>.from(r)];
  }

  @override
  Future<List<AuthUserInfo>> listUsersPage(int page, int perPage) async {
    final users = await admin.auth.admin.listUsers(
      page: page,
      perPage: perPage,
    );
    return [for (final u in users) AuthUserInfo(u.id, u.email)];
  }

  @override
  Future<void> deleteRows(
    String table,
    String column,
    List<String> values,
  ) async {
    await admin.from(table).delete().inFilter(column, values);
  }

  @override
  Future<void> deleteUser(String id) => admin.auth.admin.deleteUser(id);

  @override
  Future<String> createUser(String email, String password) async {
    final res = await admin.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: password,
        emailConfirm: true,
        userMetadata: const {'curaone_testdaten': true},
      ),
    );
    final id = res.user?.id;
    if (id == null) throw StateError('Konto $email wurde nicht angelegt');
    return id;
  }

  @override
  Future<void> upsertRows(
    String table,
    List<Row> rows,
    String onConflict,
  ) async {
    await admin.from(table).upsert(rows, onConflict: onConflict);
  }

  @override
  Future<void> updateRows(String table, Row values, Row where) async {
    var q = admin.from(table).update(values);
    for (final e in where.entries) {
      q = q.eq(e.key, e.value!);
    }
    await q;
  }

  @override
  Future<Row?> rpcAsUser(
    String email,
    String password,
    String fn,
    Row params,
  ) async {
    var client = _userClients[email];
    if (client == null) {
      client = _client(url, serviceRoleKey);
      await client.auth.signInWithPassword(email: email, password: password);
      _userClients[email] = client;
    }
    final res = await client.rpc(fn, params: params);
    if (res is List && res.isNotEmpty) {
      return Map<String, Object?>.from(res.first as Map);
    }
    if (res is Map) return Map<String, Object?>.from(res);
    return null;
  }

  @override
  Future<void> close() async {
    for (final c in _userClients.values) {
      await c.dispose();
    }
    await admin.dispose();
  }
}
