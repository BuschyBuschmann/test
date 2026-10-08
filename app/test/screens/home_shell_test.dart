// Home-Gerüst (U2b, Plan 4.1, 4.3, 4.6; UI-8, UI-42, UI-44, UI-86 A-39):
// Tabs im IndexedStack mit TickerMode, Zurück-Reihenfolge, Tabwechsel beendet
// Fenster/Hinweis/Snackbar, Tageswechsel über Fortsetzen und Tabwechsel mit
// der Reihenfolge aus Plan 4.6.
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/manny_occasions.dart' show MannyPose;
import 'package:curaone/state/app_controller.dart';
import 'package:curaone/ui/components/cura_snackbar.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/home/home_shell.dart';
import 'package:curaone/ui/home/tab_placeholders.dart';
import 'package:curaone/ui/routes/cura_sheet_route.dart';
import 'package:curaone/ui/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/controller_harness.dart';

Future<Harness> _home(WidgetTester tester, {DateTime? now}) async {
  final Harness h = await Harness.onboarded(now: now);
  addTearDown(h.dispose);
  await pumpCura(tester, h.controller);
  return h;
}

HomeShellState _shell(WidgetTester tester) =>
    tester.state<HomeShellState>(find.byType(HomeShell));

Finder _navEntry(String label) =>
    find.descendant(of: find.byType(FloatingNav), matching: find.text(label));

Future<void> _selectToday(WidgetTester tester) async {
  await tester.tap(_navEntry(S.navToday));
  await tester.pumpAndSettle();
}

Future<void> _closeLater(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await disposeApp(tester);
}

/// Legt ein Heute-Sheet an und meldet es im Register an.
Route<void> _pushTodaySheet(WidgetTester tester, {bool register = true}) {
  final BuildContext context = tester.element(find.byType(HomeShell));
  final Route<void> route = CuraSheetRoute<void>(
    context: context,
    routeLabel: 'Test',
    builder: (BuildContext context) => const CuraSheetFrame(
      header: SizedBox(height: 56, child: Text('Trainings-Sheet')),
      body: SizedBox(height: 100),
    ),
  );
  if (register) _shell(tester).todayRoutes.register(route);
  Navigator.of(context).push<void>(route);
  return route;
}

