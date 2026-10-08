// Chat-Bausteine (U2c, Ergänzung 2, UI-76 bis UI-78, UI-80, UI-84 bis UI-89):
// ChatMessageList (Datenobjekte, Manny ohne Blase, Emblem je Block, wachsende
// letzte Nachricht), ChatComposer (nur deaktiviert), ChatFooterLayout (ab 1,5
// scrollen Hinweis und Disclaimer mit), ExampleNotice, ChatHeader, ChatBubble,
// ContactRow, CuraFullscreenRoute.
import 'dart:ui' as ui;

import 'package:curaone/data/manny_chat_source.dart';
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/chat_model.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/ui/components/chat_avatar.dart';
import 'package:curaone/ui/components/chat_composer.dart';
import 'package:curaone/ui/components/chat_header.dart';
import 'package:curaone/ui/components/chat_message_list.dart';
import 'package:curaone/ui/components/chat_screen_scaffold.dart';
import 'package:curaone/ui/components/example_notice.dart';
import 'package:curaone/ui/components/glass_card.dart';
import 'package:curaone/ui/components/header_icon_button.dart';
import 'package:curaone/ui/components/manny.dart';
import 'package:curaone/ui/components/opaque_surface.dart';
import 'package:curaone/ui/components/probe_keys.dart';
import 'package:curaone/ui/messages/chat_bubble.dart';
import 'package:curaone/ui/messages/contact_row.dart';
import 'package:curaone/ui/messages/example_contacts.dart';
import 'package:curaone/ui/routes/cura_fullscreen_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/pump_app.dart';

ChatMessage _msg(
  String id,
  ChatAuthor author,
  String text, {
  ChatKind kind = ChatKind.text,
  ChatStatus status = ChatStatus.done,
}) =>
    ChatMessage(id: id, author: author, kind: kind, status: status, text: text);

List<ChatMessage> get _example =>
    const ExampleMannyChatSource().messages('Jakob');

Widget _list(List<ChatMessage> messages, {Widget? leading, Widget? trailing}) =>
    ChatMessageList(messages: messages, leading: leading, trailing: trailing);

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

/// Rechteck des Widgets, das [text] enthält.
Rect _rect(WidgetTester tester, String text) => tester.getRect(find.text(text));

