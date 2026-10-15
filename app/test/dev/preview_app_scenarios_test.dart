// App-Szenarien der Prüfumgebung (U2b): die echte App startet mit dem Speicher
// des Szenarios (`ob*`, `shell-*`), `live=1` nutzt den echten Speicher für
// Reload-Prüfungen im Browser.
import 'package:curaone/dev/preview_app.dart';
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/components/cura_dialog.dart';
import 'package:curaone/ui/components/header_icon_button.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/ui/components/manny.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
import 'package:curaone/ui/components/manny_chat_button.dart';
import 'package:curaone/ui/components/node_hint.dart';
import 'package:curaone/ui/components/header_card.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:curaone/ui/components/probe_keys.dart';
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
import '../support/line_breaks.dart';
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

  testWidgets('ob3-muscle: Hinweis „noch keinen eigenen Pfad“ steht', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const PreviewConfig(scenarioId: 'ob3-muscle'));
    expect(find.text('Schritt 3 von 4'), findsOneWidget);
    expect(find.text(S.injuryNoOwnPath), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('data-sheet-muscle / data-privacy: Hinweis im Sheet, Link '
      'öffnet die Platzhalterseite', (WidgetTester tester) async {
    await _pump(tester, const PreviewConfig(scenarioId: 'data-sheet-muscle'));
    expect(find.text(S.injuryNoOwnPath), findsOneWidget);
    expect(find.text('Phase 2 · Muskelfaserriss'), findsOneWidget);
    await disposeApp(tester);
    await _pump(tester, const PreviewConfig(scenarioId: 'data-privacy'));
    expect(find.text(S.privacyPlaceholderBody), findsOneWidget);
    await disposeApp(tester);
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
    final Finder cluster = find.byType(MannyButton);

    ScrollableState pathScroll(WidgetTester tester) =>
        tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(ProbeKeys.scroll),
            matching: find.byType(Scrollable),
          ),
        );

    testWidgets('path-loading: Ladeansicht ohne Manny-Knopf', (
      WidgetTester tester,
    ) async {
      await path(tester, 'path-loading');
      expect(find.byType(StartLoadingView), findsOneWidget);
      expect(cluster, findsNothing);
      expect(find.byType(FloatingNav), findsOneWidget);
    });

    testWidgets('path-error: Fehlertext des Pfad-Tabs (E-4), „Nochmal '
        'versuchen“, ohne Manny-Knopf', (WidgetTester tester) async {
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
      expect(find.text('12 ${S.streakFrozenWord}'), findsOneWidget);
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
            .widget<MannyIllustration>(
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

    testWidgets('path-stat-hint-freeze / -streak: die Erklärung steht', (
      WidgetTester tester,
    ) async {
      await path(tester, 'path-stat-hint-freeze');
      expect(hint, findsOneWidget);
      expect(find.text(S.hintFreeze), findsOneWidget);
      await disposeApp(tester);
      await path(tester, 'path-stat-hint-streak');
      expect(hint, findsOneWidget);
      expect(find.text(S.hintStreak), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('path-muscle: Kopfzeile zeigt den vollen Namen', (
      WidgetTester tester,
    ) async {
      await path(tester, 'path-muscle');
      expect(find.text('Phase 2 · Muskelfaserriss'), findsOneWidget);
      await disposeApp(tester);
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
      // Manny steht neben der Kugel (rechts, bei Platzmangel links), die Füße
      // auf ihrer Unterkante; unter der Fußlinie bleibt der Rand der Leinwand
      // (8 dp bei 193 dp Höhe).
      final double belowFeet =
          CuraSize.mannyPathHeight -
          MannyIllustration.feetFromTop(CuraSize.mannyPathHeight);
      expect(manny.bottom - belowFeet, closeTo(unit.bottom, 1));
      final bool right = manny.left >= unit.right;
      expect(
        right ? manny.left - unit.right : unit.left - manny.right,
        // Das Rechteck von `path-manny` enthält den 8-dp-Trefferrand.
        closeTo(CuraSize.mannyBesideGap - CuraSize.mannyHitMargin, 1),
      );
    });

    testWidgets('path-header-wrap: feste Skalierung 1,2, Kopf-Karte bei '
        '320 dp: Chips umbrechen, nichts ragt heraus', (
      WidgetTester tester,
    ) async {
      await path(tester, 'path-header-wrap', size: Viewports.small);
      final MediaQueryData mq = MediaQuery.of(
        tester.element(find.byType(HeaderCard)),
      );
      expect(mq.textScaler.scale(10), closeTo(12, 1e-9));
      final Rect card = tester.getRect(find.byType(HeaderCard));
      expect(card.left, CuraSize.cardMargin);
      expect(card.right, Viewports.small.width - CuraSize.cardMargin);
      final List<Rect> chips = <Rect>[
        for (final Element e in find.byType(HeaderChip).evaluate())
          tester.getRect(find.byWidget(e.widget)),
      ];
      expect(chips, hasLength(3));
      for (final Rect c in chips) {
        expect(c.left, greaterThanOrEqualTo(card.left));
        expect(c.right, lessThanOrEqualTo(card.right));
      }
      final Rect icon = tester.getRect(find.byType(HeaderIconButton));
      expect(icon.right, lessThanOrEqualTo(card.right));
      expect(icon.top, greaterThanOrEqualTo(card.top));
      await disposeApp(tester);
    });

    testWidgets('path-cluster-bubble: Pfad ganz unten, Blase vorhanden und '
        'über dem Manny-Knopf', (WidgetTester tester) async {
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
      // Der Hinweis darf den Pfad beim Platzieren ein Stück nach oben schieben
      // (mit den größeren Kugeln der aktuellen Unit bis etwa 200 dp).
      expect(st.position.pixels, closeTo(st.position.maxScrollExtent, 220));
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
      expect(find.byType(MannyButton), findsOneWidget);
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
      expect(primary().label, S.trainingLog);
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

    testWidgets('today-loading / today-error: ohne Primärbutton-Reihe', (
      WidgetTester tester,
    ) async {
      await today(tester, 'today-loading');
      expect(find.byType(MannyButton), findsNothing);
      expect(find.byType(FloatingNav), findsOneWidget);
      await disposeApp(tester);
      await today(tester, 'today-error');
      expect(find.text(S.todayLoadError), findsOneWidget);
      expect(find.text(S.retry), findsOneWidget);
      expect(find.byType(MannyButton), findsNothing);
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

    testWidgets('F-8: data-sheet-bottom — Sheet ans Ende gescrollt, der '
        'Löschen-Abschnitt ist sichtbar', (WidgetTester tester) async {
      for (final Size size in <Size>[Viewports.phone, Viewports.small]) {
        for (final double scale in <double>[1, 2]) {
          setViewport(tester, size);
          await tester.pumpWidget(
            PreviewApp(
              config: PreviewConfig(
                scenarioId: 'data-sheet-bottom',
                textScale: scale,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final Finder del = find.widgetWithText(
            PillButton,
            S.dataDeleteButton,
          );
          expect(del, findsOneWidget, reason: '$size ×$scale');
          final Rect r = tester.getRect(del);
          expect(r.top, greaterThanOrEqualTo(0), reason: '$size ×$scale');
          expect(
            r.bottom,
            lessThanOrEqualTo(size.height),
            reason: '$size ×$scale',
          );
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    });

    testWidgets('R-1: data-delete-dialog-bottom — Dialog ans Ende gescrollt, '
        'Buttons bei 2,0 ohne Symbol und ohne Wortbruch', (
      WidgetTester tester,
    ) async {
      for (final Size size in <Size>[Viewports.phone, Viewports.small]) {
        setViewport(tester, size);
        await tester.pumpWidget(
          PreviewApp(
            config: const PreviewConfig(
              scenarioId: 'data-delete-dialog-bottom',
              textScale: 2,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final Finder del = find.widgetWithText(PillButton, S.deleteConfirm);
        expect(del, findsOneWidget, reason: '$size');
        final Rect r = tester.getRect(del);
        expect(r.bottom, lessThanOrEqualTo(size.height), reason: '$size');
        expect(r.top, greaterThanOrEqualTo(0), reason: '$size');
        expect(
          find.descendant(of: del, matching: find.byType(Icon)),
          findsNothing,
        );
        for (final String t in <String>[S.cancel, S.deleteConfirm]) {
          expect(
            midWordBreaks(paragraphLines(tester, find.text(t))),
            isEmpty,
            reason: '$size $t',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
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
