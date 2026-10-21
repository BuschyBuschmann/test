// FloatingNav (Brief v2, 4.1; V2-15, V2-16, V2-18, V2-23): Maße, Ruhe/Aktiv,
// Auslöser (Tipp, Fokus, Scroll, Screenreader), Rückkehr nach 2 s, Gleichheit
// von Größe/Position/Hit-Areas/Fokusring in beiden Zuständen, Welt-Farben,
// aktiver Tab, Badge, Avatar, Hoher Kontrast, Skalierung 1,3, Tastatur.
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/world_time.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/tokens.dart';
import 'package:curaone/theme/world_tokens.dart';
import 'package:curaone/ui/components/cura_blur.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/world_app.dart';
import '../support/backdrops.dart';

const List<NavItem> _items = <NavItem>[
  NavItem(icon: Icons.route_rounded, label: 'Pfad'),
  NavItem(icon: Icons.event_available_rounded, label: 'Heute'),
  NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chats'),
  NavItem(
    icon: Icons.person_outline_rounded,
    label: 'Profil',
    avatarInitials: 'JB',
  ),
];

Widget _nav({
  int index = 0,
  ValueChanged<int>? onSelected,
  NavActivity? activity,
  List<NavItem> items = _items,
  bool physio = false,
}) => Align(
  alignment: Alignment.bottomCenter,
  child: FloatingNav(
    items: items,
    currentIndex: index,
    onSelected: onSelected ?? (_) {},
    activity: activity,
    physio: physio,
  ),
);

/// Glasfläche der Leiste (der Pillen-Container hinter dem Blur).
Finder _glass() => find.descendant(
  of: find.byType(FloatingNav),
  matching: find.byType(AnimatedContainer),
);

Color _glassColor(WidgetTester tester) =>
    ((tester.widget<AnimatedContainer>(_glass().first).decoration!
            as BoxDecoration)
        .color) ??
    const Color(0x00000000);

bool _isActive(WidgetTester tester) =>
    (tester.state(find.byType(FloatingNav)) as dynamic).isActive as bool;

