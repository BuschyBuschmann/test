// Kommandozeile des Testdaten-Seeds (Plan Ausschnitt 2, Abschnitt 10).
//
//   dart run tool/seed/seed.dart --target local|remote [--confirm-remote]
//   dart run tool/seed/seed.dart --dry-run            Plan anzeigen, keine Verbindung
//   dart run tool/seed/seed.dart --emit-sql           SQL fuer das lokale Test-Postgres ausgeben
//   dart run tool/seed/seed.dart --target ... --reset-only
//
// Umgebung (nie im Repository): SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY,
// optional CURAONE_SEED_PASSWORD (sonst wird ein Passwort erzeugt und einmal ausgegeben).
// Exit-Codes: 0 ok, 1 Laufzeitfehler, 2 Aufruf-/Umgebungsfehler.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'seed_backend.dart';
import 'seed_plan.dart';
import 'sql_backend.dart';
import 'supabase_backend.dart';

typedef BackendFactory = SeedBackend Function(
  String url,
  String serviceRoleKey,
  String physioPassword,
);

const String usage = '''
Testdaten-Seed fuer CuraOne (nur erfundene Testdaten)

  dart run tool/seed/seed.dart --target local|remote [--confirm-remote] [--reset-only]
  dart run tool/seed/seed.dart --dry-run
  dart run tool/seed/seed.dart --emit-sql [--today JJJJ-MM-TT]

Optionen
  --target local|remote   local: URL muss auf localhost zeigen; remote: https-URL und --confirm-remote
  --confirm-remote        ausdrueckliche Bestaetigung fuer ein echtes Projekt (loescht dort Testdaten)
  --reset-only            nur loeschen (is_test-Praxen, Konten @test.curaone.invalid), nichts anlegen
  --dry-run               Plan und Zeilenzahlen zeigen, keine Verbindung, keine Umgebung noetig
  --emit-sql              SQL fuer das lokale Test-Postgres (Nachbildung) auf stdout
  --today JJJJ-MM-TT      Bezugstag der Offsets (Standard: heutiges UTC-Datum)
  --data PFAD             andere Testdaten-Datei (Standard: testdaten.json neben dem Skript)

Umgebung (nie im Repository ablegen)
  SUPABASE_URL                 Projekt-URL
  SUPABASE_SERVICE_ROLE_KEY    Service-Role-Schluessel (nur in der Shell)
  CURAONE_SEED_PASSWORD        optional: Passwort der Test-Physios
''';

bool _isLocalHost(String host) =>
    host == 'localhost' ||
    host == '127.0.0.1' ||
    host == '::1' ||
    host == '[::1]';

String _randomPassword() {
  const alphabet = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = Random.secure();
  return List.generate(20, (_) => alphabet[r.nextInt(alphabet.length)]).join();
}

