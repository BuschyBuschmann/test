// „Deine Daten“ (U4; Ergänzung 1 3.1/3.2, UI-46 bis UI-58, UI-64 bis UI-68;
// Ergänzung 2: UI-70 unter dem Sheet, UI-82 W-Teil): Einstieg und Aufbau,
// Profil ändern und Speichern, „Änderungen verwerfen?“, „Alles löschen?“ mit
// Sperre, Laden und Fehler, Button-Gruppe unter dem Scrim, Tastatur, Hoher
// Kontrast, Bewegung reduzieren, große Schrift.
import 'dart:async';

import 'package:curaone/data/data_eraser.dart';
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/injury_type.dart';
import 'package:curaone/logic/manny_state.dart';
import 'package:curaone/logic/path_generator.dart';
import 'package:curaone/logic/streak.dart';
import 'package:curaone/state/app_controller.dart';
import 'package:curaone/state/transient_ui.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/ui/chat/manny_chat_screen.dart';
import 'package:curaone/ui/components/choice_card.dart';
import 'package:curaone/ui/components/cura_dialog.dart';
import 'package:curaone/ui/components/cura_pressable.dart';
import 'package:curaone/ui/components/cura_snackbar.dart';
import 'package:curaone/ui/components/cura_text_field.dart';
import 'package:curaone/ui/components/date_card.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/components/header_icon_button.dart';
import 'package:curaone/ui/components/manny.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
import 'package:curaone/ui/components/manny_chat_button.dart';
import 'package:curaone/ui/components/messages_button.dart';
import 'package:curaone/ui/components/mic_button.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:curaone/ui/components/probe_keys.dart';
import 'package:curaone/ui/data_sheet/data_sheet.dart';
import 'package:curaone/ui/data_sheet/delete_dialog.dart';
import 'package:curaone/ui/data_sheet/delete_error_notice.dart';
import 'package:curaone/ui/data_sheet/discard_dialog.dart';
import 'package:curaone/ui/home/home_shell.dart';
import 'package:curaone/ui/onboarding/onboarding_flow.dart';
import 'package:curaone/ui/onboarding/privacy_placeholder_page.dart';
import 'package:curaone/ui/routes/cura_sheet_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/builders.dart';
import '../support/component_support.dart';
import '../support/controller_harness.dart';
import '../support/line_breaks.dart';
import '../support/pump_app.dart';
import '../support/stores.dart';

// ---------------------------------------------------------------------------
// Helfer
// ---------------------------------------------------------------------------

/// Beispielfakt des Tages als gezeigt: keine Blase in der Ruhelage.
AppState _noBubble(AppState s) => s.copyWith(
  manny: MannyState(
    lastShown: <MannyOccasion, LocalDay>{MannyOccasion.fact: kToday},
  ),
);

/// Löscher mit Torschaltung und festgelegten Fehlversuchen.
class _Eraser implements DataEraser {
  _Eraser(this.inner, {this.failTimes = 0, this.gate});

  final DataEraser inner;
  int failTimes;
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<void> eraseAll() async {
    calls++;
    if (gate != null) await gate!.future;
    if (failTimes > 0) {
      failTimes--;
      throw StateError('Löschen fehlgeschlagen');
    }
    await inner.eraseAll();
  }
}

class _Rig {
  _Rig(this.h, this.controller, this.eraser);

  final Harness h;
  final AppController controller;
  final _Eraser eraser;

  InMemoryStore get raw => h.raw as InMemoryStore;
}

/// Controller mit eigenem Löscher über dem Speicher der [Harness].
Future<_Rig> _rig({
  AppState Function(AppState)? tweak,
  int failTimes = 0,
  Completer<void>? gate,
}) async {
  final Harness h = await Harness.onboarded(tweak: tweak ?? _noBubble);
  final _Eraser eraser = _Eraser(h.store, failTimes: failTimes, gate: gate);
  final AppController c = AppController(
    clock: h.clock.call,
    store: h.store,
    mannyText: h.controller.mannyText,
    erasers: <DataEraser>[eraser],
    transient: TransientUi(),
  );
  await c.load();
  addTearDown(() {
    c.dispose();
    h.dispose();
  });
  return _Rig(h, c, eraser);
}

/// Startet die App und öffnet „Deine Daten“.
Future<Harness> _pumpPath(
  WidgetTester tester, {
  AppState Function(AppState)? tweak,
  Size size = Viewports.phone,
  double scale = 1,
  bool rm = false,
  bool hc = false,
  bool screenReader = false,
  double keyboard = 0,
  GlobalKey<NavigatorState>? navigatorKey,
}) async {
  final Harness h = await Harness.onboarded(tweak: tweak ?? _noBubble);
  addTearDown(h.dispose);
  await pumpCura(
    tester,
    h.controller,
    size: size,
    textScale: scale,
    disableAnimations: rm,
    highContrast: hc,
    accessibleNavigation: screenReader,
    keyboard: keyboard,
    navigatorKey: navigatorKey,
  );
  return h;
}

HomeShellState _shell(WidgetTester tester) =>
    tester.state<HomeShellState>(find.byType(HomeShell, skipOffstage: false));

Finder get _dataIcon => find.byTooltip(S.dataSheetOpen);
Finder get _sheet => find.byType(DataSheet);
Finder get _save => find.widgetWithText(PillButton, S.dataSave);
Finder get _deleteButton => find.widgetWithText(PillButton, S.dataDeleteButton);
Finder get _nameField => find
    .descendant(
      of: find.byType(CuraTextField),
      matching: find.byType(TextField),
    )
    .first;
Finder _card(String title) => find.byWidgetPredicate(
  (Widget w) => w is ChoiceCard && w.title == title,
  skipOffstage: false,
);
Finder get _closeX => find.descendant(
  of: _sheet,
  matching: find.byWidgetPredicate(
    (Widget w) => w is HeaderIconButton && w.tooltip == S.close,
  ),
);

/// Bei großer Schrift läuft die Kopfzeile des Pfads mit der Liste (Plan 4.5):
/// erst nach oben scrollen, dann ist das Icon erreichbar.
void _pathToTop(WidgetTester tester) {
  final Finder keyed = find.byKey(ProbeKeys.scroll);
  final Finder inner = find.descendant(
    of: keyed,
    matching: find.byType(Scrollable),
  );
  final Finder f = inner.evaluate().isNotEmpty
      ? inner
      : find.ancestor(of: keyed, matching: find.byType(Scrollable));
  tester.state<ScrollableState>(f.first).position.jumpTo(0);
}

Future<void> _openSheet(WidgetTester tester) async {
  _pathToTop(tester);
  await tester.pump();
  await tester.tap(_dataIcon);
  await tester.pumpAndSettle();
  expect(_sheet, findsOneWidget);
}

/// Blendet die Tastatur (300 dp) bei geöffnetem Sheet ein, wie nach dem Tipp
/// auf ein Feld.
Future<void> _showKeyboard(WidgetTester tester) async {
  tester.view.viewInsets = const FakeViewPadding(bottom: 300);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpAndSettle();
}

