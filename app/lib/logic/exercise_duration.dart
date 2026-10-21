// Dauer-Schätzung je Plan-Position (Plan 8.4, N-7 nach O-17): „Zeit“ einer
// Übung ist die Dauer je Satz in Sekunden (`duration_sec`); die Pause ist die
// des Physios (`pause_sec`), ohne Angabe 60 s. Gleiche Regel im Physio-Bereich
// (Anzeige „ca. N Min“), in der Kürzung (L5) und im KI-Plan (S8b Regel 6).
// Reine Dart-Logik.
import 'framework.dart';

/// Pause zwischen den Sätzen, wenn der Physio keine angibt.
const int kDefaultPauseSec = 60;

/// Annahme je Wiederholung für Übungen ohne Dauer (N-7).
const int kSecondsPerRep = 4;

/// Geschätzte Minuten (ganze Minuten, aufgerundet, mindestens 1; erste
/// zutreffende Zeile):
/// - `durationSec` gesetzt → `max(1, ⌈(S × Dauer + (S − 1) × P) / 60⌉)`;
/// - sonst `sets` und `reps` → `max(1, ⌈(sets × reps × 4 s + (sets − 1) × P) / 60⌉)`;
/// - sonst nur `sets` → `sets` Minuten;
/// - sonst 5 Minuten.
/// S = `max(sets, 1)`, P = [pauseSec] oder 60 s.
int estimateMinutes({int? sets, int? reps, int? durationSec, int? pauseSec}) {
  final int pause = pauseSec ?? kDefaultPauseSec;
  final int s = (sets ?? 1) < 1 ? 1 : (sets ?? 1);
  if (durationSec != null) {
    return _ceilMinutes(s * durationSec + (s - 1) * pause);
  }
  if (sets != null && reps != null) {
    return _ceilMinutes(sets * reps * kSecondsPerRep + (sets - 1) * pause);
  }
  if (sets != null) return sets < 1 ? 1 : sets;
  return 5;
}

int _ceilMinutes(int seconds) {
  final int minutes = (seconds + 59) ~/ 60;
  return minutes < 1 ? 1 : minutes;
}

/// Schätzung einer Plan-Position.
int estimateItemMinutes(PlanItem item) => estimateMinutes(
  sets: item.sets,
  reps: item.reps,
  durationSec: item.durationSec,
  pauseSec: item.pauseSec,
);
