// Regeln des Briefs v2 über alle Komponenten in allen Darstellungen (4 Welten ×
// Hell/Dunkel plus Hoher Kontrast): V2-10 (Blur-Budget), V2-11 (Sheets und
// Dialoge opak), V2-12 (Transparenz reduzieren), V2-23 (Zielgrößen und Abstände),
// V2-32 (Mandarine nie als Textfarbe). Grundlage ist die Tafel
// `test/support/showcase.dart` mit allen Komponenten aus Abschnitt 4.
import 'dart:math' as math;

import 'package:curaone/logic/world_time.dart';
import 'package:curaone/theme/contrast.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/theme/tokens.dart';
import 'package:curaone/theme/world_painter.dart';
import 'package:curaone/ui/components/category_card.dart';
import 'package:curaone/ui/components/choice_card.dart';
import 'package:curaone/ui/components/cura_blur.dart';
import 'package:curaone/ui/components/cura_chip.dart';
import 'package:curaone/ui/components/cura_dialog.dart';
import 'package:curaone/ui/components/cura_snackbar.dart';
import 'package:curaone/ui/components/date_card.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/components/glass_pill.dart';
import 'package:curaone/ui/components/glass_card.dart';
import 'package:curaone/ui/components/header_card.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
import 'package:curaone/ui/components/manny_chat_button.dart';
import 'package:curaone/ui/components/manny_look_picker.dart';
import 'package:curaone/ui/components/orb_node.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:curaone/ui/components/status_chip.dart';
import 'package:curaone/ui/components/world_label_chip.dart';
import 'package:curaone/ui/routes/cura_sheet_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/showcase.dart';
import '../support/world_app.dart';
import '../support/backdrops.dart';

const Size _board = Size(390, 2300);

Future<void> _pumpShowcase(WidgetTester tester, WorldLook l) async {
  await pumpWorld(
    tester,
    v2Showcase(),
    phase: l.phase,
    brightness: l.brightness,
    highContrast: l.highContrast,
    size: _board,
  );
  await precacheImages(tester);
}

