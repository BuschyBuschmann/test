// MannyBubble (Brief 5.6, UI-6, UI-23, UI-8, UI-34, UI-9): Aufbau, Maße, X,
// Tipp irgendwo, Live-Region, Platzierung, Blur, Hoher Kontrast, Bewegung.

import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_motion.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/pump_app.dart';

const String _text = "Moin Jakob, los geht's. Dein Weg beginnt hier.";

Widget _bubble({
  VoidCallback? onClose,
  BubbleArrow arrow = BubbleArrow.left,
  String text = _text,
}) => Align(
  alignment: Alignment.topLeft,
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: MannyBubble(text: text, onClose: onClose ?? () {}, arrow: arrow),
  ),
);

Finder _body() => find.descendant(
  of: find.byType(MannyBubble),
  matching: find.byType(BackdropFilter),
);

void main() {
  testWidgets('Aufbau: E2 (surface-float, Radius 20, Rand hair), Text bubble '
      '14,5 sp, Blur, kein Schatten', (WidgetTester tester) async {
    await pumpApp(tester, _bubble());
    await tester.pumpAndSettle();
    final CuraColors c = colorsAt(tester, find.byType(MannyBubble));
    expect(backdropCount(tester), 1);
    final BoxDecoration d = decorationsUnder(
      tester,
      find.byType(MannyBubble),
    ).firstWhere((BoxDecoration x) => x.color == c.floatFill);
    expect(d.borderRadius, BorderRadius.circular(20));
    expect(d.border, Border.all(color: c.borderHair, width: 1));
    expect(d.boxShadow, isNull);
    final TextStyle s = tester.widget<Text>(find.text(_text)).style!;
    expect(s.fontSize, 14.5);
    expect(s.color, c.text1);
    expect(s.fontFamily, 'DMSans');
  });

  testWidgets('Breite höchstens 280 dp, Text bricht um; Hoher Kontrast opak '
      'ohne Blur', (WidgetTester tester) async {
    await pumpApp(
      tester,
      _bubble(text: '$_text $_text $_text'),
      size: Viewports.large,
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(_body()).width, lessThanOrEqualTo(280));
    expect(tester.takeException(), isNull);
    await pumpApp(tester, _bubble(), highContrast: true);
    await tester.pumpAndSettle();
    expect(backdropCount(tester), 0);
    final CuraColors c = colorsAt(tester, find.byType(MannyBubble));
    expect(c.floatFill, const Color(0xFF1B2129));
    expect(
      decorationsUnder(tester, find.byType(MannyBubble)).any(
        (BoxDecoration x) =>
            x.color == const Color(0xFF1B2129) &&
            x.border == Border.all(color: c.borderControlHc, width: 1),
      ),
      isTrue,
    );
  });

  testWidgets('X: 48 × 48 dp, Label „Nachricht schließen“, schließt', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle h = tester.ensureSemantics();
    int closed = 0;
    await pumpApp(tester, _bubble(onClose: () => closed++));
    await tester.pumpAndSettle();
    final Finder x = find.byIcon(Icons.close_rounded);
    expect(find.byTooltip('Nachricht schließen'), findsOneWidget);
    expect(
      tester.getSize(
        find.ancestor(of: x, matching: find.byType(SizedBox)).first,
      ),
      const Size(48, 48),
    );
    expect(find.bySemanticsLabel('Nachricht schließen'), findsOneWidget);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await tester.tap(x);
    expect(closed, 1);
    h.dispose();
  });

  testWidgets('Tipp auf die Blase schließt ebenfalls', (
    WidgetTester tester,
  ) async {
    int closed = 0;
    await pumpApp(tester, _bubble(onClose: () => closed++));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_text));
    expect(closed, 1);
  });

  testWidgets('Live-Region liest den Text vor; Manny-Label nicht doppelt', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle h = tester.ensureSemantics();
    await pumpApp(tester, _bubble());
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text(_text)),
      matchesSemantics(label: _text, isLiveRegion: true),
    );
    h.dispose();
  });

  test('Platzierung: unter 140 dp rechts steht die Blase oberhalb', () {
    expect(MannyBubble.arrowFor(139.9), BubbleArrow.down);
    expect(MannyBubble.arrowFor(140), BubbleArrow.left);
    expect(MannyBubble.arrowFor(300), BubbleArrow.left);
  });

  testWidgets('Pfeil: 8 dp zu Manny, links bzw. unten', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, _bubble(arrow: BubbleArrow.left));
    await tester.pumpAndSettle();
    Finder arrow() => find.descendant(
      of: find.byType(MannyBubble),
      matching: find.byWidgetPredicate(
        (Widget w) => w is CustomPaint && w.size != Size.zero,
      ),
    );
    expect(tester.getSize(arrow()), const Size(8, 16));
    expect(tester.getRect(arrow()).right, tester.getRect(_body()).left);
    await pumpApp(tester, _bubble(arrow: BubbleArrow.down));
    await tester.pumpAndSettle();
    expect(tester.getSize(arrow()), const Size(16, 8));
    expect(tester.getRect(arrow()).top, tester.getRect(_body()).bottom);
  });

  testWidgets('320 dp: Blase über Manny passt in den Bildschirm (UI-34)', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      _bubble(arrow: BubbleArrow.down),
      size: Viewports.small,
    );
    await tester.pumpAndSettle();
    final Rect r = tester.getRect(find.byType(MannyBubble));
    expect(r.left, greaterThanOrEqualTo(16));
    expect(r.right, lessThanOrEqualTo(320 - 16));
    expect(tester.takeException(), isNull);
  });

  group('Bewegung (Brief 3.6, UI-8)', () {
    testWidgets('normal: Einblenden plus 8 dp Schiebung in dur-base', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, _bubble());
      final Finder fade = find.descendant(
        of: find.byType(MannyBubble),
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(fade.first).opacity, 0);
      final Finder move = find.descendant(
        of: find.byType(MannyBubble),
        matching: find.byType(Transform),
      );
      expect(
        tester.widget<Transform>(move.first).transform.getTranslation().y,
        8,
      );
      await tester.pump(const Duration(milliseconds: 121));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isFalse);
      expect(tester.widget<Opacity>(fade.first).opacity, 1);
    });

    testWidgets(
      'Systemsignal reduceMotion: höchstens 120 ms, keine Schiebung',
      (WidgetTester tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await pumpApp(tester, _bubble());
        final Finder move = find.descendant(
          of: find.byType(MannyBubble),
          matching: find.byType(Transform),
        );
        expect(
          tester.widget<Transform>(move.first).transform.getTranslation().y,
          0,
        );
        await tester.pump(const Duration(milliseconds: 121));
        expect(tester.hasRunningAnimations, isFalse);
      },
    );

    testWidgets('Systemsignal disableAnimations', (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpApp(tester, _bubble());
      await tester.pump(const Duration(milliseconds: 121));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('Preview-Override', (WidgetTester tester) async {
      await pumpApp(
        tester,
        PreviewMotionOverride(reduceMotion: true, child: _bubble()),
      );
      await tester.pump(const Duration(milliseconds: 121));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('TapAnywhereDismiss', () {
    Widget host(void Function() onDismiss, void Function() onUnder) =>
        TapAnywhereDismiss(
          onDismiss: onDismiss,
          child: Center(
            child: ElevatedButton(
              onPressed: onUnder,
              child: const Text('Unten'),
            ),
          ),
        );

    testWidgets('Tipp irgendwo (auch auf ein Element) ruft onDismiss, ohne '
        'das Element zu blockieren', (WidgetTester tester) async {
      int dismissed = 0;
      int under = 0;
      await pumpApp(tester, host(() => dismissed++, () => under++));
      await tester.tapAt(const Offset(20, 20));
      expect(dismissed, 1);
      await tester.tap(find.text('Unten'));
      expect(dismissed, 2);
      expect(under, 1, reason: 'durchlässig: das Element bekommt den Tipp');
    });

    testWidgets('Wischen (über die Berührungstoleranz) schließt nicht', (
      WidgetTester tester,
    ) async {
      int dismissed = 0;
      await pumpApp(tester, host(() => dismissed++, () {}));
      await tester.dragFrom(const Offset(100, 100), const Offset(0, -80));
      expect(dismissed, 0);
    });

    testWidgets('enabled: false ignoriert Tipps', (WidgetTester tester) async {
      int dismissed = 0;
      await pumpApp(
        tester,
        TapAnywhereDismiss(
          enabled: false,
          onDismiss: () => dismissed++,
          child: const SizedBox.expand(),
        ),
      );
      await tester.tapAt(const Offset(20, 20));
      expect(dismissed, 0);
      expect(CuraSize.touchTarget, 48);
    });
  });
}