void main() {
  group('ChatMessageList (UI-76)', () {
    testWidgets(
      'Beispielverlauf aus Datenobjekten: Manny ohne Blase, Nutzer in '
      'Blase rechts',
      (WidgetTester tester) async {
        await pumpApp(tester, _list(_example));
        final ChatMessage m1 = _example[0];
        final ChatMessage u = _example[1];
        expect(find.text(m1.text), findsOneWidget);
        expect(find.text(u.text), findsOneWidget);
        expect(find.text(_example[2].text), findsOneWidget);

        // Manny: weder Opak- noch Glasfläche um den Text.
        for (final String t in <String>[m1.text, _example[2].text]) {
          expect(
            find.ancestor(
              of: find.text(t),
              matching: find.byType(OpaqueSurface),
            ),
            findsNothing,
          );
          expect(
            find.ancestor(of: find.text(t), matching: find.byType(GlassCard)),
            findsNothing,
          );
        }
        // Nutzer: Blase surface-opaque mit Rand border-hair.
        final Finder bubble = find.ancestor(
          of: find.text(u.text),
          matching: find.byType(OpaqueSurface),
        );
        expect(bubble, findsOneWidget);
        final CuraColors c = colorsAt(tester, bubble);
        final BoxDecoration d = decorationsUnder(tester, bubble).first;
        expect(d.color, c.surfaceOpaque);
        expect((d.border! as Border).top.color, c.cardBorder);
        expect((d.border! as Border).top.width, 1);
        final BorderRadius r = d.borderRadius! as BorderRadius;
        expect(r.topLeft.x, 20);
        expect(r.bottomLeft.x, 20);
        expect(r.bottomRight.x, 6, reason: 'Ecke unten rechts 6 dp');
      },
    );

    testWidgets('Nutzer-Blase: rechtsbündig, höchstens 80 % der Breite, '
        'Innenabstand 12/16', (WidgetTester tester) async {
      await pumpApp(tester, _list(_example));
      final Rect list = tester.getRect(find.byType(ListView));
      final Finder bubble = find.ancestor(
        of: find.text(_example[1].text),
        matching: find.byType(OpaqueSurface),
      );
      final Rect b = tester.getRect(bubble);
      expect(b.right, list.right - CuraSpace.pageMargin);
      expect(b.width, lessThanOrEqualTo(list.width * 0.8 + 0.01));
      final Rect text = _rect(tester, _example[1].text);
      expect(text.left - b.left, closeTo(16, 0.6));
      expect(text.top - b.top, closeTo(12, 0.6));

      // Lange Nutzer-Nachricht: bricht um, bleibt unter 80 %.
      final String long = 'Ein sehr langer Satz ' * 12;
      await pumpApp(
        tester,
        _list(<ChatMessage>[_msg('u', ChatAuthor.user, long)]),
      );
      final Rect lb = tester.getRect(find.byType(OpaqueSurface));
      expect(lb.width, lessThanOrEqualTo(list.width * 0.8 + 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Emblem je Manny-Block: vor jedem Block, nicht je Nachricht, '
        'Text ab 36 dp', (WidgetTester tester) async {
      await pumpApp(tester, _list(_example));
      // Drei Nachrichten: Manny, Nutzer, Manny → zwei Blöcke → zwei Embleme.
      expect(find.byType(MannyPlaceholder), findsNWidgets(2));
      for (final Element e in find.byType(MannyPlaceholder).evaluate()) {
        final MannyPlaceholder m = e.widget as MannyPlaceholder;
        expect(m.height, CuraSize.emblemMessage);
        expect(m.crop, MannyCrop.head);
      }
      final Rect list = tester.getRect(find.byType(ListView));
      final Rect text = _rect(tester, _example[0].text);
      expect(text.left, list.left + CuraSpace.pageMargin + 36);

      // Aufeinanderfolgende Manny-Nachrichten bilden einen Block (ein Emblem,
      // 8 dp Abstand); der Wechsel des Autors gibt 20 dp.
      await pumpApp(
        tester,
        _list(<ChatMessage>[
          _msg('a', ChatAuthor.manny, 'Erste'),
          _msg('b', ChatAuthor.manny, 'Zweite'),
          _msg('c', ChatAuthor.user, 'Dritte'),
          _msg('d', ChatAuthor.manny, 'Vierte'),
        ]),
      );
      expect(find.byType(MannyPlaceholder), findsNWidgets(2));
      final Rect a = _rect(tester, 'Erste');
      final Rect b = _rect(tester, 'Zweite');
      expect(b.top - a.bottom, closeTo(8, 0.6));
      final Rect cBubble = tester.getRect(
        find.ancestor(
          of: find.text('Dritte'),
          matching: find.byType(OpaqueSurface),
        ),
      );
      expect(cBubble.top - b.bottom, closeTo(20, 0.6));
    });

    testWidgets('Semantik: „Manny: …“ und „Du: …“', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(tester, _list(_example));
      expect(
        find.bySemanticsLabel(S.chatFromManny(_example[0].text)),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(S.chatFromYou(_example[1].text)),
        findsOneWidget,
      );
      h.dispose();
    });

    testWidgets('Standard-Semantik-Indizes: keine Liste ohne Indizes', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, _list(_example));
      final ListView list = tester.widget(find.byType(ListView));
      // `ListView(children:)` mit Standardwert (addSemanticIndexes: true).
      expect(
        (list.childrenDelegate as SliverChildListDelegate).addSemanticIndexes,
        isTrue,
      );
    });

    testWidgets('jede Kombination Autor × Art × Status rendert ohne Overflow', (
      WidgetTester tester,
    ) async {
      for (final ChatAuthor author in ChatAuthor.values) {
        for (final ChatKind kind in ChatKind.values) {
          for (final ChatStatus status in ChatStatus.values) {
            await pumpApp(
              tester,
              _list(<ChatMessage>[
                _msg(
                  'x',
                  author,
                  'Text ${author.name} ${kind.name} ${status.name}',
                  kind: kind,
                  status: status,
                ),
              ]),
              size: Viewports.small,
              textScale: 2,
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '$author $kind $status',
            );
            expect(
              find.text('Text ${author.name} ${kind.name} ${status.name}'),
              findsOneWidget,
            );
          }
        }
      }
    });

    testWidgets('Autor „Hinweis“ als Hinweiskarte, Art „Disclaimer“ als '
        'Zeile caption text-3 mittig', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _list(<ChatMessage>[
          _msg('n', ChatAuthor.notice, 'Ein Hinweis'),
          _msg('d', ChatAuthor.manny, 'Kein Rat', kind: ChatKind.disclaimer),
        ]),
      );
      expect(
        find.ancestor(
          of: find.text('Ein Hinweis'),
          matching: find.byType(ExampleNotice),
        ),
        findsOneWidget,
      );
      final Text t = tester.widget(find.text('Kein Rat'));
      expect(t.textAlign, TextAlign.center);
      expect(t.style!.fontSize, 13);
      expect(t.style!.color, colorsAt(tester, find.text('Kein Rat')).text3);
      // Der Disclaimer ist keine Manny-Zeile mit Emblem.
      expect(find.byType(MannyPlaceholder), findsNothing);
    });

    testWidgets('ersetzte Quelle: Liste zeigt genau deren Nachrichten', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        _list(<ChatMessage>[_msg('x', ChatAuthor.manny, 'Aus anderer Quelle')]),
      );
      expect(find.text('Aus anderer Quelle'), findsOneWidget);
      expect(find.text(_example[0].text), findsNothing);
    });
  });

  group('wachsende letzte Nachricht (UI-76, KS-6)', () {
    Future<ValueNotifier<String>> pumpGrowing(
      WidgetTester tester, {
      Size size = Viewports.small,
    }) async {
      final ValueNotifier<String> last = ValueNotifier<String>('Anfang');
      await pumpApp(
        tester,
        ValueListenableBuilder<String>(
          valueListenable: last,
          builder: (BuildContext context, String text, Widget? child) {
            return _list(<ChatMessage>[
              for (int i = 0; i < 6; i++)
                _msg(
                  'm$i',
                  i.isEven ? ChatAuthor.manny : ChatAuthor.user,
                  'Nachricht Nummer $i mit etwas mehr Text zum Füllen der Liste.',
                ),
              _msg(
                'last',
                ChatAuthor.manny,
                text,
                status: ChatStatus.streaming,
              ),
            ]);
          },
        ),
        size: size,
      );
      addTearDown(last.dispose);
      await tester.pumpAndSettle();
      return last;
    }

    ScrollPosition position(WidgetTester tester) =>
        tester.state<ScrollableState>(find.byType(Scrollable)).position;

    testWidgets('beim Öffnen steht das Ende sichtbar', (
      WidgetTester tester,
    ) async {
      await pumpGrowing(tester);
      final ScrollPosition p = position(tester);
      expect(p.maxScrollExtent, greaterThan(0));
      expect(p.pixels, closeTo(p.maxScrollExtent, 1));
      final Rect view = tester.getRect(find.byType(ListView));
      expect(_rect(tester, 'Anfang').bottom, lessThanOrEqualTo(view.bottom));
    });

    testWidgets('am Ende: folgt dem wachsenden Text, nichts abgeschnitten', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<String> last = await pumpGrowing(tester);
      final Rect view = tester.getRect(find.byType(ListView));
      String text = 'Anfang';
      for (int i = 0; i < 12; i++) {
        text = '$text und noch ein Stück Antworttext, der hinzukommt';
        last.value = text;
        await tester.pump();
        await tester.pump();
        expect(tester.takeException(), isNull);
        final ScrollPosition p = position(tester);
        expect(
          p.pixels,
          closeTo(p.maxScrollExtent, 1),
          reason: 'folgt dem Ende (Schritt $i)',
        );
        // Letzte Zeile sichtbar: die Unterkante des Textes liegt im Bereich.
        final Rect r = _rect(tester, text);
        expect(r.bottom, lessThanOrEqualTo(view.bottom + 0.5));
      }
    });

    testWidgets('nach Hochscrollen bleibt der Offset unverändert', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<String> last = await pumpGrowing(tester);
      await tester.drag(find.byType(ListView), const Offset(0, 150));
      await tester.pumpAndSettle();
      final double before = position(tester).pixels;
      expect(before, lessThan(position(tester).maxScrollExtent - 1));
      String text = 'Anfang';
      for (int i = 0; i < 6; i++) {
        text = '$text und noch ein Stück Antworttext, der hinzukommt';
        last.value = text;
        await tester.pump();
        await tester.pump();
        expect(position(tester).pixels, before, reason: 'Schritt $i');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('wieder am Ende angekommen: folgt erneut', (
      WidgetTester tester,
    ) async {
      final ValueNotifier<String> last = await pumpGrowing(tester);
      await tester.drag(find.byType(ListView), const Offset(0, 150));
      await tester.pumpAndSettle();
      position(tester).jumpTo(position(tester).maxScrollExtent);
      await tester.pump();
      last.value = 'Anfang ${'weiter ' * 40}';
      await tester.pump();
      await tester.pump();
      final ScrollPosition p = position(tester);
      expect(p.pixels, closeTo(p.maxScrollExtent, 1));
    });
  });

  group('ChatComposer: nur deaktiviert (UI-77, Regel 16)', () {
    Widget composer() => const ChatComposer(
      placeholder: S.chatComposerPlaceholder,
      semanticsLabel: S.chatComposerSemantics,
      sendSemanticsLabel: S.chatSendSemantics,
    );

    testWidgets('Aussehen: Pill Radius 28, ≥ 56 dp, surface-opaque, Rand 1 dp, '
        'Senden-Kreis 40 dp text-3 auf Weiß 10 %', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(alignment: Alignment.bottomCenter, child: composer()),
        ),
      );
      final Finder pill = find.byType(OpaqueSurface);
      expect(tester.getSize(pill).height, greaterThanOrEqualTo(56));
      expect(tester.getSize(pill).width, 390 - 32);
      final CuraColors c = colorsAt(tester, pill);
      final BoxDecoration d = decorationsUnder(tester, pill).first;
      expect(d.color, c.surfaceOpaque);
      expect((d.borderRadius! as BorderRadius).topLeft.x, 28);
      expect((d.border! as Border).top.width, 1);
      final Text hint = tester.widget(find.text(S.chatComposerPlaceholder));
      expect(hint.style!.color, c.text2);
      final Icon arrow = tester.widget(find.byIcon(Icons.arrow_upward_rounded));
      expect(arrow.color, c.text3);
      final Finder circle = find.ancestor(
        of: find.byIcon(Icons.arrow_upward_rounded),
        matching: find.byWidgetPredicate(
          (Widget w) => w is SizedBox && w.width == 40 && w.height == 40,
        ),
      );
      expect(circle, findsOneWidget);
      final BoxDecoration cd = decorationsUnder(tester, circle).first;
      expect(cd.shape, BoxShape.circle);
      expect(cd.color, c.disabledFill);
    });

    testWidgets('Tipp auf Leiste und Senden: keine Tastatur, kein Fokus, '
        'nichts passiert', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(alignment: Alignment.bottomCenter, child: composer()),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(EditableText), findsNothing);
      final Rect pill = tester.getRect(find.byType(OpaqueSurface));
      await tester.tapAt(pill.centerLeft + const Offset(40, 0));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(_focusInside(find.byType(ChatComposer)), isFalse);
      // Nicht fokussierbar: auch Tab erreicht die Leiste nicht.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_focusInside(find.byType(ChatComposer)), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Semantik: Leiste und Senden mit Label, Senden deaktiviert', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(
        tester,
        Align(alignment: Alignment.bottomCenter, child: composer()),
      );
      expect(find.bySemanticsLabel(S.chatComposerSemantics), findsOneWidget);
      final SemanticsNode send = tester.getSemantics(
        find.bySemanticsLabel(S.chatSendSemantics),
      );
      final SemanticsData data = send.getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, ui.Tristate.isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      h.dispose();
    });

    testWidgets('Hinweiszeile und Disclaimer: Texte wörtlich (UI-81)', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const Column(
          children: <Widget>[
            ChatHintLine(text: S.chatHint),
            ChatDisclaimer(text: S.chatDisclaimer),
          ],
        ),
      );
      expect(
        find.text('Schreiben kann ich bald, heute noch nicht.'),
        findsOneWidget,
      );
      expect(
        find.text('Manny ersetzt keine medizinische Beratung.'),
        findsOneWidget,
      );
      final CuraColors c = colorsAt(tester, find.byType(ChatHintLine));
      final Text hint = tester.widget(find.text(S.chatHint));
      expect(hint.style!.color, c.text1);
      expect(hint.style!.fontSize, 14);
      final Icon icon = tester.widget(find.byIcon(Icons.info_outline_rounded));
      expect(icon.size, 18);
      final Text dis = tester.widget(find.text(S.chatDisclaimer));
      expect(dis.style!.color, c.text3);
      expect(dis.textAlign, TextAlign.center);
    });
  });

  group('ChatFooterLayout (UI-88)', () {
    Widget scaffold() => ChatScreenScaffold(
      header: const ChatHeader(title: S.chatTitle, subtitle: S.chatSubtitle),
      notice: const ExampleNotice(
        label: S.chatNoticeLabel,
        text: S.chatNoticeText,
      ),
      hint: const ChatHintLine(text: S.chatHint),
      composer: const ChatComposer(
        placeholder: S.chatComposerPlaceholder,
        semanticsLabel: S.chatComposerSemantics,
        sendSemanticsLabel: S.chatSendSemantics,
      ),
      disclaimer: const ChatDisclaimer(text: S.chatDisclaimer),
      bodyBuilder: (BuildContext context, ChatScaffoldExtras extras) =>
          ChatMessageList(messages: _example, trailing: extras.trailing),
    );

    bool inFooter(WidgetTester tester, Finder f) {
      final Rect footer = tester.getRect(find.byKey(ProbeKeys.chatFooter));
      return footer.contains(tester.getCenter(f));
    }

    bool inList(Finder f) => find
        .descendant(of: find.byType(ListView), matching: f)
        .evaluate()
        .isNotEmpty;

    testWidgets(
      'unter 1,5: Hinweiszeile, Leiste und Disclaimer im festen Fuß',
      (WidgetTester tester) async {
        await pumpApp(tester, scaffold(), textScale: 1.4);
        await tester.pumpAndSettle();
        expect(inFooter(tester, find.text(S.chatHint)), isTrue);
        expect(inFooter(tester, find.text(S.chatDisclaimer)), isTrue);
        expect(inFooter(tester, find.byType(ChatComposer)), isTrue);
        expect(inList(find.text(S.chatHint)), isFalse);
        expect(inList(find.text(S.chatDisclaimer)), isFalse);
      },
    );

    testWidgets('ab 1,5: Hinweiszeile und Disclaimer scrollen am Listenende '
        'mit, die Leiste bleibt fest', (WidgetTester tester) async {
      for (final double scale in <double>[1.5, 2.0]) {
        await pumpApp(tester, scaffold(), textScale: scale);
        await tester.pumpAndSettle();
        expect(inList(find.text(S.chatHint)), isTrue, reason: '$scale');
        expect(inList(find.text(S.chatDisclaimer)), isTrue, reason: '$scale');
        expect(inFooter(tester, find.byType(ChatComposer)), isTrue);
        expect(inFooter(tester, find.text(S.chatHint)), isFalse);
        // Beide am Ende der Liste erreichbar und sichtbar.
        final Rect view = tester.getRect(find.byType(ListView));
        expect(
          _rect(tester, S.chatDisclaimer).bottom,
          lessThanOrEqualTo(view.bottom + 0.5),
        );
        expect(
          _rect(tester, S.chatHint).bottom,
          lessThanOrEqualTo(_rect(tester, S.chatDisclaimer).top),
        );
      }
    });

    testWidgets('Fuß belegt höchstens 40 % der Höhe, bei allen Skalierungen '
        'und kleinen Displays', (WidgetTester tester) async {
      for (final Size size in <Size>[Viewports.small, Viewports.phone]) {
        for (final double scale in <double>[1, 1.3, 1.45, 1.49, 1.5, 2]) {
          await pumpApp(tester, scaffold(), size: size, textScale: scale);
          await tester.pumpAndSettle();
          final double h = tester
              .getSize(find.byKey(ProbeKeys.chatFooter))
              .height;
          expect(
            h,
            lessThanOrEqualTo(size.height * CuraSize.chatFooterMaxFraction),
            reason: '$size ×$scale',
          );
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('K6: Hinweiskarte ab 1,5 oder bei Höhe unter 400 dp als '
        'erstes Listenelement (Manny-Chat, Nachrichten, Beispiel-Chat)', (
      WidgetTester tester,
    ) async {
      Widget screen(String kind) => ChatScreenScaffold(
        header: const ChatHeader(title: S.messagesTitle, largeTitle: true),
        notice: ExampleNotice(text: kind),
        hint: const ChatHintLine(text: S.chatHint),
        composer: const ChatComposer(
          placeholder: S.chatComposerPlaceholder,
          semanticsLabel: S.chatComposerSemantics,
          sendSemanticsLabel: S.chatSendSemantics,
        ),
        bodyBuilder: (BuildContext context, ChatScaffoldExtras extras) =>
            ListView(children: <Widget>[?extras.leading, const Text('X')]),
      );
      // (Größe, Skalierung, Karte in der Liste?)
      final List<(Size, double, bool)> cases = <(Size, double, bool)>[
        (Viewports.phone, 1, false),
        (Viewports.small, 1, false), // 568 dp: fest
        (Viewports.phone, 1.49, false),
        (Viewports.phone, 1.5, true),
        (Viewports.small, 2, true),
        (const Size(390, 400), 1, false), // genau 400 dp: fest
        (const Size(390, 399), 1, true),
        (const Size(568, 320), 1, true), // Querformat
      ];
      for (final (Size size, double scale, bool inList) in cases) {
        for (final String kind in <String>[
          S.chatNoticeText,
          S.messagesNotice,
          S.exampleChatNotice,
        ]) {
          await pumpApp(tester, screen(kind), size: size, textScale: scale);
          await tester.pumpAndSettle();
          final bool inScroll = find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(ExampleNotice),
              )
              .evaluate()
              .isNotEmpty;
          expect(inScroll, inList, reason: '$size ×$scale');
          expect(find.byType(ExampleNotice), findsOneWidget);
        }
      }
    });

    testWidgets('K6: Hinweiszeile und Disclaimer wandern auch bei Höhe unter '
        '400 dp ans Listenende, die Leiste bleibt fest', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, scaffold(), size: const Size(568, 320));
      await tester.pumpAndSettle();
      expect(inList(find.text(S.chatHint)), isTrue);
      expect(inList(find.text(S.chatDisclaimer)), isTrue);
      expect(inFooter(tester, find.byType(ChatComposer)), isTrue);
      // 400 dp und mehr: fest im Fuß.
      await pumpApp(tester, scaffold(), size: const Size(390, 400));
      await tester.pumpAndSettle();
      expect(inFooter(tester, find.text(S.chatHint)), isTrue);
      expect(inFooter(tester, find.text(S.chatDisclaimer)), isTrue);
    });

    testWidgets('K6: die Höhe zählt ohne Systemleisten und ohne Tastatur', (
      WidgetTester tester,
    ) async {
      // 440 dp Fenster, 48 dp Statusleiste: 392 dp verfügbar → mitscrollen.
      late bool along;
      Future<void> probeWith({
        required EdgeInsets padding,
        required EdgeInsets insets,
      }) async {
        setViewport(tester, const Size(390, 440));
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: const Size(390, 440),
              padding: padding,
              viewInsets: insets,
            ),
            child: Builder(
              builder: (BuildContext context) {
                along = ChatFooterLayout.scrollsAlong(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }

      await probeWith(padding: EdgeInsets.zero, insets: EdgeInsets.zero);
      expect(along, isFalse, reason: '440 dp');
      await probeWith(
        padding: const EdgeInsets.only(top: 48),
        insets: EdgeInsets.zero,
      );
      expect(along, isTrue, reason: '392 dp nach Abzug der Statusleiste');
      // Die Tastatur verändert die verfügbare Höhe nicht.
      await probeWith(
        padding: EdgeInsets.zero,
        insets: const EdgeInsets.only(bottom: 300),
      );
      expect(along, isFalse, reason: 'Tastatur zählt nicht');
    });
  });

  group('ExampleNotice (UI-76, UI-79, UI-80)', () {
    testWidgets('GlassCard Radius 16, Innenabstand 10/14, Icon 20 dp text-2, '
        'Label text-1, kein Blur', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: ExampleNotice(
            label: S.chatNoticeLabel,
            text: S.chatNoticeText,
          ),
        ),
      );
      final Finder card = find.byType(GlassCard);
      expect(card, findsOneWidget);
      expect(tester.widget<GlassCard>(card).radius, 16);
      expect(
        tester.widget<GlassCard>(card).padding,
        const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      );
      final CuraColors c = colorsAt(tester, card);
      final Icon icon = tester.widget(find.byIcon(Icons.info_outline_rounded));
      expect(icon.size, 20);
      expect(icon.color, c.text2);
      expect(backdropCount(tester), 0);
      // Der Großbuchstaben-Stil gilt nur der Darstellung.
      expect(find.text('BEISPIELVERLAUF'), findsOneWidget);
    });

    testWidgets('ein Semantik-Knoten mit Label und Text', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(
        tester,
        const ExampleNotice(label: S.chatNoticeLabel, text: S.chatNoticeText),
      );
      expect(find.bySemanticsLabel(RegExp('Beispielverlauf')), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel(RegExp('Beispielverlauf')))
            .label,
        contains(S.chatNoticeText),
      );
      h.dispose();
    });
  });

  group('ChatHeader (UI-76, UI-86, UI-89)', () {
    testWidgets('Zurück 48 dp mit Tooltip „Zurück“, Titel heading, Untertitel '
        'secondary text-2', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const ChatHeader(title: S.chatTitle, subtitle: S.chatSubtitle),
      );
      final CuraColors c = colorsAt(tester, find.byType(ChatHeader));
      expect(find.byTooltip(S.back), findsOneWidget);
      final Text title = tester.widget(find.text(S.chatTitle));
      expect(title.style!.fontSize, 18);
      expect(title.style!.color, c.text1);
      final Text sub = tester.widget(find.text(S.chatSubtitle));
      expect(sub.style!.fontSize, 14);
      expect(sub.style!.color, c.text2);
    });

    testWidgets('Screenreader: Titel vor dem Zurück-Pfeil, Tastatur: Zurück '
        'zuerst', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(
        tester,
        const ChatHeader(title: S.chatTitle, subtitle: S.chatSubtitle),
      );
      final List<String> order = <String>[];
      void walk(SemanticsNode n) {
        final String label = n.getSemanticsData().label;
        if (label.isNotEmpty) order.add(label);
        for (final SemanticsNode c in n.debugListChildrenInOrder(
          DebugSemanticsDumpOrder.traversalOrder,
        )) {
          walk(c);
        }
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
      final int title = order.indexWhere((String l) => l.contains(S.chatTitle));
      final int back = order.indexOf(S.back);
      expect(title, isNonNegative, reason: '$order');
      expect(back, isNonNegative, reason: '$order');
      expect(title, lessThan(back), reason: 'Titel vor Zurück: $order');
      // Sichtbare Tastatur-Reihenfolge beginnt beim Zurück-Pfeil.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_focusInside(find.byType(HeaderIconButton)), isTrue);
      h.dispose();
    });

    testWidgets('Titel im Stil title (Nachrichten)', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const ChatHeader(title: S.messagesTitle, largeTitle: true),
      );
      expect(
        tester.widget<Text>(find.text(S.messagesTitle)).style!.fontSize,
        24,
      );
    });
  });

  group('ChatHeader: große Schrift (A-U3, B3)', () {
    testWidgets('„Nachrichten“ bricht bei 200 % auf 320 dp nicht mitten im '
        'Wort: eine Zeile, Titel skaliert bis 1,5', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const ChatHeader(title: S.messagesTitle, largeTitle: true),
        size: Viewports.small,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      final Finder title = find.text(S.messagesTitle);
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        title,
      );
      final double lineHeight = paragraph.text.style!.height!.toDouble() * 36;
      // Ein Umbruch im Wort ergäbe mindestens zwei Zeilen.
      expect(
        paragraph.size.height,
        lessThan(lineHeight * 1.5),
        reason: 'eine Zeile',
      );
      expect(
        MediaQuery.textScalerOf(tester.element(title)).scale(24),
        36,
        reason: 'Titel ist auf 1,5 begrenzt',
      );
      // Nichts abgeschnitten: das Wort passt in die Breite neben dem Pfeil.
      expect(paragraph.size.width, lessThanOrEqualTo(320 - 8 - 48 - 8 - 16));
    });

    testWidgets('Namen im Kopf (heading) behalten die volle Skalierung', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        const ChatHeader(title: 'Praxis Müller', subtitle: 'Physio · Beispiel'),
        size: Viewports.small,
        textScale: 2,
      );
      expect(
        MediaQuery.textScalerOf(tester.element(find.text('Praxis Müller')))
            .scale(18),
        36,
      );
    });
  });

  group('ChatAvatar: Initialen berühren den Ring nicht (A-U3, B4)', () {
    Future<void> pumpAvatar(
      WidgetTester tester, {
      required double size,
      required String initials,
      double scale = 1,
    }) => pumpApp(
      tester,
      Center(
        child: ChatAvatar(
          initials: initials,
          ringColor: Colors.white,
          size: size,
        ),
      ),
      textScale: scale,
    );

    /// Die Großbuchstaben (Breite der Textbox, Höhe = Kapitälchenhöhe, ca.
    /// 72 % der wirksamen Schriftgröße) liegen im Innenkreis (Ring 2 dp), mit
    /// mindestens 1 dp Luft. Die volle Zeilenbox wäre zu streng: sie enthält
    /// Ober- und Unterlänge, die Großbuchstaben nicht brauchen.
    void expectInsideRing(
      WidgetTester tester,
      double size,
      String initials,
      String reason,
    ) {
      final Rect avatar = tester.getRect(find.byType(ChatAvatar));
      final Finder textFinder = find.text(initials);
      final Rect text = tester.getRect(textFinder);
      final double effective = MediaQuery.textScalerOf(
        tester.element(textFinder),
      ).scale(tester.widget<Text>(textFinder).style!.fontSize!);
      final double halfW = text.width / 2;
      final double halfH = effective * 0.72 / 2;
      final double inner = size / 2 - CuraSize.selectedBorder - 1;
      expect(
        Offset(halfW, halfH).distance,
        lessThanOrEqualTo(inner),
        reason: '$reason: ${text.size} (Kappe ${halfH * 2}) im Kreis $inner',
      );
      expect((text.center - avatar.center).distance, lessThan(1));
    }

    testWidgets('Kopf 36 dp: alle Beispielkontakte, 100 % und 200 %', (
      WidgetTester tester,
    ) async {
      for (final ExampleContact c in kExampleContacts) {
        for (final double scale in <double>[1, 2]) {
          await pumpAvatar(
            tester,
            size: CuraSize.avatarHeader,
            initials: c.initials,
            scale: scale,
          );
          final Text t = tester.widget(find.text(c.initials));
          expect(t.style!.fontSize, greaterThanOrEqualTo(13));
          expect(t.style!.fontSize, lessThanOrEqualTo(14));
          expectInsideRing(tester, 36, c.initials, '${c.initials} ×$scale');
        }
      }
    });

    testWidgets('Liste 48 dp bleibt bei heading', (WidgetTester tester) async {
      await pumpAvatar(tester, size: CuraSize.avatar, initials: 'PM');
      expect(tester.widget<Text>(find.text('PM')).style!.fontSize, 18);
      expectInsideRing(tester, 48, 'PM', 'PM');
    });

    testWidgets('Initialen skalieren begrenzt: Kopf bis 1,15, Liste bis 1,3 '
        '(eigene Konstanten, nicht die der Nav)', (WidgetTester tester) async {
      for (final (double size, double max) in <(double, double)>[
        (CuraSize.avatarHeader, CuraSize.avatarCompactInitialsMaxTextScale),
        (CuraSize.avatar, CuraSize.avatarInitialsMaxTextScale),
      ]) {
        await pumpAvatar(tester, size: size, initials: 'PM', scale: 3);
        expect(
          MediaQuery.textScalerOf(tester.element(find.text('PM'))).scale(10),
          closeTo(10 * max, 0.001),
          reason: '$size dp',
        );
      }
      expect(CuraSize.avatarInitialsMaxTextScale, 1.3);
      expect(CuraSize.avatarCompactInitialsMaxTextScale, 1.15);
    });
  });

  group('ChatBubble Mensch (UI-80)', () {
    testWidgets('eigene rechts auf surface-opaque, Gegenüber links auf Glas '
        'ohne Blur; Ecke zur Absenderseite 6 dp', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              ChatBubble(
                text: 'Eigene Nachricht',
                fromMe: true,
                semanticsLabel: 'Du: Eigene Nachricht',
              ),
              SizedBox(height: 8),
              ChatBubble(
                text: 'Antwort',
                fromMe: false,
                semanticsLabel: 'Praxis: Antwort',
              ),
            ],
          ),
        ),
      );
      final Rect mine = tester.getRect(
        find.ancestor(
          of: find.text('Eigene Nachricht'),
          matching: find.byType(OpaqueSurface),
        ),
      );
      final Finder other = find.ancestor(
        of: find.text('Antwort'),
        matching: find.byType(GlassCard),
      );
      final Rect theirs = tester.getRect(other);
      expect(mine.right, 390 - 16);
      expect(theirs.left, 16);
      expect(backdropCount(tester), 0);
      final BorderRadius theirsRadius = tester
          .widget<GlassCard>(other)
          .borderRadius!;
      expect(theirsRadius.bottomLeft.x, 6, reason: 'Gegenüber links');
      expect(theirsRadius.bottomRight.x, 20);
      expect(theirs.width, lessThanOrEqualTo(358 * 0.8 + 0.01));
    });

    testWidgets('Semantik-Präfix', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(
        tester,
        const ChatBubble(
          text: 'Antwort',
          fromMe: false,
          semanticsLabel: 'Praxis Müller: Antwort',
        ),
      );
      expect(find.bySemanticsLabel('Praxis Müller: Antwort'), findsOneWidget);
      h.dispose();
    });
  });

  group('ContactRow (UI-79)', () {
    ExampleContact contact(String id) =>
        kExampleContacts.firstWhere((ExampleContact c) => c.id == id);

    testWidgets('≥ 72 dp, ganze Zeile antippbar, Name bodyStrong, Vorschau '
        'secondary text-2 umbrechend, Zeit caption text-3', (
      WidgetTester tester,
    ) async {
      int taps = 0;
      await pumpApp(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: ContactRow(
            contact: contact('physio-mueller'),
            vorname: 'Jakob',
            onPressed: () => taps++,
          ),
        ),
        textScale: 2,
        size: Viewports.small,
      );
      final Rect row = tester.getRect(find.byType(ContactRow));
      expect(row.height, greaterThanOrEqualTo(72));
      expect(tester.takeException(), isNull);
      // Ganze Zeile: ein Tipp links außen und rechts außen trifft.
      await tester.tapAt(row.centerLeft + const Offset(2, 0));
      await tester.tapAt(row.centerRight - const Offset(2, 0));
      await tester.tapAt(row.topCenter + const Offset(0, 2));
      await tester.tapAt(row.bottomCenter - const Offset(0, 2));
      expect(taps, 4);
      final CuraColors c = colorsAt(tester, find.byType(ContactRow));
      expect(
        tester.widget<Text>(find.text('Praxis Müller')).style!.color,
        c.text1,
      );
      final Text preview = tester.widget(find.text(S.examplePhysioLine3));
      expect(preview.style!.color, c.text2);
      expect(preview.maxLines, isNull, reason: 'bricht um, nie abgeschnitten');
      expect(tester.widget<Text>(find.text('Mo')).style!.color, c.text3);
    });

    testWidgets('Ring: Physio cat-physio, Ärzte cat-arzt, sonst Weiß 30 %; '
        'Hoher Kontrast border-control-hc', (WidgetTester tester) async {
      Future<Color> ring(String id, {bool hc = false}) async {
        await pumpApp(
          tester,
          ContactRow(contact: contact(id), vorname: 'Jakob', onPressed: () {}),
          highContrast: hc,
        );
        await tester.pumpAndSettle();
        final Finder avatar = find.byType(ChatAvatar);
        final BoxDecoration d = decorationsUnder(tester, avatar).first;
        expect(d.color, colorsAt(tester, avatar).surfaceOpaque);
        expect((d.border! as Border).top.width, 2);
        return (d.border! as Border).top.color;
      }

      final CuraColors n = CuraColors.dark;
      expect(await ring('physio-mueller'), n.catPhysio);
      expect(await ring('aerzte-weber'), n.catArzt);
      expect(await ring('familie-mama'), n.avatarRingNeutral);
      expect(await ring('freunde-lena'), n.avatarRingNeutral);
      final CuraColors hc = CuraColors.darkHighContrast;
      expect(await ring('physio-mueller', hc: true), hc.controlBorder);
      expect(await ring('aerzte-weber', hc: true), hc.controlBorder);
    });

    testWidgets('Semantik: Beispielkontakt …, Öffnet Beispiel-Chat', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pumpApp(
        tester,
        ContactRow(
          contact: contact('physio-mueller'),
          vorname: 'Jakob',
          onPressed: () {},
        ),
      );
      expect(
        find.bySemanticsLabel(
          'Beispielkontakt Praxis Müller, Physio. Letzte Nachricht: '
          'Bring bitte Sportschuhe mit., Montag. Öffnet Beispiel-Chat.',
        ),
        findsOneWidget,
      );
      h.dispose();
    });
  });

  group('CuraFullscreenRoute (UI-86, Plan 4.4)', () {
    Future<NavigatorState> pumpHost(
      WidgetTester tester, {
      bool reduced = false,
    }) async {
      if (reduced) {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
      }
      await pumpApp(tester, const Text('Grund'));
      return Navigator.of(tester.element(find.text('Grund')));
    }

    testWidgets('Einblenden plus 24 dp Schiebung von rechts in dur-base', (
      WidgetTester tester,
    ) async {
      final NavigatorState nav = await pumpHost(tester);
      nav.push<void>(
        CuraFullscreenRoute<void>(
          context: tester.element(find.text('Grund')),
          routeLabel: 'Test',
          builder: (BuildContext context) => const Text('Neu'),
        ),
      );
      await tester.pump();
      await tester.pump();
      final double start = tester.getTopLeft(find.text('Neu')).dx;
      await tester.pump(const Duration(milliseconds: 100));
      final double mid = tester.getTopLeft(find.text('Neu')).dx;
      await tester.pumpAndSettle();
      final double end = tester.getTopLeft(find.text('Neu')).dx;
      expect(start - end, lessThanOrEqualTo(24.001));
      expect(start - end, greaterThan(15), reason: 'beginnt ca. 24 dp rechts');
      expect(mid, lessThan(start));
      expect(mid, greaterThan(end));
    });

    testWidgets('Bewegung reduzieren: keine Schiebung, nach 121 ms keine '
        'laufende Animation', (WidgetTester tester) async {
      final NavigatorState nav = await pumpHost(tester, reduced: true);
      nav.push<void>(
        CuraFullscreenRoute<void>(
          context: tester.element(find.text('Grund')),
          routeLabel: 'Test',
          builder: (BuildContext context) => const Text('Neu'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      final double start = tester.getTopLeft(find.text('Neu')).dx;
      await tester.pump(const Duration(milliseconds: 121));
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.getTopLeft(find.text('Neu')).dx, start);
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('opak, kein Scrim, kein Blur; Routenname für den '
        'Screenreader; Zurück schließt', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      final NavigatorState nav = await pumpHost(tester);
      final CuraFullscreenRoute<void> route = CuraFullscreenRoute<void>(
        context: tester.element(find.text('Grund')),
        routeLabel: 'Manny, Chat',
        builder: (BuildContext context) => const Text('Neu'),
      );
      nav.push<void>(route);
      await tester.pumpAndSettle();
      expect(route.opaque, isTrue);
      expect(route.barrierColor, isNull);
      expect(route.barrierDismissible, isFalse);
      expect(find.text('Grund'), findsNothing, reason: 'verdeckt (opak)');
      expect(backdropCount(tester), 0);
      expect(find.bySemanticsLabel('Manny, Chat'), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Neu'), findsNothing);
      expect(find.text('Grund'), findsOneWidget);
      h.dispose();
    });
  });
}
