// CuraDialog (Ergänzung 1 Abschnitt 2, UI-49, UI-65, UI-66, UI-68): Aufbau,
// Maße, gestapelte Buttons, Scrollen bei Enge, Semantik `alertdialog`,
// Anfangsfokus, Hoher Kontrast.
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/ui/components/cura_dialog.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/line_breaks.dart';
import '../support/pump_app.dart';

const String _msg =
    'Name, Verletzung, Pfad, Streak und deine Einwilligung werden von diesem '
    'Gerät gelöscht. Das lässt sich nicht rückgängig machen. Danach startest '
    'du wieder bei Schritt 1.';

Widget _dialog({
  Size screen = Viewports.phone,
  String message = _msg,
  Widget? extra,
  VoidCallback? onCancel,
}) => Center(
  child: ConstrainedBox(
    constraints: BoxConstraints(maxHeight: screen.height - 2 * 16),
    child: CuraDialog(
      icon: Icons.delete_outline_rounded,
      title: 'Alles löschen?',
      message: message,
      extra: extra,
      actions: <Widget>[
        PillButton(
          label: 'Abbrechen',
          variant: PillButtonVariant.neutral,
          autofocus: true,
          onPressed: onCancel ?? () {},
        ),
        PillButton(
          label: 'Ja, alles löschen',
          variant: PillButtonVariant.outline,
          icon: Icons.delete_outline_rounded,
          onPressed: () {},
        ),
      ],
    ),
  ),
);