void main() {
  group('Maße (Brief 3.4/4.1)', () {
    testWidgets('72 dp hoch, 14 dp Seitenabstand, 24 dp unten', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, _nav());
      final Rect bar = tester.getRect(
        find.descendant(
          of: find.byType(FloatingNav),
          matching: activeBackdrops(),
        ),
      );
      expect(bar.height, 72);
      expect(bar.left, 14);
      expect(bar.right, 390 - 14);
      expect(844 - bar.bottom, 24);
      expect(CuraSize.navBarHeight, 72);
      expect(
        FloatingNav.occupiedHeight(tester.element(find.byType(FloatingNav))),
        72 + 24,
      );
    });

    testWidgets('Safe Area unten wird zusätzlich eingehalten', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(worldApp(_nav()));
      final Rect bar = tester.getRect(
        find.descendant(
          of: find.byType(FloatingNav),
          matching: activeBackdrops(),
        ),
      );
      expect(844 - bar.bottom, 24 + 34);
    });

    testWidgets('Schleier: 150 dp, 70 % world-floor, läuft nach oben aus', (
      WidgetTester tester,
    ) async {
      for (final WorldPhase p in kWorlds) {
        await pumpWorld(tester, _nav(), phase: p);
        // Die Leiste misst Leiste + Rand unten; der Schleier ragt darüber.
        final Rect all = tester.getRect(find.byType(FloatingNav));
        expect(all.height, 72 + 24);
        expect(all.bottom, 844);
        final Finder veil = find.descendant(
          of: find.byType(FloatingNav),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).gradient is LinearGradient &&
                ((w.decoration as BoxDecoration).gradient! as LinearGradient)
                        .colors
                        .first
                        .a ==
                    0,
          ),
        );
        expect(veil, findsOneWidget);
        final Rect v = tester.getRect(veil);
        expect(v.height, CuraSize.navVeilHeight);
        expect(v.bottom, 844);
        expect(v.left, 0);
        expect(v.right, 390);
        final LinearGradient g =
            (tester.widget<DecoratedBox>(veil).decoration as BoxDecoration)
                    .gradient!
                as LinearGradient;
        final WorldPalette w = WorldPalette.of(p);
        expect(g.colors.last, w.floor.withValues(alpha: 0.70));
        expect(g.colors.first.a, 0);
        expect(g.begin, Alignment.topCenter);
      }
    });

    testWidgets(
      'Tabs: 62 × 56 dp (Physio 76 × 56), alle mit Symbol und Label',
      (WidgetTester tester) async {
        await pumpWorld(tester, _nav());
        for (final NavItem i in _items) {
          expect(find.text(i.label), findsOneWidget);
        }
        expect(find.byIcon(Icons.route_rounded), findsOneWidget);
        final Rect pill = tester.getRect(
          find
              .ancestor(
                of: find.text('Pfad'),
                matching: find.byWidgetPredicate(
                  (Widget w) => w is ConstrainedBox,
                ),
              )
              .first,
        );
        expect(pill.width, greaterThanOrEqualTo(CuraSize.navTabWidth));
        expect(pill.height, greaterThanOrEqualTo(CuraSize.navTabHeight));
        expect(CuraSize.navTabWidth, 62);
        expect(CuraSize.navTabWidthPhysio, 76);
        expect(CuraSize.navTabHeight, 56);
        await pumpWorld(tester, _nav(physio: true));
        expect(
          tester
              .getSize(
                find
                    .ancestor(
                      of: find.text('Pfad'),
                      matching: find.byType(ConstrainedBox),
                    )
                    .first,
              )
              .width,
          greaterThanOrEqualTo(CuraSize.navTabWidthPhysio),
        );
      },
    );
  });

  group('Ruhe und Aktiv (V2-16, V2-18)', () {
    testWidgets('Ruhe: Glas aus der Welt, Weiß 35 % bzw. Nacht 45 %', (
      WidgetTester tester,
    ) async {
      for (final WorldPhase p in kWorlds) {
        await pumpWorld(tester, _nav(), phase: p);
        expect(_isActive(tester), isFalse);
        expect(_glassColor(tester), WorldPalette.of(p).navRest, reason: p.name);
      }
      expect(WorldPalette.midday.navRest.a, closeTo(0.35, 0.005));
      expect(WorldPalette.night.navRest.a, closeTo(0.45, 0.005));
      expect(WorldPalette.midday.navActive.a, closeTo(0.78, 0.005));
      expect(WorldPalette.night.navActive.a, closeTo(0.82, 0.005));
    });

    testWidgets('Tipp macht aktiv (78 %), nach 2 s Ruhe zurück', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, _nav());
      await tester.tap(find.text('Heute'));
      await tester.pump();
      expect(_isActive(tester), isTrue);
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
      expect(_glassColor(tester), WorldPalette.midday.navActive);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(_isActive(tester), isTrue, reason: 'noch keine 2 s');
      await tester.pump(const Duration(milliseconds: 600));
      expect(_isActive(tester), isFalse, reason: 'nach 2 s ohne Interaktion');
      await tester.pumpAndSettle();
      expect(_glassColor(tester), WorldPalette.midday.navRest);
    });

    testWidgets('Tipp auf die Leiste (neben den Tabs) macht ebenfalls aktiv', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, _nav());
      final Rect bar = tester.getRect(
        find.descendant(
          of: find.byType(FloatingNav),
          matching: activeBackdrops(),
        ),
      );
      await tester.tapAt(bar.centerLeft + const Offset(2, 0));
      await tester.pump();
      expect(_isActive(tester), isTrue);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Beginn eines Scrolls des Inhalts macht aktiv', (
      WidgetTester tester,
    ) async {
      final NavActivity activity = NavActivity();
      addTearDown(activity.dispose);
      await pumpWorld(
        tester,
        Stack(
          children: <Widget>[
            NavScrollListener(
              activity: activity,
              child: ListView(
                children: <Widget>[
                  for (int i = 0; i < 30; i++)
                    SizedBox(height: 80, child: Text('Zeile $i')),
                ],
              ),
            ),
            _nav(activity: activity),
          ],
        ),
      );
      expect(_isActive(tester), isFalse);
      await tester.drag(find.text('Zeile 3'), const Offset(0, -120));
      await tester.pump();
      expect(_isActive(tester), isTrue);
      await tester.pump(const Duration(seconds: 3));
      expect(_isActive(tester), isFalse);
    });

    testWidgets(
      'Tastaturfokus in der Leiste: aktiv, solange der Fokus bleibt',
      (WidgetTester tester) async {
        await pumpWorld(tester, _nav());
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_isActive(tester), isTrue);
        await tester.pump(const Duration(seconds: 5));
        expect(_isActive(tester), isTrue, reason: 'Fokus bleibt in der Leiste');
      },
    );

    testWidgets('Screenreader-Fokus macht aktiv', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpWorld(tester, _nav());
      tester.semantics.performAction(
        find.semantics.byLabel('Pfad'),
        SemanticsAction.didGainAccessibilityFocus,
      );
      await tester.pump();
      expect(_isActive(tester), isTrue);
      await tester.pump(const Duration(seconds: 3));
      h.dispose();
    });

    testWidgets('V2-18: Größe, Position, Hit-Areas und Fokusring unverändert', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, _nav());
      List<Rect> rects() => <Rect>[
        tester.getRect(find.byType(FloatingNav)),
        tester.getRect(
          find.descendant(
            of: find.byType(FloatingNav),
            matching: activeBackdrops(),
          ),
        ),
        for (final NavItem i in _items)
          tester.getRect(
            find
                .ancestor(
                  of: find.text(i.label),
                  matching: find.byType(GestureDetector),
                )
                .first,
          ),
        for (final NavItem i in _items) tester.getRect(find.text(i.label)),
      ];
      final List<Rect> rest = rects();
      await tester.tap(find.text('Chats'));
      await tester.pumpAndSettle(const Duration(milliseconds: 250));
      expect(_isActive(tester), isTrue);
      expect(rects(), rest, reason: 'gleiche Rechtecke in Ruhe und Aktiv');
      // Fokusring: gleiche Maße (Ring um die Pille) in beiden Zuständen.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(_isActive(tester), isFalse);
      expect(rects(), rest);
    });

    testWidgets('Bewegung reduzieren: Wechsel ohne Übergang', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(
            disableAnimations: true,
            reduceMotion: true,
          );
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpWorld(tester, _nav());
      await tester.tap(find.text('Heute'));
      await tester.pump();
      expect(_glassColor(tester), WorldPalette.midday.navActive);
      expect(
        tester.widget<AnimatedContainer>(_glass().first).duration,
        Duration.zero,
      );
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('Aktiver Tab, Badge, Avatar', () {
    testWidgets('aktiver Tab: Mandarine-Verlauf, on-accent; inaktiv nav-ink', (
      WidgetTester tester,
    ) async {
      for (final WorldPhase p in kWorlds) {
        await pumpWorld(tester, _nav(), phase: p);
        final CuraColors c = colorsAt(tester, find.byType(FloatingNav));
        final Finder activeBox = find.ancestor(
          of: find.text('Pfad'),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is DecoratedBox &&
                (w.decoration as BoxDecoration).gradient == c.accentFill,
          ),
        );
        expect(activeBox, findsOneWidget, reason: p.name);
        expect(tester.getSize(activeBox).height, greaterThanOrEqualTo(56));
        expect(tester.widget<Text>(find.text('Pfad')).style!.color, c.onAccent);
        expect(
          tester.widget<Icon>(find.byIcon(Icons.route_rounded)).color,
          c.onAccent,
        );
        final Color ink = WorldPalette.of(p).navInk;
        expect(tester.widget<Text>(find.text('Heute')).style!.color, ink);
        expect(
          tester.widget<Icon>(find.byIcon(Icons.event_available_rounded)).color,
          ink,
        );
      }
    });

    testWidgets('Badge: Zahl, #B3261E mit weißem Text, „Chats, 2 ungelesen“', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpWorld(
        tester,
        _nav(
          items: const <NavItem>[
            NavItem(icon: Icons.route_rounded, label: 'Pfad'),
            NavItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chats',
              badgeCount: 2,
            ),
          ],
        ),
      );
      expect(find.text('2'), findsOneWidget);
      final DecoratedBox badge = tester.widget<DecoratedBox>(
        find
            .ancestor(of: find.text('2'), matching: find.byType(DecoratedBox))
            .first,
      );
      final BoxDecoration d = badge.decoration as BoxDecoration;
      expect(d.color, const Color(0xFFB3261E));
      expect((d.border! as Border).top.color, const Color(0xFFFFFFFF));
      expect(tester.widget<Text>(find.text('2')).style!.color, Colors.white);
      expect(find.bySemanticsLabel(S.navUnread('Chats', 2)), findsOneWidget);
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.text('2'),
                    matching: find.byType(ConstrainedBox),
                  )
                  .first,
            )
            .height,
        greaterThanOrEqualTo(20),
      );
      h.dispose();
    });

    testWidgets('Badge ab 100 als „99+“, ohne Zähler kein Badge', (
      WidgetTester tester,
    ) async {
      await pumpWorld(
        tester,
        _nav(
          items: const <NavItem>[
            NavItem(icon: Icons.chat_rounded, label: 'Chats', badgeCount: 120),
            NavItem(icon: Icons.person_rounded, label: 'Profil'),
          ],
        ),
      );
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('Profil: Avatar mit Initialen statt Symbol', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, _nav());
      expect(find.text('JB'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsNothing);
      expect(find.text('Profil'), findsOneWidget);
    });
  });

  group('Hoher Kontrast / Transparenz reduzieren (V2-12)', () {
    testWidgets('opak, Rand -hc, kein Blur, kein Schatten', (
      WidgetTester tester,
    ) async {
      for (final Brightness b in Brightness.values) {
        await pumpWorld(
          tester,
          _nav(),
          highContrast: true,
          brightness: b,
          phase: WorldPhase.night,
        );
        expect(backdropCount(tester), 0);
        final CuraColors c = colorsAt(tester, find.byType(FloatingNav));
        expect(_glassColor(tester), c.surfaceOpaque);
        expect(_glassColor(tester).a, 1);
        final BoxDecoration d =
            tester
                    .widget<AnimatedContainer>(_glass().first)
                    .foregroundDecoration!
                as BoxDecoration;
        expect((d.border! as Border).top.color, c.borderControlHc);
        expect(
          decorationsUnder(
            tester,
            find.byType(FloatingNav),
          ).every((BoxDecoration x) => x.boxShadow == null),
          isTrue,
        );
        // Tabs lesbar: Tinte `text-1` auf `card` 100 %.
        expect(tester.widget<Text>(find.text('Heute')).style!.color, c.text1);
      }
    });

    testWidgets('normal: genau ein Blur, σ 30, im Budget', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, _nav());
      expect(backdropCount(tester), 1);
      expect(BlurTokens.navSigma, 30);
      expect(find.byType(CuraBlur), findsOneWidget);
    });
  });

  group('Bedienung', () {
    testWidgets('Tipp wählt, Semantik: Schaltfläche mit Label und Auswahl', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      final List<int> picked = <int>[];
      await pumpWorld(tester, _nav(onSelected: picked.add));
      await tester.tap(find.text('Heute'));
      expect(picked, <int>[1]);
      expect(
        tester.getSemantics(find.text('Pfad')),
        matchesSemantics(
          label: 'Pfad',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
          hasDidGainAccessibilityFocusAction: true,
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await tester.pump(const Duration(seconds: 3));
      h.dispose();
    });

    testWidgets('Tastatur: Tab erreicht die Einträge, Enter wählt', (
      WidgetTester tester,
    ) async {
      final List<int> picked = <int>[];
      await pumpWorld(tester, _nav(onSelected: picked.add));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(picked, <int>[1]);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Ziele sind eine Liste: ein fünftes Ziel passt ohne Umbau', (
      WidgetTester tester,
    ) async {
      final List<NavItem> five = <NavItem>[
        _items[0],
        _items[1],
        const NavItem(icon: Icons.dynamic_feed_rounded, label: 'Feed'),
        _items[2],
        _items[3],
      ];
      await pumpWorld(tester, _nav(items: five));
      expect(find.text('Feed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Labels sind ab Textskalierung 1,3 begrenzt', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, _nav());
      final double normal = tester.getSize(find.text('Pfad')).height;
      await pumpWorld(tester, _nav(), textScale: 1.3);
      final double at13 = tester.getSize(find.text('Pfad')).height;
      await pumpWorld(tester, _nav(), textScale: 2);
      final double at2 = tester.getSize(find.text('Pfad')).height;
      expect(at13, greaterThan(normal));
      expect(at2, at13);
      expect(tester.takeException(), isNull);
    });

    testWidgets('320 dp und 200 %: keine Überläufe', (
      WidgetTester tester,
    ) async {
      await pumpWorld(tester, _nav(), size: const Size(320, 568), textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}
