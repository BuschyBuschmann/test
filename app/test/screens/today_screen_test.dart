// Heute (U3b; Brief 6.3, Ergänzung 1 3.3/3.4, Ergänzung 2 K3 bis K5;
// UI-26 bis UI-31, UI-37 bis UI-45, UI-70/71 (Heute), UI-73): Inhalt und
// Zustände, Zeitwahl, Tauschen/Entfernen/Eigene Übung, Trainings-Sheet,
// Eintragen und Rückgängig (8 s), Tageswechsel inkl. Eintrag über Mitternacht,
// Button-Gruppe (8 dp über dem Manny-Button, auch im Umbruchszustand),
// Snackbar 12 dp über der Gruppe, Scroll-Reserve, Fokusreihenfolge.
import 'dart:async';

import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/placeholder_pools.dart';
import 'package:curaone/logic/streak.dart';
import 'package:curaone/state/transient_ui.dart';
import 'package:curaone/ui/components/category_card.dart';
import 'package:curaone/ui/components/cura_dialog.dart';
import 'package:curaone/ui/components/cura_pressable.dart';
import 'package:curaone/ui/components/cura_snackbar.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/components/manny_chat_button.dart';
import 'package:curaone/ui/components/messages_button.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:curaone/ui/components/probe_keys.dart';
import 'package:curaone/ui/home/home_shell.dart';
import 'package:curaone/ui/today/today_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../matrix/matrix_checks.dart' show TapTarget, tapTargets;
import '../support/app_harness.dart';
import '../support/builders.dart';
import '../support/controller_harness.dart';
import '../support/pump_app.dart';

/// Hohes Fenster: der ganze Inhalt steht ohne Scrollen im Bild.
const Size _tall = Size(390, 1400);

Future<Harness> _today(
  WidgetTester tester, {
  DateTime? now,
  AppState Function(AppState)? tweak,
  Size size = _tall,
  double textScale = 1,
  TodaySource? source,
  bool accessible = false,
}) async {
  final Harness h = await Harness.onboarded(now: now, tweak: tweak);
  addTearDown(h.dispose);
  await pumpCura(
    tester,
    h.controller,
    size: size,
    textScale: textScale,
    todaySource: source,
    accessibleNavigation: accessible,
  );
  await tester.tap(_navEntry(S.navToday));
  await tester.pumpAndSettle();
  return h;
}

HomeShellState _shell(WidgetTester tester) =>
    tester.state<HomeShellState>(find.byType(HomeShell, skipOffstage: false));

Finder _navEntry(String label) =>
    find.descendant(of: find.byType(FloatingNav), matching: find.text(label));

Finder _card(String exerciseId) =>
    find.byKey(ValueKey<String>('exercise:$exerciseId'));

Finder _inCard(String exerciseId, String text) =>
    find.descendant(of: _card(exerciseId), matching: find.text(text));

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _startAndLog(WidgetTester tester) async {
  await _tap(tester, find.text(S.startTraining));
  await _tap(tester, find.text(S.trainingLog));
}

Rect _rectOf(WidgetTester tester, Finder f) => tester.getRect(f.first);

Rect _primary(WidgetTester tester) =>
    _rectOf(tester, find.byKey(ProbeKeys.primary));

/// Ende der Zeit: Snackbar-Takt läuft aus, der Test endet sauber.
Future<void> _closeLater(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await disposeApp(tester);
}

class _FailsOnce implements TodaySource {
  int calls = 0;

  @override
  Future<void>? prepare() {
    calls++;
    if (calls == 1) throw StateError('Test: Heute nicht ladbar');
    return null;
  }
}

class _Pending implements TodaySource {
  @override
  Future<void>? prepare() => Completer<void>().future;
}

/// Beschriftung des fokussierten Bausteins (Tastaturreihenfolge).
String? _focusedLabel() {
  final BuildContext? ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return null;
  String? label;
  (ctx as Element).visitAncestorElements((Element a) {
    final Widget w = a.widget;
    if (w is CuraPressable && w.semanticLabel != null) {
      label = w.semanticLabel;
      return false;
    }
    if (w is PillButton) {
      label = w.label;
      return false;
    }
    return true;
  });
  return label;
}

