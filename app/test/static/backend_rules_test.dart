// Test C, Backend (Plan 12.3): `supabase_flutter` nur in `lib/backend/**`, keine
// Schlüsselmuster im Code, `lib/logic` und `lib/data` kennen das Paket nicht.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'code_scan.dart';

Map<String, String> readLib() {
  final Map<String, String> files = <String, String>{};
  for (final FileSystemEntity e in Directory('lib').listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) {
      files[normalizePath(e.path)] = e.readAsStringSync();
    }
  }
  return files;
}

final RegExp _supabaseImport = RegExp(
  r'''import\s+['"]package:(?:supabase_flutter|supabase|gotrue|postgrest)[/a-z_.]*['"]''',
);

/// JWT-Anfang (Base64 von `{"`), Supabase-Schlüsselpräfixe, feste Projekt-URLs.
final RegExp _secretPattern = RegExp(
  r'eyJ[A-Za-z0-9_-]{16,}|sb_(?:secret|publishable)_|service_role\s*[:=]|https?://[a-z0-9-]+\.supabase\.(?:co|in)',
);

List<String> supabaseImportOutsideBackend(Map<String, String> files) =>
    <String>[
      for (final MapEntry<String, String> e in files.entries)
        if (!inDir(e.key, 'lib/backend') &&
            _supabaseImport.hasMatch(stripComments(e.value)))
          e.key,
    ];

List<String> secretPatterns(Map<String, String> files) => <String>[
  for (final MapEntry<String, String> e in files.entries)
    if (_secretPattern.hasMatch(stripComments(e.value))) e.key,
];

void main() {
  final Map<String, String> lib = readLib();

  test('Scanner sieht lib/backend/', () {
    expect(lib.keys.where((String p) => inDir(p, 'lib/backend')), isNotEmpty);
  });

  test('Backend-Pakete nur in lib/backend/**', () {
    expect(supabaseImportOutsideBackend(lib), isEmpty);
  });

  test('keine Schlüsselmuster und keine festen Projekt-URLs im Code', () {
    expect(secretPatterns(lib), isEmpty);
  });

  test('Selbsttest: die Regeln erkennen Verstöße', () {
    final Map<String, String> bad = <String, String>{
      'lib/ui/x.dart':
          "import 'package:supabase_flutter/supabase_flutter.dart';",
      'lib/data/y.dart': 'import "package:postgrest/postgrest.dart";',
      'lib/backend/ok.dart':
          "import 'package:supabase_flutter/supabase_flutter.dart';",
      'lib/logic/c.dart':
          "// import 'package:supabase_flutter/supabase_flutter.dart';",
    };
    expect(supabaseImportOutsideBackend(bad), <String>[
      'lib/ui/x.dart',
      'lib/data/y.dart',
    ]);
    expect(
      secretPatterns(<String, String>{
        'a.dart': "const k = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';",
        'b.dart': "const u = 'https://abcdefgh.supabase.co';",
        'c.dart': "const s = 'sb_secret_abc';",
        'd.dart': '// eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9',
        'e.dart': "const ok = 'SUPABASE_URL';",
      }),
      <String>['a.dart', 'b.dart', 'c.dart'],
    );
  });
}
