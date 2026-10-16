// Schmale Schnittstelle zur Supabase-API (Daten, Auth-Admin, Funktionsaufrufe als Test-Physio).
// Die Logik des Seeds (Schutzpruefung, Blaettern, Loeschreihenfolge) liegt in
// supabase_backend.dart und ist mit einem Fake-Gateway testbar; die echte Umsetzung steht in
// supabase_gateway.dart.

import 'seed_plan.dart';

class AuthUserInfo {
  const AuthUserInfo(this.id, this.email);
  final String id;
  final String? email;
}

abstract class SeedGateway {
  /// Eine Seite Zeilen (from..to einschliesslich), stabil nach id sortiert. Filter: `eq` (alle) und
  /// optional `inColumn IN inValues`.
  Future<List<Row>> selectPage(
    String table,
    String columns, {
    Row? eq,
    String? inColumn,
    List<String>? inValues,
    required int from,
    required int to,
  });

  /// Seite der Auth-Konten (page ab 1).
  Future<List<AuthUserInfo>> listUsersPage(int page, int perPage);

  Future<void> deleteRows(String table, String column, List<String> values);

  Future<void> deleteUser(String id);

  /// Legt ein bestaetigtes E-Mail+Passwort-Konto an und liefert die ID.
  Future<String> createUser(String email, String password);

  Future<void> upsertRows(String table, List<Row> rows, String onConflict);

  Future<void> updateRows(String table, Row values, Row where);

  /// Meldet [email] an und ruft [fn] mit dessen Sitzung auf (Sitzung je E-Mail wiederverwendet).
  Future<Row?> rpcAsUser(String email, String password, String fn, Row params);

  Future<void> close();
}
