// KS-3: Kontext für Mannys Texte (reine Dart-Klasse, Schema für den späteren
// Server). Bewusst ohne Verbraucher im ersten Ausschnitt (nur Tests und die
// Platzhalter-Textquelle nutzen es); es wird nichts gesendet oder gespeichert.
import 'app_state.dart';
import 'clock.dart';
import 'day_program.dart';
import 'injury_type.dart';
import 'path_generator.dart';

class MannyContext {
  const MannyContext({
    required this.firstName,
    required this.injuryType,
    required this.injuryDate,
    required this.week,
    required this.phase,
    required this.streak,
    required this.freezes,
    required this.doneToday,
    required this.timeChoice,
    required this.exerciseCount,
  });

  /// Kein „Anderes“-Freitext (KS-3).
  factory MannyContext.from(AppState s, LocalDay today) {
    final int week = currentWeek(s.onboarding.injuryDate, today);
    return MannyContext(
      firstName: s.onboarding.firstName,
      injuryType: s.onboarding.injuryType,
      injuryDate: s.onboarding.injuryDate,
      week: week,
      phase: phaseOfWeek(week),
      streak: s.streak.count,
      freezes: s.streak.freezes,
      doneToday: s.day.done,
      timeChoice: s.prefs.timeChoice,
      exerciseCount: deriveExercises(s.day, s.prefs.timeChoice).length,
    );
  }

  /// Vorname, getrimmt.
  final String firstName;
  final InjuryType? injuryType;
  final LocalDay? injuryDate;
  final int week;
  final int phase;
  final int streak;
  final int freezes;
  final bool doneToday;
  final int timeChoice;
  final int exerciseCount;

  /// Feste Feldnamen (Schema für den KI-Ausschnitt).
  Map<String, Object?> toJson() => <String, Object?>{
    'vorname': firstName,
    'injuryType': injuryType?.jsonName,
    'injuryDate': injuryDate?.toString(),
    'woche': week,
    'phase': phase,
    'streak': streak,
    'freezes': freezes,
    'heuteTrainiert': doneToday,
    'zeitwahl': timeChoice,
    'uebungenHeute': exerciseCount,
  };
}
