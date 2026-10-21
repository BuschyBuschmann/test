// MannyLookPicker (Brief-Ergänzung 1, 6a/6b; V2-66, V2-73, V2-74, V2-75): zwei
// Karten als Radio-Gruppe, Vorbelegung, Zustände nie nur Farbe, Radio-Semantik,
// Tastatur (ein Tab-Stopp, Pfeiltasten, Leertaste), Fokusring, Hit-Areas,
// untereinander bei schmaler Breite oder großer Schrift, Bewegung.
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/manny_look.dart';
import 'package:curaone/theme/contrast.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/ui/components/manny.dart';
import 'package:curaone/ui/components/manny_look_picker.dart';

import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/world_app.dart';

class _Host extends StatefulWidget {
  const _Host({this.log, this.after});

  final FocusNode? after;
  final List<MannyLook>? log;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  MannyLook value = MannyLook.brille;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: <Widget>[
          MannyLookPicker(
            value: value,
            onChanged: (MannyLook l) {
              widget.log?.add(l);
              setState(() => value = l);
            },
          ),
          if (widget.after != null)
            Focus(
              focusNode: widget.after,
              child: const SizedBox(width: 20, height: 20),
            ),
        ],
      ),
    );
  }
}

Finder _card(String name) => find.ancestor(
  of: find.text(name),
  matching: find.byWidgetPredicate(
    (Widget w) =>
        w is AnimatedContainer &&
        w.constraints?.minWidth == CuraSize.touchTarget,
  ),
);

BoxDecoration _deco(WidgetTester tester, String name) =>
    tester.widget<AnimatedContainer>(_card(name)).decoration! as BoxDecoration;

