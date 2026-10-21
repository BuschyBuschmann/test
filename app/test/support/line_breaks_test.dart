// Selbsttest von `line_breaks.dart`: Der Wortgrenzen-Test (F-3, F-4) ist nur
// etwas wert, wenn er einen Umbruch mitten im Wort auch meldet.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'line_breaks.dart';

void main() {
  test('midWordBreaks: Umbruch mitten im Wort wird gemeldet', () {
    expect(
      midWordBreaks(<String>['Prävention & Gesundh', 'eitssport']),
      hasLength(1),
    );
    expect(
      midWordBreaks(<String>['Prävention & ', 'Gesundheitssport']),
      isEmpty,
    );
    expect(midWordBreaks(<String>['Eins ', 'zwei ', 'drei']), isEmpty);
    expect(midWordBreaks(<String>['Ein-', 'Wort']), isEmpty);
    expect(midWordBreaks(<String>['einzeilig']), isEmpty);
    expect(midWordBreaks(const <String>[]), isEmpty);
  });

  testWidgets('paragraphLines liest die tatsächlichen Zeilen eines Textes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 60,
            child: Text(
              'aaa bbb ccc',
              style: TextStyle(fontSize: 20, fontFamily: 'Ahem'),
            ),
          ),
        ),
      ),
    );
    final List<String> lines = paragraphLines(tester, find.text('aaa bbb ccc'));
    expect(lines.join(), 'aaa bbb ccc');
    expect(lines.length, greaterThan(1));
    // Ahem: 20 dp je Zeichen, 60 dp breit: ein Wort je Zeile, kein Wortbruch.
    expect(midWordBreaks(lines), isEmpty);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 50,
            child: Text(
              'Gesundheit',
              style: TextStyle(fontSize: 20, fontFamily: 'Ahem'),
            ),
          ),
        ),
      ),
    );
    // Wort breiter als die Zeile: der Umbruch mitten im Wort wird erkannt.
    final List<String> broken = paragraphLines(tester, find.text('Gesundheit'));
    expect(broken.length, greaterThan(1));
    expect(midWordBreaks(broken), isNotEmpty);
  });
}
