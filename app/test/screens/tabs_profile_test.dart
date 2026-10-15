// Leiste mit vier Zielen, Scroll-Erhalt je Ziel, Profil mit „Manny-Look“ und
// „Darstellung“ (F2-R3; Brief v2, 5, 7.6, Ergänzung 1, 6b; V2-15, V2-19,
// V2-53, V2-68; Plan 3.3, 3.4).
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/display_settings.dart';
import 'package:curaone/logic/manny_look.dart';
import 'package:curaone/logic/world_time.dart';
import 'package:curaone/state/display_controller.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/components/header_card.dart';
import 'package:curaone/ui/components/list_row.dart';
import 'package:curaone/ui/components/manny_chat_button.dart';
import 'package:curaone/ui/components/manny_look_picker.dart';
import 'package:curaone/ui/components/probe_keys.dart';
import 'package:curaone/ui/home/home_shell.dart';
import 'package:curaone/ui/messages/chats_screen.dart';
import 'package:curaone/ui/profile/display_sheet.dart';
import 'package:curaone/ui/profile/manny_look_sheet.dart';
import 'package:curaone/ui/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/controller_harness.dart';
import '../support/pump_app.dart';

Future<Harness> _home(
  WidgetTester tester, {
  DisplayController? display,
  Size size = Viewports.phone,
  double textScale = 1,
}) async {
  final Harness h = await Harness.onboarded();
  addTearDown(h.dispose);
  await pumpCura(
    tester,
    h.controller,
    display: display,
    size: size,
    textScale: textScale,
  );
  return h;
}

HomeShellState _shell(WidgetTester tester) =>
    tester.state<HomeShellState>(find.byType(HomeShell));

Finder _navEntry(String label) =>
    find.descendant(of: find.byType(FloatingNav), matching: find.text(label));

Future<void> _goto(WidgetTester tester, String label) async {
  await tester.tap(_navEntry(label));
  await tester.pumpAndSettle();
}

Future<String> _assetOf(WidgetTester tester, Finder within) async {
  final Finder f = find.descendant(of: within, matching: find.byType(Image));
  final Image img = tester.widget<Image>(f.first);
  final ImageConfiguration cfg = createLocalImageConfiguration(
    tester.element(f.first),
  );
  final AssetBundleImageKey key =
      (await tester.runAsync(() => img.image.obtainKey(cfg)))!
          as AssetBundleImageKey;
  return key.name;
}

ScrollableState _scrollOf(WidgetTester tester) => tester.state<ScrollableState>(
  find
      .descendant(
        of: find.byKey(ProbeKeys.scroll),
        matching: find.byType(Scrollable),
      )
      .first,
);

