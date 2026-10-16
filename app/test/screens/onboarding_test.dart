// Onboarding (U2b, Plan 4.1 bis 4.3, UI-11 bis UI-16, UI-33/34, UI-70/71; F2-R4:
// Brief v2, Ergänzung 1, 6a, V2-65 bis V2-67, V2-75): Ablauf der fünf Schritte
// (Look, Name, Datenschutz, Verletzungstyp, Datum), Speichern jeder Eingabe,
// Fortsetzen nach Neustart, Zurück je Schritt, Mikrofon-Hinweis, Hinweise nach
// Löschen und unlesbaren Daten, Fehlerzustand beim Start, Tastatur auf
// 320 × 568.
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/injury_type.dart';
import 'package:curaone/logic/manny_look.dart';
import 'package:curaone/logic/migrations.dart' show encodeDocument;
import 'package:curaone/state/app_controller.dart';
import 'package:curaone/ui/components/choice_card.dart';
import 'package:curaone/ui/components/cura_snackbar.dart';
import 'package:curaone/ui/components/date_card.dart';
import 'package:curaone/ui/components/manny.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
import 'package:curaone/ui/components/manny_chat_button.dart';
import 'package:curaone/ui/components/manny_look_picker.dart';
import 'package:curaone/ui/components/step_progress.dart';
import 'package:curaone/ui/components/mic_button.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:curaone/ui/home/home_shell.dart';
import 'package:curaone/ui/path/path_error_view.dart';
import 'package:curaone/ui/onboarding/step4_date.dart';
import 'package:curaone/ui/routes/app_routes.dart';
import 'package:curaone/ui/components/header_card.dart';
import 'package:curaone/ui/components/header_icon_button.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/builders.dart';
import '../support/controller_harness.dart';
import '../support/pump_app.dart';
import '../support/stores.dart';

Future<Harness> _boot({RawDocumentStore? raw, DateTime? now}) async {
  final Harness h = await Harness.boot(raw: raw, now: now, load: false);
  addTearDown(h.dispose);
  return h;
}

PillButton _primary(WidgetTester tester) => tester.widget<PillButton>(
  find.byWidgetPredicate(
    (Widget w) =>
        w is PillButton && (w.label == S.next || w.label == S.consentAccept),
  ),
);

Finder _next() => find.widgetWithText(PillButton, S.next);

/// „Zurück“ der Leiste (Glas-Pille).
Finder _backButton() => find.widgetWithText(PillButton, S.back);

Future<void> _enterName(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextField), name);
  await tester.pump();
}

Future<void> _tapNext(WidgetTester tester, [String label = S.next]) async {
  await tester.tap(find.widgetWithText(PillButton, label));
  await tester.pumpAndSettle();
}

/// Baut die App am Erststart (Schritt 1, Look-Wahl) und geht mit „Weiter“ zum
/// Namen (Schritt 2): von dort zählen die Helfer unten ihre Schritte.
Future<void> _pumpAtName(
  WidgetTester tester,
  Harness h, {
  Size size = Viewports.phone,
}) async {
  await pumpCura(tester, h.controller, size: size);
  await _tapNext(tester);
}

/// Bis zur Seite [index] (0 = Name, 1 = Datenschutz, 2 = Verletzungstyp,
/// 3 = Datum; Schritt 2 bis 5) mit Name Jakob, Einwilligung und ACL.
Future<void> _advanceTo(WidgetTester tester, int index) async {
  if (index >= 1) {
    await _enterName(tester, 'Jakob');
    await _tapNext(tester);
  }
  if (index >= 2) await _tapNext(tester, S.consentAccept);
  if (index >= 3) {
    await tester.tap(find.text(S.injuryAcl));
    await tester.pump();
    await _tapNext(tester);
  }
}

