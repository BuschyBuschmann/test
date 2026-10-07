// Gemeinsame Helfer der Baustein-Tests (U2a).
import 'package:curaone/theme/cura_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Farben des aktuellen Themes an der Stelle von [finder].
CuraColors colorsAt(WidgetTester tester, Finder finder) =>
    CuraColors.of(tester.element(finder));

/// Alle `DecoratedBox`-Dekorationen unterhalb von [finder].
Iterable<BoxDecoration> decorationsUnder(WidgetTester tester, Finder finder) {
  return find
      .descendant(of: finder, matching: find.byType(DecoratedBox))
      .evaluate()
      .map((Element e) => (e.widget as DecoratedBox).decoration)
      .whereType<BoxDecoration>();
}

/// Anzahl `BackdropFilter` im gesamten Baum.
int backdropCount(WidgetTester tester) =>
    find.byType(BackdropFilter).evaluate().length;