Future<int> runSeedCli(
  List<String> args,
  Map<String, String> env, {
  required StringSink out,
  required StringSink err,
  String? defaultDataPath,
  BackendFactory? backendFactory,
  DateTime? now,
}) async {
  String? target;
  String? dataPath = defaultDataPath;
  String? todayArg;
  var confirmRemote = false;
  var dryRun = false;
  var emitSql = false;
  var resetOnly = false;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    String next() {
      if (i + 1 >= args.length) throw FormatException('Wert fuer $a fehlt');
      return args[++i];
    }

    try {
      switch (a) {
        case '--target':
          target = next();
        case '--data':
          dataPath = next();
        case '--today':
          todayArg = next();
        case '--confirm-remote':
          confirmRemote = true;
        case '--dry-run':
          dryRun = true;
        case '--emit-sql':
          emitSql = true;
        case '--reset-only':
          resetOnly = true;
        case '-h' || '--help':
          out.write(usage);
          return 0;
        default:
          err.writeln('Unbekannte Option: $a\n');
          err.write(usage);
          return 2;
      }
    } on FormatException catch (e) {
      err.writeln(e.message);
      return 2;
    }
  }

  final offline = dryRun || emitSql;
  if (!offline && target != 'local' && target != 'remote') {
    err.writeln('--target local|remote ist erforderlich.\n');
    err.write(usage);
    return 2;
  }
  if (resetOnly && offline) {
    err.writeln('--reset-only braucht --target (kein --dry-run/--emit-sql).');
    return 2;
  }

  DateTime today;
  try {
    final t = todayArg != null
        ? DateTime.parse('${todayArg}T00:00:00Z')
        : (now ?? DateTime.now().toUtc());
    today = DateTime.utc(t.year, t.month, t.day);
  } on FormatException {
    err.writeln('--today erwartet JJJJ-MM-TT.');
    return 2;
  }

  // Umgebung und Sicherheitspruefungen vor jeder Verbindung
  String? url;
  String? key;
  if (!offline) {
    final missing = [
      if ((env['SUPABASE_URL'] ?? '').trim().isEmpty) 'SUPABASE_URL',
      if ((env['SUPABASE_SERVICE_ROLE_KEY'] ?? '').trim().isEmpty)
        'SUPABASE_SERVICE_ROLE_KEY',
    ];
    if (missing.isNotEmpty) {
      err.writeln(
        'Abbruch: Umgebungsvariable(n) fehlen: ${missing.join(', ')}.',
      );
      err.writeln(
        'Setze sie nur in der Shell (nie im Repository), z. B. fuer den lokalen Stack:',
      );
      err.writeln('  export SUPABASE_URL=http://127.0.0.1:54321');
      err.writeln(
        '  export SUPABASE_SERVICE_ROLE_KEY=<Schluessel aus "supabase status">',
      );
      return 2;
    }
    url = env['SUPABASE_URL']!.trim();
    key = env['SUPABASE_SERVICE_ROLE_KEY']!.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      err.writeln('Abbruch: SUPABASE_URL ist keine gueltige URL.');
      return 2;
    }
    if (target == 'local' && !_isLocalHost(uri.host)) {
      err.writeln(
        'Abbruch: --target local, aber SUPABASE_URL zeigt auf "${uri.host}", nicht auf localhost.',
      );
      err.writeln('Fuer ein echtes Projekt: --target remote --confirm-remote.');
      return 2;
    }
    if (target == 'remote') {
      if (uri.scheme != 'https') {
        err.writeln('Abbruch: --target remote verlangt eine https-URL.');
        return 2;
      }
      if (!confirmRemote) {
        err.writeln(
          'Abbruch: --target remote loescht und schreibt Testdaten im Projekt "${uri.host}".',
        );
        err.writeln(
          'Zur Bestaetigung zusaetzlich --confirm-remote angeben (externer Schritt X2-4).',
        );
        return 2;
      }
    }
  }

  Map<String, dynamic> data;
  try {
    final path = dataPath ?? 'testdaten.json';
    data = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  } on Object catch (e) {
    err.writeln('Testdaten konnten nicht gelesen werden: $e');
    return 1;
  }

  final SeedPlan plan;
  try {
    plan = buildSeedPlan(data, today: today);
  } on SeedDataException catch (e) {
    err.writeln(e);
    return 1;
  }

  if (emitSql) {
    out.write(await renderSeedSql(plan));
    return 0;
  }
  if (dryRun) {
    out.writeln(
      'Plan (kein Zugriff auf ein Backend), Bezugstag ${dayString(today, 0)}:',
    );
    for (final e in plan.rowCounts.entries) {
      out.writeln('  ${e.key.padRight(20)} ${e.value}');
    }
    out.writeln('  Test-Physios         ${plan.physios.length}');
    for (final n in plan.notes) {
      out.writeln('Hinweis: $n');
    }
    return 0;
  }

  final generated = (env['CURAONE_SEED_PASSWORD'] ?? '').isEmpty;
  final password = generated
      ? _randomPassword()
      : env['CURAONE_SEED_PASSWORD']!;
  if (password.length < 8) {
    err.writeln(
      'Abbruch: CURAONE_SEED_PASSWORD ist zu kurz (mindestens 8 Zeichen).',
    );
    return 2;
  }
  final backend =
      (backendFactory ??
      (u, k, p) => SupabaseSeedBackend(
        url: u,
        serviceRoleKey: k,
        physioPassword: p,
      ))(url!, key!, password);
  try {
    if (resetOnly) {
      await backend.resetTestData(plan.emailDomain);
      out.writeln(
        'Reset abgeschlossen: Testpraxen und Testkonten (@${plan.emailDomain}) geloescht.',
      );
      return 0;
    }
    final report = await runSeed(plan, backend, log: (l) => out.writeln(l));
    out.writeln('\nFertig. Angelegte Zeilen:');
    for (final e in report.rowCounts.entries) {
      out.writeln('  ${e.key.padRight(20)} ${e.value}');
    }
    out.writeln('\nTest-Physios (Anmeldung mit E-Mail und Passwort):');
    for (final m in report.physioEmails) {
      out.writeln('  $m');
    }
    out.writeln(
      generated
          ? 'Passwort (zufaellig, nur dieser Lauf, wird nicht gespeichert): $password'
          : 'Passwort: Wert aus CURAONE_SEED_PASSWORD',
    );
    out.writeln(
      '\nEinladungscodes der Test-Patienten (nur hier auf der Konsole, 14 Tage gueltig):',
    );
    for (final i in report.invitations) {
      out.writeln('  ${i.subject.padRight(24)} ${i.code}');
    }
    for (final n in plan.notes) {
      out.writeln('Hinweis: $n');
    }
    return 0;
  } on Object catch (e) {
    err.writeln(
      'Seed fehlgeschlagen: ${_scrub(e.toString(), [key, password])}',
    );
    return 1;
  } finally {
    await backend.close();
  }
}

/// Entfernt Schluessel und Passwort aus Fehlermeldungen, falls eine Bibliothek sie mitliefert.
String _scrub(String text, List<String> secrets) {
  var t = text;
  for (final s in secrets) {
    if (s.isNotEmpty) t = t.replaceAll(s, '***');
  }
  return t;
}
