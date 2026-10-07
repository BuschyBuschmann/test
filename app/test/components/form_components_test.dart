// ChoiceCard, StepProgress, CuraTextField, DateCard, MicButton, CuraLabel
// (Brief 5.7–5.9, UI-11, UI-14, UI-16, UI-32, UI-35, UI-53 Regel 6).
import 'package:curaone/theme/contrast.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_motion.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/ui/components/choice_card.dart';
import 'package:curaone/ui/components/cura_label.dart';
import 'package:curaone/ui/components/cura_text_field.dart';
import 'package:curaone/ui/components/date_card.dart';
import 'package:curaone/ui/components/glass_card.dart';
import 'package:curaone/ui/components/mic_button.dart';
import 'package:curaone/ui/components/step_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/pump_app.dart';

Widget _pad(Widget child) => Padding(
  padding: const EdgeInsets.all(16),
  child: Align(alignment: Alignment.topCenter, child: child),
);

BoxDecoration _borderBox(WidgetTester tester, Finder f) => decorationsUnder(
  tester,
  f,
).firstWhere((BoxDecoration d) => d.border != null);

void main() {
  group('ChoiceCard (Brief 5.7)', () {
    Widget card({
      bool selected = false,
      VoidCallback? onPressed,
      String? subtitle,
      IconData? icon,
    }) => _pad(
      ChoiceCard(
        title: 'Kreuzbandriss (ACL)',
        subtitle: subtitle,
        selected: selected,
        onPressed: onPressed ?? () {},
        leadingIcon: icon,
      ),
    );

    testWidgets('nicht gewählt: Glas, Rand border-control, ≥ 64 dp, heading', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, card());
      await tester.pumpAndSettle();
      final Finder f = find.byType(ChoiceCard);
      final CuraColors c = colorsAt(tester, f);
      expect(
        find.descendant(of: f, matching: find.byType(GlassCard)),
        findsOneWidget,
      );
      expect(tester.getSize(f).height, greaterThanOrEqualTo(64));
      expect(tester.getSize(f).width, 390 - 32);
      expect(
        _borderBox(tester, f).border,
        Border.all(color: c.borderControl, width: 1.5),
      );
      final TextStyle s = tester
          .widget<Text>(find.text('Kreuzbandriss (ACL)'))
          .style!;
      expect(s.fontFamily, 'BricolageGrotesque');
      expect(s.fontSize, 18);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(
        decorationsUnder(
          tester,
          f,
        ).any((BoxDecoration d) => d.color == c.accentSoft),
        isFalse,
      );
    });

    testWidgets('gewählt: accent-soft, 2 dp Rand accent-hi, Haken rechts', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, card(selected: true));
      await tester.pumpAndSettle();
      final Finder f = find.byType(ChoiceCard);
      final CuraColors c = colorsAt(tester, f);
      expect(
        _borderBox(tester, f).border,
        Border.all(color: c.accentHi, width: 2),
      );
      expect(
        decorationsUnder(
          tester,
          f,
        ).any((BoxDecoration d) => d.color == c.accentSoft),
        isTrue,
      );
      final Finder check = find.byIcon(Icons.check_circle_rounded);
      expect(check, findsOneWidget);
      expect(tester.widget<Icon>(check).color, c.accentHi);
      expect(
        tester.getRect(check).right,
        greaterThan(tester.getRect(f).right - 32),
      );
    });

    testWidgets('Randwechsel in dur-fast (120 ms), danach ruhig', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<bool> selected = ValueNotifier<bool>(false);
      addTearDown(selected.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: selected,
          builder: (BuildContext context, bool v, Widget? _) =>
              card(selected: v),
        ),
      );
      await tester.pumpAndSettle();
      selected.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(milliseconds: 61));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('reduzierte Bewegung (Systemsignal und Preview-Override): '
        'Randwechsel höchstens 120 ms, danach keine Animation', (
      WidgetTester tester,
    ) async {
      for (final bool viaPreview in <bool>[false, true]) {
        if (!viaPreview) {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(reduceMotion: true);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
        }
        final ValueNotifier<bool> selected = ValueNotifier<bool>(false);
        addTearDown(selected.dispose);
        Widget inner() => ValueListenableBuilder<bool>(
          valueListenable: selected,
          builder: (BuildContext context, bool v, Widget? _) =>
              card(selected: v),
        );
        await pumpApp(
          tester,
          viaPreview
              ? PreviewMotionOverride(reduceMotion: true, child: inner())
              : inner(),
        );
        await tester.pumpAndSettle();
        selected.value = true;
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 121));
        expect(tester.hasRunningAnimations, isFalse);
      }
    });

    testWidgets('Untertitel secondary; Stift-Icon der Escape-Hatch-Karte', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        card(subtitle: 'Zum Beispiel Zerrung', icon: Icons.edit_rounded),
      );
      expect(find.text('Zum Beispiel Zerrung'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Zum Beispiel Zerrung')).style!.fontSize,
        14,
      );
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    });

    testWidgets('Semantik „…, Auswahl, (nicht) ausgewählt“, Tipp, Tastatur', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      int taps = 0;
      await pumpApp(tester, card(onPressed: () => taps++));
      expect(
        find.bySemanticsLabel('Kreuzbandriss (ACL), Auswahl, nicht ausgewählt'),
        findsOneWidget,
      );
      await tester.tap(find.byType(ChoiceCard));
      expect(taps, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 2);
      await pumpApp(tester, card(selected: true));
      expect(
        find.bySemanticsLabel('Kreuzbandriss (ACL), Auswahl, ausgewählt'),
        findsOneWidget,
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });

    testWidgets('Pressed: Überlagerung Weiß 10 %', (WidgetTester tester) async {
      await pumpApp(tester, card());
      final CuraColors c = colorsAt(tester, find.byType(ChoiceCard));
      final TestGesture g = await tester.startGesture(
        tester.getCenter(find.byType(ChoiceCard)),
      );
      await tester.pump();
      expect(
        decorationsUnder(
          tester,
          find.byType(ChoiceCard),
        ).any((BoxDecoration d) => d.color == c.pressedOverlay),
        isTrue,
      );
      await g.up();
    });

    testWidgets('Hoher Kontrast: opak, Rand border-control-hc; 200 % und '
        '320 dp ohne Überlauf', (WidgetTester tester) async {
      await pumpApp(
        tester,
        card(
          subtitle: 'Eine längere Zeile, die umbrechen muss, ohne etwas abzuschneiden',
        ),
        highContrast: true,
        size: Viewports.small,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      final CuraColors c = colorsAt(tester, find.byType(ChoiceCard));
      expect(
        _borderBox(tester, find.byType(ChoiceCard)).border,
        Border.all(color: c.borderControlHc, width: 1.5),
      );
    });

    testWidgets('Kontrast text-1 auf gewählter Fläche ≥ 4,5 (Brief 3.1)', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, card(selected: true));
      final CuraColors c = colorsAt(tester, find.byType(ChoiceCard));
      final Color ground = compose(c.accentSoft, glassWithGlow(c));
      expect(contrastRatio(c.text1, ground), greaterThanOrEqualTo(4.5));
      expect(contrastRatio(c.accentHi, ground), greaterThanOrEqualTo(3));
    });
  });

  group('StepProgress (Brief 5.8)', () {
    testWidgets(
      'Text „Schritt X von 4“, vier Segmente 4 dp hoch, 4 dp Abstand, '
      'erledigt und aktuell accent, offen Weiß 18 %',
      (WidgetTester tester) async {
        await pumpApp(tester, _pad(const StepProgress(step: 3)));
        final Finder f = find.byType(StepProgress);
        final CuraColors c = colorsAt(tester, f);
        expect(find.text('Schritt 3 von 4'), findsOneWidget);
        final TextStyle s = tester
            .widget<Text>(find.text('Schritt 3 von 4'))
            .style!;
        expect(s.fontSize, 14);
        expect(s.color, c.text2);
        final List<BoxDecoration> segs = decorationsUnder(
          tester,
          f,
        ).where((BoxDecoration d) => d.color != null).toList();
        expect(segs.length, 4);
        expect(segs.map((BoxDecoration d) => d.color).toList(), <Color?>[
          c.accent,
          c.accent,
          c.accent,
          c.progressOff,
        ]);
        expect(c.progressOff.a, closeTo(0.18, 0.005));
        final List<Rect> rects = find
            .descendant(of: f, matching: find.byType(DecoratedBox))
            .evaluate()
            .map((Element e) => tester.getRect(find.byWidget(e.widget)))
            .toList();
        expect(rects.every((Rect r) => r.height == 4), isTrue);
        expect(rects[1].left - rects[0].right, 4);
      },
    );

    testWidgets('Screenreader liest nur den Text', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(tester, _pad(const StepProgress(step: 2)));
      expect(find.bySemanticsLabel('Schritt 2 von 4'), findsOneWidget);
      final Iterable<SemanticsNode> labeled = <SemanticsNode>[
        tester.getSemantics(find.text('Schritt 2 von 4')),
      ];
      expect(labeled.single.label, 'Schritt 2 von 4');
      h.dispose();
    });

    testWidgets('Schritt 1 bis 4 passen sich an', (WidgetTester tester) async {
      for (int i = 1; i <= 4; i++) {
        await pumpApp(tester, _pad(StepProgress(step: i)));
        final CuraColors c = colorsAt(tester, find.byType(StepProgress));
        final int filled = decorationsUnder(
          tester,
          find.byType(StepProgress),
        ).where((BoxDecoration d) => d.color == c.accent).length;
        expect(filled, i);
        expect(find.text('Schritt $i von 4'), findsOneWidget);
      }
    });
  });

  group('CuraTextField (Brief 5.9)', () {
    testWidgets('Label oberhalb, 56 dp, Rand border-control, Fokus accent-hi '
        '2 dp, Eingabe body', (WidgetTester tester) async {
      final TextEditingController ctrl = TextEditingController();
      addTearDown(ctrl.dispose);
      await pumpApp(
        tester,
        _pad(CuraTextField(label: 'Dein Name', controller: ctrl)),
      );
      final Finder f = find.byType(CuraTextField);
      final CuraColors c = colorsAt(tester, f);
      expect(find.text('Dein Name'), findsOneWidget);
      expect(
        tester.getRect(find.text('Dein Name')).bottom,
        lessThan(tester.getRect(find.byType(TextField)).top),
      );
      final Finder box = find.descendant(
        of: f,
        matching: find.byType(GlassCard),
      );
      expect(tester.getSize(box).height, 56);
      expect(
        _borderBox(tester, box).border,
        Border.all(color: c.borderControl, width: 1.5),
      );
      // Tastatur öffnet sich erst beim Antippen.
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
      expect(
        _borderBox(tester, box).border,
        Border.all(color: c.accentHi, width: 2),
      );
      await tester.enterText(find.byType(TextField), 'Jakob');
      expect(ctrl.text, 'Jakob');
      final TextField tf = tester.widget(find.byType(TextField));
      expect(tf.style!.fontSize, 16);
      expect(tf.style!.color, c.text1);
    });

    testWidgets('Hinweistext text-2, Hoher Kontrast opak mit Rand -hc', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        _pad(
          const CuraTextField(label: 'Was ist passiert?', hintText: 'Optional'),
        ),
        highContrast: true,
      );
      final CuraColors c = colorsAt(tester, find.byType(CuraTextField));
      expect(find.text('Optional'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Optional')).style!.color, c.text2);
      expect(
        _borderBox(tester, find.byType(GlassCard)).border,
        Border.all(color: c.borderControlHc, width: 1.5),
      );
    });

    testWidgets('Semantik: Textfeld mit Label', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(tester, _pad(const CuraTextField(label: 'Dein Name')));
      final SemanticsNode n = tester.getSemantics(find.byType(TextField));
      expect(n, isSemantics(label: 'Dein Name', isTextField: true));
      // Das sichtbare Label wird nicht zusätzlich als eigener Knoten gelesen.
      expect(n.label, 'Dein Name');
      expect(
        find.ancestor(
          of: find.text('Dein Name'),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      h.dispose();
    });

    testWidgets('eigener FocusNode wird verwendet; 200 % und 320 dp '
        'ohne Überlauf', (WidgetTester tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await pumpApp(
        tester,
        _pad(CuraTextField(label: 'Dein Name', focusNode: node)),
        size: Viewports.small,
        textScale: 2,
      );
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('DateCard', () {
    testWidgets('Platzhalter „Datum wählen“ (text-2), Kalender-Icon, Rand '
        'border-control, ≥ 64 dp', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(tester, _pad(DateCard(onPressed: () => taps++)));
      final Finder f = find.byType(DateCard);
      final CuraColors c = colorsAt(tester, f);
      expect(find.text('Datum wählen'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Datum wählen')).style!.color,
        c.text2,
      );
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
      expect(tester.getSize(f).height, greaterThanOrEqualTo(64));
      expect(
        _borderBox(tester, f).border,
        Border.all(color: c.borderControl, width: 1.5),
      );
      await tester.tap(f);
      expect(taps, 1);
    });

    testWidgets('mit Datum text-1; Semantik liest das Datum', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(
        tester,
        _pad(DateCard(valueText: '3. September 2026', onPressed: () {})),
      );
      final CuraColors c = colorsAt(tester, find.byType(DateCard));
      expect(
        tester.widget<Text>(find.text('3. September 2026')).style!.color,
        c.text1,
      );
      expect(find.bySemanticsLabel('3. September 2026'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });
  });

  group('MicButton', () {
    testWidgets('56 dp Kreis, Glas, Rand border-control, Icon text-1, Label '
        'und Tooltip', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      int taps = 0;
      await pumpApp(tester, _pad(MicButton(onPressed: () => taps++)));
      final Finder f = find.byType(MicButton);
      final CuraColors c = colorsAt(tester, f);
      expect(tester.getSize(f), const Size(56, 56));
      expect(
        find.descendant(of: f, matching: find.byType(GlassCard)),
        findsOneWidget,
      );
      expect(
        _borderBox(tester, f).border,
        Border.all(color: c.borderControl, width: 1.5),
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.mic_none_rounded)).color,
        c.text1,
      );
      expect(
        find.bySemanticsLabel('Spracheingabe, noch nicht verfügbar'),
        findsOneWidget,
      );
      expect(
        find.byTooltip('Spracheingabe, noch nicht verfügbar'),
        findsOneWidget,
      );
      await tester.tap(f);
      expect(taps, 1);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });

    testWidgets('Hoher Kontrast: opak mit Rand -hc', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        _pad(MicButton(onPressed: () {})),
        highContrast: true,
      );
      final CuraColors c = colorsAt(tester, find.byType(MicButton));
      expect(
        _borderBox(tester, find.byType(MicButton)).border,
        Border.all(color: c.borderControlHc, width: 1.5),
      );
    });
  });

  group('CuraLabel (Brief 3.3)', () {
    testWidgets('Großbuchstaben nur in der Darstellung, Screenreader liest '
        'die normale Schreibweise als Überschrift', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(tester, _pad(const CuraLabel('Dein Profil')));
      expect(find.text('DEIN PROFIL'), findsOneWidget);
      expect(find.text('Dein Profil'), findsNothing);
      final CuraColors c = colorsAt(tester, find.byType(CuraLabel));
      final TextStyle s = tester.widget<Text>(find.text('DEIN PROFIL')).style!;
      expect(s.fontSize, 13);
      expect(s.fontWeight, FontWeight.w600);
      expect(s.letterSpacing, closeTo(13 * 0.06, 0.001));
      expect(s.color, c.text2);
      expect(
        tester.getSemantics(find.text('DEIN PROFIL')),
        matchesSemantics(label: 'Dein Profil', isHeader: true),
      );
      h.dispose();
    });

    testWidgets('Farbe und Ausrichtung wählbar, keine Überschrift auf Wunsch', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(
        tester,
        _pad(
          const CuraLabel(
            'Beispielverlauf',
            header: false,
            textAlign: TextAlign.center,
          ),
        ),
      );
      final CuraColors c = colorsAt(tester, find.byType(CuraLabel));
      expect(
        tester.widget<Text>(find.text('BEISPIELVERLAUF')).textAlign,
        TextAlign.center,
      );
      expect(c.text2, isNotNull);
      expect(
        tester.getSemantics(find.text('BEISPIELVERLAUF')),
        matchesSemantics(label: 'Beispielverlauf'),
      );
      h.dispose();
    });
  });
}
