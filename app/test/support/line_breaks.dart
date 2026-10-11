// Zeilenumbrüche gerenderter Texte (F-3, F-4, R-AB-2): Ein Umbruch mitten im
// Wort („Gesundh/eitssport“) ist ein Mangel (Präzedenz B3); erlaubt sind nur
// Umbrüche an Wortgrenzen.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die Zeilen des ersten [RenderParagraph] unter [finder] (Text je Zeile mit
/// Leerzeichen am Ende, wie die Zeile gesetzt ist).
List<String> paragraphLines(WidgetTester tester, Finder finder) {
  final RenderParagraph p = _paragraphOf(tester, finder);
  final String text = p.text.toPlainText();
  // Gleicher Text, gleiche Skalierung und Breite wie das gerenderte Objekt.
  final TextPainter tp = TextPainter(
    text: p.text,
    textDirection: p.textDirection,
    textScaler: p.textScaler,
    textAlign: p.textAlign,
  )..layout(maxWidth: p.constraints.maxWidth);
  final List<String> lines = <String>[];
  int pos = 0;
  while (pos < text.length) {
    final TextRange r = tp.getLineBoundary(TextPosition(offset: pos));
    if (r.end <= pos) break;
    lines.add(text.substring(r.start, r.end));
    pos = r.end;
  }
  tp.dispose();
  return lines;
}

RenderParagraph _paragraphOf(WidgetTester tester, Finder finder) {
  final Element e = finder.evaluate().first;
  RenderParagraph? found;
  void walk(RenderObject r) {
    if (found != null) return;
    if (r is RenderParagraph) {
      found = r;
      return;
    }
    r.visitChildren(walk);
  }

  final RenderObject? ro = e.renderObject;
  if (ro is RenderParagraph) return ro;
  if (ro != null) walk(ro);
  return found!;
}

/// Alle Zeilen außer der letzten enden an einer Wortgrenze (Leerzeichen am
/// Zeilenende bzw. Bindestrich-Wort). Liefert die Verstöße als Text, leer =
/// in Ordnung.
List<String> midWordBreaks(List<String> lines) {
  final List<String> bad = <String>[];
  for (int i = 0; i + 1 < lines.length; i++) {
    final String line = lines[i];
    final String next = lines[i + 1];
    final bool endsAtSpace = line.endsWith(' ') || line.endsWith('\n');
    final bool endsAtHyphen = line.endsWith('-');
    final bool nextStartsWord = next.isNotEmpty && next[0] != ' ';
    if (!(endsAtSpace || endsAtHyphen) || !nextStartsWord) {
      bad.add('"${line.trimRight()}" | "${next.trimRight()}"');
    }
  }
  return bad;
}
