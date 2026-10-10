// Gestufte Matrix (Plan 12.2, Tag `matrix`): jedes Szenario aus
// `lib/dev/scenarios.dart` in den drei Stufen
//   M-Layout   × 320×568, 390×844, 430×932 × Skalierung 1,0/2,0 (normal),
//              zusätzlich 768×1024 für Szenarien mit `tablet`
//   M-Modus    × 390×844 × 1,0 × {Hoher Kontrast, Bewegung reduzieren}
//   M-Kontrast × 390×844 × 1,0 × {normal, Hoher Kontrast}
// Lauf: `flutter test --tags matrix`. Bericht: build/matrix/matrix.txt.
@Tags(<String>['matrix'])
library;

import 'package:curaone/dev/scenarios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import 'matrix_checks.dart';
import 'matrix_harness.dart';

final MatrixReport _report = MatrixReport();

String _name(Scenario s, Size size, String rest) =>
    '${s.id} ${size.width.toInt()}x${size.height.toInt()} $rest';

Future<void> _tapEveryTarget(
  WidgetTester tester,
  List<Finding> out,
  bool allowProgress,
) async {
  final List<TapTarget> targets = tapTargets(tester)
      .where((TapTarget t) => !t.isTextField && !t.hidden)
      .toList();
  final Rect view = Offset.zero & viewSize(tester);
  for (final TapTarget t in targets) {
    if (!view.contains(t.rect.center)) continue;
    await tester.tapAt(t.rect.center);
    await _pastReducedLimit(tester);
    out.addAll(checkReducedMotion(tester, allowProgress: allowProgress));
  }
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
Future<void> _pastReducedLimit(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 121));
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  tearDownAll(() => _report.write('matrix'));

  group('M-Layout', () {
    for (final Scenario s in kScenarios) {
      final List<Size> sizes = <Size>[
        ...Viewports.matrix,
        if (s.tablet) Viewports.tablet,
      ];
      for (final Size size in sizes) {
        final bool tabletOnly = size == Viewports.tablet;
        // Szenarien mit festem Wert (z. B. 1,5 für die Fuß-Regel des Chats)
        // laufen nur mit diesem Wert.
        final double? fixed = s.fixedTextScale;
        for (final double scale
            in fixed != null
                ? <double>[fixed]
                : (tabletOnly ? <double>[1] : <double>[1, 2])) {
          final String name = _name(s, size, '×${scale.toStringAsFixed(1)}');
          testWidgets(name, (WidgetTester tester) async {
            final SemanticsHandle semantics = tester.ensureSemantics();
            await pumpScenario(tester, s, size: size, scale: scale);
            final List<Finding> f = <Finding>[
              ...takeLayoutExceptions(tester),
              ...await checkTapTargetSize(tester),
              ...await checkTapTargetGaps(tester),
              ...checkTextStyles(probe(tester)),
              ...checkPrimary(tester, s),
              ...checkZones(tester, s),
              ...checkTodayGroup(tester, s),
              ...checkVisibleArea(tester, s),
              ...await checkReachability(tester),
              ...checkFocusedField(tester, s),
              ...checkBackdrops(tester, s.maxBackdrops),
              ...checkChatFooter(tester, s),
              ...checkGlowRule(probe(tester), colorsFor(hc: false), size),
              ...takeLayoutExceptions(tester),
            ];
            await tester.pumpWidget(const SizedBox.shrink());
            semantics.dispose();
            expectNoFindings(f, report: _report, caseName: name);
          });
        }
      }
    }
  });

  group('M-Modus', () {
    for (final Scenario s in kScenarios) {
      final String hcName = _name(s, Viewports.phone, 'HC');
      testWidgets(hcName, (WidgetTester tester) async {
        await pumpScenario(tester, s, hc: true);
        final List<Finding> f = <Finding>[
          ...takeLayoutExceptions(tester),
          ...checkHighContrast(tester),
          ...checkGlowRule(probe(tester), colorsFor(hc: true), Viewports.phone),
        ];
        await tester.pumpWidget(const SizedBox.shrink());
        expectNoFindings(f, report: _report, caseName: hcName);
      });

      final String rmName = _name(s, Viewports.phone, 'RM');
      testWidgets(rmName, (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await pumpScenario(tester, s, rm: true);
        final List<Finding> f = <Finding>[...takeLayoutExceptions(tester)];
        // Einblenden/Schieben seit dem Aufbau: nach 121 ms nichts mehr.
        await _pastReducedLimit(tester);
        f.addAll(checkReducedMotion(tester, allowProgress: s.loops));
        // Jeden Übergang auslösen, den die Tap-Ziele anbieten.
        await _tapEveryTarget(tester, f, s.loops);
        f.addAll(takeLayoutExceptions(tester));
        await tester.pumpWidget(const SizedBox.shrink());
        semantics.dispose();
        expectNoFindings(f, report: _report, caseName: rmName);
      });
    }
  });

  group('M-Kontrast', () {
    for (final Scenario s in kScenarios) {
      for (final bool hc in <bool>[false, true]) {
        final String name = _name(s, Viewports.phone, hc ? 'HC' : 'normal');
        testWidgets(name, (WidgetTester tester) async {
          final SemanticsHandle semantics = tester.ensureSemantics();
          await pumpScenario(tester, s, hc: hc);
          final List<Finding> f = <Finding>[
            ...takeLayoutExceptions(tester),
            ...await checkTextContrast(tester),
            ...await checkLabeledTargets(tester),
          ];
          await tester.pumpWidget(const SizedBox.shrink());
          semantics.dispose();
          expectNoFindings(f, report: _report, caseName: name);
        });
      }
    }
  });
}