void main() {
  group('Ablauf (UI-11 bis UI-15)', () {
    testWidgets('1 → 4 → Home: Schritt X von 4, Manny-Texte mit Namen', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await _pumpAtName(tester, h);

      expect(find.text('Schritt 2 von 5'), findsOneWidget);
      expect(find.text(S.onboardingStep1), findsOneWidget);

      await _enterName(tester, 'Jakob');
      await _tapNext(tester);
      expect(find.text('Schritt 3 von 5'), findsOneWidget);
      expect(find.text(S.onboardingStep2('Jakob')), findsOneWidget);

      await _tapNext(tester, S.consentAccept);
      expect(find.text('Schritt 4 von 5'), findsOneWidget);
      expect(find.text(S.onboardingStep3('Jakob')), findsOneWidget);

      await tester.tap(find.text(S.injuryAcl));
      await tester.pump();
      await _tapNext(tester);
      expect(find.text('Schritt 5 von 5'), findsOneWidget);
      expect(find.text(S.onboardingStep4), findsOneWidget);

      await tester.tap(find.text(S.datePlaceholder));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.text('5'),
        ),
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('5. Oktober 2026'), findsOneWidget);

      await _tapNext(tester);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.text('Schritt 5 von 5'), findsNothing);
      final AppState? saved = await h.persisted();
      expect(saved!.onboarding.completed, isTrue);
      expect(saved.onboarding.injuryDate, const LocalDay(2026, 10, 5));
      expect(saved.manny.greetingPending, isTrue);
      await disposeApp(tester);
    });

    testWidgets('Screenreader liest nur den Text „Schritt X von 4“', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final Harness h = await _boot();
      await _pumpAtName(tester, h);
      expect(
        tester.getSemantics(find.text('Schritt 2 von 5')).label,
        'Schritt 2 von 5',
      );
      // Der Balken ist für den Screenreader ausgeblendet: keine zweite Angabe.
      expect(find.bySemanticsLabel(RegExp('Schritt')), findsOneWidget);
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('UI-12: Weiter nur mit Zeichen nach dem Trimmen', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await _pumpAtName(tester, h);
      expect(_primary(tester).onPressed, isNull);
      await _enterName(tester, '   ');
      expect(_primary(tester).onPressed, isNull);
      await _enterName(tester, 'J');
      expect(_primary(tester).onPressed, isNotNull);
      // Ungetrimmt gespeichert, getrimmt verwendet.
      await _enterName(tester, ' Mia ');
      expect(h.state.onboarding.name, ' Mia ');
      await _tapNext(tester);
      expect(find.text(S.onboardingStep2('Mia')), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets(
      'UI-13: Einwilligung gespeichert, erneut bestätigen überschreibt',
      (WidgetTester tester) async {
        final Harness h = await _boot();
        await _pumpAtName(tester, h);
        await _advanceTo(tester, 1);
        expect(
          find.widgetWithText(PillButton, S.consentAccept),
          findsOneWidget,
        );
        expect(h.state.consent, isNull, reason: 'erst mit „Verstanden“');
        // Nicht überspringbar: es gibt nur diesen Weg weiter.
        await _tapNext(tester, S.consentAccept);
        final DateTime first = h.state.consent!.acceptedAt;
        expect(first, h.clock.now.toUtc());
        expect(first.isUtc, isTrue);
        expect(h.state.consent!.version, 'prototype-0');

        h.clock.advance(const Duration(minutes: 5));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Schritt 3 von 5'), findsOneWidget);
        await _tapNext(tester, S.consentAccept);
        expect(h.state.consent!.acceptedAt, h.clock.now.toUtc());
        expect(h.state.consent!.acceptedAt.isAfter(first), isTrue);
        await disposeApp(tester);
      },
    );

    testWidgets(
      'UI-13: Link „Datenschutzerklärung lesen“ öffnet die Platzhalterseite',
      (WidgetTester tester) async {
        final Harness h = await _boot();
        await _pumpAtName(tester, h);
        await _advanceTo(tester, 1);
        await tester.tap(find.text(S.privacyLink));
        await tester.pumpAndSettle();
        expect(find.text(S.privacyTitle), findsOneWidget);
        expect(find.text(S.privacyPlaceholderBody), findsOneWidget);
        // Zurück-Pfeil schließt nur die Seite; Schritt 2 bleibt.
        await tester.tap(find.byTooltip(S.back));
        await tester.pumpAndSettle();
        expect(find.text(S.privacyTitle), findsNothing);
        expect(find.text('Schritt 3 von 5'), findsOneWidget);
        // Android-Zurück ebenso.
        await tester.tap(find.text(S.privacyLink));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text(S.privacyTitle), findsNothing);
        expect(find.text('Schritt 3 von 5'), findsOneWidget);
        await disposeApp(tester);
      },
    );

    testWidgets(
      'UI-14: vier Karten, Einfachauswahl, „Anderes“ mit optionalem Feld',
      (WidgetTester tester) async {
        final Harness h = await _boot();
        await _pumpAtName(tester, h);
        await _advanceTo(tester, 2);

        expect(find.byType(ChoiceCard), findsNWidgets(4));
        expect(_primary(tester).onPressed, isNull);
        await tester.tap(find.text(S.injuryAnkle));
        await tester.pump();
        expect(h.state.onboarding.injuryType, InjuryType.ankle);
        await tester.tap(find.text(S.injuryMuscle));
        await tester.pump();
        expect(h.state.onboarding.injuryType, InjuryType.muscle);
        final Iterable<ChoiceCard> selected = tester
            .widgetList<ChoiceCard>(find.byType(ChoiceCard))
            .where((ChoiceCard c) => c.selected);
        expect(selected.map((ChoiceCard c) => c.title), <String>[
          S.injuryMuscle,
        ]);
        expect(find.byType(TextField), findsNothing);

        await tester.tap(find.text(S.injuryOther));
        await tester.pump();
        expect(find.byType(TextField), findsOneWidget);
        expect(
          _primary(tester).onPressed,
          isNotNull,
          reason: 'Freitext optional',
        );
        await tester.enterText(find.byType(TextField), 'Schulter');
        await tester.pump();
        expect(h.state.onboarding.injuryOther, 'Schulter');
        await disposeApp(tester);
      },
    );

    testWidgets('UI-15: Weiter erst nach Datum, kein „Phase“', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await _pumpAtName(tester, h);
      await _advanceTo(tester, 3);
      expect(_primary(tester).onPressed, isNull);
      expect(find.textContaining('Phase'), findsNothing);
      await tester.tap(find.byType(DateCard));
      await tester.pumpAndSettle();
      // Abbrechen lässt es leer.
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(h.state.onboarding.injuryDate, isNull);
      expect(_primary(tester).onPressed, isNull);
      await disposeApp(tester);
    });

    test('A-27: Grenzen der Datumsauswahl', () {
      const LocalDay today = LocalDay(2026, 10, 7);
      DatePickerRange r = DatePickerRange.from(today: today);
      expect(r.last, DateTime(2026, 10, 7));
      expect(r.first, DateTime(2024, 10, 7));
      expect(r.initial, DateTime(2026, 10, 7));
      // Gespeichertes Datum vor der Zwei-Jahres-Grenze: erweitert die Grenze.
      r = DatePickerRange.from(today: today, saved: const LocalDay(2023, 1, 5));
      expect(r.first, DateTime(2023, 1, 5));
      expect(r.initial, DateTime(2023, 1, 5));
      // Gespeichertes Datum in der Zukunft (Uhr zurückgestellt): auf heute.
      r = DatePickerRange.from(
        today: today,
        saved: const LocalDay(2026, 12, 1),
      );
      expect(r.initial, DateTime(2026, 10, 7));
      expect(
        !r.initial.isBefore(r.first) && !r.initial.isAfter(r.last),
        isTrue,
      );
    });
  });

  group('Hinweis „noch keinen eigenen Pfad“ (SK-1)', () {
    testWidgets('Sprunggelenk, Muskelfaserriss und Anderes zeigen den Hinweis, '
        'Kreuzband nicht; Hinweis ist eine Live-Region', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle sem = tester.ensureSemantics();
      final Harness h = await _boot();
      await _pumpAtName(tester, h);
      await _advanceTo(tester, 2);
      expect(
        find.text(S.injuryNoOwnPath),
        findsNothing,
        reason: 'nichts gewählt',
      );
      expect(
        S.injuryNoOwnPath,
        'Für diese Verletzung gibt es noch keinen eigenen Pfad. Du siehst '
        'einen Beispielpfad.',
      );
      for (final String title in <String>[
        S.injuryAnkle,
        S.injuryMuscle,
        S.injuryOther,
      ]) {
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        expect(find.text(S.injuryNoOwnPath), findsOneWidget, reason: title);
        expect(
          tester.getSemantics(find.text(S.injuryNoOwnPath)),
          isSemantics(label: S.injuryNoOwnPath, isLiveRegion: true),
          reason: title,
        );
      }
      await tester.tap(find.text(S.injuryAcl));
      await tester.pumpAndSettle();
      expect(find.text(S.injuryNoOwnPath), findsNothing);
      sem.dispose();
      await disposeApp(tester);
    });
  });

  group('Hinweis sichtbar bei kleinem Fenster (SK-1 B1)', () {
    for (final double scale in <double>[1.0, 2.0]) {
      testWidgets('320×568, Textgröße ×$scale: Hinweis steht unter der '
          'gewählten Karte und liegt im Sichtfeld', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final Harness h = await _boot();
        await _pumpAtName(tester, h);
        await _advanceTo(tester, 2);
        await tester.ensureVisible(find.text(S.injuryMuscle));
        await tester.pumpAndSettle();
        await tester.tap(find.text(S.injuryMuscle));
        await tester.pumpAndSettle();
        final Rect note = tester.getRect(find.text(S.injuryNoOwnPath));
        final Rect card = tester.getRect(find.text(S.injuryMuscle));
        expect(note.top, greaterThanOrEqualTo(card.bottom));
        expect(note.top, lessThan(card.bottom + 80));
        expect(find.text(S.injuryNoOwnPath).hitTestable(), findsOneWidget);
        expect(note.bottom, lessThanOrEqualTo(568));
        expect(note.top, greaterThanOrEqualTo(0));
        await disposeApp(tester);
      });
    }
  });

  group('Fortsetzen und Zurück (UI-16, N-13)', () {
    testWidgets('jede Eingabe sofort gespeichert; Neustart setzt fort', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await _pumpAtName(tester, h);
      await _enterName(tester, 'Ja');
      expect((await h.persisted())!.onboarding.name, 'Ja');
      await _enterName(tester, 'Jakob');
      await _tapNext(tester);
      await _tapNext(tester, S.consentAccept);
      await tester.tap(find.text(S.injuryOther));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Schulter');
      await tester.pump();
      final AppState saved = (await h.persisted())!;
      expect(saved.onboarding.step, 3);
      expect(saved.onboarding.injuryType, InjuryType.other);
      expect(saved.onboarding.injuryOther, 'Schulter');
      await disposeApp(tester);

      // Neustart: neuer Controller auf demselben Speicher.
      final Harness again = await _boot(raw: h.raw);
      await pumpCura(tester, again.controller);
      expect(find.text('Schritt 4 von 5'), findsOneWidget);
      expect(find.text(S.onboardingStep3('Jakob')), findsOneWidget);
      expect(
        tester
            .widgetList<ChoiceCard>(find.byType(ChoiceCard))
            .where((ChoiceCard c) => c.selected)
            .single
            .title,
        S.injuryOther,
      );
      expect(find.text('Schulter'), findsOneWidget);
      // Zurück behält die Eingaben.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Schritt 3 von 5'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Schritt 2 von 5'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Jakob',
      );
      await disposeApp(tester);
    });

    testWidgets('Zurück je Schritt einen Schritt, auch bei sichtbarer Blase', (
      WidgetTester tester,
    ) async {
      final SystemPopRecorder pop = SystemPopRecorder(tester);
      final Harness h = await _boot();
      await _pumpAtName(tester, h);
      await _advanceTo(tester, 3);
      expect(find.byType(MannyBubble), findsOneWidget);
      for (final int expected in <int>[4, 3, 2]) {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Schritt $expected von 5'), findsOneWidget);
        // Die Blase ist da und blockiert das Zurück nicht.
        expect(find.byType(MannyBubble), findsOneWidget);
      }
      expect(pop.count, 0);
      // Von Schritt 2 zurück zur Look-Wahl (Schritt 1, ohne Blase).
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Schritt 1 von 5'), findsOneWidget);
      expect(find.byType(MannyBubble), findsNothing);
      expect(pop.count, 0);
      // Schritt 1: App schließen.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(pop.count, 1);
      expect(find.text('Schritt 1 von 5'), findsOneWidget);
      expect(h.state.onboarding.step, 0);
      await disposeApp(tester);
    });

    testWidgets('Zurück-Schaltfläche: auf jedem Schritt, geht einen Schritt', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await pumpCura(tester, h.controller);
      expect(_backButton(), findsOneWidget, reason: 'auch auf Schritt 1');
      await _tapNext(tester);
      await _advanceTo(tester, 1);
      expect(find.text('Schritt 3 von 5'), findsOneWidget);
      await tester.tap(_backButton());
      await tester.pumpAndSettle();
      expect(find.text('Schritt 2 von 5'), findsOneWidget);
      expect(h.state.onboarding.step, 1);
      await disposeApp(tester);
    });

    testWidgets('Escape schließt die Blase, die Zurück-Taste nicht', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await _pumpAtName(tester, h);
      await _advanceTo(tester, 1);
      expect(find.byType(MannyBubble), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(MannyBubble), findsNothing);
      expect(find.text('Schritt 3 von 5'), findsOneWidget);
      // Zurück geht trotz geschlossener oder offener Blase einen Schritt.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Schritt 2 von 5'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('jeder Schritt zeigt beim Betreten seine Blase erneut (A-32)', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await _pumpAtName(tester, h);
      await tester.tap(find.byTooltip(S.bubbleClose));
      await tester.pumpAndSettle();
      expect(find.byType(MannyBubble), findsNothing);
      await _advanceTo(tester, 1);
      expect(find.byType(MannyBubble), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('Mikrofon-Platzhalter (UI-16)', () {
    testWidgets('auf jedem Schritt sichtbar; Tipp zeigt den Hinweis', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await _pumpAtName(tester, h);
      for (int step = 0; step < 4; step++) {
        if (step > 0) {
          if (step == 1) await _advanceTo(tester, 1);
          if (step == 2) await _tapNext(tester, S.consentAccept);
          if (step == 3) {
            await tester.tap(find.text(S.injuryAcl));
            await tester.pump();
            await _tapNext(tester);
          }
        }
        expect(find.byType(MicButton), findsOneWidget, reason: 'Schritt $step');
        await tester.tap(find.byType(MicButton));
        await tester.pumpAndSettle();
        expect(find.text(S.micHint), findsOneWidget, reason: 'Schritt $step');
        expect(tester.takeException(), isNull);
      }
      await disposeApp(tester);
    });

    testWidgets(
      'Hinweis erscheint auch nach geschlossener Blase; Schrittwechsel setzt ihn zurück',
      (WidgetTester tester) async {
        final Harness h = await _boot();
        await _pumpAtName(tester, h);
        await tester.tap(find.byTooltip(S.bubbleClose));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(MicButton));
        await tester.pumpAndSettle();
        expect(find.text(S.micHint), findsOneWidget);
        await _enterName(tester, 'Jakob');
        await _tapNext(tester);
        expect(find.text(S.micHint), findsNothing);
        expect(find.text(S.onboardingStep2('Jakob')), findsOneWidget);
        await disposeApp(tester);
      },
    );
  });

  group('Keine Button-Gruppe im Onboarding (UI-70, UI-71)', () {
    testWidgets(
      'weder Manny-Button noch Nachrichten-Button auf Schritt 1 bis 4 und Datenschutz',
      (WidgetTester tester) async {
        final Harness h = await _boot();
        await _pumpAtName(tester, h);
        void expectNone() {
          expect(find.byType(MannyButton), findsNothing);
          expect(find.byType(FloatingNav), findsNothing);
        }

        expectNone();
        await _advanceTo(tester, 1);
        expectNone();
        await tester.tap(find.text(S.privacyLink));
        await tester.pumpAndSettle();
        expectNone();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await _tapNext(tester, S.consentAccept);
        expectNone();
        await tester.tap(find.text(S.injuryAcl));
        await tester.pump();
        await _tapNext(tester);
        expectNone();
        await disposeApp(tester);
      },
    );
  });

  group('Seitenwechsel (Brief 3.6, B-8)', () {
    Future<double> bubbleX(WidgetTester tester, String text) async =>
        tester.getTopLeft(find.text(text)).dx;

    testWidgets('vorwärts von rechts, zurück von links, 24 dp und Einblenden', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await _pumpAtName(tester, h);
      await _advanceTo(tester, 1);
      final double settled2 = await bubbleX(tester, S.onboardingStep2('Jakob'));

      await tester.tap(find.widgetWithText(PillButton, S.consentAccept));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final double mid = await bubbleX(tester, S.onboardingStep3('Jakob'));
      // Beide Seiten stehen im Baum, die neue kommt von rechts.
      expect(find.text(S.onboardingStep2('Jakob')), findsOneWidget);
      await tester.pumpAndSettle();
      final double settled3 = await bubbleX(tester, S.onboardingStep3('Jakob'));
      expect(settled3, closeTo(settled2, 0.5));
      expect(mid, greaterThan(settled3));
      expect(mid - settled3, lessThanOrEqualTo(24));
      expect(find.text(S.onboardingStep2('Jakob')), findsNothing);

      // Zurück: Gegenrichtung.
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final double midBack = await bubbleX(tester, S.onboardingStep2('Jakob'));
      await tester.pumpAndSettle();
      expect(midBack, lessThan(settled2));
      await disposeApp(tester);
    });

    testWidgets(
      'Bewegung reduzieren: Sofortwechsel, keine laufende Animation',
      (WidgetTester tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final Harness h = await _boot();
        await _pumpAtName(tester, h);
        await _enterName(tester, 'Jakob');
        await tester.tap(_next());
        await tester.pump();
        expect(find.text(S.onboardingStep1), findsNothing);
        expect(find.text(S.onboardingStep2('Jakob')), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 121));
        await tester.pump(const Duration(milliseconds: 1));
        expect(tester.binding.transientCallbackCount, 0);
        await disposeApp(tester);
      },
    );
  });

  group('Start: Löschen, unlesbare Daten, Fehler', () {
    testWidgets(
      'Alles löschen: Onboarding Schritt 1, Hinweis, nichts geschrieben, Zurück erreicht Home nicht',
      (WidgetTester tester) async {
        final SystemPopRecorder pop = SystemPopRecorder(tester);
        final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
        final Harness h = await Harness.onboarded();
        addTearDown(h.dispose);
        await pumpCura(tester, h.controller, navigatorKey: key);
        expect(find.byType(HomeShell), findsOneWidget);

        await h.controller.deleteAll();
        expect(h.controller.isDeleting, isTrue);
        AppRoutes.restartOnboarding(key.currentState!);
        await tester.pumpAndSettle();

        expect(find.byType(HomeShell), findsNothing);
        expect(find.text('Schritt 1 von 5'), findsOneWidget);
        expect(find.text(S.dataDeleted), findsOneWidget);
        // Der Look ist auf die Vorbelegung zurückgesetzt (Ergänzung 1, 6b).
        expect(h.state.mannyLook, MannyLook.brille);
        expect(find.byType(MannyLookPicker), findsOneWidget);
        // Vertrag: Schreibsperre ist nach dem Neuaufbau aufgehoben; ohne Eingabe
        // bleibt der Speicher leer (UI-51).
        expect(h.controller.isDeleting, isFalse);
        expect((h.raw as InMemoryStore).raw, isNull);
        expect(h.controller.startNotice, StartNotice.none);

        // Zurück erreicht Home nicht.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(pop.count, 1);
        expect(find.text('Schritt 1 von 5'), findsOneWidget);

        // Eingabe schreibt wieder.
        await _tapNext(tester);
        await _enterName(tester, 'Mia');
        expect((await h.persisted())!.onboarding.name, 'Mia');

        // Hinweis endet nach 4 s.
        await tester.pump(const Duration(seconds: 5));
        expect(find.text(S.dataDeleted), findsNothing);
        await disposeApp(tester);
      },
    );

    testWidgets(
      'unlesbare Daten: automatischer Neustart mit Hinweis, Speicher geleert',
      (WidgetTester tester) async {
        final CorruptStore raw = CorruptStore('{kein json');
        final Harness h = await _boot(raw: raw);
        await pumpCura(tester, h.controller);
        expect(find.text('Schritt 1 von 5'), findsOneWidget);
        expect(find.text(S.dataUnreadable), findsOneWidget);
        expect(raw.deleted, isTrue);
        expect(h.controller.startNotice, StartNotice.none);
        // Der Hinweis hat keine Aktion und endet nach 4 s.
        expect(find.byType(CuraSnackbar), findsOneWidget);
        await tester.pump(const Duration(seconds: 4, milliseconds: 500));
        expect(find.text(S.dataUnreadable), findsNothing);
        await disposeApp(tester);
      },
    );

    testWidgets('fehlendes Pflichtfeld und falsches Schema sind unlesbar', (
      WidgetTester tester,
    ) async {
      for (final String text in <String>[
        '{"schema":99,"onboarding":{"completed":false,"step":0}}',
        '{"schema":1,"onboarding":{"completed":false}}',
      ]) {
        final CorruptStore raw = CorruptStore(text);
        final Harness h = await _boot(raw: raw);
        await pumpCura(tester, h.controller);
        expect(find.text(S.dataUnreadable), findsOneWidget, reason: text);
        expect(raw.deleted, isTrue);
        await disposeApp(tester);
      }
    });

    testWidgets(
      'Plattformfehler beim Lesen: Fehlerzustand, Daten bleiben, Nochmal versuchen',
      (WidgetTester tester) async {
        final _FlakyStore raw = _FlakyStore(encodeOnboarded());
        final Harness h = await _boot(raw: raw);
        await pumpCura(tester, h.controller);

        expect(find.text(S.startLoadError), findsOneWidget);
        expect(find.text(S.pathLoadError), findsNothing, reason: 'E-4');
        expect(find.text(S.retry), findsOneWidget);
        expect(find.text('Schritt 1 von 5'), findsNothing);
        expect(raw.deletes, 0, reason: 'bei Lesefehlern nichts löschen');
        // Keine Button-Gruppe beim StartGate-Fehler (A-43).
        expect(find.byType(MannyButton), findsNothing);
        expect(find.byType(FloatingNav), findsNothing);

        await tester.tap(find.text(S.retry));
        await tester.pumpAndSettle();
        expect(find.byType(HomeShell), findsOneWidget);
        expect(h.state.onboarding.firstName, 'Jakob');
        await disposeApp(tester);
      },
    );

    testWidgets(
      'Programmierfehler (Error) beim Lesen zeigt ebenfalls den Fehlerzustand',
      (WidgetTester tester) async {
        final Harness h = await _boot(raw: FailingStore());
        await pumpCura(tester, h.controller);
        expect(find.text(S.startLoadError), findsOneWidget);
        expect(h.controller.loadStatus, LoadStatus.error);
        await disposeApp(tester);
      },
    );

    testWidgets('E-4: StartGate und Pfad-Tab haben getrennte Fehlertexte', (
      WidgetTester tester,
    ) async {
      expect(S.startLoadError, 'Deine Daten konnten nicht geladen werden.');
      expect(S.pathLoadError, 'Dein Pfad konnte nicht geladen werden.');
      await pumpApp(
        tester,
        PathErrorView(onRetry: () {}, message: S.pathLoadError),
      );
      expect(find.text(S.pathLoadError), findsOneWidget);
      expect(find.text(S.startLoadError), findsNothing);
      expect(find.text(S.retry), findsOneWidget);
    });

    testWidgets('abgeschlossenes Onboarding startet auf Home, Tab Pfad (A-1)', (
      WidgetTester tester,
    ) async {
      final Harness h = await Harness.onboarded();
      addTearDown(h.dispose);
      await pumpCura(tester, h.controller);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(
        tester.state<HomeShellState>(find.byType(HomeShell)).activeTab,
        HomeTab.path,
      );
      await disposeApp(tester);
    });

    testWidgets('Ladeansicht ohne künstliche Verzögerung (A-33)', (
      WidgetTester tester,
    ) async {
      final SlowStore raw = SlowStore();
      final Harness h = await _boot(raw: raw);
      await pumpCura(tester, h.controller, settle: false);
      await tester.pump();
      await tester.pump();
      expect(find.byType(HomeShell), findsNothing);
      expect(find.text('Schritt 1 von 5'), findsNothing);
      raw.release();
      await tester.pumpAndSettle();
      expect(find.text('Schritt 1 von 5'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('Tastatur auf 320 × 568 (B-10, UI-34)', () {
    testWidgets('Primärbutton und fokussiertes Feld bleiben sichtbar', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await _pumpAtName(tester, h, size: Viewports.small);
      // Erst antippen, dann erscheint die Tastatur (wie auf dem Gerät).
      await tester.tap(find.byType(TextField));
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();

      const double keyboardTop = 568 - 300;
      final Rect button = tester.getRect(_next());
      final Rect field = tester.getRect(find.byType(TextField));
      expect(button.bottom, lessThanOrEqualTo(keyboardTop));
      expect(button.top, greaterThanOrEqualTo(0));
      expect(field.bottom, lessThan(button.top));
      expect(field.top, greaterThan(0));
      // Mikrofon bleibt erreichbar.
      expect(find.byType(MicButton), findsOneWidget);
      expect(
        tester.getRect(find.byType(MicButton)).bottom,
        lessThanOrEqualTo(keyboardTop),
      );
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('Große Schrift und Tastatur auf 320 × 568 (A-U3 B1)', () {
    Future<void> openKeyboard(WidgetTester tester) async {
      // Bei 200 % liegt das Feld zunächst außerhalb: wie der Nutzer scrollen.
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
    }

    testWidgets('200 % mit Tastatur: Kopf läuft in der Scrollfläche mit, das '
        'fokussierte Feld ist sichtbar, Weiter-Leiste kompakt', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpAtName(tester, h, size: Viewports.small);
      await openKeyboard(tester);
      const double keyboardTop = 568 - 300;
      final Rect field = tester.getRect(find.byType(TextField));
      expect(field.top, greaterThanOrEqualTo(0));
      expect(field.bottom, lessThanOrEqualTo(keyboardTop));
      final Rect button = tester.getRect(_next());
      expect(field.bottom, lessThanOrEqualTo(button.top));
      // Der Fortschrittstext steht in der Scrollfläche, nicht fest oben.
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.text('Schritt 2 von 5'),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('Tastatur auf/zu ändert den Zustand des Feldes nicht (Text, '
        'Fokus bleiben, wenn der Kopf wechselt)', (WidgetTester tester) async {
      final Harness h = await _boot();
      await _pumpAtName(tester, h, size: Viewports.small);
      await _enterName(tester, 'Jakob');
      await tester.showKeyboard(find.byType(TextField));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      // 568 - 300 = 268 dp < 400 dp: der Kopf ist in die Scrollfläche gewandert.
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Jakob',
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus ??
            FocusManager.instance.primaryFocus != null,
        isTrue,
      );
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Jakob',
      );
      await disposeApp(tester);
    });

    testWidgets('Der Text „Noch etwas hinzufügen?“ bleibt erreichbar (am Ende '
        'der Scrollfläche), wenn die Leiste kompakt ist', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpAtName(tester, h, size: Viewports.small);
      expect(find.text(S.moreToAdd, skipOffstage: false), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('Weiter-Leiste bei großer Schrift (A-U3-RR R1)', () {
    /// Der Text des Primärbuttons bricht nur an Wortgrenzen: das längste Wort
    /// passt in die Breite, die der Absatz bekommt.
    void expectWholeWords(WidgetTester tester, String label) {
      final RenderParagraph p = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(PillButton),
          matching: find.text(label),
        ),
      );
      final TextStyle style = p.text.style!;
      final TextScaler scaler = p.textScaler;
      double longest = 0;
      for (final String word in label.split(' ')) {
        final TextPainter tp = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout();
        if (tp.width > longest) longest = tp.width;
        tp.dispose();
      }
      expect(
        p.constraints.maxWidth,
        greaterThanOrEqualTo(longest - 0.5),
        reason: '„$label“ bricht mitten im Wort',
      );
    }

    testWidgets('320 × 568, 200 %, Schritt 2: „Verstanden, weiter“ bricht nur '
        'an Wortgrenzen; das Mikrofon steht in der Scrollfläche', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpAtName(tester, h, size: Viewports.small);
      await _enterName(tester, 'Jakob');
      await tester.ensureVisible(_next());
      await tester.tap(_next());
      await tester.pumpAndSettle();
      expect(find.text('Schritt 3 von 5'), findsOneWidget);
      expectWholeWords(tester, S.consentAccept);
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(MicButton),
          skipOffstage: false,
        ),
        findsOneWidget,
        reason: 'Mikrofon neben „Noch etwas hinzufügen?“ in der Scrollfläche',
      );
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('320 × 568, 200 %: „Weiter“ in der Leiste, „Zurück“ am Ende '
        'des Inhalts, beide erreichbar', (WidgetTester tester) async {
      final Harness h = await _boot();
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpAtName(tester, h, size: Viewports.small);
      await _enterName(tester, 'Jakob');
      expect(_next().hitTestable(), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: _backButton(),
          skipOffstage: false,
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(_backButton());
      await tester.pumpAndSettle();
      expect(_backButton().hitTestable(), findsOneWidget);
      expectWholeWords(tester, S.next);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('390 × 844, 100 %: „Zurück“ links (mindestens 112 dp), 12 dp '
        'Abstand zu „Weiter“', (WidgetTester tester) async {
      final Harness h = await _boot();
      await pumpCura(tester, h.controller);
      final Rect next = tester.getRect(_next());
      final Rect back = tester.getRect(_backButton());
      expect(back.width, greaterThanOrEqualTo(112));
      expect(back.right, lessThan(next.left));
      expect(next.left - back.right, closeTo(12, 0.5));
      expect(next.height, greaterThanOrEqualTo(56));
      await disposeApp(tester);
    });
  });

  group('Kopf-Karte (Brief v2, V2-5)', () {
    testWidgets('Fortschritt und Titel stehen auf der Kopf-Karte; die '
        'Datenschutzseite hat Zurück-Pfeil und Titel auf der Kopf-Karte', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await _pumpAtName(tester, h);
      expect(
        find.descendant(
          of: find.byType(HeaderCard),
          matching: find.text(S.onboardingTitleName),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(HeaderCard),
          matching: find.byType(StepProgress),
        ),
        findsOneWidget,
      );
      await _advanceTo(tester, 1);
      await tester.tap(find.text(S.privacyLink));
      await tester.pumpAndSettle();
      // Wie alle Seiten: Zurück-Pfeil und Titel auf der Kopf-Karte.
      expect(
        find.descendant(
          of: find.byType(HeaderCard),
          matching: find.byType(HeaderIconButton),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(HeaderCard),
          matching: find.text(S.privacyTitle),
        ),
        findsOneWidget,
      );
      expect(find.text(S.privacyPlaceholderBody), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('Look-Schritt (Ergänzung 1, 6a, V2-65 bis V2-67, V2-75)', () {
    testWidgets('Schritt 1 von 5, zwei Karten, „Mit Brille“ vorgewählt, Weiter '
        'aktiv, keine Figur, keine Blase, kein Mikrofon', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle sem = tester.ensureSemantics();
      final Harness h = await _boot();
      await pumpCura(tester, h.controller);
      expect(find.text('Schritt 1 von 5'), findsOneWidget);
      expect(find.text(S.onboardingTitleLook), findsOneWidget);
      expect(find.text(S.mannyLookWith), findsOneWidget);
      expect(find.text(S.mannyLookWithout), findsOneWidget);
      expect(find.text(S.mannyLookSelected), findsOneWidget);
      expect(find.text(S.mannyLookHint), findsOneWidget);
      expect(h.state.mannyLook, MannyLook.brille);
      expect(_next(), findsOneWidget);
      expect(tester.widget<PillButton>(_next()).onPressed, isNotNull);
      expect(find.byType(MannyBubble), findsNothing);
      expect(find.byType(MicButton), findsNothing);
      expect(
        find.bySemanticsLabel('Manny mit Brille, ausgewählt, 1 von 2'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Manny ohne Brille, nicht ausgewählt, 2 von 2'),
        findsOneWidget,
      );
      sem.dispose();
      await disposeApp(tester);
    });

    testWidgets('Wahl „Ohne Brille“: sofort gespeichert, Name-Schritt zeigt '
        'Manny ohne Brille, Zurück behält die Wahl, Neustart ebenso', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await pumpCura(tester, h.controller);
      await tester.tap(find.text(S.mannyLookWithout));
      await tester.pumpAndSettle();
      expect(h.state.mannyLook, MannyLook.ohne);
      expect((await h.persisted())!.mannyLook, MannyLook.ohne);
      await _tapNext(tester);
      expect(find.text('Schritt 2 von 5'), findsOneWidget);
      final Finder img = find.descendant(
        of: find.byType(MannyIllustration),
        matching: find.byType(Image),
      );
      final AssetBundleImageKey key =
          (await tester.runAsync(
                () => tester
                    .widget<Image>(img.first)
                    .image
                    .obtainKey(
                      createLocalImageConfiguration(tester.element(img.first)),
                    ),
              ))!
              as AssetBundleImageKey;
      expect(key.name, startsWith('assets/manny/ohne/'));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Schritt 1 von 5'), findsOneWidget);
      expect(
        tester.widget<MannyLookPicker>(find.byType(MannyLookPicker)).value,
        MannyLook.ohne,
      );
      await disposeApp(tester);

      final Harness again = await _boot(raw: h.raw);
      await pumpCura(tester, again.controller);
      expect(
        tester.widget<MannyLookPicker>(find.byType(MannyLookPicker)).value,
        MannyLook.ohne,
      );
      await disposeApp(tester);
    });

    for (final double scale in <double>[1.0, 2.0]) {
      testWidgets('320 × 568, ×$scale: Karten (untereinander ab 200 %), '
          'Weiter und Zurück erreichbar, kein Überlauf', (
        WidgetTester tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final Harness h = await _boot();
        await pumpCura(tester, h.controller, size: Viewports.small);
        final Rect a = tester.getRect(find.text(S.mannyLookWith));
        final Rect b = tester.getRect(find.text(S.mannyLookWithout));
        // Bei Breite < 360 dp stehen die Karten immer untereinander.
        expect(b.top, greaterThan(a.bottom));
        expect(_next().hitTestable(), findsOneWidget);
        await tester.ensureVisible(_backButton());
        await tester.pumpAndSettle();
        expect(_backButton().hitTestable(), findsOneWidget);
        await tester.ensureVisible(find.text(S.mannyLookHint));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }

    testWidgets('Bewegung reduzieren: Wechsel ohne laufende Animation', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final Harness h = await _boot();
      await pumpCura(tester, h.controller);
      await tester.tap(find.text(S.mannyLookWithout));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 121));
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
      await disposeApp(tester);
    });
  });

  group('Manny im Onboarding (A-U3 B5)', () {
    testWidgets('768 × 1024: Manny steht linksbündig zur Inhaltsspalte '
        '(Kante des Namensfeldes)', (WidgetTester tester) async {
      final Harness h = await _boot();
      await _pumpAtName(tester, h, size: Viewports.tablet);
      final double manny = tester.getTopLeft(find.byType(MannyIllustration)).dx;
      final double field = tester.getTopLeft(find.byType(TextField)).dx;
      expect(manny, closeTo(field, 0.5));
      await disposeApp(tester);
    });
  });
}

/// Speicher, dessen erster Lesezugriff scheitert (Plattformfehler), danach
/// funktioniert er.
class _FlakyStore extends InMemoryStore {
  _FlakyStore(super.initial);

  bool _failed = false;

  @override
  Future<String?> read() async {
    if (!_failed) {
      _failed = true;
      throw StateError('Plattformfehler beim Lesen');
    }
    return super.read();
  }
}

String encodeOnboarded() => encodeDocument(onboardedState());