void main() {
  group('Aufbau und Zustände', () {
    testWidgets('zwei gleich große Karten nebeneinander, Mit Brille links, '
        'Mindesthöhe 300 dp', (WidgetTester tester) async {
      await pumpWorld(tester, const _Host());
      final Rect with_ = tester.getRect(_card(S.mannyLookWith));
      final Rect without = tester.getRect(_card(S.mannyLookWithout));
      expect(with_.width, closeTo(without.width, 0.01));
      expect(with_.left, lessThan(without.left));
      expect(with_.top, without.top);
      expect(with_.height, greaterThanOrEqualTo(300));
      expect(without.height, greaterThanOrEqualTo(300));
      // 390 dp Breite: je ca. 175 dp.
      expect(with_.width, closeTo(175, 6));
      expect(find.text(S.mannyLookWith), findsOneWidget);
      expect(find.text(S.mannyLookWithout), findsOneWidget);
    });

    testWidgets('Vorbelegung: Mit Brille gewählt, „Ausgewählt“ nur dort', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, const _Host());
      expect(find.text(S.mannyLookSelected), findsOneWidget);
      final CuraColors c = colorsAt(tester, find.byType(MannyLookPicker));
      final BoxDecoration sel = _deco(tester, S.mannyLookWith);
      final BoxDecoration off = _deco(tester, S.mannyLookWithout);
      expect(sel.color, c.mannyChoiceSelectedFill);
      expect(c.mannyChoiceSelectedFill, const Color(0xFFFFF1E4));
      expect((sel.border! as Border).top.color, c.accent);
      expect((sel.border! as Border).top.width, 3);
      expect((off.border! as Border).top.color, c.controlBorder);
      expect((off.border! as Border).top.width, 3);
      // Haken nur in der gewählten Karte, Radio-Kreis 28 dp in beiden.
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(
        tester.getSize(
          find.descendant(
            of: _card(S.mannyLookWith),
            matching: find.byWidgetPredicate(
              (Widget w) => w is SizedBox && w.width == 28 && w.height == 28,
            ),
          ),
        ),
        const Size(28, 28),
      );
    });

    testWidgets(
      'Zeigt Manny normal in beiden Varianten, Bild höchstens 190 dp',
      (WidgetTester tester) async {
        await pumpWorld(tester, const _Host());
        await precacheImages(tester);
        final List<MannyIllustration> m = tester
            .widgetList<MannyIllustration>(find.byType(MannyIllustration))
            .toList();
        expect(m.map((MannyIllustration x) => x.look), <MannyLook?>[
          MannyLook.brille,
          MannyLook.ohne,
        ]);
        for (final MannyIllustration x in m) {
          expect(x.pose, MannyPose.neutral);
          expect(x.height, lessThanOrEqualTo(190));
        }
        for (final Element e in find.byType(Image).evaluate()) {
          final Size s = tester.getSize(find.byWidget(e.widget));
          expect(s.height, lessThanOrEqualTo(CuraSize.mannyChoiceMaxHeight));
          expect(s.height, lessThanOrEqualTo(CuraSize.mannyBodyHeight));
        }
      },
    );

    testWidgets('Tipp wählt sofort, genau eine Karte bleibt gewählt', (
      WidgetTester tester,
    ) async {
      final List<MannyLook> log = <MannyLook>[];
      await pumpWorld(tester, _Host(log: log));
      await tester.tap(find.text(S.mannyLookWithout));
      await tester.pump(const Duration(milliseconds: 150));
      expect(log, <MannyLook>[MannyLook.ohne]);
      expect(find.text(S.mannyLookSelected), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      final CuraColors c = colorsAt(tester, find.byType(MannyLookPicker));
      expect(
        ((_deco(tester, S.mannyLookWithout)).border! as Border).top.color,
        c.accent,
      );
      // Erneuter Tipp auf die gewählte Karte ändert nichts.
      await tester.tap(find.text(S.mannyLookWithout));
      expect(log, <MannyLook>[MannyLook.ohne]);
    });

    testWidgets('Zustand nie nur Farbe: Haken, Text und Kreis; Kontraste', (
      WidgetTester tester,
    ) async {
      for (final Brightness b in Brightness.values) {
        await pumpWorld(tester, const _Host(), brightness: b);
        await tester.pumpAndSettle();
        final CuraColors c = colorsAt(tester, find.byType(MannyLookPicker));
        expect(find.text(S.mannyLookSelected), findsOneWidget);
        // Text „Ausgewählt“ (accent-text) und Name (text-1) auf der Fläche.
        expect(
          contrastRatio(c.accentText, c.mannyChoiceSelectedFill),
          greaterThanOrEqualTo(4.5),
          reason: b.name,
        );
        expect(
          contrastRatio(c.text1, c.mannyChoiceSelectedFill),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrastRatio(c.text1, c.surfaceOpaque),
          greaterThanOrEqualTo(4.5),
        );
        // Rand der nicht gewählten Karte ≥ 3:1 gegen die Fläche.
        expect(
          contrastOver(c.controlBorder, c.surfaceOpaque),
          greaterThanOrEqualTo(3),
          reason: b.name,
        );
      }
    });
  });

  group('Radio-Semantik und Tastatur (V2-66)', () {
    testWidgets('Gruppe „Manny-Look“; Karte „Manny mit Brille, ausgewählt, 1 '
        'von 2“; Bilder ausgeblendet', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpWorld(tester, const _Host());
      expect(
        find.bySemanticsLabel('Manny mit Brille, ausgewählt, 1 von 2'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Manny ohne Brille, nicht ausgewählt, 2 von 2'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(S.mannyLookGroup), findsOneWidget);
      // Das Bild-Label „Manny, dein Begleiter“ kommt nicht dazu.
      expect(find.bySemanticsLabel(S.mannyImageLabel), findsNothing);
      final SemanticsNode node = tester.getSemantics(
        find.bySemanticsLabel('Manny mit Brille, ausgewählt, 1 von 2'),
      );
      final SemanticsData d = node.getSemanticsData();
      expect(d.flagsCollection.isChecked, CheckedState.isTrue);
      expect(d.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(d.hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(find.text(S.mannyLookWithout));
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        find.bySemanticsLabel('Manny ohne Brille, ausgewählt, 2 von 2'),
        findsOneWidget,
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      h.dispose();
    });

    testWidgets('Tab hat einen Stopp in der Gruppe; Pfeiltasten wechseln, '
        'Leertaste wählt, Fokusring um die gewählte Karte', (
      WidgetTester tester,
    ) async {
      final List<MannyLook> log = <MannyLook>[];
      final FocusNode after = FocusNode();
      addTearDown(after.dispose);
      await pumpWorld(tester, _Host(log: log, after: after));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      // Ein Stopp: Fokus in der Gruppe, Ring sichtbar.
      final Finder rings = find.descendant(
        of: find.byType(MannyLookPicker),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).border != null &&
              ((w.decoration as BoxDecoration).border! as Border).top.width ==
                  CuraSize.focusRingWidth &&
              ((w.decoration as BoxDecoration).border! as Border).top.color ==
                  CuraColors.light.focusRing,
        ),
      );
      expect(rings, findsOneWidget, reason: 'Ring 3 dp um genau eine Karte');
      final Rect card = tester.getRect(_card(S.mannyLookWith));
      expect(
        tester.getRect(rings),
        Rect.fromLTRB(
          card.left - 5,
          card.top - 5,
          card.right + 5,
          card.bottom + 5,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 150));
      expect(log, <MannyLook>[MannyLook.ohne]);
      expect(rings, findsOneWidget);
      final Rect card2 = tester.getRect(_card(S.mannyLookWithout));
      expect(tester.getRect(rings).left, card2.left - 5);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 150));
      expect(log.last, MannyLook.brille, reason: 'umlaufend');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump(const Duration(milliseconds: 150));
      expect(log.last, MannyLook.ohne);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 150));
      expect(log.last, MannyLook.brille);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(log.last, MannyLook.brille);
      // Ein zweiter Tab verlässt die Gruppe (kein zweiter Stopp).
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(after.hasFocus, isTrue);
      expect(rings, findsNothing);
    });
  });

  group('Hit-Area und Layout (V2-23, V2-75)', () {
    testWidgets('ganze Karte ist Ziel, ≥ 48 dp, Abstand ≥ 8 dp', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, const _Host());
      final Rect a = tester.getRect(_card(S.mannyLookWith));
      final Rect b = tester.getRect(_card(S.mannyLookWithout));
      expect(a.size.shortestSide, greaterThanOrEqualTo(48));
      expect(b.left - a.right, greaterThanOrEqualTo(8));
      // Tipp in die Ecke der Karte wählt.
      final List<MannyLook> log = <MannyLook>[];
      await pumpWorld(tester, _Host(log: log));
      final Rect r = tester.getRect(_card(S.mannyLookWithout));
      await tester.tapAt(r.bottomRight - const Offset(4, 4));
      expect(log, <MannyLook>[MannyLook.ohne]);
    });

    testWidgets('320 × 568 und 200 % Schrift: Karten untereinander, nichts '
        'abgeschnitten, kein horizontales Scrollen', (
      WidgetTester tester,
    ) async {
      for (final (Size, double) v in <(Size, double)>[
        (const Size(320, 568), 1),
        (const Size(390, 844), 2),
        (const Size(320, 568), 2),
      ]) {
        await pumpWorld(tester, const _Host(), size: v.$1, textScale: v.$2);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$v');
        final Rect a = tester.getRect(_card(S.mannyLookWith));
        final Rect b = tester.getRect(_card(S.mannyLookWithout));
        expect(
          b.top,
          greaterThanOrEqualTo(a.bottom + 8),
          reason: 'untereinander $v',
        );
        expect(a.left, b.left);
        expect(a.right, lessThanOrEqualTo(v.$1.width - 16 + 0.01));
        expect(a.left, greaterThanOrEqualTo(16 - 0.01));
        // Bild links 120 dp.
        final MannyIllustration m = tester.widget(
          find
              .descendant(
                of: _card(S.mannyLookWith),
                matching: find.byType(MannyIllustration),
              )
              .first,
        );
        expect(m.height, CuraSize.mannyChoiceStackedImage);
        expect(
          tester
              .getRect(
                find.descendant(
                  of: _card(S.mannyLookWith),
                  matching: find.byType(Image),
                ),
              )
              .left,
          lessThan(tester.getRect(find.text(S.mannyLookWith)).left),
          reason: 'Bild links, Text rechts',
        );
      }
    });

    testWidgets('L1K M1: „Ausgewählt“ wird bei 100 bis 200 % nicht '
        'abgeschnitten, bricht nicht und die Kartenhöhe springt bei Wechsel '
        'nicht', (WidgetTester tester) async {
      for (final (Size, double) v in <(Size, double)>[
        (const Size(390, 844), 1),
        (const Size(390, 844), 1.3),
        (const Size(390, 844), 2),
        (const Size(320, 568), 1),
        (const Size(320, 568), 2),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpWorld(tester, const _Host(), size: v.$1, textScale: v.$2);
        await tester.pumpAndSettle();
        final Rect card = tester.getRect(_card(S.mannyLookWith));
        final Rect state = tester.getRect(find.text(S.mannyLookSelected));
        expect(card.contains(state.topLeft), isTrue, reason: '$v');
        expect(
          state.bottom,
          lessThanOrEqualTo(card.bottom - CuraSize.mannyChoiceBorder),
          reason: 'Text liegt ganz in der Karte $v',
        );
        // Eine Zeile: Höhe unter dem Doppelten der skalierten Zeilenhöhe.
        final double line =
            TextScaler.linear(v.$2 > 1.3 ? 1.3 : v.$2).scale(14) * 20 / 14;
        expect(state.height, lessThan(line * 1.6), reason: 'eine Zeile $v');
        // Wechsel der Wahl ändert die Höhe der Karten nicht.
        final double before = card.height;
        final double otherBefore = tester
            .getRect(_card(S.mannyLookWithout))
            .height;
        await tester.tap(_card(S.mannyLookWithout));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(_card(S.mannyLookWith)).height,
          before,
          reason: 'Karte „Mit Brille“ springt nicht $v',
        );
        expect(
          tester.getRect(_card(S.mannyLookWithout)).height,
          otherBefore,
          reason: 'Karte „Ohne Brille“ springt nicht $v',
        );
      }
    });

    test('Umschaltung: unter 360 dp oder über 130 %', () {
      expect(MannyLookPicker.stackedFor(359.9, TextScaler.noScaling), isTrue);
      expect(MannyLookPicker.stackedFor(360, TextScaler.noScaling), isFalse);
      expect(
        MannyLookPicker.stackedFor(390, const TextScaler.linear(1.3)),
        isFalse,
      );
      expect(
        MannyLookPicker.stackedFor(390, const TextScaler.linear(1.31)),
        isTrue,
      );
    });
  });

  group('Bewegung (V2-74)', () {
    testWidgets('Wechsel überblendet höchstens 120 ms; reduziert ebenso', (
      WidgetTester tester,
    ) async {
      for (final bool reduced in <bool>[false, true]) {
        if (reduced) {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(
                reduceMotion: true,
                disableAnimations: true,
              );
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
        }
        await pumpWorld(tester, const _Host());
        await tester.tap(find.text(S.mannyLookWithout));
        await tester.pump();
        final AnimatedContainer c = tester.widget(_card(S.mannyLookWithout));
        expect(
          c.duration,
          lessThanOrEqualTo(const Duration(milliseconds: 120)),
        );
        await tester.pump(const Duration(milliseconds: 121));
        expect(
          tester.hasRunningAnimations,
          isFalse,
          reason: 'reduced=$reduced',
        );
      }
    });

    testWidgets('Manny auf den Karten ist statisch (kein Ticker im Bild)', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, const _Host());
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('Hoher Kontrast', () {
    testWidgets('Rand 3 dp -hc, Flächen opak, bedienbar', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, const _Host(), highContrast: true);
      await tester.pumpAndSettle();
      final CuraColors c = colorsAt(tester, find.byType(MannyLookPicker));
      final BoxDecoration off = _deco(tester, S.mannyLookWithout);
      expect((off.border! as Border).top.color, c.borderControlHc);
      expect(off.color!.a, 1);
      expect(
        contrastOver(c.borderControlHc, c.surfaceOpaque),
        greaterThanOrEqualTo(4.3),
      );
    });
  });
}
