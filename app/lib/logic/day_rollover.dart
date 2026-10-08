// Tageswechsel (Plan 7.5, Ergänzung 1 3.4): Erkennung und Anwendung.
import 'app_state.dart';
import 'clock.dart';
import 'day_program.dart';
import 'streak.dart';

class RolloverResult {
  const RolloverResult({required this.state, required this.changed});

  final AppState state;

  /// `true`: Der Tag hat gewechselt (Snackbar, Ansage, Routen schließen,
  /// Undo beenden – das entscheidet die UI bzw. der Controller).
  final bool changed;
}

/// Tageswechsel = `today != day.dayKey` (jede Abweichung, auch rückwärts).
bool dayChanged(AppState s, LocalDay today) => today != s.day.dayKey;

/// Wendet den Tageswechsel an: frisches Programm (Zeitwahl bleibt, N-8),
/// Feier verfällt, wenn sie nicht von heute ist (der Puls verfällt mit ihr),
/// Streak wird ausgewertet. Am selben Tag unverändert (`changed: false`).
RolloverResult rollover(AppState s, LocalDay today) {
  if (!dayChanged(s, today)) return RolloverResult(state: s, changed: false);
  final CelebrationState? celebration = s.celebration;
  final bool keepCelebration = celebration != null && celebration.day == today;
  return RolloverResult(
    state: AppState(
      onboarding: s.onboarding,
      consent: s.consent,
      streak: StreakEngine.evaluate(s.streak, today),
      path: keepCelebration ? s.path : s.path.copyWith(clearPulse: true),
      day: DayProgramState.fresh(today),
      prefs: s.prefs,
      manny: s.manny,
      celebration: keepCelebration ? celebration : null,
    ),
    changed: true,
  );
}
