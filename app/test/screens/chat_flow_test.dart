// Manny-Chat, Nachrichten und Beispiel-Chats im Ablauf der echten App (U2c,
// Ergänzung 2, UI-70 bis UI-72, UI-76 bis UI-82, UI-86, UI-89, A-38, A-39):
// Button-Gruppe auf dem Pfad, Öffnen, Zurück, Escape, Fokusrückgabe, Tageswechsel
// bei offenem Chat, Rückgängig-Fenster, Speicherfreiheit, Tab-Reihenfolge.
import 'dart:convert';

import 'package:curaone/data/manny_chat_source.dart';
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/chat_model.dart';
import 'package:curaone/logic/manny_occasions.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/ui/chat/manny_chat_screen.dart';
import 'package:curaone/ui/components/action_cluster.dart';
import 'package:curaone/ui/components/chat_composer.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/components/glass_card.dart';
import 'package:curaone/ui/components/header_icon_button.dart';
import 'package:curaone/ui/components/manny_chat_button.dart';
import 'package:curaone/ui/components/messages_button.dart';
import 'package:curaone/ui/components/opaque_surface.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:curaone/ui/home/home_shell.dart';
import 'package:curaone/ui/messages/chat_bubble.dart';
import 'package:curaone/ui/messages/contact_row.dart';
import 'package:curaone/ui/messages/example_chat_screen.dart';
import 'package:curaone/ui/messages/example_contacts.dart';
import 'package:curaone/ui/messages/messages_screen.dart';
import 'package:curaone/ui/routes/app_routes.dart';
import 'package:curaone/ui/routes/cura_sheet_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/controller_harness.dart';
import '../support/pump_app.dart';
import '../support/stores.dart';

Future<Harness> _home(
  WidgetTester tester, {
  MannyChatSource? source,
  Size size = Viewports.phone,
}) async {
  final Harness h = await Harness.onboarded();
  addTearDown(h.dispose);
  await pumpCura(tester, h.controller, chatSource: source, size: size);
  return h;
}

/// Auch bei verdeckter Home-Route (Vollbild-Route darüber).
HomeShellState _shell(WidgetTester tester) =>
    tester.state<HomeShellState>(find.byType(HomeShell, skipOffstage: false));

