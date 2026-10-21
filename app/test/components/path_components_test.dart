// NodeHint und die begrenzte MannyBubble (U3a, Ergänzung 1 3.5; UI-60 bis
// UI-63, UI-65; Regel 12). Kugeln: `orb_node_test.dart`, Kopf-Karte:
// `header_card_test.dart`.
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/theme/cura_theme.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
import 'package:curaone/ui/components/node_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/pump_app.dart';

/// Wie `pumpApp`, mit „Bewegung reduzieren“ (`disableAnimations`) im
/// `MaterialApp.builder` (ein Override oberhalb der App würde nicht wirken).
Future<void> _pumpReduced(WidgetTester tester, Widget child) async {
  setViewport(tester, Viewports.phone);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CuraTheme.build(),
      locale: const Locale('de'),
      supportedLocales: const <Locale>[Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext context, Widget? app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: app!,
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('NodeHint (Ergänzung 1 3.5, UI-62)', () {
    Widget hint(
      HintArrow arrow, {
      String text = S.hintDone,
      double? maxBodyHeight,
    }) => Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 240,
        child: NodeHint(
          text: text,
          arrow: arrow,
          arrowCenter: 40,
          maxBodyHeight: maxBodyHeight,
        ),
      ),
    );

    testWidgets(
      'opak surface-opaque, Rand border-hair, Radius 16, Innenabstand '
      '12/16, kein Blur, secondary text-1',
      (WidgetTester tester) async {
        await pumpApp(tester, hint(HintArrow.down));
        final CuraColors c = colorsAt(tester, find.byType(NodeHint));
        final BoxDecoration d = decorationsUnder(
          tester,
          find.byType(NodeHint),
        ).firstWhere((BoxDecoration x) => x.borderRadius != null);
        expect(d.color, c.surfaceOpaque);
        expect((d.border! as Border).top.color, c.cardBorder);
        expect(d.borderRadius, BorderRadius.circular(16));
        expect(backdropCount(tester), 0);
        final Text t = tester.widget(find.text(S.hintDone));
        expect(t.style!.fontSize, 14);
        expect(t.style!.color, c.text1);
        final Rect body = tester.getRect(find.byType(NodeHint));
        final Rect text = tester.getRect(find.text(S.hintDone));
        expect(text.left - body.left, 16);
        expect(text.top - body.top, 12);
      },
    );

    testWidgets('Pfeil 8 dp an der gewählten Kante, alle vier Richtungen', (
      WidgetTester tester,
    ) async {
      for (final HintArrow a in HintArrow.values) {
        await pumpApp(tester, hint(a, text: 'Erledigt.'));
        expect(tester.takeException(), isNull, reason: '$a');
        final Size s = tester.getSize(find.byType(NodeHint));
        final bool vertical = a == HintArrow.down || a == HintArrow.up;
        // Körper 12 + 20 + 12 = 44 hoch; der Pfeil macht 8 dp dazu.
        if (vertical) {
          expect(s.height, 44 + 8, reason: '$a');
        } else {
          expect(s.width, closeTo(240, 0.5), reason: '$a');
          expect(s.height, greaterThanOrEqualTo(44), reason: '$a');
        }
      }
    });

    testWidgets('Live-Region mit dem Text als Label, ohne Aktion', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(tester, hint(HintArrow.up));
      final SemanticsData d = tester
          .getSemantics(find.byType(NodeHint))
          .getSemanticsData();
      expect(d.label, S.hintDone);
      expect(d.flagsCollection.isLiveRegion, isTrue);
      expect(d.hasAction(SemanticsAction.tap), isFalse);
      h.dispose();
    });

    testWidgets('Breite wächst nicht über die Vorgabe; lange Texte brechen um '
        '(Höhe wächst)', (WidgetTester tester) async {
      await pumpApp(
        tester,
        hint(
          HintArrow.down,
          text: 'Dieser Hinweistext ist absichtlich sehr lang und bricht um, weil er nicht in eine Zeile passt.',
        ),
      );
      final Size s = tester.getSize(find.byType(NodeHint));
      expect(s.width, lessThanOrEqualTo(240));
      expect(s.height, greaterThan(44 + 8 + 20));
    });

    testWidgets('begrenzt: der Text scrollt innen, die Höhe hält', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        hint(
          HintArrow.down,
          text: List<String>.filled(12, 'Wort').join(' '),
          maxBodyHeight: 60,
        ),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.getSize(find.byType(NodeHint)).height, 60 + 8);
    });

    Opacity opacity(WidgetTester tester) => tester.widget<Opacity>(
      find
          .descendant(of: find.byType(NodeHint), matching: find.byType(Opacity))
          .first,
    );

    testWidgets('erscheint mit Einblenden in dur-fast (UI-64)', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, hint(HintArrow.down));
      await tester.pump();
      expect(opacity(tester).opacity, lessThan(1));
      await tester.pump(const Duration(milliseconds: 121));
      expect(opacity(tester).opacity, 1);
    });

    testWidgets('bei reduzierter Bewegung sofort, ohne laufende Animation '
        '(UI-8, UI-64)', (WidgetTester tester) async {
      await _pumpReduced(tester, hint(HintArrow.down));
      expect(opacity(tester).opacity, 1, reason: 'schon im ersten Frame');
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 121));
      expect(tester.binding.transientCallbackCount, 0);
    });
  });

  group('MannyBubble: begrenzte Höhe (Plan 4.6, letzte Stufe)', () {
    testWidgets('mit maxBodyHeight scrollt der Text innen, der Körper hält die '
        'Höhe; ohne bleibt es wie bisher', (WidgetTester tester) async {
      final String long = List<String>.filled(30, 'Wort').join(' ');
      await pumpApp(
        tester,
        Align(
          alignment: Alignment.center,
          child: MannyBubble(
            text: long,
            onClose: () {},
            arrow: BubbleArrow.down,
            maxBodyHeight: 100,
          ),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      final Size s = tester.getSize(find.byType(MannyBubble));
      expect(s.height, 100 + CuraComponent.bubbleArrow);
      await pumpApp(
        tester,
        Align(
          alignment: Alignment.center,
          child: MannyBubble(text: long, onClose: () {}),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsNothing);
    });
  });
}
