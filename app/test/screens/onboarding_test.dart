// Onboarding (U2b, Plan 4.1 bis 4.3, UI-11 bis UI-16, UI-33/34, UI-70/71):
// Ablauf der vier Schritte, Speichern jeder Eingabe, Fortsetzen nach Neustart,
// Zurück je Schritt, Mikrofon-Hinweis, Hinweise nach Löschen und unlesbaren
// Daten, Fehlerzustand beim Start, Tastatur auf 320 × 568.
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/injury_type.dart';
import 'package:curaone/logic/migrations.dart' show encodeDocument;
import 'package:curaone/state/app_controller.dart';
import 'package:curaone/ui/components/action_cluster.dart';
import 'package:curaone/ui/components/choice_card.dart';
import 'package:curaone/ui/components/cura_snackbar.dart';
import 'package:curaone/ui/components/date_card.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
import 'package:curaone/ui/components/manny_chat_button.dart';
import 'package:curaone/ui/components/messages_button.dart';
import 'package:curaone/ui/components/mic_button.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:curaone/ui/home/home_shell.dart';
import 'package:curaone/ui/onboarding/step4_date.dart';
import 'package:curaone/ui/routes/app_routes.dart';
import 'package:flutter/material.dart';
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

Future<void> _enterName(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextField), name);
  await tester.pump();
}

Future<void> _tapNext(WidgetTester tester, [String label = S.next]) async {
  await tester.tap(find.widgetWithText(PillButton, label));
  await tester.pumpAndSettle();
}

