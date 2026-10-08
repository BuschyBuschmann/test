/// Abkürzungen, deren Punkt kein Satzende ist (Plan 7.4).
const List<String> kAbbreviations = <String>[
  'ca.',
  'z. B.',
  'Nr.',
  'Wdh.',
  'Sek.',
];

/// Zählt Sätze: Satzende ist `.`, `!` oder `?` gefolgt von Leerraum oder Ende;
/// Abkürzungen aus [kAbbreviations] zählen nicht.
int countSentences(String text) {
  String t = text;
  for (final String a in kAbbreviations) {
    t = t.replaceAll(a, a.replaceAll('.', '·'));
  }
  return RegExp(r'[.!?]+(?=\s|$)').allMatches(t.trim()).length;
}