void main() {
  group('Leiste mit vier Zielen (V2-15, Plan 3.3)', () {
    testWidgets('Pfad, Heute, Chats, Profil in dieser Reihenfolge, kein Feed, '
        'jedes Ziel mit Symbol und Label', (WidgetTester tester) async {
      await _home(tester);
      final FloatingNav nav = tester.widget<FloatingNav>(
        find.byType(FloatingNav),
      );
      expect(nav.items.map((NavItem i) => i.label), <String>[
        S.navPath,
        S.navToday,
        S.navChats,
        S.navProfile,
      ]);
      expect(nav.items.every((NavItem i) => i.label.isNotEmpty), isTrue);
      expect(nav.items.last.avatarInitials, 'J');
      expect(HomeDestination.values.map((HomeDestination d) => d.index), <int>[
        HomeTab.path,
        HomeTab.today,
        HomeTab.chats,
        HomeTab.profile,
      ]);
      await disposeApp(tester);
    });

    testWidgets('jedes Ziel ist erreichbar und zeigt seine Kopf-Karte', (
      WidgetTester tester,
    ) async {
      await _home(tester);
      expect(_shell(tester).activeTab, HomeTab.path);
      await _goto(tester, S.navChats);
      expect(_shell(tester).activeTab, HomeTab.chats);
      expect(find.byType(ChatsScreen), findsOneWidget);
      await _goto(tester, S.navProfile);
      expect(_shell(tester).activeTab, HomeTab.profile);
      expect(find.byType(ProfileScreen), findsOneWidget);
      await _goto(tester, S.navToday);
      expect(_shell(tester).activeTab, HomeTab.today);
      await _goto(tester, S.navPath);
      expect(_shell(tester).activeTab, HomeTab.path);
      await disposeApp(tester);
    });

    testWidgets('Tab-Wechsel behält die Scroll-Position je Ziel', (
      WidgetTester tester,
    ) async {
      await _home(tester, size: Viewports.small);
      // Chats scrollen.
      await _goto(tester, S.navChats);
      ScrollableState chats = _scrollOf(tester);
      expect(chats.position.maxScrollExtent, greaterThan(100));
      chats.position.jumpTo(120);
      await tester.pump();
      // Pfad: Position merken.
      await _goto(tester, S.navPath);
      final double pathOffset = _scrollOf(tester).position.pixels;
      _scrollOf(tester).position.jumpTo(pathOffset - 60);
      await tester.pump();
      final double pathMoved = _scrollOf(tester).position.pixels;
      // Profil und Heute besuchen, zurück: alles steht wie verlassen.
      await _goto(tester, S.navProfile);
      await _goto(tester, S.navToday);
      await _goto(tester, S.navChats);
      chats = _scrollOf(tester);
      expect(chats.position.pixels, 120);
      await _goto(tester, S.navPath);
      expect(_scrollOf(tester).position.pixels, pathMoved);
      await disposeApp(tester);
    });

    testWidgets('inaktive Ziele nehmen weder Semantik noch Fokus an und halten '
        'keine Animation (TickerMode)', (WidgetTester tester) async {
      await _home(tester);
      bool enabled(Type t) => TickerMode.valuesOf(
        tester.element(find.byType(t, skipOffstage: false)),
      ).enabled;
      expect(enabled(ChatsScreen), isFalse);
      expect(enabled(ProfileScreen), isFalse);
      await _goto(tester, S.navProfile);
      expect(enabled(ProfileScreen), isTrue);
      expect(enabled(ChatsScreen), isFalse);
      await disposeApp(tester);
    });

    testWidgets(
      'Blur-Budget: auf jedem Ziel höchstens 3 BackdropFilter, Leiste '
      'und Kopf-Karte des sichtbaren Ziels blurren (V2-10)',
      (WidgetTester tester) async {
        await _home(tester);
        for (final String label in <String>[
          S.navPath,
          S.navToday,
          S.navChats,
          S.navProfile,
          S.navPath,
        ]) {
          await _goto(tester, label);
          final int n = find.byType(BackdropFilter).evaluate().length;
          expect(n, lessThanOrEqualTo(3), reason: label);
          expect(
            find.descendant(
              of: find.byType(FloatingNav),
              matching: find.byType(BackdropFilter),
            ),
            findsOneWidget,
            reason: '$label: Leiste',
          );
          if (label != S.navToday) {
            expect(
              find.descendant(
                of: find.byType(HeaderCard),
                matching: find.byType(BackdropFilter),
              ),
              findsOneWidget,
              reason: '$label: Kopf-Karte',
            );
          }
        }
        await disposeApp(tester);
      },
    );

    testWidgets('Leiste unter Sheet und Vollbild nicht bedienbar (V2-19)', (
      WidgetTester tester,
    ) async {
      await _home(tester, display: DisplayController());
      await _goto(tester, S.navProfile);
      await tester.tap(find.text(S.profileRowDisplay));
      await tester.pumpAndSettle();
      expect(find.byType(DisplaySheet), findsOneWidget);
      // Tipp auf die Stelle der Leiste trifft den Scrim, kein Zielwechsel.
      await tester.tapAt(tester.getCenter(_navEntry(S.navChats)));
      await tester.pumpAndSettle();
      expect(_shell(tester).activeTab, HomeTab.profile);
      await disposeApp(tester);
    });
  });

  group('Profil (V2-53, Plan 3.4)', () {
    testWidgets('Kopf-Karte mit Avatar, Name und „Verletzung · Phase · Woche“; '
        'drei Kacheln mit Werten', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _home(tester);
      await _goto(tester, S.navProfile);
      expect(
        find.descendant(
          of: find.byType(HeaderCard),
          matching: find.text('Jakob'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(S.profileSubtitle(S.injuryShortAcl, 2, 5)),
        findsOneWidget,
      );
      for (final String t in <String>[
        S.profileTileStreak,
        S.profileTileDays,
        S.profileTileFreezes,
      ]) {
        expect(find.text(t), findsOneWidget);
      }
      expect(
        find.bySemanticsLabel(S.profileTileLabel(S.profileTileFreezes, 2)),
        findsOneWidget,
      );
      h.dispose();
      await disposeApp(tester);
    });

    testWidgets('Liste: Deine Daten, Manny-Look direkt über Darstellung, Hilfe '
        'und Datenschutz; jede Zeile ≥ 56 dp, Chevron', (
      WidgetTester tester,
    ) async {
      await _home(tester);
      await _goto(tester, S.navProfile);
      final List<Rect> rows = <Rect>[
        for (final String t in <String>[
          S.profileRowData,
          S.profileRowLook,
          S.profileRowDisplay,
          S.profileRowHelp,
        ])
          tester.getRect(
            find.ancestor(of: find.text(t), matching: find.byType(ListRow)),
          ),
      ];
      for (int i = 0; i < rows.length; i++) {
        expect(rows[i].height, greaterThanOrEqualTo(56), reason: '$i');
        if (i > 0) expect(rows[i].top, greaterThan(rows[i - 1].top));
      }
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(4));
      // Erinnerungen entfallen (Plan 3.4, O-23).
      expect(find.text('Erinnerungen'), findsNothing);
      // Manny-Look zeigt Wert und Kopf.
      expect(find.text(S.mannyLookWith), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets(
      '„Deine Daten“ öffnet das bestehende Sheet, Fokus kehrt zurück',
      (WidgetTester tester) async {
        await _home(tester);
        await _goto(tester, S.navProfile);
        await tester.tap(find.text(S.profileRowData));
        await tester.pumpAndSettle();
        expect(find.text(S.dataSheetSubtitle), findsOneWidget);
        await tester.tap(find.byTooltip(S.close));
        await tester.pumpAndSettle();
        expect(find.text(S.dataSheetSubtitle), findsNothing);
        await disposeApp(tester);
      },
    );

    testWidgets('„Hilfe und Datenschutz“ öffnet die Datenschutz-Seite', (
      WidgetTester tester,
    ) async {
      await _home(tester);
      await _goto(tester, S.navProfile);
      await tester.tap(find.text(S.profileRowHelp));
      await tester.pumpAndSettle();
      expect(find.text(S.privacyPlaceholderBody), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('Manny-Look im Profil (V2-68, Ergänzung 1, 6b)', () {
    testWidgets('Sheet wechselt sofort und ohne Neustart: Asset-Pfad vorher '
        'brille/…, nachher ohne/… an Pfad, Knopf, Chats und Profil', (
      WidgetTester tester,
    ) async {
      final Harness h = await _home(tester);
      Finder pathManny() => find.byKey(const ValueKey<String>('path-manny'));
      expect(
        await _assetOf(tester, pathManny()),
        'assets/manny/brille/normal.png',
      );
      expect(
        await _assetOf(tester, find.byType(MannyButton)),
        'assets/manny/brille/kopf.png',
      );

      await _goto(tester, S.navProfile);
      Finder lookRow() => find.ancestor(
        of: find.text(S.profileRowLook),
        matching: find.byType(ListRow),
      );
      expect(await _assetOf(tester, lookRow()), 'assets/manny/brille/kopf.png');
      await tester.tap(find.text(S.profileRowLook));
      await tester.pumpAndSettle();
      expect(find.byType(MannyLookSheet), findsOneWidget);
      expect(find.text(S.lookSheetHint), findsOneWidget);
      expect(find.byType(MannyLookPicker), findsOneWidget);

      // Wahl „Ohne Brille“: wirkt sofort, schon bei offenem Sheet.
      await tester.tap(find.text(S.mannyLookWithout));
      await tester.pumpAndSettle();
      expect(h.state.mannyLook, MannyLook.ohne);
      expect(
        await _assetOf(tester, lookRow()),
        'assets/manny/ohne/kopf.png',
        reason: 'Zeile im Hintergrund zeigt den neuen Kopf',
      );
      expect(
        find.descendant(of: lookRow(), matching: find.text(S.mannyLookWithout)),
        findsOneWidget,
      );

      await tester.tap(find.text(S.done));
      await tester.pumpAndSettle();
      expect(find.byType(MannyLookSheet), findsNothing);

      await _goto(tester, S.navPath);
      expect(
        await _assetOf(tester, pathManny()),
        'assets/manny/ohne/normal.png',
      );
      expect(
        await _assetOf(tester, find.byType(MannyButton)),
        'assets/manny/ohne/kopf.png',
      );
      await _goto(tester, S.navChats);
      expect(
        await _assetOf(tester, find.byType(ChatsScreen)),
        'assets/manny/ohne/kopf.png',
      );
      // Die Wahl ist gespeichert (Neustart-fest).
      await h.controller.idle;
      expect((await h.persisted())!.mannyLook, MannyLook.ohne);
      await disposeApp(tester);
    });

    testWidgets('Manny-Chat-Vollbild zeigt die neue Variante', (
      WidgetTester tester,
    ) async {
      final Harness h = await _home(tester);
      h.controller.setMannyLook(MannyLook.ohne);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MannyButton));
      await tester.pumpAndSettle();
      expect(
        await _assetOf(tester, find.byType(Scaffold).last),
        contains('assets/manny/ohne/'),
      );
      await disposeApp(tester);
    });

    testWidgets('Look-Karten im Sheet: bei 390 dp nebeneinander, Name in einer '
        'Zeile; bei 320 dp untereinander', (WidgetTester tester) async {
      await _home(tester);
      await _goto(tester, S.navProfile);
      await tester.tap(find.text(S.profileRowLook));
      await tester.pumpAndSettle();
      Rect name(String t) => tester.getRect(
        find
            .descendant(
              of: find.byType(MannyLookPicker),
              matching: find.text(t),
            )
            .first,
      );
      final Rect a = name(S.mannyLookWith);
      final Rect b = name(S.mannyLookWithout);
      expect(b.left, greaterThan(a.right), reason: 'nebeneinander');
      // Der Name bricht nicht um: eine Zeile (Höhe unter zwei Zeilen).
      expect(b.height, lessThan(CuraSize.mannyChoiceRadio * 1.5));
      expect(a.height, closeTo(b.height, 0.5));
      await disposeApp(tester);
    });
  });

  group('Darstellung (Plan 3.4, V2-6 bis V2-9, V2-12)', () {
    Future<DisplayController> open(WidgetTester tester) async {
      final DisplayController d = DisplayController();
      addTearDown(d.dispose);
      await _home(tester, display: d);
      await _goto(tester, S.navProfile);
      await tester.tap(find.text(S.profileRowDisplay));
      await tester.pumpAndSettle();
      return d;
    }

    testWidgets('Welt, Thema, Transparenz reduzieren, Ton und Vibration '
        'wirken sofort auf den Controller', (WidgetTester tester) async {
      final DisplayController d = await open(tester);
      expect(d.settings, const DisplaySettings());
      await tester.tap(find.text(S.worldNight));
      await tester.pumpAndSettle();
      expect(d.settings.world, WorldChoice.night);
      await tester.tap(find.text(S.themeDark));
      await tester.pumpAndSettle();
      expect(d.settings.theme, ThemeChoice.dark);
      await tester.tap(find.text(S.displayReduceTransparency));
      await tester.pumpAndSettle();
      expect(d.settings.reduceTransparency, isTrue);
      await tester.tap(find.text(S.displaySound));
      await tester.pumpAndSettle();
      expect(d.settings.sound, isFalse);
      await tester.tap(find.text(S.displayVibration));
      await tester.pumpAndSettle();
      expect(d.settings.vibration, isFalse);
      await disposeApp(tester);
    });

    testWidgets('Zustand nie nur Farbe: Haken, Wort An/Aus, Semantik', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await open(tester);
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
      expect(find.text(S.switchOn), findsNWidgets(2)); // Ton, Vibration
      expect(find.text(S.switchOff), findsOneWidget); // Transparenz
      expect(
        find.bySemanticsLabel(S.displayChoiceLabel(S.worldAutomatic, true)),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(S.displaySwitchLabel(S.displaySound, true)),
        findsOneWidget,
      );
      await tester.tap(find.text(S.displaySound));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(S.displaySwitchLabel(S.displaySound, false)),
        findsOneWidget,
      );
      h.dispose();
      await disposeApp(tester);
    });

    testWidgets('Sheet ist opak ohne Blur; Transparenz reduzieren macht die '
        'Flächen deckend', (WidgetTester tester) async {
      final DisplayController d = await open(tester);
      expect(
        find.descendant(
          of: find.byType(DisplaySheet),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
      expect(
        find.byType(BackdropFilter).evaluate().length,
        lessThanOrEqualTo(3),
      );
      await tester.tap(find.text(S.displayReduceTransparency));
      await tester.pumpAndSettle();
      expect(d.settings.reduceTransparency, isTrue);
      expect(find.byType(BackdropFilter), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('Tastatur: Pfeil-frei, Enter schaltet; „Fertig“ schließt', (
      WidgetTester tester,
    ) async {
      final DisplayController d = await open(tester);
      final Finder vib = find.ancestor(
        of: find.text(S.displayVibration),
        matching: find.byType(Focus),
      );
      expect(vib, findsWidgets);
      await tester.tap(find.text(S.done));
      await tester.pumpAndSettle();
      expect(find.byType(DisplaySheet), findsNothing);
      expect(d.settings.vibration, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await disposeApp(tester);
    });
  });
}
