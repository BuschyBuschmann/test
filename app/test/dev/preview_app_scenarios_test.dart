// App-Szenarien der Prüfumgebung (U2b): die echte App startet mit dem Speicher
// des Szenarios (`ob*`, `shell-*`), `live=1` nutzt den echten Speicher für
// Reload-Prüfungen im Browser.
import 'package:curaone/dev/preview_app.dart';
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/ui/components/action_cluster.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/components/cura_dialog.dart';
import 'package:curaone/ui/components/header_icon_button.dart';
import 'package:curaone/ui/components/manny.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
import 'package:curaone/ui/components/messages_button.dart';
import 'package:curaone/ui/components/node_hint.dart';
import 'package:curaone/ui/components/path_header.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:curaone/ui/components/probe_keys.dart';
import 'package:curaone/ui/components/stat_pill.dart';
import 'package:curaone/ui/start/start_loading_view.dart';
import 'package:curaone/ui/home/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Siehe test/data/stores_test.dart: In-Memory-Ersatz der Plattform.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/app_harness.dart';
import '../support/pump_app.dart';

Future<void> _pump(WidgetTester tester, PreviewConfig config) async {
  setViewport(tester, Viewports.phone);
  await tester.pumpWidget(PreviewApp(config: config));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('ob-mic-hint: Skript tippt den Mikrofon-Button', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const PreviewConfig(scenarioId: 'ob-mic-hint'));
    expect(find.text(S.micHint), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('ob1-deleted-snackbar: echter Löschweg, Schritt 1 mit Hinweis', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const PreviewConfig(scenarioId: 'ob1-deleted-snackbar'),
    );
    expect(find.text('Schritt 1 von 4'), findsOneWidget);
    expect(find.text(S.dataDeleted), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('ob1-corrupt-snackbar: Neustart nach unlesbaren Daten', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const PreviewConfig(scenarioId: 'ob1-corrupt-snackbar'),
    );
    expect(find.text('Schritt 1 von 4'), findsOneWidget);
    expect(find.text(S.dataUnreadable), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('shell-tab-today: Home mit aktivem Tab Heute', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const PreviewConfig(scenarioId: 'shell-tab-today'));
    expect(
      tester.state<HomeShellState>(find.byType(HomeShell)).activeTab,
      HomeTab.today,
    );
    await disposeApp(tester);
  });

  testWidgets('ob3-acl: Szenario setzt Zustand (Schritt 3, ACL gewählt)', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const PreviewConfig(scenarioId: 'ob3-acl'));
    expect(find.text('Schritt 3 von 4'), findsOneWidget);
    expect(find.text(S.onboardingStep3('Jakob')), findsOneWidget);
  });

  testWidgets('Tastatur-Szenario blendet die Platzhalterfläche ein', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const PreviewConfig(scenarioId: 'ob1-keyboard'));
    expect(
      tester.view.viewInsets.bottom,
      0,
      reason: 'Echte View bleibt unberührt, nur MediaQuery wird überschrieben',
    );
    expect(find.byKey(const ValueKey<String>('overlay:keyboard')), findsOne);
    final Rect button = tester.getRect(find.byType(PillButton));
    expect(button.bottom, lessThanOrEqualTo(Viewports.phone.height - 300));
    await disposeApp(tester);
  });

  // Pfad-Szenarien (U3a, Plan 12.4): jedes zeigt, was sein Name sagt, über den
  // echten Weg der App (StartGate, HomeShell, PathScreen).
  group('Pfad-Szenarien', () {
    Future<void> path(WidgetTester tester, String id, {Size? size}) async {
      setViewport(tester, size ?? Viewports.phone);
      await tester.pumpWidget(
        PreviewApp(config: PreviewConfig(scenarioId: id)),
      );
      await tester.pumpAndSettle();
    }

    final Finder bubble = find.byType(MannyBubble);
    final Finder hint = find.byType(NodeHint);
    final Finder cluster = find.byType(ActionCluster);

    ScrollableState pathScroll(WidgetTester tester) =>
        tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(ProbeKeys.scroll),
            matching: find.byType(Scrollable),
          ),
        );

    testWidgets('path-loading: Ladeansicht ohne Button-Gruppe', (
      WidgetTester tester,
    ) async {
      await path(tester, 'path-loading');
      expect(find.byType(StartLoadingView), findsOneWidget);
      expect(cluster, findsNothing);
      expect(find.byType(FloatingNav), findsOneWidget);
    });

    testWidgets('path-error: Fehlertext des Pfad-Tabs (E-4), „Nochmal '
        'versuchen“, ohne Button-Gruppe', (WidgetTester tester) async {
      await path(tester, 'path-error');
      expect(find.text(S.pathLoadError), findsOneWidget);
      expect(find.text(S.retry), findsOneWidget);
      expect(cluster, findsNothing);
    });

    testWidgets('path-active: Woche 5, Streak 12, Freezes 2, keine Blase', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await path(tester, 'path-active');
      expect(find.text('Woche 5'), findsOneWidget);
      expect(find.bySemanticsLabel('Streak: 12 Tage'), findsOneWidget);
      expect(find.bySemanticsLabel('Streak-Freezes: 2'), findsOneWidget);
      expect(bubble, findsNothing);
      expect(cluster, findsOneWidget);
      h.dispose();
    });

    testWidgets('path-frozen: „eingefroren“ und ein Freeze weniger', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await path(tester, 'path-frozen');
      expect(find.text(S.streakFrozenWord), findsOneWidget);
      expect(
        find.bySemanticsLabel('Streak: 12 Tage, eingefroren'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Streak-Freezes: 1'), findsOneWidget);
      h.dispose();
    });

    testWidgets('path-reset: Zahl 0, keine Blase', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await path(tester, 'path-reset');
      expect(find.bySemanticsLabel('Streak: 0 Tage'), findsOneWidget);
      expect(find.bySemanticsLabel('Streak-Freezes: 0'), findsOneWidget);
      expect(bubble, findsNothing);
      h.dispose();
    });

    for (final (String, String) c in <(String, String)>[
      (
        'path-bubble-greeting',
        "Moin Jakob, los geht's. Dein Weg beginnt hier.",
      ),
      (
        'path-bubble-danger',
        'Dein Streak von 12 Tagen wartet auf dich. Heute noch eine Runde?',
      ),
      (
        'path-bubble-restart',
        'Neuer Anlauf, Jakob. Dein Pfad bleibt, der Streak startet heute neu.',
      ),
      ('path-celebration', 'Stark, Jakob. Das war Tag 13.'),
    ]) {
      testWidgets('${c.$1}: Blase mit dem Text des Anlasses', (
        WidgetTester tester,
      ) async {
        await path(tester, c.$1);
        expect(find.text(c.$2), findsOneWidget);
        expect(bubble, findsOneWidget);
      });
    }

    testWidgets('path-celebration: Pose feiernd', (WidgetTester tester) async {
      await path(tester, 'path-celebration');
      expect(
        tester
            .widget<MannyPlaceholder>(
              find.byKey(const ValueKey<String>('path-manny')),
            )
            .pose,
        MannyPose.feiernd,
      );
    });

    testWidgets('path-hint-locked / path-hint-done: der Hinweis steht', (
      WidgetTester tester,
    ) async {
      await path(tester, 'path-hint-locked');
      expect(hint, findsOneWidget);
      expect(find.text(S.hintThisWeek), findsOneWidget);
      await disposeApp(tester);
      await path(tester, 'path-hint-done');
      expect(hint, findsOneWidget);
      expect(find.text(S.hintDone), findsOneWidget);
    });

    testWidgets('path-week1 und path-end: Woche 1, Endfall mit Manny auf dem '
        'letzten Phasen-Abschluss', (WidgetTester tester) async {
      await path(tester, 'path-week1');
      expect(find.text('Woche 1'), findsOneWidget);
      await disposeApp(tester);
      await path(tester, 'path-end');
      expect(find.text('Woche 12'), findsOneWidget);
      final Rect manny = tester.getRect(
        find.byKey(const ValueKey<String>('path-manny')),
      );
      final Rect unit = tester.getRect(
        find.byKey(const ValueKey<String>('unit:p3-end'), skipOffstage: false),
      );
      expect(manny.center.dx, closeTo(unit.center.dx, 1));
      expect(manny.bottom, closeTo(unit.top + 6, 3));
    });

    testWidgets('path-header-wrap: feste Skalierung 1,2, Umbruch-Layout bei '
        '320 dp', (WidgetTester tester) async {
      await path(tester, 'path-header-wrap', size: Viewports.small);
      final MediaQueryData mq = MediaQuery.of(
        tester.element(find.byType(PathHeader)),
      );
      expect(mq.textScaler.scale(10), closeTo(12, 1e-9));
      final Rect icon = tester.getRect(find.byType(HeaderIconButton));
      final Rect pill = tester.getRect(find.byType(StatPill).first);
      expect(
        pill.top,
        greaterThan(icon.center.dy),
        reason: 'Pillen in Zeile 2',
      );
      expect(pill.left, 16);
    });

    testWidgets('path-cluster-bubble: Pfad ganz unten, Blase vorhanden und '
        'über der Gruppe', (WidgetTester tester) async {
      await path(tester, 'path-cluster-bubble', size: Viewports.small);
      final ScrollableState st = pathScroll(tester);
      expect(st.position.pixels, closeTo(st.position.maxScrollExtent, 1));
      expect(bubble, findsOneWidget);
      expect(
        tester.getRect(bubble).bottom,
        lessThanOrEqualTo(tester.getRect(cluster).top - 8 + 0.5),
      );
    });

    testWidgets('path-cluster-hint: Pfad ganz unten, Hinweis an einer Unit '
        'nahe der Gruppe', (WidgetTester tester) async {
      await path(tester, 'path-cluster-hint', size: Viewports.small);
      final ScrollableState st = pathScroll(tester);
      expect(st.position.pixels, closeTo(st.position.maxScrollExtent, 40));
      expect(hint, findsOneWidget);
      expect(find.text(S.hintDone), findsOneWidget);
      expect(
        tester.getRect(hint).bottom,
        lessThanOrEqualTo(tester.getRect(cluster).top - 8 + 0.5),
      );
    });

    testWidgets('path-scrolled-bottom: unterste Unit über der Gruppe', (
      WidgetTester tester,
    ) async {
      await path(tester, 'path-scrolled-bottom', size: Viewports.small);
      final ScrollableState st = pathScroll(tester);
      expect(st.position.pixels, closeTo(st.position.maxScrollExtent, 1));
      final Rect unit = tester.getRect(
        find.byKey(const ValueKey<String>('unit:w1-d1'), skipOffstage: false),
      );
      expect(unit.bottom, lessThanOrEqualTo(tester.getRect(cluster).top));
    });
  });

  // Heute-Szenarien (U3b, Plan 12.4): jedes zeigt, was sein Name sagt, über den
  // echten Weg der App (StartGate, HomeShell, TodayScreen, echte Aktionen).
  group('Heute-Szenarien', () {
    Future<void> today(WidgetTester tester, String id, {Size? size}) async {
      setViewport(tester, size ?? Viewports.phone);
      await tester.pumpWidget(
        PreviewApp(config: PreviewConfig(scenarioId: id)),
      );
      await tester.pumpAndSettle();
    }

    ScrollableState list(WidgetTester tester) => tester.state(
      find.descendant(
        of: find.byKey(ProbeKeys.scroll),
        matching: find.byType(Scrollable),
      ),
    );

    testWidgets('today-standard: Mittwoch, Physio, Gruppe, 20 Min', (
      WidgetTester tester,
    ) async {
      await today(tester, 'today-standard');
      expect(find.text('Mittwoch, 7. Oktober'), findsOneWidget);
      expect(find.text(S.apptPhysioTitle), findsOneWidget);
      expect(find.text('ÜBUNGEN · CA. 20 MIN'), findsOneWidget);
      expect(find.byType(MessagesButton), findsOneWidget);
      expect(find.byKey(ProbeKeys.primaryRow), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('today-friday / today-weekend: Termine nach Wochentag', (
      WidgetTester tester,
    ) async {
      await today(tester, 'today-friday');
      expect(find.text('Freitag, 9. Oktober'), findsOneWidget);
      expect(find.text(S.apptDoctorTitle), findsOneWidget);
      expect(find.text(S.apptPhysioTitle), findsOneWidget);
      await disposeApp(tester);
      await today(tester, 'today-weekend');
      expect(find.text('Samstag, 10. Oktober'), findsOneWidget);
      expect(find.text(S.noAppointments), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('today-10 / today-30: Zeitwahl im Zustand', (
      WidgetTester tester,
    ) async {
      await today(tester, 'today-10');
      expect(find.text('ÜBUNGEN · CA. 10 MIN'), findsOneWidget);
      await disposeApp(tester);
      await today(tester, 'today-30');
      expect(find.text('ÜBUNGEN · CA. 30 MIN'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('today-empty / today-done / today-empty-done', (
      WidgetTester tester,
    ) async {
      PillButton primary() =>
          tester.widget<PillButton>(find.byKey(ProbeKeys.primary));
      await today(tester, 'today-empty');
      expect(find.text(S.emptyExercises), findsOneWidget);
      expect(primary().label, S.startTraining);
      expect(primary().onPressed, isNull);
      await disposeApp(tester);
      await today(tester, 'today-done');
      expect(primary().label, S.trainingDone);
      await disposeApp(tester);
      await today(tester, 'today-empty-done');
      expect(find.text(S.emptyExercises), findsOneWidget);
      expect(primary().label, S.trainingDone);
      await disposeApp(tester);
    });

    testWidgets('today-loading / today-error: ohne Button-Gruppe', (
      WidgetTester tester,
    ) async {
      await today(tester, 'today-loading');
      expect(find.byType(MessagesButton), findsNothing);
      expect(find.byType(FloatingNav), findsOneWidget);
      await disposeApp(tester);
      await today(tester, 'today-error');
      expect(find.text(S.todayLoadError), findsOneWidget);
      expect(find.text(S.retry), findsOneWidget);
      expect(find.byType(MessagesButton), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('today-cluster / today-done-cluster: Liste ganz unten', (
      WidgetTester tester,
    ) async {
      for (final String id in <String>['today-cluster', 'today-done-cluster']) {
        await today(tester, id, size: Viewports.small);
        final ScrollableState st = list(tester);
        expect(st.position.maxScrollExtent, greaterThan(0));
        expect(st.position.pixels, st.position.maxScrollExtent, reason: id);
        await disposeApp(tester);
      }
    });

    testWidgets('today-snackbar-removed / -logged / -cluster', (
      WidgetTester tester,
    ) async {
      await today(tester, 'today-snackbar-removed');
      expect(find.text(S.removedSnackbar), findsOneWidget);
      expect(find.text(S.exSquatName), findsNothing);
      await disposeApp(tester);
      await today(tester, 'today-snackbar-logged');
      expect(find.text(S.loggedSnackbar), findsOneWidget);
      expect(find.text(S.trainingDone), findsOneWidget);
      await disposeApp(tester);
      await today(tester, 'today-snackbar-cluster', size: Viewports.small);
      expect(find.text(S.removedSnackbar), findsOneWidget);
      final ScrollableState st = list(tester);
      expect(st.position.pixels, greaterThan(0), reason: 'am Ende, nicht oben');
      await disposeApp(tester);
    });

    testWidgets('today-mode-sheet / today-custom-dialog(-keyboard)', (
      WidgetTester tester,
    ) async {
      await today(tester, 'today-mode-sheet');
      expect(find.text(S.trainingSheetTitle), findsOneWidget);
      await disposeApp(tester);
      await today(tester, 'today-custom-dialog');
      expect(find.byType(CuraDialog), findsOneWidget);
      await disposeApp(tester);
      await today(tester, 'today-custom-dialog-keyboard');
      expect(find.byType(CuraDialog), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('overlay:keyboard')), findsOne);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .focusNode
            .hasFocus,
        isTrue,
      );
      await disposeApp(tester);
    });

    testWidgets(
      'today-newday-snackbar: Zeitsprung, frisches Programm, Snackbar',
      (WidgetTester tester) async {
        await today(tester, 'today-newday-snackbar');
        expect(find.text('Donnerstag, 8. Oktober'), findsOneWidget);
        expect(find.text(S.newDaySnackbar), findsOneWidget);
        // Das Szenario hatte eine Übung entfernt: das neue Programm ist frisch.
        expect(find.text('ÜBUNGEN · CA. 20 MIN'), findsOneWidget);
        await tester.pump(const Duration(seconds: 10));
        await disposeApp(tester);
      },
    );
  });

  group('live=1 (echter Speicher, Reload)', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    testWidgets('Eingabe überlebt den Neuaufbau (Reload)', (
      WidgetTester tester,
    ) async {
      const PreviewConfig live = PreviewConfig(
        scenarioId: 'ob1-empty',
        live: true,
      );
      await _pump(tester, live);
      await tester.enterText(find.byType(TextField), 'Jakob');
      await tester.pump();
      await tester.tap(find.widgetWithText(PillButton, S.next));
      await tester.pumpAndSettle();
      expect(find.text('Schritt 2 von 4'), findsOneWidget);
      await disposeApp(tester);

      // „Reload“: neue App, derselbe Speicher.
      await _pump(tester, live);
      expect(find.text('Schritt 2 von 4'), findsOneWidget);
      expect(find.text(S.onboardingStep2('Jakob')), findsOneWidget);
      await disposeApp(tester);
    });
  });
}
