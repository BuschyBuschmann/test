// Unverbindlicher Platzhalter, keine Spec (Brief-Ergänzung 2, K10).
//
// Beispielkontakte und Beispiel-Chats der Nachrichten-Übersicht: erfundene,
// rein organisatorische Platzhalter. Sie legen keine Funktion, Kategorie oder
// Datenstruktur fest und ersetzen keine Spec (Direktnachrichten haben keine
// Spec; Haftung und Datenschutz für Ärzte-Chats sind ungeklärt). Eigene feste
// Daten, **nicht** als `ChatMessage` und ohne Verbindung zum Manny-Chat
// (KS-10, UI-83). Alle Texte stehen in `strings_de.dart`.
import '../../l10n/strings_de.dart';

/// Abschnitt der Übersicht (Gruppierung statt Filter).
enum ExampleSection {
  physio(S.sectionPhysio),
  family(S.sectionFamily),
  friends(S.sectionFriends),
  doctors(S.sectionDoctors);

  const ExampleSection(this.title);

  /// Abschnittsüberschrift („Physio“, „Familie“, „Freunde“, „Ärzte“).
  final String title;
}

/// Eine Zeile des Beispiel-Chats; [fromMe] = vom Nutzer („Du“).
class ExampleLine {
  const ExampleLine({required this.fromMe, required this.text});

  final bool fromMe;
  final String text;
}

class ExampleContact {
  const ExampleContact({
    required this.id,
    required this.section,
    required this.initials,
    required this.name,
    required this.role,
    required this.weekday,
    required this.lines,
  });

  final String id;
  final ExampleSection section;
  final String initials;
  final String name;

  /// Rolle im Kopf des Beispiel-Chats („Physio“, „Arzt“ …), ohne „· Beispiel“.
  final String role;

  /// Platzhalter-Wochentag (0 = Montag), keine echte Chronologie.
  final int weekday;

  /// Verlauf; die erste Zeile des Physio-Chats nennt den Vornamen aus dem
  /// Onboarding.
  final List<ExampleLine> Function(String vorname) lines;

  String dayShort() => S.weekdaysShort[weekday];
  String dayLong() => S.weekdays[weekday];

  /// Vorschau der Übersicht = letzte Nachricht des Beispiel-Chats.
  String lastMessage(String vorname) => lines(vorname).last.text;
}

List<ExampleLine> _physio(String vorname) => <ExampleLine>[
  ExampleLine(fromMe: false, text: S.examplePhysioLine1(vorname)),
  const ExampleLine(fromMe: true, text: S.examplePhysioLine2),
  const ExampleLine(fromMe: false, text: S.examplePhysioLine3),
];

List<ExampleLine> _mama(String vorname) => const <ExampleLine>[
  ExampleLine(fromMe: true, text: S.exampleMamaLine1),
  ExampleLine(fromMe: false, text: S.exampleMamaLine2),
];

List<ExampleLine> _tim(String vorname) => const <ExampleLine>[
  ExampleLine(fromMe: true, text: S.exampleTimLine1),
  ExampleLine(fromMe: false, text: S.exampleTimLine2),
];

List<ExampleLine> _lena(String vorname) => const <ExampleLine>[
  ExampleLine(fromMe: true, text: S.exampleLenaLine1),
  ExampleLine(fromMe: false, text: S.exampleLenaLine2),
];

List<ExampleLine> _basti(String vorname) => const <ExampleLine>[
  ExampleLine(fromMe: true, text: S.exampleBastiLine1),
  ExampleLine(fromMe: false, text: S.exampleBastiLine2),
];

List<ExampleLine> _weber(String vorname) => const <ExampleLine>[
  ExampleLine(fromMe: true, text: S.exampleWeberLine1),
  ExampleLine(fromMe: false, text: S.exampleWeberLine2),
];

/// Die sechs Beispielkontakte in der Reihenfolge der Übersicht
/// (Ergänzung 2, 3.3).
const List<ExampleContact> kExampleContacts = <ExampleContact>[
  ExampleContact(
    id: 'physio-mueller',
    section: ExampleSection.physio,
    initials: S.contactPhysioInitials,
    name: S.contactPhysioName,
    role: S.rolePhysio,
    weekday: 0,
    lines: _physio,
  ),
  ExampleContact(
    id: 'familie-mama',
    section: ExampleSection.family,
    initials: S.contactMamaInitials,
    name: S.contactMamaName,
    role: S.roleFamily,
    weekday: 1,
    lines: _mama,
  ),
  ExampleContact(
    id: 'familie-tim',
    section: ExampleSection.family,
    initials: S.contactTimInitials,
    name: S.contactTimName,
    role: S.roleFamily,
    weekday: 6,
    lines: _tim,
  ),
  ExampleContact(
    id: 'freunde-lena',
    section: ExampleSection.friends,
    initials: S.contactLenaInitials,
    name: S.contactLenaName,
    role: S.roleFriends,
    weekday: 5,
    lines: _lena,
  ),
  ExampleContact(
    id: 'freunde-basti',
    section: ExampleSection.friends,
    initials: S.contactBastiInitials,
    name: S.contactBastiName,
    role: S.roleFriends,
    weekday: 4,
    lines: _basti,
  ),
  ExampleContact(
    id: 'aerzte-weber',
    section: ExampleSection.doctors,
    initials: S.contactWeberInitials,
    name: S.contactWeberName,
    role: S.roleDoctor,
    weekday: 3,
    lines: _weber,
  ),
];

/// Kontakte eines Abschnitts in der Reihenfolge der Übersicht.
List<ExampleContact> exampleContactsIn(ExampleSection section) =>
    <ExampleContact>[
      for (final ExampleContact c in kExampleContacts)
        if (c.section == section) c,
    ];

/// Label der Zeile für den Screenreader (Ergänzung 2, 3.5).
String exampleContactLabel(ExampleContact c, String vorname) =>
    S.contactRowLabel(
      c.name,
      c.section.title,
      c.lastMessage(vorname),
      c.dayLong(),
    );
