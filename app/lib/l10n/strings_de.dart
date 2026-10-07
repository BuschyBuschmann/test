// Alle sichtbaren und vorgelesenen Texte (KONVENTIONEN Regel 4, Plan A-26).
//
// Diese Datei hat bewusst **keinen Flutter-Import** (und kein `dart:ui`),
// damit `lib/logic/` die Texte nutzen darf (Konvention 3, Regel 7).
// Ton: Deutsch, „du“, kurz, direkt, nie klinisch (UI-36, UI-69, Regel 10).
//
// Hinweis: Inhalte, die als „Platzhalter“ gekennzeichnet sind, ersetzt später
// das Physio-Framework bzw. die KI-Anbindung (Plan N-4).

abstract final class S {
  // -------------------------------------------------------------------------
  // Plural (B-5)
  // -------------------------------------------------------------------------
  static const String dayOne = '1 Tag';
  static String dayMany(int n) => '$n Tage';

  /// Dativ („Dein Streak von 12 Tagen …“, Brief 6.2).
  static String dayManyDative(int n) => '$n Tagen';

  // -------------------------------------------------------------------------
  // Datum (Plan 6.4): „Mittwoch, 7. Oktober“, „3. September 2026“
  // -------------------------------------------------------------------------
  /// Index 0 = Montag … 6 = Sonntag (wie `DateTime.weekday - 1`).
  static const List<String> weekdays = <String>[
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];

  /// Index 0 = Januar … 11 = Dezember.
  static const List<String> months = <String>[
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];

  // -------------------------------------------------------------------------
  // Manny, Onboarding (Brief 6.1) und Mikrofon-Hinweis
  // -------------------------------------------------------------------------
  static const String onboardingStep1 =
      'Moin, ich bin Manny und begleite dich durch deine Reha. Wie heißt du?';
  static String onboardingStep2(String name) =>
      'Kurz und ehrlich, $name: Das passiert mit deinen Daten.';
  static String onboardingStep3(String name) => "Was hat's erwischt, $name?";
  static const String onboardingStep4 = 'Wann war die Verletzung oder OP?';
  static const String micHint = 'Das kann ich bald, heute noch nicht.';

  // -------------------------------------------------------------------------
  // Manny, Blasen auf dem Pfad (Brief 6.2, Platzhalter bis zur KI)
  // -------------------------------------------------------------------------
  static String bubbleGreeting(String name) =>
      "Moin $name, los geht's. Dein Weg beginnt hier.";
  static String bubbleStreakDanger(String daysText) =>
      'Dein Streak von $daysText wartet auf dich. Heute noch eine Runde?';
  static String bubbleCelebration(String name, int day) =>
      'Stark, $name. Das war Tag $day.';
  static String bubbleRestart(String name) =>
      'Neuer Anlauf, $name. Dein Pfad bleibt, der Streak startet heute neu.';
  static const String factTissueId = 'fact-gewebe-umbau';
  static const String factTissueText =
      'Dein Gewebe baut sich gerade aktiv um. Heute zählt.';

  // -------------------------------------------------------------------------
  // Pfad (Plan 7.2)
  // -------------------------------------------------------------------------
  static const String samplePathLabel = 'Beispielpfad';
  static String weekTitle(int week) => 'Woche $week';
  static String phaseLine(int phase, String shortName) =>
      'Phase $phase · $shortName';

  /// Kurznamen der Verletzungstypen für die Kopfzeile (A-13).
  static const String injuryShortAcl = 'Kreuzband';
  static const String injuryShortAnkle = 'Sprunggelenk';
  static const String injuryShortMuscle = 'Muskelfaser';
  static const String injuryShortOther = 'Reha';

  /// Bezeichnungen der Units (Screenreader, Hinweise).
  static String unitTrainingDay(int day) => 'Trainingstag $day';
  static const String unitWeekGoal = 'Wochenziel';
  static const String unitPhaseEnd = 'Phasen-Abschluss';
  static const String unitBoss = 'Return to Sport';

  static const String hintDone = 'Erledigt. Das hast du geschafft.';
  static const String hintThisWeek = 'Kommt noch diese Woche';
  static String hintComesInWeek(int week) => 'Kommt in Woche $week';
  static String hintPhaseEndComesInWeek(int week) =>
      'Phasen-Abschluss kommt in Woche $week';
  static String hintBossComesInWeek(int week) =>
      'Return to Sport kommt in Woche $week';