/// Alle Labels des Semantik-Baums (nur, was der Screenreader erreicht).
Set<String> _semanticLabels(WidgetTester tester) {
  final Set<String> out = <String>{};
  void walk(SemanticsNode n) {
    final String label = n.getSemanticsData().label;
    if (label.isNotEmpty) out.add(label);
    n.visitChildren((SemanticsNode c) {
      walk(c);
      return true;
    });
  }

  walk(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return out;
}

Finder _navEntry(String label) =>
    find.descendant(of: find.byType(FloatingNav), matching: find.text(label));

Future<void> _openChat(WidgetTester tester) async {
  await tester.tap(find.byType(MannyChatButton));
  await tester.pumpAndSettle();
}

Future<void> _openMessages(WidgetTester tester) async {
  await tester.tap(find.byType(MessagesButton));
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

/// Liegt der Primärfokus innerhalb von [within]?
bool _focusInside(Finder within) {
  final BuildContext? ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  final Set<Element> targets = within.evaluate().toSet();
  bool inside = false;
  ctx.visitAncestorElements((Element e) {
    if (targets.contains(e)) {
      inside = true;
      return false;
    }
    return true;
  });
  return inside;
}

ExampleContact _contact(String id) =>
    kExampleContacts.firstWhere((ExampleContact c) => c.id == id);

Finder _row(ExampleContact c) => find.byWidgetPredicate(
  (Widget w) => w is ContactRow && w.contact.id == c.id,
);

void main() {
  group('Button-Gruppe auf dem Pfad (UI-70 bis UI-72, Plan 4.6)', () {
    testWidgets('Manny-Button 56 dp, Nachrichten-Button 48 dp, rechts 16 dp, '
        'Manny 16 dp über der Nav, Nachrichten 8 dp darüber, rechtsbündig', (
      WidgetTester tester,
    ) async {
      await _home(tester);
      final BuildContext context = tester.element(find.byType(HomeShell));
      final double navTop =
          tester.view.physicalSize.height - FloatingNav.occupiedHeight(context);
      final Rect manny = tester.getRect(find.byType(MannyChatButton));
      final Rect messages = tester.getRect(find.byType(MessagesButton));
      expect(manny.size, const Size(56, 56));
      expect(messages.size, const Size(48, 48));
      expect(manny.right, 390 - 16);
      expect(messages.right, manny.right);
      expect(manny.bottom, navTop - 16);
      expect(manny.top - messages.bottom, 8);
      // Nav und Gruppe überschneiden sich nicht.
      expect(
        manny.bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(FloatingNav)).top),
      );
      // Tooltips und Labels.
      expect(find.byTooltip(S.mannyChatOpen), findsOneWidget);
      expect(find.byTooltip(S.messagesButton), findsOneWidget);
      // Das Rechteck der Gruppe steht für Blase und Hinweis bereit.
      final Rect? cluster = ActionCluster.rectOf(_shell(tester).clusterKey);
      expect(cluster, isNotNull);
      expect(cluster!.contains(manny.center), isTrue);
      expect(cluster.contains(messages.center), isTrue);
      await disposeApp(tester);
    });

    testWidgets('Manny-Button öffnet den Manny-Chat, Nachrichten-Button die '
        'Nachrichten; der Tab bleibt', (WidgetTester tester) async {
      await _home(tester);
      await _openChat(tester);
      expect(find.byType(MannyChatScreen), findsOneWidget);
      expect(_shell(tester).activeTab, HomeTab.path);
      await _back(tester);
      expect(find.byType(MannyChatScreen), findsNothing);
      await _openMessages(tester);
      expect(find.byType(MessagesScreen), findsOneWidget);
      await _back(tester);
      expect(find.byType(MessagesScreen), findsNothing);
      expect(_shell(tester).activeTab, HomeTab.path);
      await disposeApp(tester);
    });

    testWidgets('Enter und Leertaste lösen aus (Tastaturfokus)', (
      WidgetTester tester,
    ) async {
      await _home(tester);
      _shell(tester).chatButtonFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(MannyChatScreen), findsOneWidget);
      await _back(tester);
      _shell(tester).messagesButtonFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byType(MessagesScreen), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('unter einem Sheet: weder Semantik noch Fokus noch Tipp '
        '(UI-70)', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _home(tester);
      expect(find.bySemanticsLabel(S.mannyChatOpen), findsOneWidget);
      expect(find.bySemanticsLabel(S.messagesButton), findsOneWidget);

      final BuildContext context = tester.element(find.byType(HomeShell));
      Navigator.of(context).push<void>(
        CuraSheetRoute<void>(
          context: context,
          routeLabel: 'Test',
          builder: (BuildContext context) => const CuraSheetFrame(
            header: SizedBox(height: 56, child: Text('Sheet')),
            body: SizedBox(height: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Die Gruppe bleibt sichtbar (unter dem Scrim), ist aber nicht bedienbar.
      expect(find.byType(MannyChatButton), findsOneWidget);
      expect(_semanticLabels(tester), isNot(contains(S.mannyChatOpen)));
      expect(_semanticLabels(tester), isNot(contains(S.messagesButton)));
      // Tastatur: Tab bleibt im Sheet.
      for (int i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_focusInside(find.byType(MannyChatButton)), isFalse);
        expect(_focusInside(find.byType(MessagesButton)), isFalse);
      }
      // Tipp auf die Stelle der Gruppe trifft den Scrim, nicht den Button.
      await tester.tapAt(tester.getCenter(find.byType(MannyChatButton)));
      await tester.pumpAndSettle();
      expect(find.byType(MannyChatScreen), findsNothing);
      h.dispose();
      await disposeApp(tester);
    });

    testWidgets('Tab-Reihenfolge Pfad: Nachrichten-Button, Manny-Button, Nav '
        '(UI-89)', (WidgetTester tester) async {
      await _home(tester);
      final List<String> seen = <String>[];
      for (int i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        if (_focusInside(find.byType(MessagesButton))) {
          seen.add('messages');
        } else if (_focusInside(find.byType(MannyChatButton))) {
          seen.add('chat');
        } else if (_focusInside(find.byType(FloatingNav))) {
          seen.add('nav');
        } else {
          seen.add('?');
        }
      }
      expect(seen.take(3), <String>[
        'messages',
        'chat',
        'nav',
      ], reason: '$seen');
      await disposeApp(tester);
    });
  });

  group('Manny-Chat (UI-76 bis UI-78, UI-81)', () {
    testWidgets('Kopf, Karte, Beispielverlauf mit dem Namen aus dem '
        'Onboarding, Hinweiszeile, Leiste, Disclaimer', (
      WidgetTester tester,
    ) async {
      await _home(tester);
      await _openChat(tester);
      expect(find.text('Manny'), findsOneWidget);
      expect(find.text('Dein Reha-Begleiter'), findsOneWidget);
      expect(find.text('BEISPIELVERLAUF'), findsOneWidget);
      expect(find.text('So sieht dein Chat bald aus.'), findsOneWidget);
      expect(find.text('Moin Jakob. Wie läuft dein Tag?'), findsOneWidget);
      expect(find.text('Ich hab heute keine Zeit.'), findsOneWidget);
      expect(
        find.text(
          'Dann machen wir die 10-Minuten-Variante. Das schaffst du. '
          'Sag mir kurz Bescheid, wenn du durch bist.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Schreiben kann ich bald, heute noch nicht.'),
        findsOneWidget,
      );
      expect(find.text('Schreib Manny'), findsOneWidget);
      expect(
        find.text('Manny ersetzt keine medizinische Beratung.'),
        findsOneWidget,
      );
      // UI-78: kein Mikrofon, kein „Neuer Chat“, kein Menü, keine Chips.
      expect(find.byIcon(Icons.mic_none_rounded), findsNothing);
      expect(find.textContaining('Neuer Chat'), findsNothing);
      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);
      expect(find.byType(ActionChip), findsNothing);
      // Keine Nav, keine Button-Gruppe, kein Blur (UI-85).
      expect(find.byType(FloatingNav), findsNothing);
      expect(find.byType(MannyChatButton), findsNothing);
      expect(find.byType(MessagesButton), findsNothing);
      expect(find.byType(BackdropFilter), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('Nachrichten kommen aus der Quelle (ChatMessage-Objekte)', (
      WidgetTester tester,
    ) async {
      await _home(tester, source: _FakeSource());
      await _openChat(tester);
      expect(find.text('Quelle für Jakob'), findsOneWidget);
      expect(find.text('Antwort aus der Quelle'), findsOneWidget);
      expect(find.text('Moin Jakob. Wie läuft dein Tag?'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('Tipp auf die Leiste öffnet keine Tastatur und ändert nichts', (
      WidgetTester tester,
    ) async {
      final Harness h = await _home(tester);
      final AppState before = h.state;
      await _openChat(tester);
      await tester.tap(find.byType(ChatComposer));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(find.byType(TextField), findsNothing);
      expect(h.state, before);
      await disposeApp(tester);
    });

    testWidgets('Routenname, Semantik der Nachrichten und der Leiste (UI-89)', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _home(tester);
      await _openChat(tester);
      expect(find.bySemanticsLabel('Manny, Chat'), findsWidgets);
      expect(
        find.bySemanticsLabel('Manny: Moin Jakob. Wie läuft dein Tag?'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Du: Ich hab heute keine Zeit.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Nachricht an Manny, noch nicht verfügbar'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Senden, noch nicht verfügbar'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(S.chatDisclaimer), findsOneWidget);
      expect(find.bySemanticsLabel(S.chatHint), findsOneWidget);
      h.dispose();
      await disposeApp(tester);
    });

    testWidgets('Tab-Reihenfolge Chat: nur Zurück (Verlauf lesend)', (
      WidgetTester tester,
    ) async {
      await _home(tester);
      await _openChat(tester);
      // Anfangsfokus: der Zurück-Pfeil.
      expect(_focusInside(find.byType(HeaderIconButton)), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.byType(MannyChatScreen), findsOneWidget);
      // Weitere Fokusziele gibt es nicht: Tab bleibt beim Zurück-Pfeil.
      expect(_focusInside(find.byType(HeaderIconButton)), isTrue);
      await disposeApp(tester);
    });

    testWidgets('320 × 568 und 200 %: nichts abgeschnitten, Leiste und '
        'Disclaimer erreichbar', (WidgetTester tester) async {
      final Harness h = await Harness.onboarded();
      addTearDown(h.dispose);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpCura(tester, h.controller, size: Viewports.small);
      await _openChat(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(ChatComposer), findsOneWidget);
      // Der Disclaimer ist am Listenende erreichbar.
      await tester.scrollUntilVisible(
        find.text(S.chatDisclaimer),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(S.chatDisclaimer), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('beim Öffnen ist die erste Nachricht sichtbar (K6, UI-76, UI-88)', () {
    /// Erste Nachricht im Sichtfenster der Liste: ganz, oder (höher als das
    /// Fenster) mit ihrem Anfang.
    void expectVisibleInList(WidgetTester tester, Finder message, String why) {
      expect(message, findsOneWidget, reason: why);
      final Rect list = tester.getRect(find.byType(ListView).first);
      final Rect r = tester.getRect(message);
      expect(r.top, greaterThanOrEqualTo(list.top - 0.5), reason: why);
      expect(r.top, lessThan(list.bottom), reason: why);
      if (r.height <= list.height) {
        expect(r.bottom, lessThanOrEqualTo(list.bottom + 0.5), reason: why);
      }
    }

    final List<(Size, double)> cases = <(Size, double)>[
      (Viewports.small, 2),
      (const Size(568, 320), 1),
      (const Size(568, 320), 2),
    ];

    for (final (Size size, double scale) in cases) {
      testWidgets('Manny-Chat ${size.width.toInt()}x${size.height.toInt()} '
          '×$scale: Karte steht in der Liste, erste Nachricht sichtbar', (
        WidgetTester tester,
      ) async {
        final Harness h = await Harness.onboarded();
        addTearDown(h.dispose);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpCura(tester, h.controller, size: size);
        await _openChat(tester);
        expect(tester.takeException(), isNull);
        final String first = const ExampleMannyChatSource()
            .messages('Jakob')
            .first
            .text;
        expectVisibleInList(
          tester,
          find.text(first, findRichText: true),
          'erste Manny-Nachricht',
        );
        // Weiter oben: die Karte ist durch Hochscrollen erreichbar.
        final ScrollPosition p = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        p.jumpTo(0);
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(ListView),
            matching: find.text(S.chatNoticeText),
          ),
          findsOneWidget,
          reason: 'Karte ist erstes Listenelement',
        );
        await disposeApp(tester);
      });

      testWidgets('Beispiel-Chat ${size.width.toInt()}x${size.height.toInt()} '
          '×$scale: erste Nachricht sichtbar', (WidgetTester tester) async {
        final Harness h = await Harness.onboarded();
        addTearDown(h.dispose);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpCura(tester, h.controller, size: size);
        await _openMessages(tester);
        final ExampleContact c = _contact('physio-mueller');
        await tester.scrollUntilVisible(
          _row(c),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(_row(c));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final String first = c.lines('Jakob').first.text;
        expectVisibleInList(
          tester,
          find.ancestor(
            of: find.text(first, findRichText: true),
            matching: find.byType(ChatBubble),
          ),
          'erste Nachricht des Beispiel-Chats',
        );
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(ListView),
            matching: find.text(S.exampleChatNotice),
          ),
          findsOneWidget,
          reason: 'Karte ist erstes Listenelement',
        );
        await disposeApp(tester);
      });
    }

    testWidgets('390 × 844 ×1,0: Karte bleibt fest, das Ende steht sichtbar', (
      WidgetTester tester,
    ) async {
      final Harness h = await Harness.onboarded();
      addTearDown(h.dispose);
      await pumpCura(tester, h.controller);
      await _openChat(tester);
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text(S.chatNoticeText),
        ),
        findsNothing,
      );
      expect(find.text(S.chatNoticeText), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('Nachrichten und Beispiel-Chats (UI-79, UI-80)', () {
    testWidgets('Kopf, Karte, vier Abschnitte als Überschriften, sechs '
        'Kontakte, kein Badge, keine Suche', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _home(tester);
      await _openMessages(tester);
      expect(find.text('Nachrichten'), findsOneWidget);
      expect(
        find.text('Beispiel-Ansicht. Echte Chats folgen.'),
        findsOneWidget,
      );
      for (final String s in <String>[
        'PHYSIO',
        'FAMILIE',
        'FREUNDE',
        'ÄRZTE',
      ]) {
        expect(find.text(s), findsOneWidget);
      }
      for (final String s in <String>[
        'Physio',
        'Familie',
        'Freunde',
        'Ärzte',
      ]) {
        expect(
          tester
              .getSemantics(find.bySemanticsLabel(s))
              .getSemanticsData()
              .flagsCollection
              .isHeader,
          isTrue,
          reason: 'Überschrift $s',
        );
      }
      expect(find.byType(ContactRow), findsNWidgets(6));
      for (final ExampleContact c in kExampleContacts) {
        expect(find.text(c.name), findsOneWidget);
        expect(find.text(c.dayShort()), findsWidgets);
        expect(
          find.bySemanticsLabel(exampleContactLabel(c, 'Jakob')),
          findsOneWidget,
        );
        expect(
          tester.getSize(_row(c)).height,
          greaterThanOrEqualTo(CuraSize.contactRowMin),
        );
      }
      // Keine Suche, kein „Neuer Chat“, kein Badge.
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.search_rounded), findsNothing);
      expect(find.textContaining('Neuer Chat'), findsNothing);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(FloatingNav), findsNothing);
      h.dispose();
      await disposeApp(tester);
    });

    testWidgets('jede Zeile öffnet ihren Beispiel-Chat; Zurück → Übersicht '
        '(Fokus auf der Zeile) → Pfad (Fokus auf dem Nachrichten-Button)', (
      WidgetTester tester,
    ) async {
      await _home(tester);
      await _openMessages(tester);
      for (final ExampleContact c in kExampleContacts) {
        await tester.ensureVisible(_row(c));
        await tester.tap(_row(c));
        await tester.pumpAndSettle();
        expect(find.byType(ExampleChatScreen), findsOneWidget, reason: c.id);
        // Kopf: Avatar, Name, „[Rolle] · Beispiel“.
        expect(find.text(c.name), findsOneWidget);
        expect(find.text('${c.role} · Beispiel'), findsOneWidget);
        expect(find.text('Beispiel-Chat. Nur zum Ansehen.'), findsOneWidget);
        expect(find.text('Schreiben in Chats folgt bald.'), findsOneWidget);
        expect(find.text('Nachricht'), findsOneWidget);
        expect(
          find.text(S.chatDisclaimer),
          findsNothing,
          reason: 'kein Disclaimer',
        );
        expect(find.byType(ChatBubble), findsNWidgets(c.lines('Jakob').length));
        for (final ExampleLine l in c.lines('Jakob')) {
          expect(find.text(l.text), findsOneWidget);
        }
        expect(find.byType(BackdropFilter), findsNothing);
        // Zurück: Übersicht, Fokus auf der Zeile.
        await _back(tester);
        expect(find.byType(ExampleChatScreen), findsNothing);
        expect(find.byType(MessagesScreen), findsOneWidget);
        expect(_focusInside(_row(c)), isTrue, reason: 'Fokus auf ${c.id}');
      }
      await _back(tester);
      expect(find.byType(MessagesScreen), findsNothing);
      expect(_shell(tester).activeTab, HomeTab.path);
      expect(
        FocusManager.instance.primaryFocus,
        _shell(tester).messagesButtonFocus,
      );
      await disposeApp(tester);
    });

    testWidgets('Beispiel-Chat: Gegenüber links, „Du“ rechts, Semantik mit '
        'Präfix; der Physio-Chat nennt den Vornamen', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _home(tester);
      await _openMessages(tester);
      await tester.tap(_row(_contact('physio-mueller')));
      await tester.pumpAndSettle();
      expect(
        find.text('Moin Jakob, dein Termin ist am Donnerstag um 17:00 Uhr.'),
        findsOneWidget,
      );
      Rect surface(int i) => tester.getRect(
        find.descendant(
          of: find.byType(ChatBubble).at(i),
          matching: find.byWidgetPredicate(
            (Widget w) => w is OpaqueSurface || w is GlassCard,
          ),
        ),
      );
      final Rect first = surface(0);
      final Rect second = surface(1);
      expect(first.left, lessThan(second.left));
      expect(second.right, 390 - 16);
      expect(
        find.bySemanticsLabel('Du: Perfekt, ich bin pünktlich da.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Praxis Müller: Bring bitte Sportschuhe mit.'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Beispiel-Chat Praxis Müller'),
        findsWidgets,
      );
      expect(
        find.bySemanticsLabel(
          'Nachricht an Praxis Müller, noch nicht verfügbar',
        ),
        findsOneWidget,
      );
      h.dispose();
      await disposeApp(tester);
    });

    testWidgets('von Heute aus geöffnet: Zurück → Übersicht → Tab Heute '
        '(UI-80)', (WidgetTester tester) async {
      await _home(tester);
      await tester.tap(_navEntry(S.navToday));
      await tester.pumpAndSettle();
      expect(_shell(tester).activeTab, HomeTab.today);

      final Future<void> done = _shell(tester).openMessages();
      await tester.pumpAndSettle();
      expect(find.byType(MessagesScreen), findsOneWidget);
      await tester.tap(_row(_contact('familie-tim')));
      await tester.pumpAndSettle();
      expect(find.byType(ExampleChatScreen), findsOneWidget);
      await _back(tester);
      expect(find.byType(MessagesScreen), findsOneWidget);
      await _back(tester);
      await done;
      expect(find.byType(MessagesScreen), findsNothing);
      expect(_shell(tester).activeTab, HomeTab.today);
      await disposeApp(tester);
    });

    testWidgets('Tab-Reihenfolge Nachrichten: Zurück, dann die Zeilen in '
        'Reihenfolge (UI-89)', (WidgetTester tester) async {
      await _home(tester);
      await _openMessages(tester);
      expect(_focusInside(find.byType(HeaderIconButton)), isTrue);
      for (final ExampleContact c in kExampleContacts) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_focusInside(_row(c)), isTrue, reason: c.id);
      }
      await disposeApp(tester);
    });

    testWidgets('Enter auf der fokussierten Zeile öffnet den Beispiel-Chat', (
      WidgetTester tester,
    ) async {
      await _home(tester);
      await _openMessages(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(ExampleChatScreen), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('Öffnen und Schließen (UI-86, Plan 4.1, 4.4, A-38)', () {
    testWidgets('Zurück (Android), Escape und Pfeil schließen; Fokus kehrt an '
        'den auslösenden Button zurück', (WidgetTester tester) async {
      await _home(tester);
      // Android-Zurück.
      await _openChat(tester);
      await _back(tester);
      expect(find.byType(MannyChatScreen), findsNothing);
      expect(
        FocusManager.instance.primaryFocus,
        _shell(tester).chatButtonFocus,
      );
      // Escape.
      await _openChat(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(MannyChatScreen), findsNothing);
      expect(
        FocusManager.instance.primaryFocus,
        _shell(tester).chatButtonFocus,
      );
      // Zurück-Pfeil.
      await _openMessages(tester);
      await tester.tap(find.byType(HeaderIconButton));
      await tester.pumpAndSettle();
      expect(find.byType(MessagesScreen), findsNothing);
      expect(
        FocusManager.instance.primaryFocus,
        _shell(tester).messagesButtonFocus,
      );
      // Escape im Beispiel-Chat schließt nur den Beispiel-Chat.
      await _openMessages(tester);
      await tester.tap(_row(_contact('freunde-lena')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ExampleChatScreen), findsNothing);
      expect(find.byType(MessagesScreen), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('Fokus-Rückgabe mit mounted-Prüfung: Auslöser weg → kein '
        'Fehler', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
      final Harness h = await Harness.onboarded();
      addTearDown(h.dispose);
      await pumpCura(tester, h.controller, navigatorKey: key);
      await _openChat(tester);
      // Der Auslöser verschwindet, während der Chat offen ist (Wechsel auf das
      // Onboarding durch Löschen).
      await h.controller.deleteAll();
      AppRoutes.restartOnboarding(key.currentState!);
      await tester.pumpAndSettle();
      expect(find.byType(MannyChatScreen), findsNothing);
      expect(find.text('Schritt 1 von 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('Öffnen beendet Rückgängig-Fenster, schließt Hinweis, Blase '
        '(zählt als gezeigt) und Snackbar (UI-39)', (
      WidgetTester tester,
    ) async {
      final Harness h = await _home(tester);
      h.controller.logTraining(forDay: h.controller.today);
      expect(h.controller.transient.undoWindowOpen, isTrue);
      h.controller.transient
        ..showBubble(
          const BubbleDecision(
            occasion: MannyOccasion.greeting,
            pose: MannyPose.neutral,
          ),
        )
        ..showHint('w5-d3');
      await tester.pump();
      final bool done = h.state.day.done;

      await _openChat(tester);
      expect(h.controller.transient.undoWindowOpen, isFalse);
      expect(h.controller.transient.hintUnitId, isNull);
      expect(h.controller.transient.visibleBubble, isNull);
      expect(
        h.state.manny.shownOn(MannyOccasion.greeting, h.controller.today),
        isTrue,
        reason: 'Blase zählt als gezeigt',
      );
      expect(h.state.day.done, done, reason: 'Eintrag bleibt');
      await _back(tester);
      expect(h.controller.transient.undoWindowOpen, isFalse);
      await disposeApp(tester);
    });

    testWidgets('Nachrichten öffnen beenden das Rückgängig-Fenster ebenfalls', (
      WidgetTester tester,
    ) async {
      final Harness h = await _home(tester);
      h.controller.logTraining(forDay: h.controller.today);
      await _openMessages(tester);
      expect(h.controller.transient.undoWindowOpen, isFalse);
      await disposeApp(tester);
    });

    testWidgets('Bewegung reduzieren: keine Schiebung, nach 121 ms keine '
        'laufende Animation', (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _home(tester);
      await tester.tap(find.byType(MannyChatButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      final double start = tester.getTopLeft(find.text('Manny')).dx;
      await tester.pump(const Duration(milliseconds: 121));
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.getTopLeft(find.text('Manny')).dx, start);
      expect(tester.binding.transientCallbackCount, 0);
      await disposeApp(tester);
    });

    testWidgets('Browser-Zurück entspricht Android-Zurück: Beispiel-Chat → '
        'Nachrichten → Pfad, die App schließt nicht', (
      WidgetTester tester,
    ) async {
      final SystemPopRecorder pop = SystemPopRecorder(tester);
      await _home(tester);
      await _openMessages(tester);
      await tester.tap(_row(_contact('freunde-basti')));
      await tester.pumpAndSettle();
      await _back(tester);
      expect(find.byType(MessagesScreen), findsOneWidget);
      await _back(tester);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(pop.count, 0);
      await disposeApp(tester);
    });
  });

  group('Tageswechsel bei offenem Chat (A-39, UI-86)', () {
    for (final String which in <String>['Manny-Chat', 'Nachrichten']) {
      testWidgets('$which offen, +1 Tag, Fortsetzen: keine Snackbar, keine '
          'Ansage; danach Heute ohne Snackbar', (WidgetTester tester) async {
        final Harness h = await _home(tester);
        await tester.tap(_navEntry(S.navToday));
        await tester.pumpAndSettle();
        final Future<void> done = which == 'Manny-Chat'
            ? _shell(tester).openChat()
            : _shell(tester).openMessages();
        await tester.pumpAndSettle();
        tester.takeAnnouncements();

        h.clock.advanceDays(1);
        resumeApp(tester);
        await tester.pumpAndSettle();
        expect(find.text(S.newDaySnackbar), findsNothing);
        expect(tester.takeAnnouncements(), isEmpty);
        expect(h.state.day.dayKey, h.controller.today);

        await _back(tester);
        await done;
        expect(_shell(tester).activeTab, HomeTab.today);
        expect(find.text(S.newDaySnackbar), findsNothing);
        expect(tester.takeAnnouncements(), isEmpty);
        await disposeApp(tester);
      });
    }

    testWidgets('Beispiel-Chat offen: dasselbe', (WidgetTester tester) async {
      final Harness h = await _home(tester);
      await tester.tap(_navEntry(S.navToday));
      await tester.pumpAndSettle();
      _shell(tester).openMessages();
      await tester.pumpAndSettle();
      await tester.tap(_row(_contact('aerzte-weber')));
      await tester.pumpAndSettle();
      tester.takeAnnouncements();
      h.clock.advanceDays(1);
      resumeApp(tester);
      await tester.pumpAndSettle();
      expect(find.text(S.newDaySnackbar), findsNothing);
      expect(tester.takeAnnouncements(), isEmpty);
      await disposeApp(tester);
    });
  });

  group('nichts gespeichert (UI-82, KS-9)', () {
    testWidgets('Öffnen, Ansehen und Schließen ändern weder Zustand noch '
        'Speicher', (WidgetTester tester) async {
      final Harness h = await _home(tester);
      final InMemoryStore raw = h.raw as InMemoryStore;
      await h.controller.idle;
      final AppState before = h.state;
      final String? document = raw.raw;
      final int writes = raw.writes;
      await _openChat(tester);
      await tester.tap(find.byType(ChatComposer));
      await _back(tester);
      await _openMessages(tester);
      for (final ExampleContact c in kExampleContacts) {
        await tester.ensureVisible(_row(c));
        await tester.tap(_row(c));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ChatComposer));
        await _back(tester);
      }
      await _back(tester);
      await h.controller.idle;
      expect(h.state, before);
      expect(raw.raw, document);
      expect(raw.writes, writes);
      await disposeApp(tester);
    });

    testWidgets('Alles löschen, neues Onboarding mit anderem Namen: gleicher '
        'Beispielverlauf mit neuem Namen, kein Chat-Rest im Speicher', (
      WidgetTester tester,
    ) async {
      final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
      final Harness h = await Harness.onboarded();
      addTearDown(h.dispose);
      await pumpCura(tester, h.controller, navigatorKey: key);
      await _openChat(tester);
      expect(find.text('Moin Jakob. Wie läuft dein Tag?'), findsOneWidget);
      await _back(tester);

      await h.controller.deleteAll();
      AppRoutes.restartOnboarding(key.currentState!);
      await tester.pumpAndSettle();
      expect((h.raw as InMemoryStore).raw, isNull);

      // Neues Onboarding: Mia, Einwilligung, ACL, Datum.
      await tester.enterText(find.byType(TextField), 'Mia');
      await tester.pump();
      await tester.tap(find.widgetWithText(PillButton, S.next));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PillButton, S.consentAccept));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.injuryAcl));
      await tester.pump();
      await tester.tap(find.widgetWithText(PillButton, S.next));
      await tester.pumpAndSettle();
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
      await tester.tap(find.widgetWithText(PillButton, S.next));
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);

      await _openChat(tester);
      expect(find.text('Moin Mia. Wie läuft dein Tag?'), findsOneWidget);
      expect(find.text('Ich hab heute keine Zeit.'), findsOneWidget);
      await _back(tester);

      // Im Speicher steht nur das Zustandsdokument, kein Chat-Feld.
      await h.controller.idle;
      final Map<String, Object?> doc =
          jsonDecode((h.raw as InMemoryStore).raw!) as Map<String, Object?>;
      expect(doc.keys.toSet(), <String>{
        'schema',
        'onboarding',
        'consent',
        'streak',
        'path',
        'day',
        'prefs',
        'manny',
        'celebration',
      });
      expect(
        jsonEncode(doc).toLowerCase().contains('chat'),
        isFalse,
        reason: 'kein Chat-Rest im Dokument',
      );
      await disposeApp(tester);
    });
  });
}

class _FakeSource implements MannyChatSource {
  @override
  List<ChatMessage> messages(String vorname) => <ChatMessage>[
    ChatMessage(
      id: 'f1',
      author: ChatAuthor.manny,
      kind: ChatKind.text,
      status: ChatStatus.done,
      text: 'Quelle für $vorname',
    ),
    const ChatMessage(
      id: 'f2',
      author: ChatAuthor.user,
      kind: ChatKind.text,
      status: ChatStatus.done,
      text: 'Antwort aus der Quelle',
    ),
  ];
}
