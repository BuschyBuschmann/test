// HeaderIconButton, MannyButton, MessagesButton, ActionCluster
// (Ergänzung 1/2, UI-46, UI-70–72, UI-87; Regel 12).
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/ui/components/action_cluster.dart';
import 'package:curaone/ui/components/focus_ring.dart';
import 'package:curaone/ui/components/header_icon_button.dart';
import 'package:curaone/ui/components/manny.dart';
import 'package:curaone/ui/components/manny_chat_button.dart';
import 'package:curaone/ui/components/messages_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/pump_app.dart';
import '../support/world_app.dart';

Widget _right(Widget child) => Padding(
  padding: const EdgeInsets.all(16),
  child: Align(alignment: Alignment.bottomRight, child: child),
);

void main() {
  group('HeaderIconButton (Ergänzung 1)', () {
    testWidgets('48 × 48 dp, Icon 24 dp text-2, Fläche transparent, Tooltip '
        'und Label', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      int taps = 0;
      await pumpApp(
        tester,
        _right(
          HeaderIconButton(
            icon: Icons.person_outline_rounded,
            tooltip: 'Deine Daten',
            onPressed: () => taps++,
          ),
        ),
      );
      final Finder f = find.byType(HeaderIconButton);
      final CuraColors c = colorsAt(tester, f);
      expect(tester.getSize(f), const Size(48, 48));
      final Icon icon = tester.widget(
        find.byIcon(Icons.person_outline_rounded),
      );
      expect(icon.size, 24);
      expect(icon.color, c.text2);
      final BoxDecoration d = decorationsUnder(tester, f).single;
      expect(d.color, isNull);
      expect(d.border, isNull);
      expect(find.byTooltip('Deine Daten'), findsOneWidget);
      expect(
        tester.getSemantics(find.byIcon(Icons.person_outline_rounded)),
        matchesSemantics(
          label: 'Deine Daten',
          isButton: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(f);
      expect(taps, 1);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      h.dispose();
    });

    testWidgets('Pressed: Kreis Weiß 10 %; Hoher Kontrast: Kreisrand -hc', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        _right(
          HeaderIconButton(
            icon: Icons.person_outline_rounded,
            tooltip: 'Deine Daten',
            onPressed: () {},
          ),
        ),
      );
      final CuraColors c = colorsAt(tester, find.byType(HeaderIconButton));
      final TestGesture g = await tester.startGesture(
        tester.getCenter(find.byType(HeaderIconButton)),
      );
      // Mit Tooltip (Long-Press-Konkurrent) meldet der Tipp „down“ nach kPressTimeout.
      await tester.pump(kPressTimeout);
      final BoxDecoration d = decorationsUnder(
        tester,
        find.byType(HeaderIconButton),
      ).single;
      expect(d.color, c.pressedOverlay);
      expect(d.shape, BoxShape.circle);
      await g.up();
      await pumpApp(
        tester,
        _right(
          HeaderIconButton(
            icon: Icons.person_outline_rounded,
            tooltip: 'Deine Daten',
            onPressed: () {},
          ),
        ),
        highContrast: true,
      );
      await tester.pumpAndSettle(); // Theme-Wechsel läuft über AnimatedTheme
      final CuraColors hcColors = colorsAt(
        tester,
        find.byType(HeaderIconButton),
      );
      final BoxDecoration hc = decorationsUnder(
        tester,
        find.byType(HeaderIconButton),
      ).single;
      expect(
        hc.border,
        Border.all(color: hcColors.borderControlHc, width: 1.5),
      );
      expect(hcColors.highContrast, isTrue);
    });

    testWidgets('Tastatur: Fokus mit focus-ring, Enter löst aus', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpApp(
        tester,
        _right(
          HeaderIconButton(
            icon: Icons.person_outline_rounded,
            tooltip: 'Deine Daten',
            onPressed: () => taps++,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(tester.widget<FocusRing>(find.byType(FocusRing)).focused, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
    });
  });

  group('MannyButton (Brief v2, Ergänzung 1, 6.4)', () {
    testWidgets('56 dp Kreis, Glas Weiß 78 %, Blur σ 30, Kopf 86 % (48 dp)', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, _right(MannyButton(onPressed: () {})));
      final Finder f = find.byType(MannyButton);
      final CuraColors c = colorsAt(tester, f);
      expect(tester.getSize(f), const Size(56, 56));
      final BoxDecoration d = decorationsUnder(
        tester,
        f,
      ).firstWhere((BoxDecoration x) => x.color == c.mannyButtonGlass);
      expect(d.shape, BoxShape.circle);
      expect(
        c.mannyButtonGlass,
        const Color(0xFFFFFFFF).withValues(alpha: 0.78),
      );
      expect(
        decorationsUnder(
          tester,
          f,
        ).any((BoxDecoration x) => x.boxShadow == CuraShadow.actionButton),
        isTrue,
      );
      final MannyIllustration manny = tester.widget(
        find.byType(MannyIllustration),
      );
      expect(manny.crop, MannyCrop.head);
      final double head = tester.getSize(find.byType(MannyIllustration)).width;
      expect(head, closeTo(56 * 0.86, 0.001));
      expect(head, greaterThanOrEqualTo(CuraSize.mannyHeadMin));
      expect(backdropCount(tester), 1, reason: 'eine der drei Blur-Flächen');
    });

    testWidgets('Glas Weiß 78 % in allen Welten und beiden Themen', (
      WidgetTester tester,
    ) async {
      for (final WorldLook l in allWorldLooks()) {
        await pumpWorld(
          tester,
          _right(MannyButton(onPressed: () {})),
          phase: l.phase,
          brightness: l.brightness,
          highContrast: l.highContrast,
        );
        await tester.pumpAndSettle(); // Theme-Wechsel läuft über AnimatedTheme
        final CuraColors c = colorsAt(tester, find.byType(MannyButton));
        expect(
          decorationsUnder(
            tester,
            find.byType(MannyButton),
          ).any((BoxDecoration x) => x.color == c.mannyButtonGlass),
          isTrue,
          reason: l.name,
        );
        expect(backdropCount(tester), l.highContrast ? 0 : 1, reason: l.name);
      }
    });

    testWidgets('Tooltip und Screenreader „Manny, Chat öffnen“, Tipp, '
        'Enter und Leertaste', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      int taps = 0;
      await pumpApp(tester, _right(MannyButton(onPressed: () => taps++)));
      expect(find.byTooltip('Manny, Chat öffnen'), findsOneWidget);
      expect(find.bySemanticsLabel('Manny, Chat öffnen'), findsOneWidget);
      // Das Manny-Bild-Label kommt nicht doppelt dazu.
      expect(find.bySemanticsLabel('Manny, dein Begleiter'), findsNothing);
      await tester.tap(find.byType(MannyButton));
      expect(taps, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(tester.widget<FocusRing>(find.byType(FocusRing)).focused, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(taps, 3);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      h.dispose();
    });

    testWidgets('Pressed: Überlagerung 10 %; Hoher Kontrast: opake helle '
        'Scheibe, Rand -hc, Schatten bleibt, kein Blur', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, _right(MannyButton(onPressed: () {})));
      final CuraColors c = colorsAt(tester, find.byType(MannyButton));
      final TestGesture g = await tester.startGesture(
        tester.getCenter(find.byType(MannyButton)),
      );
      await tester.pump(kPressTimeout);
      expect(
        decorationsUnder(
          tester,
          find.byType(MannyButton),
        ).any((BoxDecoration x) => x.color == c.pressedOverlay),
        isTrue,
      );
      await g.up();
      for (final Brightness b in Brightness.values) {
        await pumpWorld(
          tester,
          _right(MannyButton(onPressed: () {})),
          highContrast: true,
          brightness: b,
        );
        await tester.pumpAndSettle();
        final CuraColors hc = colorsAt(tester, find.byType(MannyButton));
        final BoxDecoration d = decorationsUnder(
          tester,
          find.byType(MannyButton),
        ).firstWhere((BoxDecoration x) => x.color == hc.mannyButtonGlass);
        expect(hc.mannyButtonGlass.a, 1);
        expect(
          hc.mannyButtonGlass,
          hc.mannyDisc,
          reason: 'Kopf auf heller Scheibe',
        );
        expect(d.border, Border.all(color: hc.lightSurfaceBorder, width: 1.5));
        expect(
          decorationsUnder(
            tester,
            find.byType(MannyButton),
          ).any((BoxDecoration x) => x.boxShadow == CuraShadow.actionButton),
          isTrue,
        );
        expect(backdropCount(tester), 0);
      }
    });
  });

  group('MessagesButton (Ergänzung 2)', () {
    testWidgets('48 dp Kreis, Icon chat_bubble_outline_rounded 24 dp text-1, '
        'Tooltip und Label „Nachrichten“', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      int taps = 0;
      await pumpApp(tester, _right(MessagesButton(onPressed: () => taps++)));
      final Finder f = find.byType(MessagesButton);
      final CuraColors c = colorsAt(tester, f);
      expect(tester.getSize(f), const Size(48, 48));
      final Icon icon = tester.widget(
        find.byIcon(Icons.chat_bubble_outline_rounded),
      );
      expect(icon.size, 24);
      expect(icon.color, c.text1);
      expect(find.byTooltip('Nachrichten'), findsOneWidget);
      expect(find.bySemanticsLabel('Nachrichten'), findsOneWidget);
      final BoxDecoration d = decorationsUnder(
        tester,
        f,
      ).firstWhere((BoxDecoration x) => x.color == c.surfaceOpaque);
      expect(d.border, Border.all(color: c.borderControl, width: 1.5));
      expect(d.boxShadow, CuraShadow.actionButton);
      await tester.tap(f);
      expect(taps, 1);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      h.dispose();
    });
  });

  group('ActionCluster (Ergänzung 2, Plan 4.6)', () {
    Widget cluster(
      ActionClusterMode mode, {
      GlobalKey? key,
      VoidCallback? onChat,
      VoidCallback? onMessages,
    }) => _right(
      ActionCluster(
        mode: mode,
        rectKey: key,
        onOpenChat: onChat,
        onOpenMessages: onMessages ?? () {},
      ),
    );

    testWidgets('Pfad: Nachrichten-Button 8 dp über dem Manny-Button, '
        'rechtsbündig', (WidgetTester tester) async {
      await pumpApp(tester, cluster(ActionClusterMode.path, onChat: () {}));
      final Rect messages = tester.getRect(find.byType(MessagesButton));
      final Rect manny = tester.getRect(find.byType(MannyButton));
      expect(manny.top - messages.bottom, CuraSpace.clusterGap);
      expect(manny.top - messages.bottom, 8);
      expect(messages.right, manny.right);
      expect(manny.right, 390 - 16);
    });

    testWidgets('Heute: nur der Nachrichten-Button', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, cluster(ActionClusterMode.today));
      expect(find.byType(MessagesButton), findsOneWidget);
      expect(find.byType(MannyButton), findsNothing);
    });

    testWidgets('stellt sein Rechteck bereit (GlobalKey), vollständig im '
        'Bildschirm bei 320 × 568', (WidgetTester tester) async {
      final GlobalKey key = GlobalKey();
      expect(ActionCluster.rectOf(key), isNull);
      await pumpApp(
        tester,
        cluster(ActionClusterMode.path, key: key, onChat: () {}),
        size: Viewports.small,
      );
      final Rect r = ActionCluster.rectOf(key)!;
      expect(r.width, 56);
      expect(r.height, 48 + 8 + 56);
      expect(r.right, 320 - 16);
      expect(r.bottom, 568 - 16);
      expect(r.top, greaterThanOrEqualTo(0));
    });

    testWidgets('Abstand zwischen den Tap-Zielen ≥ 8 dp, Tipps erreichen die '
        'richtigen Buttons', (WidgetTester tester) async {
      int chat = 0;
      int messages = 0;
      await pumpApp(
        tester,
        cluster(
          ActionClusterMode.path,
          onChat: () => chat++,
          onMessages: () => messages++,
        ),
      );
      await tester.tap(find.byType(MannyButton));
      await tester.tap(find.byType(MessagesButton));
      expect((chat, messages), (1, 1));
      final Rect a = tester.getRect(find.byType(MessagesButton));
      final Rect b = tester.getRect(find.byType(MannyButton));
      expect(b.top - a.bottom, greaterThanOrEqualTo(CuraSize.minTargetGap));
    });

    testWidgets('Fokusreihenfolge: Nachrichten-Button, dann Manny-Button; '
        'Fokusknoten für die Fokusrückgabe', (WidgetTester tester) async {
      final FocusNode chatNode = FocusNode();
      final FocusNode messagesNode = FocusNode();
      addTearDown(chatNode.dispose);
      addTearDown(messagesNode.dispose);
      await pumpApp(
        tester,
        _right(
          ActionCluster(
            mode: ActionClusterMode.path,
            onOpenChat: () {},
            onOpenMessages: () {},
            chatFocusNode: chatNode,
            messagesFocusNode: messagesNode,
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(messagesNode.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      expect(chatNode.hasFocus, isTrue);
      chatNode.unfocus();
      messagesNode.requestFocus();
      await tester.pump();
      expect(messagesNode.hasFocus, isTrue);
    });

    testWidgets('keine Akzent-Ringe oder Glow-Elemente (UI-72); Blur nur im '
        'Manny-Knopf (Brief v2)', (WidgetTester tester) async {
      await pumpApp(tester, cluster(ActionClusterMode.path, onChat: () {}));
      expect(backdropCount(tester), 1);
      expect(
        find.descendant(
          of: find.byType(MessagesButton),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
      final CuraColors c = colorsAt(tester, find.byType(ActionCluster));
      final Iterable<BoxDecoration> d = decorationsUnder(
        tester,
        find.byType(ActionCluster),
      );
      for (final BoxDecoration x in d) {
        expect(x.border?.top.color, isNot(c.accent));
        expect(x.border?.top.color, isNot(c.accentText));
      }
    });
  });
}