void main() {
  testWidgets('opak surface-opaque, Rand hair, Radius 24, Icon 28 dp, Titel '
      'title, Text body; kein Blur', (WidgetTester tester) async {
    await pumpApp(tester, _dialog());
    await tester.pumpAndSettle();
    final Finder f = find.byType(CuraDialog);
    final CuraColors c = colorsAt(tester, f);
    final BoxDecoration d = decorationsUnder(tester, f).first;
    expect(d.color, c.surfaceOpaque);
    expect(d.borderRadius, BorderRadius.circular(28));
    expect(d.border, Border.all(color: c.borderHair, width: 1));
    expect(d.boxShadow, isNull);
    expect(backdropCount(tester), 0);
    final Icon icon = tester.widget(
      find.byIcon(Icons.delete_outline_rounded).first,
    );
    expect(icon.size, 28);
    expect(icon.color, c.text1);
    final TextStyle title = tester
        .widget<Text>(find.text('Alles löschen?'))
        .style!;
    expect(title.fontSize, 24);
    expect(title.fontFamily, 'BricolageGrotesque');
    expect(title.color, c.text1);
    final TextStyle body = tester.widget<Text>(find.text(_msg)).style!;
    expect(body.fontSize, 16);
    expect(body.color, c.text1);
  });

  testWidgets('Breite: Bildschirm − 32 dp, höchstens 400 dp', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      _dialog(screen: Viewports.small),
      size: Viewports.small,
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(decoratedDialog(tester)).width, 320 - 32);
    await pumpApp(tester, _dialog(), size: Viewports.phone);
    await tester.pumpAndSettle();
    expect(tester.getSize(decoratedDialog(tester)).width, 390 - 32);
    await pumpApp(
      tester,
      _dialog(screen: Viewports.tablet),
      size: Viewports.tablet,
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(decoratedDialog(tester)).width, 400);
  });

  testWidgets('Buttons gestapelt, volle Breite, 56 dp, Abstand 8 dp; sichere '
      'Aktion oben mit Anfangsfokus', (WidgetTester tester) async {
    await pumpApp(tester, _dialog());
    await tester.pumpAndSettle();
    final Rect a = tester.getRect(find.widgetWithText(PillButton, 'Abbrechen'));
    final Rect b = tester.getRect(
      find.widgetWithText(PillButton, 'Ja, alles löschen'),
    );
    expect(a.height, 56);
    expect(b.height, 56);
    expect(a.width, b.width);
    expect(b.top - a.bottom, 8);
    final Rect dlg = tester.getRect(decoratedDialog(tester));
    expect(a.left - dlg.left, 24);
    expect(a.width, dlg.width - 48);
    // Anfangsfokus auf „Abbrechen“.
    expect(
      _focusIsWithin(find.widgetWithText(PillButton, 'Abbrechen')),
      isTrue,
    );
    expect(
      _focusIsWithin(find.widgetWithText(PillButton, 'Ja, alles löschen')),
      isFalse,
    );
  });

  testWidgets('Zusatzinhalt (Fehlerhinweis) steht über den Buttons', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      _dialog(
        extra: const Text('Das Löschen hat nicht geklappt.', key: Key('extra')),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const Key('extra'))).bottom,
      lessThan(
        tester.getRect(find.widgetWithText(PillButton, 'Abbrechen')).top,
      ),
    );
  });

  testWidgets('Enge unter 150 % (320 × 568, 130 %): Inhalt scrollt, Buttons '
      'bleiben unten stehen', (WidgetTester tester) async {
    await pumpApp(
      tester,
      _dialog(screen: Viewports.small, message: '$_msg $_msg $_msg'),
      size: Viewports.small,
      textScale: 1.3,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final Finder scroll = find.descendant(
      of: find.byType(CuraDialog),
      matching: find.byType(SingleChildScrollView),
    );
    final ScrollableState st = tester.state(
      find.descendant(of: scroll, matching: find.byType(Scrollable)),
    );
    expect(st.position.maxScrollExtent, greaterThan(0));
    final Rect cancel = tester.getRect(
      find.widgetWithText(PillButton, 'Abbrechen'),
    );
    final Rect confirm = tester.getRect(
      find.widgetWithText(PillButton, 'Ja, alles löschen'),
    );
    expect(cancel.top, greaterThanOrEqualTo(0));
    expect(confirm.bottom, lessThanOrEqualTo(568));
    // Scrollen verschiebt den Text, nicht die Buttons.
    final double before = tester.getRect(find.text('Alles löschen?')).top;
    await tester.drag(scroll, const Offset(0, -80));
    await tester.pump();
    expect(tester.getRect(find.text('Alles löschen?')).top, lessThan(before));
    expect(
      tester.getRect(find.widgetWithText(PillButton, 'Abbrechen')),
      cancel,
    );
  });

  group('F-4: ab 150 % scrollt der ganze Dialog', () {
    for (final double scale in <double>[1.5, 2.0]) {
      testWidgets('320 × 568 × $scale: Titel höchstens 150 %, Buttons laufen '
          'mit, kein Symbol in den Buttons, Seitenrand s4, ohne Wortbruch', (
        WidgetTester tester,
      ) async {
        await pumpApp(
          tester,
          _dialog(screen: Viewports.small, message: '$_msg $_msg'),
          size: Viewports.small,
          textScale: scale,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final Finder scroll = find.descendant(
          of: find.byType(CuraDialog),
          matching: find.byType(SingleChildScrollView),
        );
        // Nur ein Scrollbereich: der ganze Dialog (Titel, Text, Buttons).
        expect(scroll, findsOneWidget);
        expect(
          find.descendant(of: scroll, matching: find.byType(PillButton)),
          findsNWidgets(2),
        );
        // Titel auf 150 % geklemmt.
        expect(
          MediaQuery.textScalerOf(tester.element(find.text('Alles löschen?')))
              .scale(10),
          lessThanOrEqualTo(15 + 0.01),
        );
        // Kein Symbol in den Dialog-Buttons.
        expect(
          find.descendant(
            of: find.byType(PillButton),
            matching: find.byType(Icon),
          ),
          findsNothing,
        );
        // Seitenrand s4 (16 dp) statt s6 (24 dp).
        final Rect button = tester.getRect(
          find.widgetWithText(PillButton, 'Abbrechen'),
        );
        final Rect label = tester.getRect(find.text('Abbrechen'));
        expect(label.left - button.left, greaterThanOrEqualTo(16));
        expect(label.left - button.left, lessThan(24 + 40));
        final Rect padded = tester.getRect(
          find
              .descendant(
                of: find.widgetWithText(PillButton, 'Ja, alles löschen'),
                matching: find.byType(Padding),
              )
              .first,
        );
        expect(padded.width, button.width);
        // Wortbruch: nur an Wortgrenzen.
        for (final String t in <String>['Abbrechen', 'Ja, alles löschen']) {
          final List<String> lines = paragraphLines(tester, find.text(t));
          expect(lines.join(), t);
          expect(midWordBreaks(lines), isEmpty, reason: '$t: $lines');
        }
        // Die Buttons laufen mit dem Inhalt (der ganze Dialog scrollt).
        final Rect before = tester.getRect(
          find.widgetWithText(PillButton, 'Abbrechen'),
        );
        await tester.drag(scroll, const Offset(0, -80));
        await tester.pump();
        expect(
          tester.getRect(find.widgetWithText(PillButton, 'Abbrechen')).top,
          lessThan(before.top),
        );
        // Am Ende des Wegs sind beide Buttons ganz zu sehen.
        final ScrollableState st = tester.state(
          find.descendant(of: scroll, matching: find.byType(Scrollable)),
        );
        st.position.jumpTo(st.position.maxScrollExtent);
        await tester.pump();
        expect(
          tester
              .getRect(find.widgetWithText(PillButton, 'Ja, alles löschen'))
              .bottom,
          lessThanOrEqualTo(568),
        );
      });
    }

    testWidgets('R-1: im scrollenden Dialog liegt ein Innenrand um die '
        'Buttons (Fokusring wird seitlich nicht abgeschnitten)', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        _dialog(screen: Viewports.small),
        size: Viewports.small,
        textScale: 2,
      );
      await tester.pumpAndSettle();
      final Rect view = tester.getRect(
        find.descendant(
          of: find.byType(CuraDialog),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      for (final String t in <String>['Abbrechen', 'Ja, alles löschen']) {
        final Rect b = tester.getRect(find.widgetWithText(PillButton, t));
        expect(b.left - view.left, greaterThanOrEqualTo(4 - 0.01), reason: t);
        expect(view.right - b.right, greaterThanOrEqualTo(4 - 0.01), reason: t);
      }
    });

    testWidgets('320 × 568 × 2,0: der Zusatz (Fehlerhinweis) steht gleich '
        'unter dem Titel und ist ohne Scrollen sichtbar', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        _dialog(
          screen: Viewports.small,
          extra: const Text('Fehlerhinweis', key: Key('extra')),
        ),
        size: Viewports.small,
        textScale: 2,
      );
      await tester.pumpAndSettle();
      final Rect extra = tester.getRect(find.byKey(const Key('extra')));
      expect(extra.top, greaterThanOrEqualTo(0));
      expect(extra.bottom, lessThanOrEqualTo(568));
      expect(
        extra.top,
        lessThan(tester.getRect(find.textContaining('Name, Verletzung')).top),
      );
    });

    testWidgets('bis 130 %: Symbol bleibt, Seitenrand s6, Zusatz unter dem '
        'Text', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _dialog(extra: const Text('Fehlerhinweis', key: Key('extra'))),
        textScale: 1.3,
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.widgetWithText(PillButton, 'Ja, alles löschen'),
          matching: find.byType(Icon),
        ),
        findsOneWidget,
      );
      expect(
        tester.getRect(find.byKey(const Key('extra'))).top,
        greaterThan(
          tester.getRect(find.textContaining('Name, Verletzung')).top,
        ),
      );
    });
  });

  testWidgets('Semantik: alertdialog, Route umfasst den Dialog, Titel '
      'benennt die Route', (WidgetTester tester) async {
    final SemanticsHandle h = tester.ensureSemantics();
    await pumpApp(tester, _dialog());
    await tester.pumpAndSettle();
    final SemanticsNode dialog = tester.getSemantics(
      find
          .descendant(
            of: find.byType(CuraDialog),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(dialog, isSemantics(scopesRoute: true));
    expect(
      find.semantics.byPredicate(
        (SemanticsNode n) => n.role == SemanticsRole.alertDialog,
      ),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.text('Alles löschen?')),
      isSemantics(label: 'Alles löschen?', namesRoute: true, isHeader: true),
    );
    // Das Icon ist dekorativ.
    expect(find.bySemanticsLabel(RegExp('delete')), findsNothing);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    h.dispose();
  });

  testWidgets('Hoher Kontrast: Rand border-control-hc, opak, kein Blur', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, _dialog(), highContrast: true);
    await tester.pumpAndSettle();
    final CuraColors c = colorsAt(tester, find.byType(CuraDialog));
    final BoxDecoration d = decorationsUnder(
      tester,
      find.byType(CuraDialog),
    ).first;
    expect(d.color, c.surfaceOpaque);
    expect(d.border, Border.all(color: c.borderControlHc, width: 1));
    expect(backdropCount(tester), 0);
  });
}

/// Liegt der Primärfokus innerhalb des Elements von [finder]?
bool _focusIsWithin(Finder finder) {
  final BuildContext? focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  final Element target = finder.evaluate().single;
  bool inside = false;
  focused.visitAncestorElements((Element e) {
    if (e == target) inside = true;
    return !inside;
  });
  return inside;
}

/// Die Dialogfläche (erste `DecoratedBox` im `CuraDialog`).
Finder decoratedDialog(WidgetTester tester) => find
    .descendant(
      of: find.byType(CuraDialog),
      matching: find.byType(DecoratedBox),
    )
    .first;
