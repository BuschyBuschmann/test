// Kennzahlen für Kopf-Karte und Profil (Brief 7.1, 7.6), abgeleitet aus dem
// vorhandenen Zustand. Es kommt nichts Neues in den Zustand: weder Wochentage
// mit Training noch Zähler werden gespeichert (Ausschnitt 1 kennt sie nicht).
import 'clock.dart';
import 'path_generator.dart';
import 'path_model.dart';

/// Anfangsbuchstabe des Namens für Avatar und Leiste („jakob“ → „J“); leer,
/// wenn der Name leer ist.
String nameInitial(String name) {
  final String t = name.trim();
  if (t.isEmpty) return '';
  return String.fromCharCode(t.runes.first).toUpperCase();
}

/// Der Tag in der aktuellen Pfadwoche, 1 bis 7: Grundlage des Wochenbalkens
/// „N von 7 Tagen“ der Kopf-Karte. Vor dem Verletzungsdatum oder ohne Datum
/// gilt 1, nach dem Ende des Pfads (Woche 12 vorbei) 7.
int dayInPathWeek(LocalDay? injuryDate, LocalDay today) {
  if (injuryDate == null) return 1;
  final int days = injuryDate.daysUntil(today);
  if (days < 0) return 1;
  if (days >= kPathWeeks * 7) return 7;
  return days % 7 + 1;
}

/// Anzahl der erledigten Trainingstage im Pfad (Kachel „Trainingstage“).
int trainingDaysDone(PathProgress progress) {
  int n = 0;
  for (int i = 0; i < progress.units.length; i++) {
    if (progress.units[i].kind == UnitKind.trainingDay &&
        progress.statuses[i] == UnitStatus.done) {
      n++;
    }
  }
  return n;
}
