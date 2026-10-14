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
              ...checkCardTextContrast(
                probe(tester),
                colorsFor(hc: false),
                size,
              ),
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
          ...checkCardTextContrast(
            probe(tester),
            colorsFor(hc: true),
            Viewports.phone,
          ),
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
        await pastReducedLimit(tester);
        f.addAll(checkReducedMotion(tester, allowProgress: s.loops));
        // Jeden Übergang auslösen, den die Tap-Ziele anbieten: jedes Ziel in
        // frisch aufgebautem Ausgangszustand (R-AB-1).
        final TapSweep sweep = await tapEveryTarget(
          tester,
          rebuild: () async {
            await tester.pumpWidget(const SizedBox.shrink());
            await pumpScenario(tester, s, rm: true);
          },
          allowProgress: s.loops,
        );
        f.addAll(sweep.findings);
        _report.sweepCandidates += sweep.candidates;
        _report.sweepTapped += sweep.tapped;
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
