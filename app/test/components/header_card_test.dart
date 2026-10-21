// HeaderCard, HeaderChip, HeaderProgress, WorldLabelChip (Design-Brief v2, 4 und
// 3.1; V2-5, V2-10, V2-12, V2-33): Glas aus der Welt mit Blur σ 24, Radius 32,
// aller Text `#FFFFFF`, Wert des Balkens auch als Text, Label-Chip aus der Welt.
import 'dart:ui' as ui;

import 'package:curaone/logic/world_time.dart';
import 'package:curaone/theme/contrast.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/tokens.dart';
import 'package:curaone/theme/world_tokens.dart';
import 'package:curaone/ui/components/header_card.dart';
import 'package:curaone/ui/components/world_label_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/world_app.dart';
import '../support/backdrops.dart';

Widget _card({Widget? trailing, String? subtitle = 'Phase 2 · Kreuzband'}) =>
    Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: HeaderCard(
          title: 'Woche 5',
          subtitle: subtitle,
          trailing: trailing,
          chips: const <Widget>[
            HeaderChip(icon: Icons.local_fire_department_rounded, label: '12'),
            HeaderChip(
              icon: Icons.ac_unit_rounded,
              label: '1',
              semanticLabel: '1 Freeze',
            ),
          ],
          progress: const HeaderProgress(value: 4 / 7, label: '4 von 7 Tagen'),
        ),
      ),
    );

BoxDecoration _glass(WidgetTester tester) => decorationsUnder(
  tester,
  find.byType(HeaderCard),
).firstWhere((BoxDecoration d) => d.borderRadius == BorderRadius.circular(32));

