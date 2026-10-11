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

  /// Tap-Ziele, die der Durchlauf „jedes Ziel antippen“ vorfand / antippte.
  int sweepCandidates = 0;
  int sweepTapped = 0;
  final List<String> advisories = <String>[];
  final Stopwatch clock = Stopwatch()..start();

  void write(String name) {
    final Directory dir = Directory('build/matrix')
      ..createSync(recursive: true);
    File('${dir.path}/$name.txt').writeAsStringSync(
      'Fälle: $cases\n'
      'Tap-Ziele (RM-Durchlauf): $sweepTapped von $sweepCandidates angetippt\n'
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
/// eingeschlossen), bei Dauer-Animation eine feste Zeit in vielen kleinen
/// Frames: Das Skript eines App-Szenarios (Tipps auf echte Bausteine, z. B.
/// `data-delete-busy`) braucht je Schritt einen Frame, und der Fortschrittskreis
/// erscheint erst nach 300 ms.
Future<void> settle(WidgetTester tester, Scenario scenario) async {
  if (scenario.loops) {
    await tester.pump();
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
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

/// Wartet so, dass jede erlaubte Animation (höchstens `dur-fast` = 120 ms)
/// beendet ist, bevor gezählt wird:
/// 1. ein kurzer erster Frame: baut die Folgen der Aktion (Tipp) und startet
///    neue Animationen. Ohne ihn fiele der Start einer Animation erst in den
///    121-ms-Frame, und sie liefe am Ende noch.
/// 2. 121 ms (länger als jede erlaubte Animation),
/// 3. ein weiterer Frame: Ein `LayoutBuilder` (jeder `ContentFrame`) legt einen
///    einzelnen „aufgeschobenen“ Frame-Callback an, wenn unter ihm nach dem
///    Frame etwas neu gebaut wird (z. B. Fokus-Folgen eines Tab-Wechsels). Er
///    läuft im nächsten Frame ab und ist keine Animation; eine echte Animation
///    über 120 ms läuft nach dem Zusatzframe weiter und wird erkannt.
///
/// Davor laufen einige Frames **ohne Zeitfortschritt**: Die Folgen einer
/// Aktion (Besuch des Pfads, Route, Snackbar) bauen sich über mehrere
/// aufeinanderfolgende Frames auf (Nachbau im Post-Frame-Callback, bis zu zehn
/// Wiederholungen). Begänne eine erlaubte Animation erst im letzten Frame des
/// Fensters, liefe sie beim Zählen noch, und der Befund wäre ein Messartefakt.
/// Zeit läuft dabei nicht; jede Animation beginnt innerhalb des Fensters und
/// muss darin enden.
Future<void> pastReducedLimit(WidgetTester tester) async {
  for (int i = 0; i < 12; i++) {
    await tester.pump(Duration.zero);
  }
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 121));
  await tester.pump(const Duration(milliseconds: 1));
}

/// Ergebnis von [tapEveryTarget].
class TapSweep {
  const TapSweep(this.findings, this.candidates, this.tapped);

  final List<Finding> findings;

  /// Ziele, die im Ausgangszustand sichtbar und antippbar waren.
  final int candidates;

  /// Davon tatsächlich angetippt. Ein Unterschied ist immer auch ein Befund.
  final int tapped;
}

/// Tippt **jedes** sichtbare Tap-Ziel an (R-AB-1) und prüft nach jedem Tipp
/// „Bewegung reduzieren“.
///
/// Ein Tipp verändert die Seite (öffnet eine Route, tauscht Beschriftungen,
/// blendet Felder ein); die übrigen Ziele wären danach begraben oder anders
/// beschriftet. Darum wird vor jedem weiteren Ziel der Ausgangszustand mit
/// [rebuild] **neu aufgebaut** (der Aufrufer baut das Szenario frisch auf) und
/// das Ziel dort anhand von Beschriftung und Rang unter gleich beschrifteten
/// Zielen gesucht. Fehlt es dort oder liegt es nicht mehr auf dem Bildschirm,
/// ist das ein harter Befund: ein übersprungenes Ziel darf nie still bleiben.
///
/// Textfelder und als verdeckt markierte Ziele (außerhalb des Scrollfensters)
/// sind keine Kandidaten; für diese gilt die Erreichbarkeitsprüfung.
Future<TapSweep> tapEveryTarget(
  WidgetTester tester, {
  required Future<void> Function() rebuild,
  required bool allowProgress,
}) async {
  final Rect view = Offset.zero & viewSize(tester);
  List<TapTarget> current() =>
      tapTargets(tester)
          .where((TapTarget t) => !t.isTextField && !t.hidden)
          .toList();

  final List<(String, int)> wanted = <(String, int)>[];
  final Map<String, int> seen = <String, int>{};
  for (final TapTarget t in current()) {
    final int nth = seen.update(t.label, (int n) => n + 1, ifAbsent: () => 0);
    if (view.contains(t.rect.center)) wanted.add((t.label, nth));
  }

  final List<Finding> out = <Finding>[];
  int tapped = 0;
  for (int i = 0; i < wanted.length; i++) {
    final (String label, int nth) = wanted[i];
    if (i > 0) await rebuild();
    final List<TapTarget> same = current()
        .where((TapTarget t) => t.label == label)
        .toList();
    if (same.length <= nth) {
      out.add(
        Finding(
          'Tap-Ziel angetippt',
          '"$label" (Nr. ${nth + 1}) ist im neu aufgebauten Ausgangszustand '
              'nicht mehr vorhanden und wurde nicht angetippt',
        ),
      );
      continue;
    }
    final TapTarget t = same[nth];
    if (!view.contains(t.rect.center)) {
      out.add(
        Finding(
          'Tap-Ziel angetippt',
          '$t liegt im neu aufgebauten Ausgangszustand außerhalb des '
              'Bildschirms und wurde nicht angetippt',
        ),
      );
      continue;
    }
    await tester.tapAt(t.rect.center);
    tapped++;
    await pastReducedLimit(tester);
    out.addAll(
      checkReducedMotion(tester, allowProgress: allowProgress).map(
        (Finding f) => Finding(
          f.check,
          '${f.message} (nach Tipp auf "$label")',
          advisory: f.advisory,
        ),
      ),
    );
  }
  return TapSweep(out, wanted.length, tapped);
}
