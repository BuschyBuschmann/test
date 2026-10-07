// FocusRing und CuraPressable (Brief 5/8, UI-35, UI-72): sichtbarer Fokus nur
// bei Tastatur-/Switch-Fokus, 2 dp Ring mit 2 dp Abstand, Aktivierung per
// Enter/Leertaste, deaktivierte Elemente nehmen keinen Fokus.
import 'package:curaone/ui/components/cura_pressable.dart';
import 'package:curaone/ui/components/focus_ring.dart';
import 'package:curaone/ui/components/manny.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/pump_app.dart';

Widget _target({VoidCallback? onPressed, FocusNode? node}) => Center(
  child: CuraPressable(
    onPressed: onPressed,
    focusNode: node,
    semanticLabel: 'Ziel',
    builder: (BuildContext context, bool pressed) => const SizedBox.square(
      dimension: 56,
      child: ColoredBox(color: Color(0xFF444444)),
    ),
  ),
);

void main() {
  testWidgets('FocusRing: aus ohne Fokus, an mit Radius + 4 dp Außenkante', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const Center(
        child: FocusRing(
          focused: false,
          radius: 12,
          child: SizedBox.square(key: Key('t'), dimension: 56),
        ),
      ),
    );
    expect(find.byType(DecoratedBox), findsNothing);
    await pumpApp(
      tester,
      const Center(
        child: FocusRing(
          focused: true,
          radius: 12,
          child: SizedBox.square(key: Key('t'), dimension: 56),
        ),
      ),
    );
    final Finder ring = find.descendant(
      of: find.byType(FocusRing),
      matching: find.byType(DecoratedBox),
    );
    final Rect r = tester.getRect(ring);
    final Rect t = tester.getRect(find.byKey(const Key('t')));
    expect(r.inflate(-4), t);
    expect(FocusRing.outset, 4);
    final BoxDecoration d =
        tester.widget<DecoratedBox>(ring).decoration as BoxDecoration;
    expect(d.borderRadius, BorderRadius.circular(16));
    expect(d.border!.top.width, 2);
    expect(d.border!.top.color, const Color(0xFFF2F0EB));
    // Der Ring fängt keine Tipps ab und ist nicht in der Semantik.
    expect(
      find.ancestor(of: ring, matching: find.byType(IgnorePointer)),
      findsWidgets,
    );
    expect(
      find.ancestor(of: ring, matching: find.byType(ExcludeSemantics)),
      findsWidgets,
    );
  });

  testWidgets('Tippen setzt keinen Fokus-Ring (nur Tastatur/Switch)', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, _target(onPressed: () {}));
    await tester.tap(find.byType(CuraPressable));
    await tester.pump();
    expect(tester.widget<FocusRing>(find.byType(FocusRing)).focused, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(tester.widget<FocusRing>(find.byType(FocusRing)).focused, isTrue);
  });

  testWidgets('Deaktiviert: kein Fokus, keine Aktion, Semantik deaktiviert', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle h = tester.ensureSemantics();
    final FocusNode node = FocusNode();
    addTearDown(node.dispose);
    await pumpApp(tester, _target(node: node));
    node.requestFocus();
    await tester.pump();
    expect(node.hasFocus, isFalse);
    expect(
      tester.getSemantics(
        find.descendant(
          of: find.byType(CuraPressable),
          matching: find.byType(ColoredBox),
        ),
      ),
      matchesSemantics(
        label: 'Ziel',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    h.dispose();
  });

  testWidgets('Aktivierung per Enter und Leertaste; Pressed nur während des '
      'Tippens', (WidgetTester tester) async {
    int n = 0;
    bool pressedSeen = false;
    await pumpApp(
      tester,
      Center(
        child: CuraPressable(
          onPressed: () => n++,
          builder: (BuildContext context, bool pressed) {
            pressedSeen = pressedSeen || pressed;
            return const SizedBox.square(dimension: 56);
          },
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(n, 2);
    expect(pressedSeen, isFalse);
    final TestGesture g = await tester.startGesture(
      tester.getCenter(find.byType(CuraPressable)),
    );
    await tester.pump();
    expect(pressedSeen, isTrue);
    await g.up();
  });

  testWidgets(
    'Manny auf dem Pfad ist keine Fokusstation (Tab überspringt ihn)',
    (WidgetTester tester) async {
      final FocusNode other = FocusNode();
      addTearDown(other.dispose);
      await pumpApp(
        tester,
        Column(
          children: <Widget>[
            MannyPlaceholder(height: 80, onTap: () {}),
            Focus(
              focusNode: other,
              child: const SizedBox(width: 20, height: 20),
            ),
          ],
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(other.hasFocus, isTrue);
      expect(
        find.ancestor(
          of: find.byType(CustomPaint),
          matching: find.byType(ExcludeFocus),
        ),
        findsWidgets,
      );
      expect(decorationsUnder(tester, find.byType(MannyPlaceholder)), isEmpty);
    },
  );
}