void main() {
  group('Aufbau', () {
    testWidgets('Radius 32, Blur σ 24, Innenabstand 16, Tönung der Welt', (
      WidgetTester tester,
    ) async {
      for (final WorldPhase p in kWorlds) {
        await pumpWorld(tester, _card(), phase: p);
        expect(backdropCount(tester), 1, reason: p.name);
        final BackdropFilter f = tester.widget(activeBackdrops());
        expect(
          f.filter,
          ui.ImageFilter.blur(
            sigmaX: BlurTokens.headerSigma,
            sigmaY: BlurTokens.headerSigma,
          ),
        );
        expect(BlurTokens.headerSigma, 24);
        expect(
          _glass(tester).color,
          WorldPalette.of(p).headerTint,
          reason: p.name,
        );
        expect(CuraRadius.headerCard, 32);
      }
      expect(WorldPalette.midday.headerTint.a, closeTo(0.66, 0.005));
      expect(WorldPalette.night.headerTint.a, closeTo(0.58, 0.005));
      final Rect card = tester.getRect(find.byType(HeaderCard));
      final Rect title = tester.getRect(find.text('Woche 5'));
      expect(title.left - card.left, 16);
      expect(title.top - card.top, 16);
    });

    testWidgets('Titel 30/32 Bricolage 800, Untertitel secondary, Chips mit '
        'Symbol und Text', (WidgetTester tester) async {
      await pumpWorld(tester, _card());
      final TextStyle t = tester.widget<Text>(find.text('Woche 5')).style!;
      expect(t.fontSize, 30);
      expect(t.fontWeight, FontWeight.w800);
      expect(t.fontFamily, 'BricolageGrotesque');
      final TextStyle s = tester
          .widget<Text>(find.text('Phase 2 · Kreuzband'))
          .style!;
      expect(s.fontSize, 14);
      expect(s.fontWeight, FontWeight.w500);
      expect(find.text('12'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(find.byIcon(Icons.ac_unit_rounded), findsOneWidget);
      final TextStyle c = tester.widget<Text>(find.text('12')).style!;
      expect(c.fontSize, 13);
      expect(c.fontWeight, FontWeight.w700);
    });

    testWidgets('trailing steht rechts neben dem Titel', (
      WidgetTester tester,
    ) async {
      await pumpWorld(
        tester,
        _card(trailing: const Icon(Icons.person_outline_rounded)),
      );
      expect(
        tester.getRect(find.byIcon(Icons.person_outline_rounded)).left,
        greaterThan(tester.getRect(find.text('Woche 5')).left),
      );
    });
  });

  group('Text immer #FFFFFF, Kontrast je Welt (V2-3, V2-5)', () {
    testWidgets('alle Texte in Weiß, Gewicht ≥ 500, in allen Darstellungen', (
      WidgetTester tester,
    ) async {
      for (final WorldLook l in allWorldLooks()) {
        await pumpWorld(
          tester,
          _card(),
          phase: l.phase,
          brightness: l.brightness,
          highContrast: l.highContrast,
        );
        await tester.pumpAndSettle();
        for (final String text in <String>[
          'Woche 5',
          'Phase 2 · Kreuzband',
          '12',
          '1',
          '4 von 7 Tagen',
        ]) {
          final TextStyle s = tester.widget<Text>(find.text(text)).style!;
          expect(s.color, const Color(0xFFFFFFFF), reason: '$text ${l.name}');
          expect(s.fontWeight!.value, greaterThanOrEqualTo(500), reason: text);
        }
      }
    });

    testWidgets(
      'weißer Text gegen die Tönung ≥ 4,5:1 im Worst Case (Welt-Tabelle)',
      (WidgetTester tester) async {
        for (final WorldPhase p in kWorlds) {
          expect(
            worldHeaderContrast(WorldPalette.of(p)),
            greaterThanOrEqualTo(4.5),
          );
        }
      },
    );
  });

  group('Fortschritt (V2-33)', () {
    testWidgets('Wert steht als Text; Spur mit Rand ≥ 3:1', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, _card());
      expect(find.text('4 von 7 Tagen'), findsOneWidget);
      final Finder track = find
          .descendant(
            of: find.byType(HeaderProgress),
            matching: find.byType(DecoratedBox),
          )
          .first;
      final BoxDecoration d =
          tester.widget<DecoratedBox>(track).decoration as BoxDecoration;
      final Color border = d.border!.top.color;
      expect(border, const Color(0xFFFFFFFF));
      expect(d.border!.top.width, 1);
      for (final WorldPhase p in kWorlds) {
        // Rand (Weiß) gegen die Tönung der Kopf-Karte, Worst Case Weiß darunter.
        final Color under = compose(
          WorldPalette.of(p).headerTint,
          const Color(0xFFFFFFFF),
        );
        expect(contrastRatio(border, under), greaterThanOrEqualTo(3));
      }
      // Füllung 4/7.
      final FractionallySizedBox fill = tester.widget(
        find.descendant(
          of: find.byType(HeaderProgress),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(fill.widthFactor, closeTo(4 / 7, 1e-9));
    });

    testWidgets('Screenreader liest den Wert', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpWorld(tester, _card());
      expect(find.bySemanticsLabel('4 von 7 Tagen'), findsOneWidget);
      expect(find.bySemanticsLabel('1 Freeze'), findsOneWidget);
      h.dispose();
    });
  });

  group('Transparenz reduzieren / Hoher Kontrast (V2-12)', () {
    testWidgets('Tönung zu 100 %, kein Blur, Rand ≥ 4,3:1', (
      WidgetTester tester,
    ) async {
      for (final WorldPhase p in kWorlds) {
        await pumpWorld(tester, _card(), phase: p, highContrast: true);
        await tester.pumpAndSettle();
        expect(backdropCount(tester), 0, reason: p.name);
        final BoxDecoration d = _glass(tester);
        expect(d.color!.a, 1);
        expect(d.color, WorldPalette.of(p).headerTintOpaque);
        final Color border = d.border!.top.color;
        expect(
          contrastRatio(border, d.color!),
          greaterThanOrEqualTo(4.3),
          reason: p.name,
        );
      }
    });
  });

  group('WorldLabelChip (Label-Chip, V2-5)', () {
    testWidgets('Fläche und Text aus der Welt, Kontrast je Welt', (
      WidgetTester tester,
    ) async {
      for (final WorldPhase p in kWorlds) {
        await pumpWorld(
          tester,
          const Center(child: WorldLabelChip('Tag 12')),
          phase: p,
        );
        final WorldPalette w = WorldPalette.of(p);
        final BoxDecoration d = decorationsUnder(
          tester,
          find.byType(WorldLabelChip),
        ).first;
        expect(d.color, w.chip);
        expect(
          tester.widget<Text>(find.text('Tag 12')).style!.color,
          w.chipText,
        );
        expect(w.chip.a, inInclusiveRange(0.72, 0.74));
        expect(backdropCount(tester), 0);
        expect(worldChipContrast(w), greaterThanOrEqualTo(4.5));
      }
      await pumpWorld(
        tester,
        const Center(child: WorldLabelChip('Tag 12')),
        phase: WorldPhase.night,
      );
      expect(
        tester.widget<Text>(find.text('Tag 12')).style!.color,
        const Color(0xFFFFFFFF),
      );
    });

    testWidgets('Hoher Kontrast: opake Karte mit Rand', (
      WidgetTester tester,
    ) async {
      await pumpWorld(
        tester,
        const Center(child: WorldLabelChip('Tag 12')),
        highContrast: true,
      );
      final CuraColors c = colorsAt(tester, find.byType(WorldLabelChip));
      final BoxDecoration d = decorationsUnder(
        tester,
        find.byType(WorldLabelChip),
      ).first;
      expect(d.color, c.surfaceOpaque);
      expect(d.border!.top.color, c.controlBorder);
    });
  });
}
