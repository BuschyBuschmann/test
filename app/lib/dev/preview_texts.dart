// Beispieltexte der Prüfumgebung (U2p). Nur für `lib/dev/` (Szenarien,
// `main_preview`): Sie sind kein Produkttext und werden von `main.dart` nicht
// importiert. Echte Texte der App stehen in `lib/l10n/strings_de.dart`
// (KONVENTIONEN Regel 4); wo ein Szenario einen vorhandenen Text braucht,
// nimmt es ihn von dort.

abstract final class PreviewTexts {
  static const String indexTitle = 'Szenarien der Prüfumgebung';

  static const String startTraining = 'Training starten';
  static const String cancel = 'Abbrechen';
  static const String deleteAll = 'Ja, alles löschen';
  static const String doneToday = 'Heute erledigt';
  static const String injuryLabel = 'Verletzung';
  static const String choiceAcl = 'Kreuzbandriss (ACL)';
  static const String choiceAnkle = 'Bänderriss Sprunggelenk';
  static const String choiceOther = 'Anderes / selbst eingeben';
  static const String nameLabel = 'Dein Name';
  static const String nameHint = 'Wie heißt du?';
  static const String nameValue = 'Jakob';
  static const String dateValue = '3. September 2026';
  static const String yourData = 'Deine Daten';
  static const String injuryOtherValue = 'Schulter ausgekugelt';

  static const String glassCardText =
      'Glas-Karte: kein Blur, innere Lichtkante.';
  static const String sampleName = 'Jakob';
  static const int sampleDay = 4;
  static const String snackbarAdded = 'Eingetragen.';
  static const String snackbarUndo = 'Rückgängig';
  static const String snackbarDeleted = 'Alle Daten sind gelöscht.';
  static const String dialogTitle = 'Alles löschen?';
  static const String dialogMessage =
      'Name, Verletzung, Pfad, Streak und deine Einwilligung werden von '
      'diesem Gerät gelöscht. Das lässt sich nicht rückgängig machen.';
  static const String cardPrefix = 'Karte';
  static const String typoSample = 'Heute, Jakob 17:00';
  static const String typoLabelSample = 'Abschnittstitel';
  static const String pathTab = 'Pfad';
  static const String todayTab = 'Heute';
  static const String pipetteTitle = 'Dein Weg';
}
