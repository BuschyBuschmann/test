// Rückgängig (Plan 7.6). Die Fenster selbst (Timer, Halter) liegen in
// `TransientUi`; hier nur die reinen Schnappschüsse und das Zurückspielen.
import 'app_state.dart';
import 'clock.dart';
import 'day_program.dart';
import 'equality.dart';
import 'streak.dart';

/// Zustand vor „Training eintragen“: gesamter Streak, Pfadfortschritt, Puls,
/// Erledigt-Flag und ausstehende Feier.
class TrainingSnapshot {
  const TrainingSnapshot({
    required this.day,
    required this.streak,
    required this.completedUnitIds,
    required this.pulsePending,
    required this.done,
    required this.celebration,
  });

  factory TrainingSnapshot.capture(AppState s) => TrainingSnapshot(
    day: s.day.dayKey,
    streak: s.streak,
    completedUnitIds: s.path.completedUnitIds,
    pulsePending: s.path.pulsePending,
    done: s.day.done,
    celebration: s.celebration,
  );

  /// Tag, für den der Schnappschuss gilt; nach einem Tageswechsel wird
  /// Rückgängig abgelehnt.
  final LocalDay day;
  final StreakState streak;
  final List<String> completedUnitIds;
  final String? pulsePending;
  final bool done;
  final CelebrationState? celebration;

  @override
  bool operator ==(Object other) =>
      other is TrainingSnapshot &&
      other.day == day &&
      other.streak == streak &&
      listEquals(other.completedUnitIds, completedUnitIds) &&
      other.pulsePending == pulsePending &&
      other.done == done &&
      other.celebration == celebration;

  @override
  int get hashCode => Object.hash(
    day,
    streak,
    Object.hashAll(completedUnitIds),
    pulsePending,
    done,
    celebration,
  );
}

/// Spielt genau die Felder des Schnappschusses zurück.
AppState undoTraining(AppState s, TrainingSnapshot snap) {
  return AppState(
    onboarding: s.onboarding,
    consent: s.consent,
    streak: snap.streak,
    path: PathState(
      completedUnitIds: snap.completedUnitIds,
      pulsePending: snap.pulsePending,
    ),
    day: s.day.copyWith(done: snap.done),
    prefs: s.prefs,
    manny: s.manny,
    celebration: snap.celebration,
  );
}

/// Token für „Entfernt. Rückgängig“: nur eine Snackbar gleichzeitig.
///
/// Abweichung vom Plan-Wortlaut `{exerciseId, previousRemoved}`: Beim
/// Rückgängig wird gezielt **diese** Übung wiederhergestellt (statt die ganze
/// vorherige Liste zurückzuspielen), damit zwischenzeitlich hinzugefügte
/// eigene Übungen nicht verloren gehen.
class RemovalToken {
  const RemovalToken({
    required this.day,
    required this.exerciseId,
    this.customExercise,
    this.customIndex = 0,
  });

  final LocalDay day;
  final String exerciseId;

  /// Bei einer entfernten eigenen Übung: die Übung und ihre Position.
  final CustomExercise? customExercise;
  final int customIndex;
}

/// Macht das Entfernen rückgängig. Eine bereits wieder vorhandene Übung
/// bleibt unverändert.
DayProgramState undoRemoval(DayProgramState d, RemovalToken token) {
  final CustomExercise? custom = token.customExercise;
  if (custom != null) {
    if (d.custom.any((CustomExercise c) => c.id == custom.id)) return d;
    final List<CustomExercise> list = List<CustomExercise>.of(d.custom);
    list.insert(token.customIndex.clamp(0, list.length), custom);
    return d.copyWith(custom: list);
  }
  return d.copyWith(
    removed: <String>[
      for (final String id in d.removed)
        if (id != token.exerciseId) id,
    ],
  );
}