Future<void> _tapIn(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

bool _saveEnabled(WidgetTester tester) =>
    tester.widget<PillButton>(_save).onPressed != null;

/// Ändert den Entwurf: andere Verletzung.
Future<void> _makeDirty(WidgetTester tester) =>
    _tapIn(tester, _card(S.injuryMuscle));

Future<void> _openDelete(WidgetTester tester) async {
  await _tapIn(tester, _deleteButton);
  expect(find.byType(DeleteDialog), findsOneWidget);
}

/// Der Fokus liegt im Button mit diesem Label.
bool _focusOnButton(String label) =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<PillButton>()
        ?.label ==
    label;

PillButton _confirmButton(WidgetTester tester) => tester.widget<PillButton>(
  find
      .descendant(
        of: find.byType(DeleteDialog),
        matching: find.byType(PillButton),
      )
      .last,
);

Finder get _confirm => find
    .descendant(
      of: find.byType(DeleteDialog),
      matching: find.byType(PillButton),
    )
    .last;

Finder get _cancel => find
    .descendant(
      of: find.byType(DeleteDialog),
      matching: find.byType(PillButton),
    )
    .first;

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle();

void main() {
  // -------------------------------------------------------------------------
  group('Einstieg und Aufbau (UI-46, UI-47, UI-48, UI-53, UI-56)', () {
    testWidgets('UI-46: Icon in der Pfad-Kopfzeile, 48 dp, Tooltip und '
        'Label; auf Heute gibt es keinen Einstieg', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pumpPath(tester);
      expect(_dataIcon, findsOneWidget);
      final Size size = tester.getSize(
        find
            .ancestor(of: _dataIcon, matching: find.byType(CuraPressable))
            .first,
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(find.bySemanticsLabel(S.dataSheetOpen), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(FloatingNav),
          matching: find.text(S.navToday),
        ),
      );
      await tester.pumpAndSettle();
      expect(_dataIcon, findsNothing);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('öffnet mit Titel, Untertitel, Schließen, vorbefüllten Feldern '
        'und Hinweis; Speichern ist aus (UI-48, UI-53, UI-56)', (
      WidgetTester tester,
    ) async {
      final Harness h = await _pumpPath(tester);
      await _openSheet(tester);
      expect(
        find.descendant(of: _sheet, matching: find.text(S.dataSheetTitle)),
        findsOneWidget,
      );
      expect(find.text(S.dataSheetSubtitle), findsOneWidget);
      expect(_closeX, findsOneWidget);
      // Name vorbefüllt.
      expect(
        tester.widget<TextField>(_nameField).controller!.text,
        h.state.onboarding.name,
      );
      // Vier Karten, aktueller Typ gewählt.
      for (final String t in <String>[
        S.injuryAcl,
        S.injuryAnkle,
        S.injuryMuscle,
        S.injuryOther,
      ]) {
        expect(_card(t), findsOneWidget);
      }
      expect(tester.widget<ChoiceCard>(_card(S.injuryAcl)).selected, isTrue);
      expect(
        tester.widget<ChoiceCard>(_card(S.injuryMuscle)).selected,
        isFalse,
      );
      // Datum (30 Tage vor dem 7. Oktober 2026).
      expect(find.text('7. September 2026'), findsOneWidget);
      expect(find.byType(DateCard), findsOneWidget);
      // Hinweis dauerhaft (UI-56), Löschen-Abschnitt.
      await tester.ensureVisible(find.text(S.dataRecomputeNote));
      expect(find.text(S.dataRecomputeNote), findsOneWidget);
      expect(find.text(S.dataDeleteText), findsOneWidget);
      expect(_deleteButton, findsOneWidget);
      expect(_saveEnabled(tester), isFalse);
      await disposeApp(tester);
    });

    testWidgets('UI-53: dieselben Widgets wie im Onboarding; kein Manny, keine '
        'Mikrofon-Zeile; „Anderes“ zeigt den vorbefüllten Freitext', (
      WidgetTester tester,
    ) async {
      await _pumpPath(
        tester,
        tweak: (AppState s) => _noBubble(
          s.copyWith(
            onboarding: s.onboarding.copyWith(
              injuryType: InjuryType.other,
              injuryOther: 'Schulter',
            ),
          ),
        ),
      );
      await _openSheet(tester);
      expect(
        find.descendant(of: _sheet, matching: find.byType(MannyPlaceholder)),
        findsNothing,
      );
      expect(
        find.descendant(of: _sheet, matching: find.byType(MicButton)),
        findsNothing,
      );
      expect(
        find.descendant(of: _sheet, matching: find.byType(DateCard)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _sheet, matching: find.byType(CuraTextField)),
        findsNWidgets(2),
      );
      final TextField other = tester.widget<TextField>(
        find.descendant(of: _sheet, matching: find.byType(TextField)).at(1),
      );
      expect(other.controller!.text, 'Schulter');
      expect(tester.widget<ChoiceCard>(_card(S.injuryOther)).selected, isTrue);
      await disposeApp(tester);
    });

    testWidgets('UI-47: eine sichtbare Blase schließt beim Öffnen (zählt als '
        'gezeigt); mit Sheet höchstens 2 BackdropFilter, auch mit Dialog', (
      WidgetTester tester,
    ) async {
      final Harness h = await _pumpPath(
        tester,
        tweak: (AppState s) =>
            s.copyWith(manny: const MannyState(greetingPending: true)),
      );
      expect(find.byType(MannyBubble), findsOneWidget);
      await _openSheet(tester);
      expect(find.byType(MannyBubble), findsNothing);
      expect(h.controller.transient.visibleBubble, isNull);
      expect(
        h.state.manny.lastShown[MannyOccasion.greeting],
        kToday,
        reason: 'weggetippt zählt als gezeigt',
      );
      expect(backdropCount(tester), 2, reason: 'Nav und Sheet');
      await _openDelete(tester);
      expect(backdropCount(tester), 2, reason: 'Dialog ohne Blur');
      await tester.tap(_cancel);
      await _settle(tester);
      await _makeDirty(tester);
      await tester.tap(_closeX);
      await _settle(tester);
      expect(find.byType(DiscardDialog), findsOneWidget);
      expect(backdropCount(tester), 2);
      await disposeApp(tester);
    });

    testWidgets('UI-47: eine Blase, die erst nach dem Öffnen fällig wird, '
        'erscheint nicht unter dem Sheet', (WidgetTester tester) async {
      // 200 % Schrift: der Besuch wartet auf die Messung der Kopfzeile.
      final Harness h = await _pumpPath(
        tester,
        tweak: (AppState s) =>
            s.copyWith(manny: const MannyState(greetingPending: true)),
        scale: 2,
        size: Viewports.small,
      );
      await _openSheet(tester);
      expect(find.byType(MannyBubble), findsNothing);
      expect(backdropCount(tester), lessThanOrEqualTo(2));
      expect(h.controller.transient.visibleBubble, isNull);
      await disposeApp(tester);
    });

    testWidgets('UI-47: ein offener Knoten-Hinweis schließt beim Öffnen; '
        'Zurück (Android) schließt das Sheet, nicht die App', (
      WidgetTester tester,
    ) async {
      final SystemPopRecorder pops = SystemPopRecorder(tester);
      final Harness h = await _pumpPath(tester);
      h.controller.transient.showHint('w9-d1');
      await tester.pump();
      expect(h.controller.transient.hintUnitId, isNotNull);
      await _openSheet(tester);
      expect(h.controller.transient.hintUnitId, isNull);
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(_sheet, findsNothing);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(pops.count, 0);
      await disposeApp(tester);
    });

    testWidgets('UI-48: Schließen ohne Änderungen: X, Zurück, Escape, Scrim, '
        'Wischen auf dem Kopf; Fokus kehrt zum Icon zurück', (
      WidgetTester tester,
    ) async {
      await _pumpPath(tester);
      final HomeShellState shell = _shell(tester);

      Future<void> closeWith(Future<void> Function() how) async {
        await _openSheet(tester);
        await how();
        await _settle(tester);
        expect(_sheet, findsNothing);
        expect(find.byType(DiscardDialog), findsNothing);
        expect(shell.dataButtonFocus.hasFocus, isTrue);
      }

      await closeWith(() => tester.tap(_closeX));
      await closeWith(() => tester.binding.handlePopRoute());
      await closeWith(() => tester.sendKeyEvent(LogicalKeyboardKey.escape));
      await closeWith(() => tester.tapAt(const Offset(195, 20)));
      await closeWith(
        () => tester.fling(
          find.descendant(of: _sheet, matching: find.text(S.dataSheetTitle)),
          const Offset(0, 400),
          1500,
        ),
      );
      await disposeApp(tester);
    });

    testWidgets('UI-48: Kopf und Fußleiste bleiben beim Scrollen; Routenname; '
        'Tastaturreihenfolge beginnt bei „Schließen“', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pumpPath(tester, size: Viewports.small);
      await _openSheet(tester);
      final double head = tester
          .getTopLeft(
            find.descendant(of: _sheet, matching: find.text(S.dataSheetTitle)),
          )
          .dy;
      final double foot = tester.getTopLeft(_save).dy;
      await tester.drag(_card(S.injuryMuscle), const Offset(0, -300));
      await tester.pump();
      expect(
        tester
            .getTopLeft(
              find.descendant(
                of: _sheet,
                matching: find.text(S.dataSheetTitle),
              ),
            )
            .dy,
        head,
      );
      expect(tester.getTopLeft(_save).dy, foot);
      expect(find.bySemanticsLabel(S.dataSheetTitle), findsWidgets);
      // Erste Tab-Station im Sheet ist „Schließen“; Enter schließt (UI-68).
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final HeaderIconButton? focused = FocusManager
          .instance
          .primaryFocus
          ?.context
          ?.findAncestorWidgetOfExactType<HeaderIconButton>();
      expect(focused, isNotNull);
      expect(focused!.tooltip, S.close);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      expect(_sheet, findsNothing);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  group('Profil ändern (UI-54, UI-55)', () {
    testWidgets('UI-54: Speichern ist aus, solange nichts geändert ist oder '
        'der Name (getrimmt) leer ist', (WidgetTester tester) async {
      final Harness h = await _pumpPath(tester);
      await _openSheet(tester);
      expect(_saveEnabled(tester), isFalse);
      await tester.enterText(_nameField, 'Jakob Neu');
      await tester.pump();
      expect(_saveEnabled(tester), isTrue);
      await tester.enterText(_nameField, '   ');
      await tester.pump();
      expect(_saveEnabled(tester), isFalse);
      await tester.enterText(_nameField, '');
      await tester.pump();
      expect(_saveEnabled(tester), isFalse);
      // Zurück auf den gespeicherten Namen (nur Leerraum drumherum): keine
      // Änderung.
      await tester.enterText(_nameField, '  ${h.state.onboarding.name} ');
      await tester.pump();
      expect(_saveEnabled(tester), isFalse);
      // Anderer Typ: aktiv; zurück auf den alten: wieder aus.
      await _makeDirty(tester);
      expect(_saveEnabled(tester), isTrue);
      await _tapIn(tester, _card(S.injuryAcl));
      expect(_saveEnabled(tester), isFalse);
      await disposeApp(tester);
    });

    testWidgets('UI-55: nur der Name: Sheet zu, neuer Name auf Heute, Ansage '
        '„Gespeichert.“, Pfad nicht neu berechnet', (
      WidgetTester tester,
    ) async {
      final Harness h = await _pumpPath(tester);
      final AppState before = h.state;
      await _openSheet(tester);
      tester.takeAnnouncements();
      await tester.enterText(_nameField, 'Mia');
      await tester.pump();
      await tester.tap(_save);
      await _settle(tester);
      expect(_sheet, findsNothing);
      expect(
        tester.takeAnnouncements().map((a) => a.message).last,
        S.dataSaved,
      );
      expect(h.state.onboarding.name, 'Mia');
      expect(h.state.path, before.path);
      expect(h.state.streak, before.streak);
      expect(h.state.day, before.day);
      expect(h.state.onboarding.injuryType, before.onboarding.injuryType);
      // Heute zeigt den neuen Namen.
      await tester.tap(
        find.descendant(
          of: find.byType(HomeShell),
          matching: find.text(S.navToday),
        ),
      );
      await _settle(tester);
      expect(find.text(S.todayTitle('Mia')), findsOneWidget);
      expect(_shell(tester).dataButtonFocus.hasFocus, isFalse);
      await disposeApp(tester);
    });

    testWidgets('UI-55: Typ und Datum: Pfad neu berechnet, Streak, Freezes und '
        'Heute-Änderungen bleiben, kein Puls, aktuelle Unit auf 55 %', (
      WidgetTester tester,
    ) async {
      final Harness h = await _pumpPath(
        tester,
        tweak: (AppState s) => _noBubble(s).copyWith(
          streak: StreakState(
            count: 12,
            freezes: 1,
            lastTrainingDay: kToday.addDays(-1),
            evaluatedThrough: kToday.addDays(-1),
          ),
          path: const PathState(
            completedUnitIds: <String>['w5-d1'],
            pulsePending: 'w5-d1',
          ),
          day: _noBubble(s).day.copyWith(removed: <String>['ex-wade']),
        ),
      );
      final AppState before = h.state;
      await _openSheet(tester);
      tester.takeAnnouncements();
      await _tapIn(tester, _card(S.injuryAnkle));
      // Anderes Datum über die Datumsauswahl.
      await _tapIn(tester, find.byType(DateCard));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      final DatePickerDialog picker = tester.widget(
        find.byType(DatePickerDialog),
      );
      expect(picker.lastDate, DateTime(2026, 10, 7));
      await tester.tap(
        find
            .descendant(
              of: find.byType(DatePickerDialog),
              matching: find.text('1'),
            )
            .first,
      );
      await tester.tap(find.text('OK'));
      await _settle(tester);
      expect(_sheet, findsOneWidget);
      expect(_saveEnabled(tester), isTrue);
      await tester.tap(_save);
      await _settle(tester);
      expect(_sheet, findsNothing);
      expect(
        tester.takeAnnouncements().map((a) => a.message).last,
        S.dataSavedRecomputed,
      );
      final AppState after = h.state;
      expect(after.onboarding.injuryType, InjuryType.ankle);
      expect(after.onboarding.injuryDate, isNot(before.onboarding.injuryDate));
      expect(after.streak, before.streak);
      expect(after.streak.freezes, 1);
      expect(after.day, before.day);
      expect(after.path.completedUnitIds, isEmpty);
      expect(
        after.path.pulsePending,
        isNull,
        reason: 'kein Puls auf dem neuen Pfad',
      );
      await h.controller.idle;
      expect((await h.store.load())!.onboarding.injuryType, InjuryType.ankle);
      // Kein Ring-Puls läuft, aktuelle Unit steht auf 55 %.
      final PathProgress p = computePathProgress(
        injuryDate: after.onboarding.injuryDate,
        today: kToday,
        completedUnitIds: const <String>[],
      );
      final Rect view = tester.getRect(find.byKey(ProbeKeys.scroll));
      final double f =
          (tester
                  .getRect(
                    find.byKey(
                      ValueKey<String>('unit:${p.units[p.mannyIndex].id}'),
                    ),
                  )
                  .center
                  .dy -
              view.top) /
          view.height;
      expect(f, closeTo(0.55, 0.01));
      expect(find.text('Woche ${p.week}'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
      await disposeApp(tester);
    });

    testWidgets('UI-55: nur der Typ (gleiche Woche): der Pfad zentriert '
        'trotzdem neu', (WidgetTester tester) async {
      final Harness h = await _pumpPath(tester);
      await _openSheet(tester);
      await _tapIn(tester, _card(S.injuryMuscle));
      await tester.tap(_save);
      await _settle(tester);
      expect(h.state.onboarding.injuryType, InjuryType.muscle);
      expect(tester.binding.transientCallbackCount, 0);
      await disposeApp(tester);
    });

    testWidgets('„Anderes“ mit Freitext wird gespeichert; anderer Typ löscht '
        'den Freitext', (WidgetTester tester) async {
      final Harness h = await _pumpPath(tester);
      await _openSheet(tester);
      await _tapIn(tester, _card(S.injuryOther));
      final Finder other = find
          .descendant(of: _sheet, matching: find.byType(TextField))
          .at(1);
      await tester.enterText(other, 'Schulter');
      await tester.pump();
      await tester.tap(_save);
      await _settle(tester);
      expect(h.state.onboarding.injuryType, InjuryType.other);
      expect(h.state.onboarding.injuryOther, 'Schulter');
      await _openSheet(tester);
      await _tapIn(tester, _card(S.injuryAcl));
      await tester.tap(_save);
      await _settle(tester);
      expect(h.state.onboarding.injuryOther, isEmpty);
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  group('Hinweis „noch keinen eigenen Pfad“ und Datenschutz (SK-1)', () {
    testWidgets('Der Hinweis folgt der Auswahl im Entwurf: bei Kreuzband weg, '
        'sonst da', (WidgetTester tester) async {
      await _pumpPath(tester);
      await _openSheet(tester);
      expect(find.text(S.injuryNoOwnPath), findsNothing);
      for (final String title in <String>[
        S.injuryAnkle,
        S.injuryMuscle,
        S.injuryOther,
      ]) {
        await _tapIn(tester, _card(title));
        expect(find.text(S.injuryNoOwnPath), findsOneWidget, reason: title);
      }
      await _tapIn(tester, _card(S.injuryAcl));
      expect(find.text(S.injuryNoOwnPath), findsNothing);
      await disposeApp(tester);
    });

    testWidgets(
      'Gespeichert als Muskelfaserriss: Hinweis beim Öffnen, Kopfzeile '
      'zeigt den vollen Namen',
      (WidgetTester tester) async {
        await _pumpPath(
          tester,
          tweak: (AppState s) => s.copyWith(
            onboarding: s.onboarding.copyWith(injuryType: InjuryType.muscle),
          ),
        );
        expect(find.text('Phase 2 · Muskelfaserriss'), findsOneWidget);
        await _openSheet(tester);
        expect(find.text(S.injuryNoOwnPath), findsOneWidget);
        // Beim Öffnen keine zusätzliche Ansage; erst eine Änderung im Entwurf.
        final SemanticsHandle sem = tester.ensureSemantics();
        await tester.pumpAndSettle();
        expect(
          tester.getSemantics(find.text(S.injuryNoOwnPath)),
          isSemantics(label: S.injuryNoOwnPath, isLiveRegion: false),
        );
        await _tapIn(tester, _card(S.injuryAnkle));
        expect(
          tester.getSemantics(find.text(S.injuryNoOwnPath)),
          isSemantics(label: S.injuryNoOwnPath, isLiveRegion: true),
        );
        sem.dispose();
        await disposeApp(tester);
      },
    );

    testWidgets('Der Link „Datenschutzerklärung“ öffnet die Platzhalterseite '
        'über dem Sheet; der Entwurf bleibt, der Fokus kehrt zurück', (
      WidgetTester tester,
    ) async {
      await _pumpPath(tester);
      await _openSheet(tester);
      await _makeDirty(tester);
      final Finder link = find.bySemanticsLabel(S.dataPrivacyEntry);
      await tester.ensureVisible(find.text(S.dataPrivacyEntry));
      await tester.pumpAndSettle();
      final Rect r = tester.getRect(find.text(S.dataPrivacyEntry));
      expect(r.height, greaterThan(0));
      await tester.tap(find.text(S.dataPrivacyEntry));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyPlaceholderPage), findsOneWidget);
      expect(find.text(S.privacyPlaceholderBody), findsOneWidget);
      await tester.tap(find.byTooltip(S.back));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyPlaceholderPage), findsNothing);
      expect(_sheet, findsOneWidget);
      expect(_saveEnabled(tester), isTrue, reason: 'Entwurf bleibt');
      expect(link, findsWidgets);
      final BuildContext? ctx = FocusManager.instance.primaryFocus?.context;
      expect(ctx, isNotNull);
      expect(
        ctx!.findAncestorWidgetOfExactType<CuraPressable>()?.semanticLabel,
        S.dataPrivacyEntry,
      );
      await disposeApp(tester);
    });

    testWidgets(
      'Datenschutz-Link: Hit-Area ≥ 48 dp, Semantik als Schaltfläche',
      (WidgetTester tester) async {
        final SemanticsHandle sem = tester.ensureSemantics();
        await _pumpPath(tester);
        await _openSheet(tester);
        await tester.ensureVisible(find.text(S.dataPrivacyEntry));
        await tester.pumpAndSettle();
        final SemanticsNode node = tester.getSemantics(
          find.bySemanticsLabel(S.dataPrivacyEntry),
        );
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.rect.height, greaterThanOrEqualTo(48));
        sem.dispose();
        await disposeApp(tester);
      },
    );
  });

  group('Änderungen verwerfen (UI-57)', () {
    Future<void> expectDiscardFor(
      WidgetTester tester,
      Future<void> Function() how,
    ) async {
      await _openSheet(tester);
      await _makeDirty(tester);
      await how();
      await _settle(tester);
      expect(find.byType(DiscardDialog), findsOneWidget);
      expect(_sheet, findsOneWidget);
      // „Weiter bearbeiten“: Dialog zu, Sheet und Änderung bleiben.
      await tester.tap(find.text(S.discardKeep));
      await _settle(tester);
      expect(find.byType(DiscardDialog), findsNothing);
      expect(_sheet, findsOneWidget);
      expect(tester.widget<ChoiceCard>(_card(S.injuryMuscle)).selected, isTrue);
      expect(_saveEnabled(tester), isTrue);
      // Aufräumen für den nächsten Weg: Änderung zurücknehmen, direkt schließen.
      await _tapIn(tester, _card(S.injuryAcl));
      await tester.tap(_closeX);
      await _settle(tester);
      expect(_sheet, findsNothing);
    }

    testWidgets('alle Schließwege öffnen „Änderungen verwerfen?“; „Weiter '
        'bearbeiten“ behält die Änderung', (WidgetTester tester) async {
      await _pumpPath(tester);
      await expectDiscardFor(tester, () => tester.tap(_closeX));
      await expectDiscardFor(tester, () => tester.binding.handlePopRoute());
      await expectDiscardFor(
        tester,
        () => tester.sendKeyEvent(LogicalKeyboardKey.escape),
      );
      await expectDiscardFor(tester, () => tester.tapAt(const Offset(195, 20)));
      await expectDiscardFor(
        tester,
        () => tester.fling(
          find.descendant(of: _sheet, matching: find.text(S.dataSheetTitle)),
          const Offset(0, 400),
          1500,
        ),
      );
      await disposeApp(tester);
    });

    testWidgets(
      'Aufbau: „Weiter bearbeiten“ hell mit Anfangsfokus, '
      '„Verwerfen“ Umriss; alertdialog mit Routenname; ohne Blur und Akzent',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await _pumpPath(tester);
        await _openSheet(tester);
        await _makeDirty(tester);
        await tester.tap(_closeX);
        await _settle(tester);
        final PillButton keep = tester.widget(
          find.widgetWithText(PillButton, S.discardKeep),
        );
        final PillButton discard = tester.widget(
          find.widgetWithText(PillButton, S.discardConfirm),
        );
        expect(keep.variant, PillButtonVariant.neutral);
        expect(keep.autofocus, isTrue);
        expect(discard.variant, PillButtonVariant.outline);
        expect(find.text(S.discardTitle), findsOneWidget);
        expect(find.text(S.discardText), findsOneWidget);
        expect(
          tester.getTopLeft(find.text(S.discardKeep)).dy,
          lessThan(tester.getTopLeft(find.text(S.discardConfirm)).dy),
        );
        expect(
          find.semantics.byPredicate(
            (SemanticsNode n) => n.role == SemanticsRole.alertDialog,
          ),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel(S.discardTitle), findsWidgets);
        expect(
          find.descendant(
            of: find.byType(DiscardDialog),
            matching: find.byType(BackdropFilter),
          ),
          findsNothing,
        );
        semantics.dispose();
        await disposeApp(tester);
      },
    );

    testWidgets('Tipp auf den Scrim des Dialogs bedeutet weiter bearbeiten; '
        '„Verwerfen“ schließt, ohne zu speichern', (WidgetTester tester) async {
      final Harness h = await _pumpPath(tester);
      final AppState before = h.state;
      await _openSheet(tester);
      await _makeDirty(tester);
      await tester.tap(_closeX);
      await _settle(tester);
      await tester.tapAt(const Offset(195, 10));
      await _settle(tester);
      expect(find.byType(DiscardDialog), findsNothing);
      expect(_sheet, findsOneWidget);

      await tester.tap(_closeX);
      await _settle(tester);
      await tester.tap(find.text(S.discardConfirm));
      await _settle(tester);
      expect(_sheet, findsNothing);
      expect(find.byType(DiscardDialog), findsNothing);
      expect(h.state, before, reason: 'nichts gespeichert');
      await h.controller.idle;
      // Erneut öffnen: wieder der gespeicherte Stand.
      await _openSheet(tester);
      expect(tester.widget<ChoiceCard>(_card(S.injuryAcl)).selected, isTrue);
      expect(_saveEnabled(tester), isFalse);
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  group('Alles löschen (UI-49 bis UI-52, UI-82)', () {
    testWidgets('UI-49: Umriss-Button ohne Akzent und Fehlerfarbe; Dialog '
        'opak, „Abbrechen“ hell mit Anfangsfokus, „Ja, alles löschen“ Umriss', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pumpPath(tester);
      await _openSheet(tester);
      final PillButton trigger = tester.widget(_deleteButton);
      expect(trigger.variant, PillButtonVariant.outline);
      expect(trigger.icon, Icons.delete_outline_rounded);
      await _openDelete(tester);
      final CuraColors c = colorsAt(tester, find.byType(DeleteDialog));
      final PillButton cancel = tester.widget(_cancel);
      final PillButton confirm = tester.widget(_confirm);
      expect(cancel.label, S.cancel);
      expect(cancel.variant, PillButtonVariant.neutral);
      expect(cancel.autofocus, isTrue);
      expect(confirm.label, S.deleteConfirm);
      expect(confirm.variant, PillButtonVariant.outline);
      expect(confirm.icon, Icons.delete_outline_rounded);
      expect(find.text(S.deleteTitle), findsOneWidget);
      expect(find.text(S.deleteText), findsOneWidget);
      expect(find.byType(DeleteErrorNotice), findsNothing);
      // Opak, ohne Blur.
      final BoxDecoration d = decorationsUnder(
        tester,
        find.byType(CuraDialog),
      ).firstWhere((BoxDecoration x) => x.borderRadius != null);
      expect(d.color, c.surfaceOpaque);
      expect(
        find.descendant(
          of: find.byType(DeleteDialog),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
      expect(
        find.semantics.byPredicate(
          (SemanticsNode n) => n.role == SemanticsRole.alertDialog,
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(S.deleteTitle), findsWidgets);
      // Anfangsfokus auf „Abbrechen“, Tab-Reihenfolge Abbrechen vor Bestätigen.
      expect(FocusManager.instance.primaryFocus, isNotNull);
      expect(
        tester.getTopLeft(find.text(S.cancel)).dy,
        lessThan(tester.getTopLeft(find.text(S.deleteConfirm)).dy),
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('UI-50: Abbrechen, Zurück, Escape und Scrim lassen alle Daten '
        'unverändert; der Fokus kehrt zum Löschen-Button zurück', (
      WidgetTester tester,
    ) async {
      final _Rig rig = await _rig();
      await pumpCura(tester, rig.controller);
      final AppState before = rig.controller.state;
      await _openSheet(tester);

      Future<void> tryClose(Future<void> Function() how) async {
        await _openDelete(tester);
        await how();
        await _settle(tester);
        expect(find.byType(DeleteDialog), findsNothing);
        expect(_sheet, findsOneWidget);
      }

      await tryClose(() => tester.tap(_cancel));
      await tryClose(() => tester.binding.handlePopRoute());
      await tryClose(() => tester.sendKeyEvent(LogicalKeyboardKey.escape));
      await tryClose(() => tester.tapAt(const Offset(195, 10)));
      expect(rig.eraser.calls, 0);
      expect(rig.controller.state, before);
      expect(rig.raw.raw, isNotNull);
      expect(rig.controller.isDeleting, isFalse);
      await disposeApp(tester);
    });

    testWidgets('UI-51: bestätigt: Onboarding Schritt 1 leer, Zurück erreicht '
        'Pfad und Sheet nicht, Snackbar 4 s, Speicher leer, Neustart bei '
        'Schritt 1, Einwilligung erneut', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
      final SystemPopRecorder pops = SystemPopRecorder(tester);
      final _Rig rig = await _rig(
        tweak: (AppState s) => _noBubble(s).copyWith(
          streak: StreakState(
            count: 7,
            freezes: 0,
            lastTrainingDay: kToday.addDays(-1),
            evaluatedThrough: kToday.addDays(-1),
          ),
          prefs: const PrefsState(timeChoice: 30),
        ),
      );
      await pumpCura(tester, rig.controller, navigatorKey: key);
      await _openSheet(tester);
      await _openDelete(tester);
      await tester.tap(_confirm);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await _settle(tester);

      expect(find.byType(OnboardingFlow), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
      expect(_sheet, findsNothing);
      expect(find.byType(DeleteDialog), findsNothing);
      expect(find.text(S.stepOf(1, 4)), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text(S.dataDeleted), findsOneWidget);
      // Zurück erreicht Pfad und Sheet nicht: auf Schritt 1 schließt die App.
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(find.byType(HomeShell), findsNothing);
      expect(pops.count, 1);
      expect(key.currentState!.canPop(), isFalse);
      // Der Hinweis dauert 4 s.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text(S.dataDeleted), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(S.dataDeleted), findsNothing);

      // Zustand und Speicher.
      final AppState s = rig.controller.state;
      expect(s, AppState.initial(rig.controller.today));
      expect(s.streak.count, 0);
      expect(s.streak.freezes, 2);
      expect(s.prefs.timeChoice, 20);
      expect(s.consent, isNull);
      await rig.controller.idle;
      expect(rig.raw.raw, isNull);
      expect(
        rig.controller.isDeleting,
        isFalse,
        reason: 'completeDeletion lief',
      );

      // Neustart: der Speicher ist leer, die App beginnt bei Schritt 1.
      final Harness again = await Harness.boot(raw: rig.raw);
      addTearDown(again.dispose);
      expect(again.state.onboarding.step, 0);
      expect(again.state.consent, isNull);
      expect(again.state.onboarding.completed, isFalse);
      await disposeApp(tester);
    });

    testWidgets('UI-51: Einwilligung muss nach dem Löschen erneut bestätigt '
        'werden; danach Ausgangswerte', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
      final _Rig rig = await _rig(
        tweak: (AppState s) => _noBubble(s).copyWith(
          streak: StreakState(
            count: 7,
            freezes: 0,
            lastTrainingDay: kToday.addDays(-1),
            evaluatedThrough: kToday.addDays(-1),
          ),
        ),
      );
      await pumpCura(tester, rig.controller, navigatorKey: key);
      await _openSheet(tester);
      await _openDelete(tester);
      await tester.tap(_confirm);
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'Mia');
      await tester.pump();
      await tester.tap(find.widgetWithText(PillButton, S.next));
      await _settle(tester);
      expect(find.widgetWithText(PillButton, S.consentAccept), findsOneWidget);
      expect(rig.controller.state.consent, isNull);
      await tester.tap(find.widgetWithText(PillButton, S.consentAccept));
      await _settle(tester);
      expect(rig.controller.state.consent, isNotNull);
      expect(rig.controller.state.streak.count, 0);
      expect(rig.controller.state.streak.freezes, 2);
      await disposeApp(tester);
    });

    testWidgets('UI-52 Laden: ab 300 ms Fortschrittskreis und gesperrter '
        'Button; Zurück, Escape, Scrim und Abbrechen wirkungslos; Doppeltipp '
        'startet nur einen Vorgang; Ansage „Wird gelöscht“', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      final Completer<void> gate = Completer<void>();
      final _Rig rig = await _rig(gate: gate);
      await pumpCura(tester, rig.controller);
      await _openSheet(tester);
      await _openDelete(tester);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(_confirm);
      await tester.pump();
      await tester.tap(_confirm, warnIfMissed: false); // Doppeltipp
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'vor 300 ms noch kein Kreis',
      );
      await tester.pump(const Duration(milliseconds: 51));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(_confirmButton(tester).busy, isTrue);
      expect(rig.eraser.calls, 1, reason: 'nur ein Vorgang');
      expect(rig.controller.isDeleting, isTrue);
      expect(
        find.bySemanticsLabel(
          S.busyLabel(S.deleteConfirm, S.busyStatusDeleting),
        ),
        findsOneWidget,
      );
      // Gesperrt: tippen und alle Schließwege bleiben ohne Wirkung.
      await tester.tap(_confirm, warnIfMissed: false);
      await tester.pump();
      await tester.tap(_cancel, warnIfMissed: false);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.tapAt(const Offset(195, 10));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(DeleteDialog), findsOneWidget);
      expect(_sheet, findsOneWidget);
      expect(rig.eraser.calls, 1);

      gate.complete();
      await tester.pump();
      await _settle(tester);
      expect(find.byType(OnboardingFlow), findsOneWidget);
      expect(rig.raw.raw, isNull);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('F-4: Löschfehler bei 320 × 568 × 2,0: Fehlertext ohne '
        'Scrollen sichtbar, Buttons ohne Wortbruch', (
      WidgetTester tester,
    ) async {
      final _Rig rig = await _rig(failTimes: 1);
      await pumpCura(
        tester,
        rig.controller,
        size: Viewports.small,
        textScale: 2,
      );
      await _openSheet(tester);
      await _openDelete(tester);
      await tester.ensureVisible(_confirm);
      await tester.pump();
      await tester.tap(_confirm);
      await _settle(tester);
      expect(find.byType(DeleteErrorNotice), findsOneWidget);
      final Rect err = tester.getRect(find.text(S.deleteError));
      expect(err.top, greaterThanOrEqualTo(0));
      expect(err.bottom, lessThanOrEqualTo(568));
      // Ohne gescrollt zu haben: der Dialog steht am Anfang seines Wegs.
      final ScrollableState st = tester.state(
        find.descendant(
          of: find.byType(DeleteDialog),
          matching: find.byType(Scrollable),
        ),
      );
      expect(st.position.pixels, 0);
      // N-3: der Fokus liegt auf dem Hinweis (Live-Region), nicht auf dem
      // aus dem Bild gesprungenen Button.
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Dialog-Hinweis');
      // „Nochmal versuchen“ bleibt per Tab erreichbar und kommt dabei ins Bild.
      for (int i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        if (_focusOnButton(S.retry)) break;
      }
      expect(_focusOnButton(S.retry), isTrue, reason: 'per Tab erreichbar');
      await tester.pumpAndSettle();
      expect(tester.getRect(_confirm).bottom, lessThanOrEqualTo(568 + 0.5));
      expect(tester.getRect(_confirm).top, greaterThanOrEqualTo(0));
      for (final String t in <String>[S.cancel, S.retry]) {
        final List<String> lines = paragraphLines(tester, find.text(t));
        expect(lines.join(), t);
        expect(midWordBreaks(lines), isEmpty, reason: '$t: $lines');
      }
      await disposeApp(tester);
    });

    testWidgets('UI-52 Fehler: Icon, Text und „Nochmal versuchen“; Zustand '
        'unverändert; Abbrechen möglich; erneuter Versuch löscht', (
      WidgetTester tester,
    ) async {
      final _Rig rig = await _rig(failTimes: 1);
      await pumpCura(tester, rig.controller);
      final AppState before = rig.controller.state;
      await _openSheet(tester);
      await _openDelete(tester);
      await tester.tap(_confirm);
      await _settle(tester);

      expect(find.byType(DeleteDialog), findsOneWidget);
      expect(find.byType(DeleteErrorNotice), findsOneWidget);
      expect(find.text(S.deleteError), findsOneWidget);
      final Icon icon = tester.widget(
        find.descendant(
          of: find.byType(DeleteErrorNotice),
          matching: find.byType(Icon),
        ),
      );
      expect(icon.icon, Icons.error_outline_rounded);
      expect(
        icon.color,
        colorsAt(tester, find.byType(DeleteDialog)).statusError,
      );
      expect(_confirmButton(tester).label, S.retry);
      expect(_confirmButton(tester).busy, isFalse);
      expect(rig.controller.state, before);
      expect(rig.controller.isDeleting, isFalse);
      expect(rig.raw.raw, isNotNull);
      // Erneuter Versuch gelingt.
      await tester.tap(_confirm);
      await _settle(tester);
      expect(rig.eraser.calls, 2);
      expect(find.byType(OnboardingFlow), findsOneWidget);
      expect(rig.raw.raw, isNull);
      await disposeApp(tester);
    });

    testWidgets('UI-52 Fehler: „Abbrechen“ schließt den Dialog, die Daten '
        'bleiben', (WidgetTester tester) async {
      final _Rig rig = await _rig(failTimes: 5);
      await pumpCura(tester, rig.controller);
      await _openSheet(tester);
      await _openDelete(tester);
      await tester.tap(_confirm);
      await _settle(tester);
      expect(find.byType(DeleteErrorNotice), findsOneWidget);
      await tester.tap(_cancel);
      await _settle(tester);
      expect(find.byType(DeleteDialog), findsNothing);
      expect(_sheet, findsOneWidget);
      expect(rig.controller.state.onboarding.completed, isTrue);
      await disposeApp(tester);
    });

    testWidgets('UI-82: Löschen über den Dialog, neues Onboarding mit anderem '
        'Namen: Beispielverlauf mit neuem Namen, im Speicher nur das '
        'Zustandsdokument', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
      final _Rig rig = await _rig();
      await pumpCura(tester, rig.controller, navigatorKey: key);
      await _openSheet(tester);
      await _openDelete(tester);
      await tester.tap(_confirm);
      await _settle(tester);

      await tester.enterText(find.byType(TextField), 'Mia');
      await tester.pump();
      await tester.tap(find.widgetWithText(PillButton, S.next));
      await _settle(tester);
      await tester.tap(find.widgetWithText(PillButton, S.consentAccept));
      await _settle(tester);
      await tester.tap(find.text(S.injuryAcl));
      await tester.pump();
      await tester.tap(find.widgetWithText(PillButton, S.next));
      await _settle(tester);
      await tester.tap(find.text(S.datePlaceholder));
      await _settle(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('5'),
        ),
      );
      await tester.tap(find.text('OK'));
      await _settle(tester);
      await tester.tap(find.widgetWithText(PillButton, S.next));
      await _settle(tester);
      expect(find.byType(HomeShell), findsOneWidget);

      await tester.tap(find.byTooltip(S.mannyChatOpen));
      await _settle(tester);
      expect(find.byType(MannyChatScreen), findsOneWidget);
      expect(find.text('Moin Mia. Wie läuft dein Tag?'), findsOneWidget);
      expect(find.textContaining('Jakob'), findsNothing);
      await rig.controller.idle;
      expect(rig.raw.raw, isNotNull);
      expect(rig.raw.raw!.toLowerCase().contains('chat'), isFalse);
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  group('Button-Gruppe unter dem Scrim (UI-70)', () {
    testWidgets('bei offenem Sheet und Dialog: weder Semantik-Knoten noch '
        'fokussierbar noch per Tipp erreichbar', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _pumpPath(tester);
      final Rect chat = tester.getRect(find.byType(MannyChatButton));
      final Rect messages = tester.getRect(find.byType(MessagesButton));
      expect(find.bySemanticsLabel(S.mannyChatOpen), findsOneWidget);
      await _openSheet(tester);

      bool hasLabel(String label) {
        bool found = false;
        void walk(SemanticsNode n) {
          if (n.getSemanticsData().label == label) found = true;
          n.visitChildren((SemanticsNode c) {
            walk(c);
            return true;
          });
        }

        walk(
          tester
              .binding
              .renderViews
              .first
              .owner!
              .semanticsOwner!
              .rootSemanticsNode!,
        );
        return found;
      }

      void expectBlocked() {
        expect(hasLabel(S.mannyChatOpen), isFalse);
        expect(hasLabel(S.messagesButton), isFalse);
        expect(hasLabel(S.dataSheetOpen) && hasLabel(S.navToday), isFalse);
      }

      expectBlocked();
      // Tab durch das Sheet erreicht die Gruppe nicht.
      for (int i = 0; i < 25; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final BuildContext? ctx = FocusManager.instance.primaryFocus?.context;
        if (ctx == null) continue;
        expect(ctx.findAncestorWidgetOfExactType<MannyChatButton>(), isNull);
        expect(ctx.findAncestorWidgetOfExactType<MessagesButton>(), isNull);
      }
      // Tipp auf die Stelle der Gruppe trifft den Scrim/das Sheet, kein Chat.
      for (final Rect r in <Rect>[chat, messages]) {
        await tester.tapAt(r.center);
        await _settle(tester);
        expect(find.byType(MannyChatScreen), findsNothing);
        // Die Stelle der Gruppe kann im Sheet auf einen echten Button fallen
        // (z. B. „Alle Daten löschen“): ein dadurch geöffneter Dialog wird
        // geschlossen, hier zählt nur, dass nie der Chat aufgeht.
        if (find.byType(DeleteDialog).evaluate().isNotEmpty) {
          await tester.tap(_cancel);
          await _settle(tester);
        }
      }

      // Auch unter dem Dialog.
      if (_sheet.evaluate().isEmpty) await _openSheet(tester);
      await _openDelete(tester);
      expectBlocked();
      await tester.tapAt(chat.center);
      await _settle(tester);
      expect(find.byType(MannyChatScreen), findsNothing);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  group(
    'Tastatur, große Schrift, Bewegung, Kontrast (UI-58, UI-64 bis UI-68)',
    () {
      testWidgets('UI-58: 320 × 568 mit Tastatur: „Speichern“ bleibt sichtbar, '
          'das fokussierte Feld auch', (WidgetTester tester) async {
        await _pumpPath(tester, size: Viewports.small);
        await _openSheet(tester);
        await tester.tap(_nameField);
        await tester.pumpAndSettle();
        final EditableText before = tester.widget(
          find.byType(EditableText).first,
        );
        await _showKeyboard(tester);
        // Der Wechsel in den kompakten Zustand behält das Feld samt Fokus.
        final EditableText after = tester.widget(
          find.byType(EditableText).first,
        );
        expect(after.focusNode, same(before.focusNode));
        expect(after.focusNode.hasFocus, isTrue);
        final Rect field = tester.getRect(_nameField);
        final Rect save = tester.getRect(_save);
        expect(save.bottom, lessThanOrEqualTo(568 - 300 + 0.5));
        expect(save.top, greaterThanOrEqualTo(0));
        expect(field.top, greaterThanOrEqualTo(0));
        // Das Feld steht über der Fußleiste (der Schreibcursor ist im Bild).
        expect(field.center.dy, lessThan(save.top));
        // Mit geändertem Namen ist „Speichern“ aktiv und bedienbar.
        await tester.enterText(_nameField, 'Mia');
        await tester.pump();
        expect(_saveEnabled(tester), isTrue);
        await tester.tap(_save);
        await _settle(tester);
        expect(_sheet, findsNothing);
        await disposeApp(tester);
      });

      testWidgets('F-6: kompaktes Sheet rückt unter die Statusleiste; nach '
          'dem Schließen der Tastatur ist der Normalzustand zurück (Kopf und '
          '„Schließen“ fest)', (WidgetTester tester) async {
        tester.view.padding = const FakeViewPadding(top: 24);
        addTearDown(tester.view.resetPadding);
        await _pumpPath(tester, size: Viewports.small);
        await _openSheet(tester);
        Finder scrollAbove(Finder f) => find.ancestor(
          of: f,
          matching: find.descendant(
            of: _sheet,
            matching: find.byType(SingleChildScrollView),
          ),
        );
        // Normal: „Schließen“ liegt im festen Kopf, nicht in der Scrollfläche.
        expect(scrollAbove(_closeX), findsNothing);
        await tester.tap(_nameField);
        await tester.pumpAndSettle();
        await _showKeyboard(tester);
        // Kompakt: der Kopf läuft mit, steht aber unter dem oberen Inset.
        expect(scrollAbove(_closeX), findsOneWidget);
        tester
            .state<ScrollableState>(
              find
                  .descendant(of: _sheet, matching: find.byType(Scrollable))
                  .first,
            )
            .position
            .jumpTo(0);
        await tester.pump();
        expect(tester.getRect(_closeX).top, greaterThanOrEqualTo(24 - 0.5));
        // Tastatur zu: Normalzustand.
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(scrollAbove(_closeX), findsNothing);
        final Rect x = tester.getRect(_closeX);
        final ScrollableState st = tester.state(
          find.descendant(of: _sheet, matching: find.byType(Scrollable)).first,
        );
        st.position.jumpTo(st.position.maxScrollExtent);
        await tester.pump();
        expect(tester.getRect(_closeX), x, reason: 'Kopf fest');
        await disposeApp(tester);
      });

      testWidgets('UI-58: mit Tastatur und 200 % Schrift bleibt „Speichern“ '
          'sichtbar, Löschen-Abschnitt entfällt, solange die Tastatur steht', (
        WidgetTester tester,
      ) async {
        await _pumpPath(tester, size: Viewports.small, scale: 2);
        await _openSheet(tester);
        expect(_deleteButton, findsOneWidget);
        await tester.tap(_nameField);
        await tester.pumpAndSettle();
        await _showKeyboard(tester);
        expect(
          tester.getRect(_save).bottom,
          lessThanOrEqualTo(568 - 300 + 0.5),
        );
        expect(_deleteButton, findsNothing);
        expect(
          tester.getRect(_nameField).center.dy,
          lessThan(tester.getRect(_save).top),
        );
        // Ohne Tastatur ist der Abschnitt wieder da.
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(_deleteButton, findsOneWidget);
        await disposeApp(tester);
      });

      testWidgets('UI-66: 320 × 568 bei 200 %: alles erreichbar, Speichern '
          'fest sichtbar, nichts läuft über', (WidgetTester tester) async {
        await _pumpPath(tester, size: Viewports.small, scale: 2);
        await _openSheet(tester);
        final Rect save = tester.getRect(_save);
        expect(save.bottom, lessThanOrEqualTo(568.5));
        // Alle Karten, das Datum und der Löschen-Button lassen sich in den
        // Scrollbereich holen.
        for (final Finder f in <Finder>[
          _card(S.injuryAcl),
          _card(S.injuryOther),
          find.byType(DateCard),
          _deleteButton,
        ]) {
          await tester.ensureVisible(f);
          await tester.pumpAndSettle();
          final Rect r = tester.getRect(f);
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(320.5));
          expect(r.bottom, lessThanOrEqualTo(save.top + 0.5));
        }
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });

      testWidgets('UI-64: Bewegung reduzieren: Sheet und Dialoge ohne '
          'Schiebung, nach 121 ms keine laufende Animation', (
        WidgetTester tester,
      ) async {
        await _pumpPath(tester, rm: true);
        await tester.tap(_dataIcon);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        expect(
          find.ancestor(of: _sheet, matching: find.byType(SlideTransition)),
          findsNothing,
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.binding.transientCallbackCount, 0);
        await _makeDirty(tester);
        await tester.tap(_closeX);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 121));
        await tester.pump(const Duration(milliseconds: 1));
        expect(find.byType(DiscardDialog), findsOneWidget);
        expect(tester.binding.transientCallbackCount, 0);
        await tester.tap(find.text(S.discardKeep));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 121));
        await tester.pump(const Duration(milliseconds: 1));
        await _openDelete(tester);
        await tester.pump(const Duration(milliseconds: 121));
        expect(tester.binding.transientCallbackCount, 0);
        await disposeApp(tester);
      });

      testWidgets(
        'UI-64: Fortschrittskreis darf bei Bewegung reduzieren weiter '
        'drehen (E-3); sonst nichts',
        (WidgetTester tester) async {
          final Completer<void> gate = Completer<void>();
          final _Rig rig = await _rig(gate: gate);
          await pumpCura(tester, rig.controller, disableAnimations: true);
          await _openSheet(tester);
          await _openDelete(tester);
          await tester.tap(_confirm);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 301));
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          await tester.pump(const Duration(milliseconds: 500));
          // Es läuft genau der Fortschrittskreis (eine Animation), sonst keine.
          expect(tester.binding.transientCallbackCount, 1);
          gate.complete();
          await tester.pump();
          await _settle(tester);
          await disposeApp(tester);
        },
      );

      testWidgets('UI-65: Hoher Kontrast: Sheet und Dialoge opak mit '
          'border-control-hc, Scrim 72 %, kein Blur', (
        WidgetTester tester,
      ) async {
        await _pumpPath(tester, hc: true);
        await tester.pumpAndSettle();
        await _openSheet(tester);
        final CuraColors c = colorsAt(tester, _sheet);
        expect(c.highContrast, isTrue);
        expect(backdropCount(tester), 0);
        final BoxDecoration d = decorationsUnder(
          tester,
          find.byType(CuraSheetFrame),
        ).firstWhere((BoxDecoration x) => x.color != null);
        expect(d.color, c.surfaceOpaque);
        expect(
          tester
              .widget<AnimatedModalBarrier>(
                find.byType(AnimatedModalBarrier).last,
              )
              .color
              .value!
              .a,
          closeTo(0.72, 0.01),
        );
        // Das Kopf-Icon hat den Kreisrand (im Pfad dahinter).
        final BoxDecoration icon = decorationsUnder(
          tester,
          find.ancestor(of: _dataIcon, matching: find.byType(CuraPressable)),
        ).firstWhere((BoxDecoration x) => x.shape == BoxShape.circle);
        expect(icon.border, isNotNull);
        await _openDelete(tester);
        final BoxDecoration dd = decorationsUnder(
          tester,
          find.byType(CuraDialog),
        ).firstWhere((BoxDecoration x) => x.borderRadius != null);
        expect(dd.color, c.surfaceOpaque);
        expect((dd.border! as Border).top.color, c.borderControlHc);
        expect(backdropCount(tester), 0);
        await disposeApp(tester);
      });

      testWidgets('UI-68: Ansagen, Routennamen und Tastaturbedienung', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        await _pumpPath(tester);
        await _openSheet(tester);
        expect(find.bySemanticsLabel(S.dataSheetTitle), findsWidgets);
        // Name ändern, speichern: Ansage nach dem Speichern.
        await tester.enterText(_nameField, 'Mia');
        await tester.pump();
        tester.takeAnnouncements();
        await tester.tap(_save);
        await _settle(tester);
        expect(
          tester.takeAnnouncements().map((a) => a.message).toList(),
          contains(S.dataSaved),
        );
        // Dialoge tragen ihren Routennamen.
        await _openSheet(tester);
        await _openDelete(tester);
        expect(find.bySemanticsLabel(S.deleteTitle), findsWidgets);
        semantics.dispose();
        await disposeApp(tester);
      });
    },
  );

  // -------------------------------------------------------------------------
  group('Tageswechsel und Sheet (UI-44)', () {
    testWidgets('„Deine Daten“ bleibt bei einem Tageswechsel offen und '
        'unverändert; keine Snackbar darunter', (WidgetTester tester) async {
      final Harness h = await _pumpPath(tester);
      await _openSheet(tester);
      await tester.enterText(_nameField, 'Mia');
      await tester.pump();
      h.clock.advanceDays(1);
      resumeApp(tester);
      await tester.pump();
      await tester.pump();
      expect(_sheet, findsOneWidget);
      expect(tester.widget<TextField>(_nameField).controller!.text, 'Mia');
      expect(find.byType(CuraSnackbar), findsNothing);
      await disposeApp(tester);
    });
  });
}
