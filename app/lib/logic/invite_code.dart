// Einladungscode (Plan 6.5, N-7): 10 Zeichen Crockford-Base32, Anzeige
// `XXXXX-XXXXX`. Normalisierung und Alphabet entsprechen der Datenbankfunktion
// `app.normalize_invite_code` und der Prüfung in `redeem_invitation`.
// Reine Dart-Logik.

/// Crockford-Base32 ohne `I L O U` (32 Zeichen).
const String kInviteAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

const int kInviteCodeLength = 10;
const int kInviteCodeGroup = 5;

/// Normalisiert eine Eingabe: Großschreibung; Leerzeichen und Bindestriche
/// entfernen; `O` → `0`, `I`/`L` → `1`. Prüft nicht auf Gültigkeit.
String normalizeInviteCode(String raw) {
  final StringBuffer out = StringBuffer();
  for (final int unit in raw.toUpperCase().runes) {
    final String ch = String.fromCharCode(unit);
    if (ch == '-' || ch.trim().isEmpty) continue;
    switch (ch) {
      case 'O':
        out.write('0');
      case 'I':
      case 'L':
        out.write('1');
      default:
        out.write(ch);
    }
  }
  return out.toString();
}

/// `true`, wenn [normalized] (Ergebnis von [normalizeInviteCode]) genau 10
/// Zeichen des Alphabets hat.
bool isValidNormalizedInviteCode(String normalized) {
  if (normalized.length != kInviteCodeLength) return false;
  for (final int unit in normalized.codeUnits) {
    if (!kInviteAlphabet.contains(String.fromCharCode(unit))) return false;
  }
  return true;
}

/// Normalisierter, gültiger Code oder `null`.
String? parseInviteCode(String raw) {
  final String n = normalizeInviteCode(raw);
  return isValidNormalizedInviteCode(n) ? n : null;
}

/// Anzeigeform `XXXXX-XXXXX` für einen gültigen Code, sonst `null`.
String? formatInviteCode(String raw) {
  final String? n = parseInviteCode(raw);
  if (n == null) return null;
  return '${n.substring(0, kInviteCodeGroup)}-${n.substring(kInviteCodeGroup)}';
}

/// Eingabehilfe während des Tippens: normalisiert, kürzt auf 10 Zeichen und
/// setzt nach dem fünften Zeichen den Bindestrich. Unzulässige Zeichen
/// bleiben erhalten (die Prüfung meldet sie), damit nichts still verschwindet.
String formatInviteCodeInput(String raw) {
  final String n = normalizeInviteCode(raw);
  final String cut = n.length > kInviteCodeLength
      ? n.substring(0, kInviteCodeLength)
      : n;
  if (cut.length <= kInviteCodeGroup) return cut;
  return '${cut.substring(0, kInviteCodeGroup)}-${cut.substring(kInviteCodeGroup)}';
}

/// Code aus einem Einladungslink (Plan 6.6): `<BASIS>/?einladung=XXXXX-XXXXX`
/// oder `curaone://einladung?code=XXXXX-XXXXX`. Liefert den **normalisierten**
/// Code, auch wenn er ungültig ist (das Feld soll ihn zeigen, B-8); `null`
/// ohne Parameter.
String? inviteCodeFromLink(Uri link) {
  final String? value =
      link.queryParameters['einladung'] ?? link.queryParameters['code'];
  if (value == null) return null;
  final String n = normalizeInviteCode(value);
  return n.isEmpty ? null : n;
}
