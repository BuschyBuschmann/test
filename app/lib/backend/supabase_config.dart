// Konfiguration des Backends (Plan 5, 11): URL und Anon-Key kommen **nur** aus
// der Konfiguration, nie aus dem Code. Aufruf:
//
//   flutter run --dart-define-from-file=config/supabase.local.json
//
// Die Datei `app/config/supabase.local.json` ist nicht eingecheckt
// (`.gitignore`) und enthält die Schlüssel `SUPABASE_URL`,
// `SUPABASE_ANON_KEY` und optional `INVITE_LINK_BASE`. Ohne Konfiguration
// startet die App ohne Backend wie bisher (Onboarding mit lokalen Daten);
// [SupabaseConfig.fromEnvironment] liefert dann `null`. Die Prüfumgebung
// (`main_preview`) und `CURAONE_DEMO=true` (Plan 8.12) sind davon unabhängig.

class SupabaseConfig {
  const SupabaseConfig._({
    required this.url,
    required this.anonKey,
    this.inviteLinkBase,
  });

  /// Basis-URL des Projekts, ohne abschließenden Schrägstrich.
  final String url;
  final String anonKey;

  /// Basis für Einladungslinks (`<BASIS>/?einladung=XXXXX-XXXXX`), optional.
  final String? inviteLinkBase;

  /// Aus den `--dart-define`-Werten; `null`, wenn URL oder Schlüssel fehlen
  /// oder die URL unbrauchbar ist.
  static SupabaseConfig? fromEnvironment() => tryCreate(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    inviteLinkBase: const String.fromEnvironment('INVITE_LINK_BASE'),
  );

  /// Prüft die Werte: `https` (für den lokalen Stack ist `http` nur auf
  /// Loopback bzw. dem Android-Emulator-Host erlaubt), Host vorhanden, Schlüssel
  /// nicht leer.
  static SupabaseConfig? tryCreate({
    required String url,
    required String anonKey,
    String? inviteLinkBase,
  }) {
    final String key = anonKey.trim();
    final Uri? uri = Uri.tryParse(url.trim());
    if (key.isEmpty || uri == null || uri.host.isEmpty) return null;
    final bool secure = uri.scheme == 'https';
    final bool localHttp =
        uri.scheme == 'http' && _localHosts.contains(uri.host);
    if (!secure && !localHttp) return null;
    String clean = url.trim();
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    final String? base = inviteLinkBase?.trim();
    return SupabaseConfig._(
      url: clean,
      anonKey: key,
      inviteLinkBase: (base == null || base.isEmpty) ? null : base,
    );
  }

  static const Set<String> _localHosts = <String>{
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
  };
}
