// Konfiguration nur aus der Umgebung (Plan 5): ohne Werte kein Backend.
import 'package:curaone/backend/supabase_bootstrap.dart';
import 'package:curaone/backend/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ohne --dart-define: keine Konfiguration (Demo-Modus bleibt)', () {
    expect(SupabaseConfig.fromEnvironment(), isNull);
  });

  test('ohne Konfiguration startet nichts', () async {
    expect(await createPatientBackend(null), isNull);
  });

  test('gültige Werte', () {
    final SupabaseConfig? c = SupabaseConfig.tryCreate(
      url: ' https://abc.supabase.co/ ',
      anonKey: ' key ',
      inviteLinkBase: ' https://app.example.org ',
    );
    expect(c!.url, 'https://abc.supabase.co');
    expect(c.anonKey, 'key');
    expect(c.inviteLinkBase, 'https://app.example.org');
  });

  test('Einladungsbasis ist optional', () {
    expect(
      SupabaseConfig.tryCreate(
        url: 'https://a.b',
        anonKey: 'k',
      )!.inviteLinkBase,
      isNull,
    );
    expect(
      SupabaseConfig.tryCreate(
        url: 'https://a.b',
        anonKey: 'k',
        inviteLinkBase: '  ',
      )!.inviteLinkBase,
      isNull,
    );
  });

  test('unbrauchbar: leer, ohne Schlüssel, ohne Host, unsicheres http', () {
    for (final (String, String) v in <(String, String)>[
      ('', 'k'),
      ('https://a.b', ''),
      ('https://a.b', '   '),
      ('nicht-url', 'k'),
      ('https://', 'k'),
      ('http://example.org', 'k'),
      ('ftp://a.b', 'k'),
    ]) {
      expect(
        SupabaseConfig.tryCreate(url: v.$1, anonKey: v.$2),
        isNull,
        reason: '$v',
      );
    }
  });

  test('lokaler Stack über http auf Loopback und Emulator-Host', () {
    for (final String host in <String>['127.0.0.1', 'localhost', '10.0.2.2']) {
      expect(
        SupabaseConfig.tryCreate(url: 'http://$host:54321', anonKey: 'k'),
        isNotNull,
        reason: host,
      );
    }
  });
}
