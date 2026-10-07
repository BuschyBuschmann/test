// MINOR-3 (R-U1): Material-Standards dürfen `accent` nicht als Textfarbe
// nehmen (Brief-E-2, UI-4). `colorScheme.primary` bleibt `accent`.
import 'package:curaone/theme/cura_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

/// Alle Textfarben unterhalb von [root].
Set<Color> textColors(WidgetTester tester, Finder root) {
  final Set<Color> out = <Color>{};
  for (final Element e
      in find
          .descendant(of: root, matching: find.byType(RichText))
          .evaluate()) {
    final RenderParagraph p = e.renderObject! as RenderParagraph;
    p.text.visitChildren((InlineSpan span) {
      final Color? c = span.style?.color;
      if (c != null) out.add(c);
      return true;
    });
    final Color? top = p.text.style?.color;
    if (top != null) out.add(top);
  }
  return out;
}

void main() {
  final CuraColors colors = CuraColors.dark;

  testWidgets('TextButton ohne eigenen Stil: Text accentHi, nicht accent', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      TextButton(onPressed: () {}, child: const Text('Weiter')),
    );
    expect(textColors(tester, find.byType(TextButton)), <Color>{
      colors.accentHi,
    });
  });

  testWidgets('fokussiertes Eingabefeld: Label nie accent', (
    WidgetTester tester,
  ) async {
    final FocusNode node = FocusNode();
    addTearDown(node.dispose);
    await pumpApp(
      tester,
      TextField(
        focusNode: node,
        decoration: const InputDecoration(labelText: 'Dein Name'),
      ),
    );
    node.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final Set<Color> used = textColors(tester, find.byType(TextField));
    expect(used, isNot(contains(colors.accent)));
    expect(used, contains(colors.accentHi));
  });

  for (final DatePickerEntryMode mode in <DatePickerEntryMode>[
    DatePickerEntryMode.calendarOnly,
    DatePickerEntryMode.inputOnly,
  ]) {
    testWidgets('Datumsauswahl ($mode): kein Text in accent', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () => showDatePicker(
              context: context,
              initialDate: DateTime(2026, 10, 7),
              firstDate: DateTime(2024),
              lastDate: DateTime(2026, 10, 7),
              initialEntryMode: mode,
            ),
            child: const Text('Datum'),
          ),
        ),
      );
      await tester.tap(find.text('Datum'));
      await tester.pumpAndSettle();
      if (mode == DatePickerEntryMode.inputOnly) {
        await tester.tap(find.byType(TextField));
        await tester.pump();
      }
      final Set<Color> used = textColors(tester, find.byType(Dialog));
      expect(used, isNot(contains(colors.accent)));
    });
  }
}