/// Bis Schritt [index] (0 … 3) mit Name Jakob, Einwilligung und ACL.
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
      await pumpCura(tester, h.controller);

      expect(find.text('Schritt 1 von 4'), findsOneWidget);
      expect(find.text(S.onboardingStep1), findsOneWidget);

      await _enterName(tester, 'Jakob');
      await _tapNext(tester);
      expect(find.text('Schritt 2 von 4'), findsOneWidget);
      expect(find.text(S.onboardingStep2('Jakob')), findsOneWidget);

      await _tapNext(tester, S.consentAccept);
      expect(find.text('Schritt 3 von 4'), findsOneWidget);
      expect(find.text(S.onboardingStep3('Jakob')), findsOneWidget);

      await tester.tap(find.text(S.injuryAcl));
      await tester.pump();
      await _tapNext(tester);
      expect(find.text('Schritt 4 von 4'), findsOneWidget);
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
      expect(find.text('Schritt 4 von 4'), findsNothing);
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
      await pumpCura(tester, h.controller);
      expect(
        tester.getSemantics(find.text('Schritt 1 von 4')).label,
        'Schritt 1 von 4',
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
      await pumpCura(tester, h.controller);
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
        await pumpCura(tester, h.controller);
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
        expect(find.text('Schritt 2 von 4'), findsOneWidget);
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
        await pumpCura(tester, h.controller);
        await _advanceTo(tester, 1);
        await tester.tap(find.text(S.privacyLink));
        await tester.pumpAndSettle();
        expect(find.text(S.privacyTitle), findsOneWidget);
        expect(find.text(S.privacyPlaceholderBody), findsOneWidget);
        // Zurück-Pfeil schließt nur die Seite; Schritt 2 bleibt.
        await tester.tap(find.byTooltip(S.back));
        await tester.pumpAndSettle();
        expect(find.text(S.privacyTitle), findsNothing);
        expect(find.text('Schritt 2 von 4'), findsOneWidget);
        // Android-Zurück ebenso.
        await tester.tap(find.text(S.privacyLink));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text(S.privacyTitle), findsNothing);
        expect(find.text('Schritt 2 von 4'), findsOneWidget);
        await disposeApp(tester);
      },
    );

    testWidgets(
      'UI-14: vier Karten, Einfachauswahl, „Anderes“ mit optionalem Feld',
      (WidgetTester tester) async {
        final Harness h = await _boot();
        await pumpCura(tester, h.controller);
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
      await pumpCura(tester, h.controller);
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

  group('Fortsetzen und Zurück (UI-16, N-13)', () {
    testWidgets('jede Eingabe sofort gespeichert; Neustart setzt fort', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await pumpCura(tester, h.controller);
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
      expect(saved.onboarding.step, 2);
      expect(saved.onboarding.injuryType, InjuryType.other);
      expect(saved.onboarding.injuryOther, 'Schulter');
      await disposeApp(tester);

      // Neustart: neuer Controller auf demselben Speicher.
      final Harness again = await _boot(raw: h.raw);
      await pumpCura(tester, again.controller);
      expect(find.text('Schritt 3 von 4'), findsOneWidget);
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
      expect(find.text('Schritt 2 von 4'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Schritt 1 von 4'), findsOneWidget);
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
      await pumpCura(tester, h.controller);
      await _advanceTo(tester, 3);
      expect(find.byType(MannyBubble), findsOneWidget);
      for (final int expected in <int>[3, 2, 1]) {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Schritt $expected von 4'), findsOneWidget);
        // Die Blase ist da und blockiert das Zurück nicht.
        expect(find.byType(MannyBubble), findsOneWidget);
      }
      expect(pop.count, 0);
      // Schritt 1: App schließen.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(pop.count, 1);
      expect(find.text('Schritt 1 von 4'), findsOneWidget);
      expect(h.state.onboarding.step, 0);
      await disposeApp(tester);
    });

    testWidgets('Zurück-Pfeil: erst ab Schritt 2, geht einen Schritt zurück', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await pumpCura(tester, h.controller);
      expect(find.byTooltip(S.back), findsNothing);
      await _advanceTo(tester, 1);
      await tester.tap(find.byTooltip(S.back));
      await tester.pumpAndSettle();
      expect(find.text('Schritt 1 von 4'), findsOneWidget);
      expect(h.state.onboarding.step, 0);
      await disposeApp(tester);
    });

    testWidgets('Escape schließt die Blase, die Zurück-Taste nicht', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await pumpCura(tester, h.controller);
      await _advanceTo(tester, 1);
      expect(find.byType(MannyBubble), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(MannyBubble), findsNothing);
      expect(find.text('Schritt 2 von 4'), findsOneWidget);
      // Zurück geht trotz geschlossener oder offener Blase einen Schritt.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Schritt 1 von 4'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('jeder Schritt zeigt beim Betreten seine Blase erneut (A-32)', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await pumpCura(tester, h.controller);
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
      await pumpCura(tester, h.controller);
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
        await pumpCura(tester, h.controller);
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
        await pumpCura(tester, h.controller);
        void expectNone() {
          expect(find.byType(MannyChatButton), findsNothing);
          expect(find.byType(MessagesButton), findsNothing);
          expect(find.byType(ActionCluster), findsNothing);
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
      await pumpCura(tester, h.controller);
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
        await pumpCura(tester, h.controller);
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
        expect(find.text('Schritt 1 von 4'), findsOneWidget);
        expect(find.text(S.dataDeleted), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
        // Vertrag: Schreibsperre ist nach dem Neuaufbau aufgehoben; ohne Eingabe
        // bleibt der Speicher leer (UI-51).
        expect(h.controller.isDeleting, isFalse);
        expect((h.raw as InMemoryStore).raw, isNull);
        expect(h.controller.startNotice, StartNotice.none);

        // Zurück erreicht Home nicht.
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(pop.count, 1);
        expect(find.text('Schritt 1 von 4'), findsOneWidget);

        // Eingabe schreibt wieder.
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
        expect(find.text('Schritt 1 von 4'), findsOneWidget);
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

        expect(find.text(S.pathLoadError), findsOneWidget);
        expect(find.text(S.retry), findsOneWidget);
        expect(find.text('Schritt 1 von 4'), findsNothing);
        expect(raw.deletes, 0, reason: 'bei Lesefehlern nichts löschen');
        // Keine Button-Gruppe beim StartGate-Fehler (A-43).
        expect(find.byType(MannyChatButton), findsNothing);
        expect(find.byType(MessagesButton), findsNothing);

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
        expect(find.text(S.pathLoadError), findsOneWidget);
        expect(h.controller.loadStatus, LoadStatus.error);
        await disposeApp(tester);
      },
    );

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
      expect(find.text('Schritt 1 von 4'), findsNothing);
      raw.release();
      await tester.pumpAndSettle();
      expect(find.text('Schritt 1 von 4'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('Tastatur auf 320 × 568 (B-10, UI-34)', () {
    testWidgets('Primärbutton und fokussiertes Feld bleiben sichtbar', (
      WidgetTester tester,
    ) async {
      final Harness h = await _boot();
      await pumpCura(tester, h.controller, size: Viewports.small);
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