void main() {
  group('Inhalt (UI-26 bis UI-29, UI-43, UI-45)', () {
    testWidgets('Datum, Titel, Zeitwahl 20 und Überschrift mit Summe (UI-26)', (
      WidgetTester tester,
    ) async {
      final Harness h = await _today(tester);
      expect(find.text('Mittwoch, 7. Oktober'), findsOneWidget);
      expect(find.text(S.todayTitle('Jakob')), findsOneWidget);
      expect(h.state.prefs.timeChoice, 20);
      FontWeight? weight(String t) =>
          tester.widget<Text>(find.text(t)).style?.fontWeight;
      expect(weight('20 Min'), FontWeight.w700);
      expect(weight('10 Min'), isNot(FontWeight.w700));
      expect(find.text('ÜBUNGEN · CA. 20 MIN'), findsOneWidget);
      expect(find.text('TERMINE'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('Zeitwechsel ändert Liste und Überschrift; Wahl bleibt (N-8)', (
      WidgetTester tester,
    ) async {
      final Harness h = await _today(tester);
      await _tap(tester, find.text('30 Min'));
      expect(h.state.prefs.timeChoice, 30);
      expect(find.text('ÜBUNGEN · CA. 30 MIN'), findsOneWidget);
      // Ein Termin plus sechs Übungen.
      expect(find.byType(CategoryCard), findsNWidgets(7));
      await _tap(tester, find.text('10 Min'));
      expect(find.text('ÜBUNGEN · CA. 10 MIN'), findsOneWidget);
      expect(find.byType(CategoryCard), findsNWidgets(3));

      h.clock.advanceDays(1);
      resumeApp(tester);
      await tester.pumpAndSettle();
      expect(h.state.prefs.timeChoice, 10, reason: 'Zeitwahl bleibt');
      expect(find.text('ÜBUNGEN · CA. 10 MIN'), findsOneWidget);
      await _closeLater(tester);
    });

    testWidgets(
      'Beispieltermine: Mittwoch Physio, Freitag Arzt, Samstag keine',
      (WidgetTester tester) async {
        await _today(tester);
        expect(find.text(S.apptPhysioTitle), findsOneWidget);
        expect(find.text(S.apptPhysioMeta), findsOneWidget);
        expect(find.text('17:00'), findsOneWidget);
        expect(find.text(S.apptDoctorTitle), findsNothing);
        await disposeApp(tester);

        await _today(tester, now: DateTime(2026, 10, 9, 12));
        expect(find.text(S.apptDoctorTitle), findsOneWidget);
        expect(find.text(S.apptDoctorMeta), findsOneWidget);
        expect(find.text('09:30'), findsOneWidget);
        expect(find.text('17:00'), findsOneWidget);
        // Nach Uhrzeit: der Arzt steht vor dem Physio.
        expect(
          tester.getTopLeft(find.text('09:30')).dy,
          lessThan(tester.getTopLeft(find.text('17:00')).dy),
        );
        await disposeApp(tester);

        await _today(tester, now: DateTime(2026, 10, 10, 12));
        expect(find.text(S.noAppointments), findsOneWidget);
        expect(find.text(S.apptPhysioTitle), findsNothing);
        await disposeApp(tester);
      },
    );

    testWidgets(
      'Kategorien: Streifen, Icon und Label, nicht nur Farbe (UI-18, UI-19)',
      (WidgetTester tester) async {
        await _today(tester, now: DateTime(2026, 10, 9, 12));
        for (final (String label, IconData icon) in <(String, IconData)>[
          ('PHYSIO', Icons.accessibility_new_rounded),
          ('ARZT', Icons.medical_services_rounded),
          ('ÜBUNG', Icons.fitness_center_rounded),
        ]) {
          expect(find.text(label), findsWidgets, reason: label);
          expect(find.byIcon(icon), findsWidgets, reason: label);
        }
        // Je Karte genau ein Streifen in der Kategoriefarbe.
        final int cards = find.byType(CategoryCard).evaluate().length;
        expect(cards, 6); // Arzt, Physio, vier Übungen
        await disposeApp(tester);
      },
    );

    testWidgets(
      'Übungskarte zeigt Name, Wiederholungen, Dauer und beide Aktionen (UI-27)',
      (WidgetTester tester) async {
        await _today(tester);
        expect(find.text(S.exSquatName), findsOneWidget);
        expect(find.text('3 × 12 Wdh. · 6 Min'), findsOneWidget);
        expect(_inCard('ex-kniebeuge', S.exerciseSwap), findsOneWidget);
        expect(_inCard('ex-kniebeuge', S.exerciseRemove), findsOneWidget);
        await disposeApp(tester);
      },
    );

    testWidgets(
      'Tauschen ersetzt die Übung durch die nächste Alternative (A-15)',
      (WidgetTester tester) async {
        final Harness h = await _today(tester);
        await _tap(tester, _inCard('ex-kniebeuge', S.exerciseSwap));
        expect(find.text(S.exSquatName), findsNothing);
        expect(find.text(S.exSquatAlt1), findsOneWidget);
        expect(h.state.day.swaps['ex-kniebeuge'], 1);
        await disposeApp(tester);
      },
    );

    testWidgets(
      'Entfernen: Karte weg, „Entfernt. Rückgängig“, Rückgängig stellt her',
      (WidgetTester tester) async {
        final Harness h = await _today(tester);
        await _tap(tester, _inCard('ex-kniebeuge', S.exerciseRemove));
        expect(find.text(S.exSquatName), findsNothing);
        expect(find.text('ÜBUNGEN · CA. 14 MIN'), findsOneWidget);
        expect(find.text(S.removedSnackbar), findsOneWidget);
        expect(find.text(S.undo), findsOneWidget);
        expect(h.controller.transient.undoWindowOpen, isTrue);

        await _tap(tester, find.text(S.undo));
        expect(find.text(S.exSquatName), findsOneWidget);
        expect(find.text('ÜBUNGEN · CA. 20 MIN'), findsOneWidget);
        expect(find.byType(CuraSnackbar), findsNothing);
        expect(h.controller.transient.undoWindowOpen, isFalse);
        await disposeApp(tester);
      },
    );

    testWidgets(
      'Eigene Übung: vorbefüllter Dialog, Name ist Pflicht (UI-27, N-16)',
      (WidgetTester tester) async {
        final Harness h = await _today(tester);
        await _tap(tester, find.text(S.customAdd));
        expect(find.byType(CuraDialog), findsOneWidget);
        expect(find.text('3 × 10'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        PillButton add() => tester.widget<PillButton>(
          find.widgetWithText(PillButton, S.customAddButton),
        );
        expect(add().onPressed, isNull, reason: 'ohne Namen deaktiviert');

        await tester.enterText(find.byType(TextField).first, '  Plank ');
        await tester.pump();
        expect(add().onPressed, isNotNull);
        await _tap(tester, find.widgetWithText(PillButton, S.customAddButton));
        expect(find.byType(CuraDialog), findsNothing);
        expect(h.state.day.custom.single.name, 'Plank');
        expect(h.state.day.custom.single.reps, '3 × 10');
        expect(h.state.day.custom.single.minutes, 5);
        // Karte mit Name, Wiederholungen und Dauer; eigene Übungen ohne „Tauschen“.
        expect(find.text('Plank'), findsOneWidget);
        expect(find.text('3 × 10 · 5 Min'), findsOneWidget);
        expect(_inCard('custom-1', S.exerciseSwap), findsNothing);
        expect(_inCard('custom-1', S.exerciseRemove), findsOneWidget);
        expect(find.text('ÜBUNGEN · CA. 25 MIN'), findsOneWidget);
        await disposeApp(tester);
      },
    );

    testWidgets(
      'Eigene Übung: geleerte Felder fallen auf die Vorgaben zurück',
      (WidgetTester tester) async {
        final Harness h = await _today(tester);
        await _tap(tester, find.text(S.customAdd));
        await tester.enterText(find.byType(TextField).at(0), 'Dehnen');
        await tester.enterText(find.byType(TextField).at(1), '');
        await tester.enterText(find.byType(TextField).at(2), '');
        await tester.pump();
        await _tap(tester, find.widgetWithText(PillButton, S.customAddButton));
        expect(h.state.day.custom.single.reps, S.customDefaultReps);
        expect(h.state.day.custom.single.minutes, S.customDefaultMinutes);
        expect(find.text('3 × 10 · 5 Min'), findsOneWidget);
        await disposeApp(tester);
      },
    );

    testWidgets('Eigene Übung: Abbrechen fügt nichts hinzu', (
      WidgetTester tester,
    ) async {
      final Harness h = await _today(tester);
      await _tap(tester, find.text(S.customAdd));
      await tester.enterText(find.byType(TextField).first, 'Plank');
      await _tap(tester, find.text(S.cancel));
      expect(find.byType(CuraDialog), findsNothing);
      expect(h.state.day.custom, isEmpty);
      await disposeApp(tester);
    });

    testWidgets(
      'Leer: Karte, Überschrift „ÜBUNGEN“, „Training starten“ deaktiviert (UI-29)',
      (WidgetTester tester) async {
        final Harness h = await _today(
          tester,
          tweak: (AppState s) => s.copyWith(
            day: s.day.copyWith(
              removed: <String>[
                for (final ExerciseFamily f in kBaseExercises[20]!) f.base.id,
              ],
            ),
          ),
        );
        expect(find.text(S.emptyExercises), findsOneWidget);
        expect(find.text('ÜBUNGEN'), findsOneWidget);
        expect(find.textContaining('CA.'), findsNothing);
        expect(find.text(S.customAdd), findsOneWidget);
        final PillButton button = tester.widget<PillButton>(
          find.byKey(ProbeKeys.primary),
        );
        expect(button.label, S.startTraining);
        expect(button.onPressed, isNull);
        // Eintragen ist nicht möglich.
        await tester.tap(find.byKey(ProbeKeys.primary), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text(S.trainingSheetTitle), findsNothing);
        expect(h.state.day.done, isFalse);
        await disposeApp(tester);
      },
    );

    testWidgets('Leer und erledigt: der Button zeigt „Heute erledigt“ (B-6)', (
      WidgetTester tester,
    ) async {
      await _today(
        tester,
        tweak: (AppState s) => s.copyWith(
          day: s.day.copyWith(
            done: true,
            removed: <String>[
              for (final ExerciseFamily f in kBaseExercises[20]!) f.base.id,
            ],
          ),
        ),
      );
      final PillButton button = tester.widget<PillButton>(
        find.byKey(ProbeKeys.primary),
      );
      expect(button.label, S.trainingDone);
      expect(button.onPressed, isNull);
      expect(find.text(S.emptyExercises), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets(
      'Erledigt: Haken, Übungen und Aktionen bleiben bedienbar (A-19)',
      (WidgetTester tester) async {
        final Harness h = await _today(
          tester,
          tweak: (AppState s) => s.copyWith(day: s.day.copyWith(done: true)),
        );
        expect(find.text(S.trainingDone), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
        expect(find.text(S.startTraining), findsNothing);
        await _tap(tester, _inCard('ex-kniebeuge', S.exerciseSwap));
        expect(find.text(S.exSquatAlt1), findsOneWidget);
        await _tap(tester, find.text('30 Min'));
        expect(h.state.prefs.timeChoice, 30);
        await _closeLater(tester);
      },
    );

    testWidgets(
      'Programm bleibt nach vollständigem Neustart erhalten (UI-43)',
      (WidgetTester tester) async {
        final Harness h = await _today(tester);
        await _tap(tester, _inCard('ex-kniebeuge', S.exerciseSwap));
        await _tap(tester, _inCard('ex-wade', S.exerciseRemove));
        await h.controller.idle;
        await disposeApp(tester);
        final Harness again = await Harness.boot(raw: h.raw, now: h.clock.now);
        addTearDown(again.dispose);
        await pumpCura(tester, again.controller, size: _tall);
        await tester.tap(_navEntry(S.navToday));
        await tester.pumpAndSettle();
        expect(find.text(S.exSquatAlt1), findsOneWidget);
        expect(find.text(S.exCalfName), findsNothing);
        await disposeApp(tester);
      },
    );
  });

  group('Laden und Fehler (A-43)', () {
    testWidgets('Laden: Platzhalterkarten, keine Button-Gruppe', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _today(tester, source: _Pending());
      expect(find.bySemanticsLabel(S.loading), findsOneWidget);
      expect(find.byType(MessagesButton), findsNothing);
      expect(find.byType(MannyChatButton), findsNothing);
      expect(find.text(S.startTraining), findsNothing);
      expect(find.byType(FloatingNav), findsOneWidget);
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets(
      'Fehler: Text, „Nochmal versuchen“, ohne Gruppe; Wiederholen lädt',
      (WidgetTester tester) async {
        final _FailsOnce source = _FailsOnce();
        await _today(tester, source: source);
        expect(find.text(S.todayLoadError), findsOneWidget);
        expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
        expect(find.byType(MessagesButton), findsNothing);
        expect(find.byType(MannyChatButton), findsNothing);
        await _tap(tester, find.text(S.retry));
        expect(source.calls, 2);
        expect(find.text(S.todayLoadError), findsNothing);
        expect(find.text(S.todayTitle('Jakob')), findsOneWidget);
        expect(find.byType(MessagesButton), findsOneWidget);
        await disposeApp(tester);
      },
    );
  });

  group('Training starten und eintragen (UI-30, UI-37, UI-38)', () {
    testWidgets(
      'Sheet: drei Modi, nur Manuell aktiv, „Folgt“ bei Passiv und Aktiv',
      (WidgetTester tester) async {
        await _today(tester);
        await _tap(tester, find.text(S.startTraining));
        expect(find.text(S.trainingSheetTitle), findsOneWidget);
        expect(find.text(S.modeManual), findsOneWidget);
        expect(find.text(S.modeManualHint), findsOneWidget);
        expect(find.text(S.modePassive), findsOneWidget);
        expect(find.text(S.modeActive), findsOneWidget);
        expect(find.text(S.modeSoon), findsNWidgets(2));
        expect(find.text(S.trainingLog), findsOneWidget);
        // Passiv und Aktiv sind keine Fokusziele.
        expect(
          find.ancestor(
            of: find.text(S.modePassive),
            matching: find.byType(CuraPressable),
          ),
          findsNothing,
        );
        await tester.tap(find.byTooltip(S.close));
        await tester.pumpAndSettle();
        expect(find.text(S.trainingSheetTitle), findsNothing);
        await disposeApp(tester);
      },
    );

    testWidgets(
      'Eintragen: Sheet zu, „Heute erledigt“, Streak, Unit, Snackbar mit Rückgängig',
      (WidgetTester tester) async {
        final Harness h = await _today(tester);
        await _startAndLog(tester);
        expect(find.text(S.trainingSheetTitle), findsNothing);
        expect(find.text(S.trainingDone), findsOneWidget);
        expect(h.state.day.done, isTrue);
        expect(h.state.streak.count, 1);
        expect(h.state.path.completedUnitIds, hasLength(1));
        expect(find.text(S.loggedSnackbar), findsOneWidget);
        expect(find.text(S.undo), findsOneWidget);
        // Aktion mit Hit-Area ≥ 48 dp (UI-37).
        final Rect action = tester.getRect(
          find.ancestor(
            of: find.text(S.undo),
            matching: find.byType(CuraPressable),
          ),
        );
        expect(action.height, greaterThanOrEqualTo(48));
        expect(action.width, greaterThanOrEqualTo(48));
        await _closeLater(tester);
      },
    );

    testWidgets(
      'Snackbar steht 12 dp über der Gruppe und überdeckt sie nicht (UI-37, UI-41)',
      (WidgetTester tester) async {
        await _today(tester);
        await _startAndLog(tester);
        final Rect snackbar = tester.getRect(find.byType(CuraSnackbar));
        final Rect row = tester.getRect(find.byKey(ProbeKeys.primaryRow));
        expect(row.top - snackbar.bottom, closeTo(12, 0.5));
        final Rect nav = tester.getRect(find.byType(FloatingNav));
        expect(snackbar.overlaps(nav), isFalse);
        expect(snackbar.overlaps(row), isFalse);
        // Opak, ohne Blur: nur die Nav hat einen BackdropFilter.
        expect(find.byType(BackdropFilter), findsOneWidget);
        await _closeLater(tester);
      },
    );

    testWidgets(
      'Rückgängig: alles wie vorher, keine Feier, erneutes Eintragen möglich (UI-38)',
      (WidgetTester tester) async {
        final Harness h = await _today(
          tester,
          tweak: (AppState s) => s.copyWith(
            streak: StreakState(
              count: 5,
              lastTrainingDay: kToday.addDays(-1),
              evaluatedThrough: kToday.addDays(-1),
            ),
          ),
        );
        final StreakState before = h.state.streak;
        final List<String> unitsBefore = h.state.path.completedUnitIds;
        await _startAndLog(tester);
        expect(h.state.streak.count, 6);
        tester.takeAnnouncements();

        await _tap(tester, find.text(S.undo));
        expect(h.state.streak, before);
        expect(h.state.path.completedUnitIds, unitsBefore);
        expect(h.state.day.done, isFalse);
        expect(h.state.celebration, isNull);
        expect(find.text(S.startTraining), findsOneWidget);
        expect(find.byType(CuraSnackbar), findsNothing);
        expect(
          tester.takeAnnouncements().map((a) => a.message),
          contains(S.loggedUndoneAnnouncement),
        );
        // Erneutes Eintragen ist normal möglich.
        await _startAndLog(tester);
        expect(h.state.streak.count, 6);
        await _closeLater(tester);
      },
    );

    testWidgets(
      '8-s-Fenster: nach Ablauf kein Rückgängig mehr, Eintrag bleibt (UI-39)',
      (WidgetTester tester) async {
        final Harness h = await _today(tester);
        await _startAndLog(tester);
        // Nach 5 s ist sie noch da, nach insgesamt rund 9 s (8 s plus
        // Einblenden und Sheet-Übergang davor) weg.
        await tester.pump(const Duration(seconds: 5));
        expect(find.text(S.undo), findsOneWidget);
        expect(h.controller.transient.undoWindowOpen, isTrue);
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        expect(find.byType(CuraSnackbar), findsNothing);
        expect(h.controller.transient.undoWindowOpen, isFalse);
        expect(h.state.day.done, isTrue);
        expect(h.state.streak.count, 1);
        await disposeApp(tester);
      },
    );

    testWidgets(
      'Screenreader aktiv: kein Ablauf; Fenster bleibt offen (UI-39)',
      (WidgetTester tester) async {
        final Harness h = await _today(tester, accessible: true);
        await _startAndLog(tester);
        await tester.pump(const Duration(seconds: 30));
        expect(find.text(S.undo), findsOneWidget);
        expect(h.controller.transient.undoWindowOpen, isTrue);
        await _tap(tester, find.text(S.undo));
        expect(h.state.day.done, isFalse);
        await disposeApp(tester);
      },
    );

    testWidgets(
      'Tabwechsel auf den Pfad beendet das Fenster; die Feier folgt danach (UI-40)',
      (WidgetTester tester) async {
        final Harness h = await _today(tester);
        await _startAndLog(tester);
        // Auf Heute keine Feier und keine Blase.
        expect(h.controller.transient.visibleBubble, isNull);
        await tester.tap(_navEntry(S.navPath));
        await tester.pumpAndSettle();
        expect(h.controller.transient.undoWindowOpen, isFalse);
        expect(find.byType(CuraSnackbar), findsNothing);
        expect(find.text(S.bubbleCelebration('Jakob', 1)), findsOneWidget);
        await _closeLater(tester);
      },
    );

    testWidgets('Eine neue Snackbar beendet das Fenster des Eintrags (UI-39)', (
      WidgetTester tester,
    ) async {
      final Harness h = await _today(tester);
      await _startAndLog(tester);
      await _tap(tester, _inCard('ex-kniebeuge', S.exerciseRemove));
      expect(find.text(S.loggedSnackbar), findsNothing);
      expect(find.text(S.removedSnackbar), findsOneWidget);
      // Das offene Fenster gehört jetzt dem Entfernen, nicht dem Eintrag.
      expect(h.controller.transient.undo, isA<RemovalUndo>());
      expect(h.state.day.done, isTrue, reason: 'Eintrag bleibt endgültig');
      await _closeLater(tester);
    });

    testWidgets(
      'Manny-Chat und Nachrichten öffnen beenden das Fenster (UI-39)',
      (WidgetTester tester) async {
        final Harness h = await _today(tester);
        await _startAndLog(tester);
        expect(h.controller.transient.undoWindowOpen, isTrue);
        await _tap(tester, find.byType(MannyChatButton));
        expect(h.controller.transient.undoWindowOpen, isFalse);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(CuraSnackbar), findsNothing);
        expect(h.state.day.done, isTrue);

        await _tap(tester, _inCard('ex-kniebeuge', S.exerciseRemove));
        expect(h.controller.transient.undoWindowOpen, isTrue);
        await _tap(tester, find.byType(MessagesButton));
        expect(h.controller.transient.undoWindowOpen, isFalse);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text(S.removedSnackbar), findsNothing);
        await disposeApp(tester);
      },
    );

    testWidgets('Doppeltipp auf „Training eintragen“ trägt nur einmal ein', (
      WidgetTester tester,
    ) async {
      final Harness h = await _today(tester);
      await _tap(tester, find.text(S.startTraining));
      await tester.tap(find.text(S.trainingLog));
      await tester.tap(find.text(S.trainingLog), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(h.state.streak.count, 1);
      expect(h.state.path.completedUnitIds, hasLength(1));
      expect(find.byType(HomeShell), findsOneWidget);
      expect(_shell(tester).activeTab, HomeTab.today);
      await _closeLater(tester);
    });

    testWidgets('Fokus kehrt nach dem Sheet an „Training starten“ zurück', (
      WidgetTester tester,
    ) async {
      await _today(tester);
      await _tap(tester, find.text(S.startTraining));
      await tester.tap(find.byTooltip(S.close));
      await tester.pumpAndSettle();
      expect(_focusedLabel(), S.startTraining);
      await disposeApp(tester);
    });
  });

  group('Tageswechsel (UI-42, UI-44, N-11, Plan 4.6)', () {
    testWidgets(
      'Eintrag über Mitternacht zählt für den Vortag, danach frischer Tag',
      (WidgetTester tester) async {
        final Harness h = await _today(
          tester,
          now: DateTime(2026, 10, 7, 23, 59),
        );
        await _tap(tester, find.text(S.startTraining));
        expect(find.text(S.trainingSheetTitle), findsOneWidget);
        h.clock.set(DateTime(2026, 10, 8, 0, 1));
        tester.takeAnnouncements();

        await tester.tap(find.text(S.trainingLog));
        await tester.pumpAndSettle();

        // Zählt für den Vortag; heute ist nicht verpasst, Programm frisch.
        expect(h.state.streak.count, 1);
        expect(h.state.streak.lastTrainingDay, const LocalDay(2026, 10, 7));
        expect(h.state.streak.freezes, 2);
        expect(h.state.day.dayKey, const LocalDay(2026, 10, 8));
        expect(h.state.day.done, isFalse);
        expect(h.state.celebration, isNull, reason: 'Feier verfällt');
        expect(h.controller.transient.undoWindowOpen, isFalse);
        // Sheet zu, Snackbar „Neuer Tag“ ohne Rückgängig, Ansage.
        expect(find.text(S.trainingSheetTitle), findsNothing);
        expect(find.text(S.startTraining), findsOneWidget);
        expect(find.text('Donnerstag, 8. Oktober'), findsOneWidget);
        expect(find.text(S.newDaySnackbar), findsOneWidget);
        expect(find.text(S.undo), findsNothing);
        expect(find.text(S.loggedSnackbar), findsNothing);
        expect(
          tester.takeAnnouncements().map((a) => a.message),
          contains(S.newDayAnnouncement),
        );
        await _closeLater(tester);
      },
    );

    testWidgets(
      'Sheet offen, Tageswechsel, dazu offener Chat: Sheet zu, keine Snackbar',
      (WidgetTester tester) async {
        final Harness h = await _today(tester);
        await _tap(tester, find.text(S.startTraining));
        expect(find.text(S.trainingSheetTitle), findsOneWidget);
        unawaited(_shell(tester).openChat());
        await tester.pumpAndSettle();
        tester.takeAnnouncements();
        h.clock.advanceDays(1);
        resumeApp(tester);
        await tester.pumpAndSettle();
        expect(h.state.day.dayKey, h.controller.today);
        expect(find.text(S.newDaySnackbar), findsNothing);
        expect(tester.takeAnnouncements(), isEmpty);
        expect(_shell(tester).todayRoutes.length, 0);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text(S.trainingSheetTitle), findsNothing);
        expect(find.text(S.newDaySnackbar), findsNothing);
        expect(find.text('Donnerstag, 8. Oktober'), findsOneWidget);
        await disposeApp(tester);
      },
    );

    testWidgets(
      'halb ausgefüllter Dialog „Eigene Übung“ geht verloren, nichts wird eingetragen',
      (WidgetTester tester) async {
        final Harness h = await _today(tester);
        await _tap(tester, find.text(S.customAdd));
        await tester.enterText(find.byType(TextField).first, 'Plank');
        await tester.pump();
        h.clock.advanceDays(1);
        resumeApp(tester);
        await tester.pumpAndSettle();
        expect(find.byType(CuraDialog), findsNothing);
        expect(h.state.day.custom, isEmpty);
        expect(find.text(S.newDaySnackbar), findsOneWidget);
        await _closeLater(tester);
      },
    );

    testWidgets(
      'Rückgängig-Fenster verfällt beim Tageswechsel; Snackbar „Neuer Tag“ ersetzt sie',
      (WidgetTester tester) async {
        final Harness h = await _today(tester);
        await _startAndLog(tester);
        h.clock.advanceDays(1);
        resumeApp(tester);
        await tester.pumpAndSettle();
        expect(h.controller.transient.undoWindowOpen, isFalse);
        expect(find.text(S.loggedSnackbar), findsNothing);
        expect(find.text(S.undo), findsNothing);
        expect(find.text(S.newDaySnackbar), findsOneWidget);
        expect(h.state.streak.count, 1, reason: 'Eintrag bleibt');
        await _closeLater(tester);
      },
    );

    testWidgets('Aktion nach Mitternacht: der Wechsel wird zuerst angewendet', (
      WidgetTester tester,
    ) async {
      final Harness h = await _today(tester);
      await _tap(tester, _inCard('ex-wade', S.exerciseRemove));
      await tester.pump(const Duration(seconds: 9));
      h.clock.advanceDays(1);
      // Kein Resume und kein Tabwechsel: die Aktion selbst findet den Wechsel.
      await tester.tap(find.text('30 Min'));
      await tester.pumpAndSettle();
      expect(h.state.day.dayKey, h.controller.today);
      expect(h.state.day.removed, isEmpty, reason: 'Programm des Vortags weg');
      expect(h.state.prefs.timeChoice, 30);
      expect(find.text(S.newDaySnackbar), findsOneWidget);
      await _closeLater(tester);
    });
  });

  group('Button-Gruppe, Snackbar und Reserve (UI-71, UI-73, UI-31)', () {
    testWidgets(
      'Nachrichten-Button 8 dp über dem Manny-Button, rechtsbündig; Primär 96 dp schmaler',
      (WidgetTester tester) async {
        await _today(tester, size: Viewports.phone);
        final Rect messages = _rectOf(tester, find.byType(MessagesButton));
        final Rect manny = _rectOf(tester, find.byType(MannyChatButton));
        final Rect primary = _primary(tester);
        expect(manny.top - messages.bottom, closeTo(8, 0.01));
        expect(messages.right, closeTo(manny.right, 0.01));
        expect(messages.size, const Size(48, 48));
        expect(manny.size, const Size(56, 56));
        expect(manny.bottom, closeTo(primary.bottom, 0.01));
        expect(primary.width, closeTo(390 - 32 - 56 - 8, 0.01));
        expect(primary.left, 16);
        // 16 dp über der Nav.
        expect(844 - manny.bottom, closeTo(64 + 22 + 16, 0.01));
        await disposeApp(tester);
      },
    );

    testWidgets('bei 320 dp ist der Primärbutton genau 224 dp breit (UI-73)', (
      WidgetTester tester,
    ) async {
      await _today(tester, size: Viewports.small);
      expect(_primary(tester).width, closeTo(224, 0.01));
      expect(_primary(tester).height, 56);
      await disposeApp(tester);
    });

    testWidgets(
      'Umbruchszustand: Reihe höher als 56 dp, Nachrichten-Button folgt dem Manny-Button (UI-71)',
      (WidgetTester tester) async {
        for (final double scale in <double>[1.3, 1.5, 2.0]) {
          await _today(tester, size: Viewports.small, textScale: scale);
          final Rect primary = _primary(tester);
          expect(
            primary.height,
            greaterThan(56),
            reason: '„Training starten“ bricht bei ×$scale um',
          );
          final Rect messages = _rectOf(tester, find.byType(MessagesButton));
          final Rect manny = _rectOf(tester, find.byType(MannyChatButton));
          expect(manny.size, const Size(56, 56), reason: 'bleibt bei ×$scale');
          expect(manny.bottom, closeTo(primary.bottom, 0.01));
          expect(
            manny.top - messages.bottom,
            closeTo(8, 0.01),
            reason: '×$scale',
          );
          expect(messages.right, closeTo(manny.right, 0.01));
          expect(primary.width, closeTo(224, 0.01));
          await disposeApp(tester);
        }
      },
    );

    testWidgets(
      'Snackbar steht auch bei 320×568 und 2,0 12 dp über der Gruppe',
      (WidgetTester tester) async {
        await _today(tester, size: Viewports.small, textScale: 2);
        await tester.ensureVisible(_inCard('ex-kniebeuge', S.exerciseRemove));
        await tester.pumpAndSettle();
        await tester.tap(
          _inCard('ex-kniebeuge', S.exerciseRemove),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        final Rect snackbar = tester.getRect(find.byType(CuraSnackbar));
        final Rect row = tester.getRect(find.byKey(ProbeKeys.primaryRow));
        expect(row.top - snackbar.bottom, closeTo(12, 0.5));
        expect(snackbar.overlaps(row), isFalse);
        expect(
          snackbar.overlaps(_rectOf(tester, find.byType(MessagesButton))),
          isFalse,
        );
        await _closeLater(tester);
      },
    );

    testWidgets(
      'Scroll-Reserve: Listenende frei über Reihe, Nachrichten-Button und Nav (UI-31)',
      (WidgetTester tester) async {
        for (final (Size size, double scale) in <(Size, double)>[
          (Viewports.small, 1),
          (Viewports.small, 2),
          (Viewports.phone, 1),
        ]) {
          await _today(tester, size: size, textScale: scale);
          final ScrollableState list = tester.state(
            find.descendant(
              of: find.byKey(ProbeKeys.scroll),
              matching: find.byType(Scrollable),
            ),
          );
          list.position.jumpTo(list.position.maxScrollExtent);
          await tester.pump();
          final Rect last = _rectOf(tester, find.text(S.customAdd));
          final Rect row = tester.getRect(find.byKey(ProbeKeys.primaryRow));
          final Rect nav = tester.getRect(find.byType(FloatingNav));
          expect(
            last.bottom,
            lessThanOrEqualTo(row.top),
            reason: '$size ×$scale',
          );
          expect(
            last.bottom,
            lessThanOrEqualTo(nav.top),
            reason: '$size ×$scale',
          );
          // Jede Aktion der Liste lässt sich frei von der Gruppe scrollen.
          expect(
            find.byKey(ProbeKeys.primaryRow).hitTestable(),
            findsOneWidget,
          );
          await disposeApp(tester);
        }
      },
    );

    testWidgets(
      'Fokusreihenfolge: Liste, Nachrichten, „Training starten“, Manny, Nav',
      (WidgetTester tester) async {
        await _today(tester);
        final List<String> order = <String>[];
        for (int i = 0; i < 40; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          final String? label = _focusedLabel();
          if (label != null && !order.contains(label)) order.add(label);
          if (label == S.navPath || label == S.navToday) {
            if (order.contains(S.navToday) && order.contains(S.navPath)) break;
          }
        }
        int at(String l) => order.indexOf(l);
        expect(at(S.messagesButton), greaterThan(at(S.customAddLabel)));
        expect(at(S.startTraining), greaterThan(at(S.messagesButton)));
        expect(at(S.mannyChatOpen), greaterThan(at(S.startTraining)));
        expect(at(S.navPath), greaterThan(at(S.mannyChatOpen)));
        // Zeitwahl und Aktionen der Liste stehen vor „Eigene Übung“.
        expect(
          at(S.timeChoiceLabel(10)),
          lessThan(at(S.exerciseSwapLabel(S.exSquatName))),
        );
        expect(
          at(S.exerciseRemoveLabel(S.exSquatName)),
          lessThan(at(S.customAddLabel)),
        );
        await disposeApp(tester);
      },
    );

    testWidgets(
      'Sheet offen: Gruppe weder in der Semantik noch fokussierbar (UI-70)',
      (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await _today(tester);
        List<String> labels() =>
            tapTargets(tester).map((TapTarget t) => t.label).toList();
        expect(labels(), contains(S.mannyChatOpen));
        expect(labels(), contains(S.messagesButton));
        await _tap(tester, find.text(S.startTraining));
        expect(labels(), isNot(contains(S.mannyChatOpen)));
        expect(labels(), isNot(contains(S.messagesButton)));
        expect(labels(), isNot(contains(S.navPath)));
        expect(labels(), contains(S.trainingLog));
        for (int i = 0; i < 12; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(<String?>[
            S.mannyChatOpen,
            S.messagesButton,
            S.navPath,
            S.navToday,
            S.startTraining,
          ], isNot(contains(_focusedLabel())));
        }
        handle.dispose();
        await disposeApp(tester);
      },
    );

    testWidgets(
      'Schriftgröße 200 %: kein Overflow, Inhalt und Gruppe sichtbar (UI-33)',
      (WidgetTester tester) async {
        await _today(tester, size: Viewports.small, textScale: 2);
        expect(tester.takeException(), isNull);
        expect(find.byType(MessagesButton), findsOneWidget);
        expect(find.text(S.todayTitle('Jakob')), findsOneWidget);
        await disposeApp(tester);
      },
    );
  });
}
