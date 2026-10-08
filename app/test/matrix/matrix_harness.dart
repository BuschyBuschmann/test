// Harness der gestuften Matrix (Plan 12.2): baut ein Szenario in der
// Preview-App (derselbe Weg wie im Browser), setzt Viewport, Skalierung, HC
// und RM, lässt einschwingen und sammelt Befunde.
import 'dart:io';

import 'package:curaone/dev/preview_app.dart';
import 'package:curaone/dev/scenarios.dart';
import 'package:curaone/dev/text_probe.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import 'matrix_checks.dart';

/// Befunde aller Fälle für den Bericht.
class MatrixReport {
  int cases = 0;
  final List<String> advisories = <String>[];
  final Stopwatch clock = Stopwatch()..start();

  void write(String name) {
    final Directory dir = Directory('build/matrix')
      ..createSync(recursive: true);
    File('${dir.path}/$name.txt').writeAsStringSync(
      'Fälle: $cases\n'
      'Laufzeit: ${(clock.elapsedMilliseconds / 1000).toStringAsFixed(1)} s\n'
      'Richtwert-Befunde: ${advisories.length}\n'
      '${advisories.join('\n')}\n',
    );
  }
}

/// Baut [scenario] und schwingt ein. Szenarien mit Dauer-Animation
/// (`loops`) laufen nur einige Frames weiter.
Future<void> pumpScenario(
  WidgetTester tester,
  Scenario scenario, {
  Size size = Viewports.phone,
  double scale = 1,
  bool hc = false,
  bool rm = false,
}) async {
  setViewport(tester, size);
  await tester.pumpWidget(
    PreviewApp(
      config: PreviewConfig(
        scenarioId: scenario.id,
        textScale: scale,
        highContrast: hc,
        reduceMotion: rm,
      ),
    ),
  );
  await settle(tester, scenario);
}

/// Einschwingen: `pumpAndSettle` (Theme-Übergang 200 ms nach einem HC-Wechsel
/// eingeschlossen), bei Dauer-Animation nur eine feste Zeit.
Future<void> settle(WidgetTester tester, Scenario scenario) async {
  if (scenario.loops) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  } else {
    await tester.pumpAndSettle();
  }
}

CuraColors colorsFor({required bool hc}) =>
    hc ? CuraColors.darkHighContrast : CuraColors.dark;

TextProbe probe(WidgetTester tester) => probeTexts(view: viewSize(tester));

/// Sammelt Befunde: schlägt fehl bei harten Befunden, meldet Richtwerte.
void expectNoFindings(
  List<Finding> findings, {
  required MatrixReport report,
  required String caseName,
}) {
  report.cases++;
  final List<Finding> hard = findings
      .where((Finding f) => !f.advisory)
      .toList();
  for (final Finding f in findings.where((Finding f) => f.advisory)) {
    report.advisories.add('$caseName: $f');
  }
  expect(hard, isEmpty, reason: '$caseName\n${hard.join('\n')}');
}