/// Tippbare Semantik-Knoten (ohne Nachfahren eines tippbaren Knotens) mit
/// ihren globalen Rechtecken.
List<Rect> _tapTargets(WidgetTester tester) {
  Rect globalRect(SemanticsNode n) {
    Rect r = n.rect;
    for (SemanticsNode? cur = n; cur != null; cur = cur.parent) {
      final Matrix4? t = cur.transform;
      if (t != null) r = MatrixUtils.transformRect(t, r);
    }
    return r;
  }

  final List<Rect> out = <Rect>[];
  void visit(SemanticsNode n) {
    final SemanticsData d = n.getSemanticsData();
    if (d.hasAction(SemanticsAction.tap) &&
        !n.flagsCollection.isHidden &&
        !n.flagsCollection.scopesRoute) {
      out.add(globalRect(n));
      return;
    }
    n.visitChildren((SemanticsNode c) {
      visit(c);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return out;
}

void main() {
  group('V2-10: Blur-Budget', () {
    testWidgets('höchstens 3 BackdropFilter: Kopf-Karte, Leiste, Manny-Knopf', (
      WidgetTester tester,
    ) async {
      for (final WorldLook l in allWorldLooks()) {
        await _pumpShowcase(tester, l);
        expect(tester.takeException(), isNull, reason: l.name);
        final int n = backdropCount(tester);
        expect(n, l.highContrast ? 0 : 3, reason: l.name);
        expect(n, lessThanOrEqualTo(BlurTokens.maxPerScreen));
        for (final Type t in <Type>[HeaderCard, FloatingNav, MannyButton]) {
          expect(
            find.descendant(of: find.byType(t), matching: activeBackdrops()),
            l.highContrast ? findsNothing : findsOneWidget,
            reason: '$t ${l.name}',
          );
        }
      }
    });

    testWidgets(
      'Karten, Chips, Zeilen, Kugeln, Buttons, Blasen enthalten keinen '
      'Blur',
      (WidgetTester tester) async {
        await _pumpShowcase(
          tester,
          const WorldLook(WorldPhase.night, Brightness.light),
        );
        for (final Type t in <Type>[
          GlassCard,
          CategoryCard,
          ChoiceCard,
          DateCard,
          StatusChip,
          CuraChip,
          WorldLabelChip,
          OrbNode,
          PillButton,
          MannyBubble,
          CuraSnackbar,
          CuraDialog,
          MannyLookPicker,
        ]) {
          expect(
            find.byType(t),
            findsWidgets,
            reason: '$t fehlt auf der Tafel',
          );
          expect(
            find.descendant(of: find.byType(t), matching: activeBackdrops()),
            findsNothing,
            reason: '$t darf keinen Blur enthalten',
          );
        }
      },
    );

    testWidgets('ein vierter CuraBlur bleibt unscharf (Budget 3)', (
      WidgetTester tester,
    ) async {
      await pumpWorld(
        tester,
        Stack(
          children: <Widget>[
            v2Showcase(withDialog: false),
            const Positioned(
              top: 400,
              left: 20,
              child: CuraBlur(child: SizedBox(width: 40, height: 40)),
            ),
          ],
        ),
        size: _board,
      );
      await precacheImages(tester);
      expect(backdropCount(tester), 3);
    });
  });

  group('V2-11: Sheets und Dialoge opak', () {
    testWidgets('Dialog: card 100 %, Radius 28, kein Blur; Scrim ink-1 45 %', (
      WidgetTester tester,
    ) async {
      for (final Brightness b in Brightness.values) {
        await pumpWorld(
          tester,
          Center(
            child: CuraDialog(
              title: 'Alles löschen?',
              message: 'Das lässt sich nicht rückgängig machen.',
              actions: <Widget>[
                GlassPill(label: 'Abbrechen', onPressed: () {}),
              ],
            ),
          ),
          brightness: b,
        );
        await tester.pumpAndSettle();
        final CuraColors c = colorsAt(tester, find.byType(CuraDialog));
        final BoxDecoration d = decorationsUnder(
          tester,
          find.byType(CuraDialog),
        ).firstWhere((BoxDecoration x) => x.borderRadius != null);
        expect(d.color, c.surfaceOpaque);
        expect(d.color!.a, 1);
        expect(d.borderRadius, BorderRadius.circular(28));
        expect(backdropCount(tester), 0);
        expect(c.scrim.a, closeTo(0.45, 0.005));
        expect(c.scrim.toARGB32() & 0xFFFFFF, 0x211B16);
      }
    });

    testWidgets('Sheet: card 100 %, Radius 32 oben, Griff, kein Blur', (
      WidgetTester tester,
    ) async {
      for (final Brightness b in Brightness.values) {
        await pumpWorld(
          tester,
          const Align(
            alignment: Alignment.bottomCenter,
            child: CuraSheetFrame(
              header: Text('Kopf'),
              body: Text('Inhalt'),
              footer: Text('Fuß'),
            ),
          ),
          brightness: b,
        );
        await tester.pumpAndSettle();
        final CuraColors c = colorsAt(tester, find.byType(CuraSheetFrame));
        final Iterable<BoxDecoration> d = decorationsUnder(
          tester,
          find.byType(CuraSheetFrame),
        );
        final BoxDecoration surface = d.firstWhere(
          (BoxDecoration x) => x.color == c.surfaceOpaque,
        );
        expect(
          surface.borderRadius,
          const BorderRadius.vertical(top: Radius.circular(32)),
        );
        expect(c.surfaceOpaque.a, 1);
        expect(backdropCount(tester), 0);
        // Griff 36 × 4 dp.
        final Finder handle = find.byWidgetPredicate(
          (Widget w) =>
              w is SizedBox &&
              w.width == CuraSize.sheetHandleWidth &&
              w.height == CuraSize.sheetHandleHeight,
        );
        expect(handle, findsOneWidget);
        expect(tester.getSize(handle), const Size(36, 4));
      }
    });

    testWidgets('Snackbar: card opak, kein Blur, Standarddauer 6 s', (
      WidgetTester tester,
    ) async {
      await pumpWorld(
        tester,
        const Center(child: CuraSnackbar(text: 'Eingetragen.')),
      );
      final CuraColors c = colorsAt(tester, find.byType(CuraSnackbar));
      expect(
        decorationsUnder(
          tester,
          find.byType(CuraSnackbar),
        ).any((BoxDecoration x) => x.color == c.surfaceOpaque),
        isTrue,
      );
      expect(backdropCount(tester), 0);
      expect(
        const CuraSnackbarMessage(text: 'x').duration,
        const Duration(seconds: 6),
      );
      expect(SnackbarTokens.standard, const Duration(seconds: 6));
    });
  });

  group('V2-12: Transparenz reduzieren / Hoher Kontrast', () {
    testWidgets('Kopf-Karte, Leiste, Sheet, Manny-Knopf opak, kein Blur, Welt '
        'ohne Dekor, Ränder ≥ 4,3:1', (WidgetTester tester) async {
      for (final Brightness b in Brightness.values) {
        for (final WorldPhase p in WorldPhase.values) {
          await pumpWorld(
            tester,
            Stack(
              children: <Widget>[
                v2Showcase(withDialog: false),
                const Align(
                  alignment: Alignment.center,
                  child: CuraSheetFrame(
                    header: Text('Kopf'),
                    body: Text('Inhalt'),
                  ),
                ),
              ],
            ),
            phase: p,
            brightness: b,
            highContrast: true,
            size: _board,
          );
          await precacheImages(tester);
          final String where = '${p.name} ${b.name}';
          expect(backdropCount(tester), 0, reason: where);
          // Welt ohne Körnung, Dunst, Sterne, Sonne/Mond.
          final Iterable<WorldPainter> painters = tester
              .widgetList<CustomPaint>(find.byType(CustomPaint))
              .map((CustomPaint c) => c.painter)
              .whereType<WorldPainter>();
          expect(painters, isNotEmpty);
          expect(
            painters.every((WorldPainter w) => !w.decor),
            isTrue,
            reason: where,
          );
          final CuraColors c = colorsAt(tester, find.byType(FloatingNav));
          // Opak: Leiste, Sheet, Manny-Knopf (helle Scheibe), Kopf-Karte.
          expect(
            decorationsUnder(
              tester,
              find.byType(FloatingNav),
            ).any((BoxDecoration x) => x.color == c.surfaceOpaque),
            isTrue,
            reason: where,
          );
          expect(
            decorationsUnder(
              tester,
              find.byType(CuraSheetFrame),
            ).any((BoxDecoration x) => x.color == c.surfaceOpaque),
            isTrue,
          );
          expect(
            decorationsUnder(
              tester,
              find.byType(MannyButton),
            ).any((BoxDecoration x) => x.color == c.mannyButtonGlass),
            isTrue,
          );
          expect(c.mannyButtonGlass.a, 1);
          expect(
            decorationsUnder(
              tester,
              find.byType(HeaderCard),
            ).any((BoxDecoration x) => x.color != null && x.color!.a == 1),
            isTrue,
          );
          // Ränder ≥ 4,3:1 gegen die Fläche.
          expect(
            contrastOver(c.borderControlHc, c.surfaceOpaque),
            greaterThanOrEqualTo(4.3),
            reason: where,
          );
          expect(
            contrastOver(c.lightSurfaceBorder, c.mannyButtonGlass),
            greaterThanOrEqualTo(4.3),
            reason: where,
          );
        }
      }
    });
  });

  group('V2-23: Zielgrößen und Abstände', () {
    testWidgets('alle tippbaren Ziele ≥ 48 × 48 dp, Abstand ≥ 8 dp', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      for (final WorldLook l in allWorldLooks()) {
        await _pumpShowcase(tester, l);
        final List<Rect> targets = _tapTargets(tester);
        expect(targets.length, greaterThan(15), reason: l.name);
        for (final Rect r in targets) {
          expect(
            r.width,
            greaterThanOrEqualTo(48 - 0.01),
            reason: '$r ${l.name}',
          );
          expect(
            r.height,
            greaterThanOrEqualTo(48 - 0.01),
            reason: '$r ${l.name}',
          );
        }
        for (int i = 0; i < targets.length; i++) {
          for (int j = i + 1; j < targets.length; j++) {
            final Rect a = targets[i];
            final Rect b = targets[j];
            final double dx = math.max(
              0,
              math.max(a.left, b.left) - math.min(a.right, b.right),
            );
            final double dy = math.max(
              0,
              math.max(a.top, b.top) - math.min(a.bottom, b.bottom),
            );
            final double gap = math.sqrt(dx * dx + dy * dy);
            expect(
              gap,
              greaterThanOrEqualTo(8 - 0.01),
              reason: '$a und $b liegen zu dicht (${l.name})',
            );
          }
        }
      }
      h.dispose();
    });

    testWidgets('Guidelines: Tap-Ziele und Labels', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _pumpShowcase(
        tester,
        const WorldLook(WorldPhase.midday, Brightness.light),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });
  });

  group('V2-32: Mandarine nie als Textfarbe', () {
    testWidgets('kein Text und kein Symbol in `accent`, Orange als Text nur '
        'accent-text', (WidgetTester tester) async {
      for (final WorldLook l in allWorldLooks()) {
        await _pumpShowcase(tester, l);
        final CuraColors c = colorsAt(tester, find.byType(FloatingNav));
        for (final Text t in tester.widgetList<Text>(find.byType(Text))) {
          final Color? color = t.style?.color;
          if (color == null) continue;
          expect(color, isNot(c.accent), reason: '"${t.data}" ${l.name}');
          expect(color, isNot(c.accentTop), reason: '"${t.data}" ${l.name}');
        }
        for (final Icon i in tester.widgetList<Icon>(find.byType(Icon))) {
          if (i.color == null) continue;
          // Symbole dürfen nie die reine Mandarine-Füllung als Farbe tragen,
          // außer als Fläche; hier gilt das Gleiche wie für Text.
          expect(i.color, isNot(c.accent), reason: '${i.icon} ${l.name}');
        }
        expect(c.accentText, isNot(c.accent));
        expect(
          contrastOver(c.accentText, c.card),
          greaterThanOrEqualTo(4.5),
          reason: l.name,
        );
      }
    });
  });
}
