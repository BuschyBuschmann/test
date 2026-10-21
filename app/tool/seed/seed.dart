// Einstieg: dart run tool/seed/seed.dart --help
// Logik und Tests: seed_cli.dart, seed_plan.dart.

import 'dart:io';

import 'seed_cli.dart';

Future<void> main(List<String> args) async {
  final code = await runSeedCli(
    args,
    Platform.environment,
    out: stdout,
    err: stderr,
    defaultDataPath: Platform.script.resolve('testdaten.json').toFilePath(),
  );
  await stdout.flush();
  await stderr.flush();
  exit(code);
}