  static const String statusCurrent = 'aktuell';
  static const String statusLocked = 'gesperrt';
  static const String statusDone = 'erledigt';
  static const String opensToday = 'Öffnet Heute.';

  /// „Woche 5, Trainingstag 3, aktuell.“
  static String unitLabel(String weekText, String kindText, String status) =>
      '$weekText, $kindText, $status.';

  /// „Return to Sport, gesperrt.“
  static String bossLabel(String status) => '$unitBoss, $status.';

  // -------------------------------------------------------------------------
  // Heute (Plan 7.4, 7.5)
  // -------------------------------------------------------------------------
  static const String exercisesHeadingEmpty = 'Übungen';
  static String exercisesHeading(int minutes) => 'Übungen · ca. $minutes Min';

  /// Vorgaben im Dialog „Eigene Übung“ (N-16).
  static const String customDefaultReps = '3 × 10';
  static const int customDefaultMinutes = 5;

  // Übungspool (Platzhalter, keine medizinische Aussage).
  static const String exSquatName = 'Kniebeuge am Stuhl';
  static const String exSquatAlt1 = 'Aufstehen vom Stuhl';
  static const String exSquatAlt2 = 'Mini-Kniebeuge an der Wand';
  static const String exCalfName = 'Wadenheben im Stand';
  static const String exCalfAlt1 = 'Zehenspitzenstand am Stuhl';
  static const String exCalfAlt2 = 'Fersengang auf der Stelle';
  static const String exBridgeName = 'Brücke mit Fersendruck';
  static const String exBridgeAlt1 = 'Brücke mit Kissen';
  static const String exBridgeAlt2 = 'Beckenheben im Liegen';
  static const String exLegRaiseName = 'Seitliches Beinheben';
  static const String exLegRaiseAlt1 = 'Beinheben nach hinten';
  static const String exLegRaiseAlt2 = 'Beinkreisen im Liegen';
  static const String exLungeName = 'Ausfallschritt mit Halt';
  static const String exLungeAlt1 = 'Schrittwechsel auf der Stelle';
  static const String exLungeAlt2 = 'Aufsteigen auf eine Stufe';
  static const String exStretchName = 'Dehnung Oberschenkelvorderseite';
  static const String exStretchAlt1 = 'Dehnung Wade an der Wand';
  static const String exStretchAlt2 = 'Dehnung Oberschenkelrückseite';

  static const String repsThreeTwelve = '3 × 12 Wdh.';
  static const String repsThreeFifteen = '3 × 15 Wdh.';
  static const String repsThreeTen = '3 × 10 Wdh.';
  static const String repsThreeEight = '3 × 8 Wdh.';
  static const String repsTwoTwelve = '2 × 12 Wdh.';
  static const String repsThirtySeconds = '3 × 30 Sek.';

  // Beispieltermine (N-14, Platzhalter; Ort des Arzttermins offen, F-18).
  static const String apptPhysioTitle = 'Physiotherapie, Praxis Müller';
  static const String apptPhysioMeta = 'Köln-Ehrenfeld · Beispiel';
  static const String apptDoctorTitle = 'Kontrolle Orthopädie';
  static const String apptDoctorMeta = 'Köln-Nippes · Beispiel';
  static const String categoryPhysio = 'Physio';
  static const String categoryDoctor = 'Arzt';

  /// „Beispieltermin, Physio, Physiotherapie, Praxis Müller, 17:00 Uhr“
  static String appointmentLabel(String category, String title, String time) =>
      'Beispieltermin, $category, $title, $time Uhr';

  // -------------------------------------------------------------------------
  // Manny-Chat: Beispielverlauf (Ergänzung 2, 3.2, Platzhalter)
  // -------------------------------------------------------------------------
  static String chatExampleManny1(String name) =>
      'Moin $name. Wie läuft dein Tag?';
  static const String chatExampleUser1 = 'Ich hab heute keine Zeit.';
  static const String chatExampleManny2 =
      'Dann machen wir die 10-Minuten-Variante. Das schaffst du. '
      'Sag mir kurz Bescheid, wenn du durch bist.';
}
