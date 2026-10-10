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

  /// Boss in der laufenden Woche 12 (Nutzerentscheidung).
  static const String hintBossGoal = 'Dein Ziel: zurück in deinen Sport.';
  static const String hintThisWeek = 'Kommt noch diese Woche';
  static String hintComesInWeek(int week) => 'Kommt in Woche $week';
  static String hintPhaseEndComesInWeek(int week) =>
      'Phasen-Abschluss kommt in Woche $week';
  static String hintBossComesInWeek(int week) =>
      'Return to Sport kommt in Woche $week';

  /// Ausblick hinter dem Boss (Ergänzung 3, Abschnitt 3). PLATZHALTER: die volle
  /// Phase folgt mit eigener Spec. Keine Zahl, Übung oder Zeitangabe.
  static const String outlookTitle = 'Prävention & Gesundheitssport';
  static const String outlookSubtitle = 'Danach geht es weiter';
  static const String outlookHint =
      'Nach Return to Sport geht es hier weiter. Die Details folgen noch.';
  static const String outlookLabel =
      'Prävention und Gesundheitssport, gesperrt.';

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
  // Kopfzeile Pfad (Brief 5.9, 8; Ergänzung 1, 3.1)
  // -------------------------------------------------------------------------
  /// Zusatzlabel an der Streak-Pill (Text, nicht nur Farbe, UI-18, UI-22).
  static const String streakFrozenWord = 'eingefroren';

  /// „Streak: 12 Tage“ (Screenreader); [daysText] kommt aus `tage(n)`.
  static String streakLabel(String daysText) => 'Streak: $daysText';
  static String streakFrozenLabel(String daysText) =>
      'Streak: $daysText, $streakFrozenWord';

  /// „Streak-Freezes: 2“
  static String freezesLabel(int n) => 'Streak-Freezes: $n';

  /// Einstieg ins Sheet „Deine Daten“ (Tooltip und Label des Icons).
  static const String dataSheetOpen = 'Deine Daten';

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
  static const String apptDoctorTitle = 'Kontrolltermin Orthopädie';
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

  // -------------------------------------------------------------------------
  // Manny-Chat: Kopf, Hinweise, Eingabeleiste (Ergänzung 2, 3.2, 3.5)
  // -------------------------------------------------------------------------
  static const String chatRouteName = 'Manny, Chat';
  static const String chatTitle = 'Manny';
  static const String chatSubtitle = 'Dein Reha-Begleiter';
  static const String chatNoticeLabel = 'Beispielverlauf';
  static const String chatNoticeText = 'So sieht dein Chat bald aus.';
  static const String chatHint = 'Schreiben kann ich bald, heute noch nicht.';
  static const String chatComposerPlaceholder = 'Schreib Manny';

  /// Disclaimer, wörtlich Spec 7.
  static const String chatDisclaimer =
      'Manny ersetzt keine medizinische Beratung.';
  static const String chatComposerSemantics =
      'Nachricht an Manny, noch nicht verfügbar';
  static const String chatSendSemantics = 'Senden, noch nicht verfügbar';

  /// Screenreader-Präfixe der Nachrichten („Manny: …“, „Du: …“).
  static String chatFromManny(String text) => 'Manny: $text';
  static String chatFromYou(String text) => 'Du: $text';
  static String chatFromPerson(String name, String text) => '$name: $text';

  // -------------------------------------------------------------------------
  // Nachrichten und Beispiel-Chats (Ergänzung 2, 3.3, 3.4; unverbindlicher
  // Platzhalter ohne Spec, K10)
  // -------------------------------------------------------------------------
  static const String messagesTitle = 'Nachrichten';
  static const String messagesNotice = 'Beispiel-Ansicht. Echte Chats folgen.';
  static const String sectionPhysio = 'Physio';
  static const String sectionFamily = 'Familie';
  static const String sectionFriends = 'Freunde';
  static const String sectionDoctors = 'Ärzte';
  static const String exampleChatNotice = 'Beispiel-Chat. Nur zum Ansehen.';
  static const String exampleChatHint = 'Schreiben in Chats folgt bald.';
  static const String exampleChatPlaceholder = 'Nachricht';

  /// Rollen im Kopf des Beispiel-Chats.
  static const String rolePhysio = 'Physio';
  static const String roleFamily = 'Familie';
  static const String roleFriends = 'Freunde';
  static const String roleDoctor = 'Arzt';
  static String roleExample(String role) => '$role · Beispiel';

  static String exampleChatRouteName(String name) => 'Beispiel-Chat $name';
  static String exampleChatComposerSemantics(String name) =>
      'Nachricht an $name, noch nicht verfügbar';

  /// „Beispielkontakt Praxis Müller, Physio. Letzte Nachricht: …, Montag.
  /// Öffnet Beispiel-Chat.“
  static String contactRowLabel(
    String name,
    String section,
    String lastMessage,
    String day,
  ) =>
      'Beispielkontakt $name, $section. Letzte Nachricht: $lastMessage, $day. '
      'Öffnet Beispiel-Chat.';

  /// Wochentage kurz (0 = Montag), für die Zeitangabe in der Übersicht.
  static const List<String> weekdaysShort = <String>[
    'Mo',
    'Di',
    'Mi',
    'Do',
    'Fr',
    'Sa',
    'So',
  ];

  // Beispielkontakte und -chats (erfundene Platzhalter, rein organisatorisch).
  static const String contactPhysioName = 'Praxis Müller';
  static const String contactPhysioInitials = 'PM';
  static String examplePhysioLine1(String vorname) =>
      'Moin $vorname, dein Termin ist am Donnerstag um 17:00 Uhr.';
  static const String examplePhysioLine2 = 'Perfekt, ich bin pünktlich da.';
  static const String examplePhysioLine3 = 'Bring bitte Sportschuhe mit.';

  static const String contactMamaName = 'Mama';
  static const String contactMamaInitials = 'M';
  static const String exampleMamaLine1 = 'Heute Training geschafft.';
  static const String exampleMamaLine2 = 'Schön, dass du dranbleibst!';

  static const String contactTimName = 'Tim (Bruder)';
  static const String contactTimInitials = 'T';
  static const String exampleTimLine1 = 'Samstag habe ich noch nichts vor.';
  static const String exampleTimLine2 = 'Soll ich dich am Samstag abholen?';

  static const String contactLenaName = 'Lena';
  static const String contactLenaInitials = 'L';
  static const String exampleLenaLine1 = 'Bin zu Hause.';
  static const String exampleLenaLine2 = 'Wie lief dein Tag?';

  static const String contactBastiName = 'Basti';
  static const String contactBastiInitials = 'B';
  static const String exampleBastiLine1 = 'Bin bald wieder fit.';
  static const String exampleBastiLine2 = 'Kaffee, wenn du wieder darfst?';

  static const String contactWeberName = 'Dr. Weber, Orthopädie';
  static const String contactWeberInitials = 'DW';
  static const String exampleWeberLine1 =
      'Ich möchte den Termin gern bestätigen.';
  static const String exampleWeberLine2 = 'Termin am 14. um 9:30 bestätigt.';

  // -------------------------------------------------------------------------
  // Bausteine (U2a): feste Beschriftungen, Tooltips, Screenreader-Labels
  // -------------------------------------------------------------------------
  static const String mannyImageLabel = 'Manny, dein Begleiter';
  static const String mannyChatOpen = 'Manny, Chat öffnen';
  static const String messagesButton = 'Nachrichten';
  static const String micUnavailable = 'Spracheingabe, noch nicht verfügbar';
  static const String bubbleClose = 'Nachricht schließen';
  static const String datePlaceholder = 'Datum wählen';

  /// „Schritt 3 von 4“ (Brief 5.8, Screenreader liest nur den Text).
  static String stepOf(int step, int total) => 'Schritt $step von $total';

  /// „Kreuzbandriss (ACL), Auswahl, ausgewählt“ (Brief 8).
  static String choiceLabel(String title, bool selected) =>
      '$title, Auswahl, ${selected ? 'ausgewählt' : 'nicht ausgewählt'}';

  /// Mit Untertitel: „Manuell, Ich trage es nachher ein, Auswahl, ausgewählt“.
  static String choiceLabelDetail(String title, String detail, bool selected) =>
      choiceLabel('$title, $detail', selected);

  /// Snackbar mit Aktion: „Eingetragen. Rückgängig, Schaltfläche“
  /// (Ergänzung 1, 3.3).
  static String snackbarWithAction(String text, String action) =>
      '$text $action, Schaltfläche';

  // -------------------------------------------------------------------------
  // Statusansage laufender Vorgänge (Erratum E-3, `PillButton(busy)`)
  // -------------------------------------------------------------------------
  /// Standard, wenn der Besitzer keinen eigenen Status nennt.
  static const String busyStatusDefault = 'Wird ausgeführt';

  /// Löschen-Dialog (Ergänzung 1, 3.2).
  static const String busyStatusDeleting = 'Wird gelöscht';

  /// „Ja, alles löschen, Wird gelöscht“ (Label plus Status, Live-Region).
  static String busyLabel(String label, String status) => '$label, $status';

  // -------------------------------------------------------------------------
  // Navigation, Start, Fehlerzustand (U2b)
  // -------------------------------------------------------------------------
  /// Name der App (Fenstertitel im Web).
  static const String appTitle = 'CuraOne';
  static const String navPath = 'Pfad';
  static const String navToday = 'Heute';
  static const String back = 'Zurück';
  static const String close = 'Schließen';

  /// Ladeansicht des Starts (Screenreader, Live-Region).
  static const String loading = 'Wird geladen';

  /// Fehlerzustand des Pfad-Tabs (Brief 6.2).
  static const String pathLoadError = 'Dein Pfad konnte nicht geladen werden.';

  /// Fehlerzustand beim Start, solange unklar ist, ob das Onboarding
  /// abgeschlossen war (Erratum E-4, Brief v1 Abschnitt 14).
  static const String startLoadError =
      'Deine Daten konnten nicht geladen werden.';
  static const String retry = 'Nochmal versuchen';

  /// Hinweise nach dem Neustart des Onboardings (Snackbar, 4 s, A-34).
  static const String dataDeleted = 'Alle Daten sind gelöscht.';
  static const String dataUnreadable =
      'Deine gespeicherten Daten waren nicht lesbar. Du startest neu.';

  /// Tageswechsel auf Heute (Ergänzung 1, 3.4): Snackbar und Ansage.
  static const String newDaySnackbar = 'Neuer Tag, neues Programm.';
  static const String newDayAnnouncement =
      'Neuer Tag. Dein Programm für heute ist neu.';

  // -------------------------------------------------------------------------
  // Heute (Brief 6.3, Ergänzung 1 und 2, U3b)
  // -------------------------------------------------------------------------
  static String todayTitle(String name) => 'Heute, $name';

  /// Fehlerzustand des Tabs Heute (Brief 6.3: „Text plus Nochmal versuchen“;
  /// Wortlaut analog zum Pfad, Annahme bis zur Klärung mit dem ui-designer).
  static const String todayLoadError =
      'Dein Programm konnte nicht geladen werden.';

  static const String cancel = 'Abbrechen';

  /// Zeitwahl (Spec 2): sichtbar „20 Min“, vorgelesen „20 Minuten“.
  static const String timeChoiceGroup = 'Trainingszeit';
  static String timeChoiceText(int minutes) => '$minutes Min';
  static String timeChoiceLabel(int minutes) => '$minutes Minuten';

  static const String appointmentsHeading = 'Termine';
  static const String noAppointments = 'Heute keine Termine.';

  static const String categoryExercise = 'Übung';
  static const String exerciseSwap = 'Tauschen';
  static const String exerciseRemove = 'Entfernen';
  static String exerciseSwapLabel(String name) => '$name tauschen';
  static String exerciseRemoveLabel(String name) => '$name entfernen';

  /// „3 × 12 Wdh. · 6 Min“
  static String exerciseMeta(String reps, int minutes) =>
      '$reps · $minutes Min';

  /// Vorlesetext der Wiederholungen: „3 × 12 Wdh.“ wird „3 mal 12
  /// Wiederholungen“, „3 × 30 Sek.“ wird „3 mal 30 Sekunden“.
  static String repsSpoken(String reps) => reps
      .replaceAll(' × ', ' mal ')
      .replaceAll('Wdh.', 'Wiederholungen')
      .replaceAll('Sek.', 'Sekunden');

  /// „Übung, Kniebeuge am Stuhl, 3 mal 12 Wiederholungen, 6 Minuten“
  static String exerciseLabel(String name, String reps, int minutes) =>
      '$categoryExercise, $name, ${repsSpoken(reps)}, '
      '${minutes == 1 ? '1 Minute' : '$minutes Minuten'}';

  static const String emptyExercises = 'Heute noch nichts geplant.';
  static const String customAdd = 'Eigene Übung';
  static const String customAddLabel = 'Eigene Übung hinzufügen';

  static const String startTraining = 'Training starten';
  static const String trainingDone = 'Heute erledigt';

  /// Trainings-Sheet „Wie willst du trainieren?“ (Brief 6.3, Spec 2).
  static const String trainingSheetTitle = 'Wie willst du trainieren?';
  static const String modeManual = 'Manuell';
  static const String modeManualHint = 'Ich trage es nachher ein';
  static const String modePassive = 'Passiv';
  static const String modeActive = 'Aktiv';
  static const String modeSoon = 'Folgt';
  static String modeDisabledLabel(String title) =>
      '$title, folgt, noch nicht verfügbar';
  static const String trainingLog = 'Training eintragen';

  /// Snackbars mit Rückgängig (Ergänzung 1, 3.3; Brief 6.3).
  static const String loggedSnackbar = 'Eingetragen.';
  static const String removedSnackbar = 'Entfernt.';
  static const String undo = 'Rückgängig';
  static const String undoLoggedLabel = 'Eintrag rückgängig machen';
  static const String undoRemovedLabel = 'Entfernen rückgängig machen';
  static const String loggedUndoneAnnouncement = 'Eintrag zurückgenommen.';

  /// Dialog „Eigene Übung“ (Brief 6.3, Plan 9 B-4).
  static const String customDialogTitle = 'Eigene Übung';
  static const String customNameLabel = 'Name';
  static const String customRepsLabel = 'Wiederholungen';
  static const String customMinutesLabel = 'Dauer in Minuten';
  static const String customAddButton = 'Hinzufügen';

  // -------------------------------------------------------------------------
  // Onboarding (Brief 6.1)
  // -------------------------------------------------------------------------
  static const String moreToAdd = 'Noch etwas hinzufügen?';
  static const String next = 'Weiter';
  static const String consentAccept = 'Verstanden, weiter';
  static const String nameLabel = 'Dein Name';

  /// Datenschutz, Schritt 2 (Platzhalter, vor Echtbetrieb juristisch
  /// zu ersetzen, Brief 6.0).
  static const String consentStoredLabel = 'Was gespeichert wird';
  static const String consentStoredText =
      'Dein Name, deine Verletzung, das Datum und dein Fortschritt. '
      'Alles bleibt auf diesem Gerät.';
  static const String consentDurationLabel = 'Wie lange';
  static const String consentDurationText =
      'Bis du es löschst oder die App entfernst.';
  static const String consentRightLabel = 'Dein Recht auf Löschung';
  static const String consentRightText =
      'Du kannst alles jederzeit löschen. Dann nimmst du auch deine '
      'Einwilligung zurück.';
  static const String consentPlaceholderNote =
      'Platzhaltertext. Er wird vor dem echten Einsatz ersetzt.';
  static const String privacyLink = 'Datenschutzerklärung lesen';
  static const String privacyTitle = 'Datenschutzerklärung';
  static const String privacyPlaceholderBody =
      'Platzhalter. Hier steht später die Datenschutzerklärung.';

  // Verletzungstyp, Schritt 3.
  static const String injuryAcl = 'Kreuzbandriss (ACL)';
  static const String injuryAnkle = 'Bänderriss Sprunggelenk';
  static const String injuryMuscle = 'Muskelfaserriss';
  static const String injuryOther = 'Anderes / selbst eingeben';
  static const String injuryOtherLabel = 'Was ist passiert?';
}