void main() {
  group('Tabs', () {
    testWidgets('öffnet auf Pfad (A-1); Nav mit Pfad und Heute', (
      WidgetTester tester,
    ) async {
      await _home(tester);
      expect(_shell(tester).activeTab, HomeTab.path);
      expect(find.text(S.pathTabTitle), findsOneWidget);
      expect(_navEntry(S.navPath), findsOneWidget);
      expect(_navEntry(S.navToday), findsOneWidget);
      expect(
        tester.widget<FloatingNav>(find.byType(FloatingNav)).currentIndex,
        HomeTab.path,
      );
      await disposeApp(tester);
    });

    testWidgets('Tabwechsel ist keine Route; beide Tabs bleiben im Baum', (
      WidgetTester tester,
    ) async {
      await _home(tester);
      final NavigatorState nav = Navigator.of(
        tester.element(find.byType(HomeShell)),
      );
      expect(nav.canPop(), isFalse);
      await _selectToday(tester);
      expect(nav.canPop(), isFalse);
      expect(_shell(tester).activeTab, HomeTab.today);
      expect(find.text(S.todayTitle('Jakob')), findsOneWidget);
      // IndexedStack: der inaktive Tab bleibt gebaut (Scrollposition bleibt).
      expect(find.byType(PathTabPlaceholder, skipOffstage: false), findsOne);
      await disposeApp(tester);
    });

    testWidgets('inaktiver Tab läuft in TickerMode(enabled: false) (UI-8)', (
      WidgetTester tester,
    ) async {
      await _home(tester);
      bool enabled(Type type) => TickerMode.valuesOf(
        tester.element(find.byType(type, skipOffstage: false)),
      ).enabled;
      expect(enabled(PathTabPlaceholder), isTrue);
      expect(enabled(TodayTabPlaceholder), isFalse);
      await _selectToday(tester);
      expect(enabled(PathTabPlaceholder), isFalse);
      expect(enabled(TodayTabPlaceholder), isTrue);
      await disposeApp(tester);
    });

    testWidgets('inaktiver Tab nimmt weder Semantik noch Fokus an', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _home(tester);
      expect(find.bySemanticsLabel(S.pathTabTitle), findsOneWidget);
      expect(find.bySemanticsLabel(S.todayTitle('Jakob')), findsNothing);
      await _selectToday(tester);
      expect(find.bySemanticsLabel(S.pathTabTitle), findsNothing);
      expect(find.bySemanticsLabel(S.todayTitle('Jakob')), findsOneWidget);
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('Tabwechsel beendet Rückgängig-Fenster, Hinweis und Snackbar', (
      WidgetTester tester,
    ) async {
      final Harness h = await _home(tester);
      await _selectToday(tester);
      h.controller.logTraining(forDay: h.controller.today);
      expect(h.controller.transient.undoWindowOpen, isTrue);
      _shell(tester).snackbar.show(const CuraSnackbarMessage(text: 'Test'));
      await tester.pump();
      expect(find.text('Test'), findsOneWidget);
      h.controller.transient.showHint('w5-d3');

      await tester.tap(_navEntry(S.navPath));
      await tester.pumpAndSettle();
      expect(h.controller.transient.undoWindowOpen, isFalse);
      expect(h.controller.transient.hintUnitId, isNull);
      expect(find.text('Test'), findsNothing);
      await _closeLater(tester);
    });
  });

  group('Zurück (Plan 4.3, N-6)', () {
    testWidgets('Heute → Pfad, beendet das Rückgängig-Fenster', (
      WidgetTester tester,
    ) async {
      final Harness h = await _home(tester);
      await _selectToday(tester);
      h.controller.logTraining(forDay: h.controller.today);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_shell(tester).activeTab, HomeTab.path);
      expect(h.controller.transient.undoWindowOpen, isFalse);
      await _closeLater(tester);
    });

    testWidgets('Pfad: erst Blase, dann Hinweis, dann App schließen', (
      WidgetTester tester,
    ) async {
      final SystemPopRecorder pop = SystemPopRecorder(tester);
      final Harness h = await _home(tester);
      h.controller.transient
        ..showBubble(
          const BubbleDecision(
            occasion: MannyOccasion.greeting,
            pose: MannyPose.neutral,
          ),
        )
        ..showHint('w5-d3');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(h.controller.transient.visibleBubble, isNull);
      expect(h.controller.transient.hintUnitId, 'w5-d3');
      // Weggetippt zählt als gezeigt.
      expect(
        h.state.manny.shownOn(MannyOccasion.greeting, h.controller.today),
        isTrue,
      );
      expect(pop.count, 0);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(h.controller.transient.hintUnitId, isNull);
      expect(pop.count, 0);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(pop.count, 1);
      expect(find.byType(HomeShell), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('Zurück auf Heute schließt nur zum Pfad, nicht die App', (
      WidgetTester tester,
    ) async {
      final SystemPopRecorder pop = SystemPopRecorder(tester);
      await _home(tester);
      await _selectToday(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(pop.count, 0);
      expect(_shell(tester).activeTab, HomeTab.path);
      await disposeApp(tester);
    });

    testWidgets('offenes Sheet schließt zuerst; Tab bleibt', (
      WidgetTester tester,
    ) async {
      final SystemPopRecorder pop = SystemPopRecorder(tester);
      await _home(tester);
      await _selectToday(tester);
      _pushTodaySheet(tester);
      await tester.pumpAndSettle();
      expect(find.text('Trainings-Sheet'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Trainings-Sheet'), findsNothing);
      expect(_shell(tester).activeTab, HomeTab.today);
      expect(pop.count, 0);
      await disposeApp(tester);
    });
  });

  group('Tageswechsel (Ergänzung 1, 3.4; Plan 4.6)', () {
    testWidgets(
      'Heute sichtbar, Fortsetzen: Snackbar 5 s und Ansage, Undo vorbei',
      (WidgetTester tester) async {
        final Harness h = await _home(tester);
        await _selectToday(tester);
        h.controller.logTraining(forDay: h.controller.today);
        expect(h.state.day.done, isTrue);
        tester.takeAnnouncements();

        h.clock.advanceDays(1);
        resumeApp(tester);
        await tester.pumpAndSettle();

        expect(h.state.day.dayKey, h.controller.today);
        expect(h.state.day.done, isFalse, reason: 'frisches Programm');
        expect(h.controller.transient.undoWindowOpen, isFalse);
        expect(find.text(S.newDaySnackbar), findsOneWidget);
        expect(
          tester.takeAnnouncements().map((a) => a.message),
          contains(S.newDayAnnouncement),
        );
        // Ohne Aktion, 5 s.
        expect(find.text('Rückgängig'), findsNothing);
        await tester.pump(const Duration(seconds: 4));
        expect(find.text(S.newDaySnackbar), findsOneWidget);
        await tester.pump(const Duration(seconds: 1, milliseconds: 200));
        await tester.pumpAndSettle();
        expect(find.text(S.newDaySnackbar), findsNothing);
        await disposeApp(tester);
      },
    );

    testWidgets(
      'Pfad sichtbar: Zustand wechselt, keine Snackbar, keine Ansage',
      (WidgetTester tester) async {
        final Harness h = await _home(tester);
        tester.takeAnnouncements();
        final LocalDay before = h.state.day.dayKey;
        h.clock.advanceDays(1);
        resumeApp(tester);
        await tester.pumpAndSettle();
        expect(h.state.day.dayKey, isNot(before));
        expect(find.text(S.newDaySnackbar), findsNothing);
        expect(tester.takeAnnouncements(), isEmpty);
        await disposeApp(tester);
      },
    );

    testWidgets('gleicher Tag: nichts passiert', (WidgetTester tester) async {
      final Harness h = await _home(tester);
      await _selectToday(tester);
      tester.takeAnnouncements();
      resumeApp(tester);
      await tester.pumpAndSettle();
      expect(find.text(S.newDaySnackbar), findsNothing);
      expect(tester.takeAnnouncements(), isEmpty);
      expect(h.state.day.dayKey, h.controller.today);
      await disposeApp(tester);
    });

    testWidgets('Wechsel auf Heute bei neuem Tag gilt als sichtbar (A-31)', (
      WidgetTester tester,
    ) async {
      final Harness h = await _home(tester);
      h.clock.advanceDays(1);
      tester.takeAnnouncements();
      await tester.tap(_navEntry(S.navToday));
      await tester.pumpAndSettle();
      expect(h.state.day.dayKey, h.controller.today);
      expect(find.text(S.newDaySnackbar), findsOneWidget);
      expect(
        tester.takeAnnouncements().map((a) => a.message),
        contains(S.newDayAnnouncement),
      );
      await _closeLater(tester);
    });

    testWidgets('Heute-Routen werden zuerst geschlossen, danach die Snackbar', (
      WidgetTester tester,
    ) async {
      final Harness h = await _home(tester);
      await _selectToday(tester);
      _pushTodaySheet(tester);
      await tester.pumpAndSettle();
      expect(find.text('Trainings-Sheet'), findsOneWidget);

      h.clock.advanceDays(1);
      resumeApp(tester);
      await tester.pump(); // Routen geschlossen, Ende abwarten
      await tester.pumpAndSettle();
      expect(find.text('Trainings-Sheet'), findsNothing);
      expect(find.text(S.newDaySnackbar), findsOneWidget);
      expect(_shell(tester).todayRoutes.length, 0);
      await _closeLater(tester);
    });

    testWidgets(
      'offene Vollbild-Route (A-39): keine Snackbar, keine Ansage, Heute zeigt danach das neue Datum',
      (WidgetTester tester) async {
        final Harness h = await _home(tester);
        await _selectToday(tester);
        final BuildContext context = tester.element(find.byType(HomeShell));
        // Stellvertreter für Chat/Nachrichten/„Deine Daten“: eine Seitenroute,
        // die nicht im Heute-Register steht.
        Navigator.of(context).push<void>(AppRoutes.privacy(context));
        await tester.pumpAndSettle();
        tester.takeAnnouncements();

        h.clock.advanceDays(1);
        resumeApp(tester);
        await tester.pumpAndSettle();
        expect(find.text(S.newDaySnackbar), findsNothing);
        expect(tester.takeAnnouncements(), isEmpty);
        expect(h.state.day.dayKey, h.controller.today);

        // Zurück: neues Datum, weiterhin ohne Snackbar.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(HomeShell), findsOneWidget);
        expect(find.text(S.newDaySnackbar), findsNothing);
        await disposeApp(tester);
      },
    );

    testWidgets('Sheet nicht im Register („Deine Daten“) bleibt offen', (
      WidgetTester tester,
    ) async {
      final Harness h = await _home(tester);
      await _selectToday(tester);
      _pushTodaySheet(tester, register: false);
      await tester.pumpAndSettle();
      h.clock.advanceDays(1);
      resumeApp(tester);
      await tester.pumpAndSettle();
      expect(find.text('Trainings-Sheet'), findsOneWidget);
      expect(find.text(S.newDaySnackbar), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('Bewegung reduzieren: Wechsel ohne laufende Animation', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final Harness h = await _home(tester);
      await _selectToday(tester);
      h.clock.advanceDays(1);
      resumeApp(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 121));
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text(S.newDaySnackbar), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
      await _closeLater(tester);
    });
  });
}
