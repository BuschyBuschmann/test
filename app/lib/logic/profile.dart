// Profiländerung (Plan 7.8, N-7, n3): Entwurf, Prüfung, Anwendung.
import 'app_state.dart';
import 'clock.dart';
import 'injury_type.dart';
import 'path_generator.dart';

class ProfileDraft {
  const ProfileDraft({
    required this.name,
    required this.injuryType,
    required this.injuryOther,
    required this.injuryDate,
  });

  factory ProfileDraft.fromState(AppState s) => ProfileDraft(
    name: s.onboarding.name,
    injuryType: s.onboarding.injuryType,
    injuryOther: s.onboarding.injuryOther,
    injuryDate: s.onboarding.injuryDate,
  );

  final String name;
  final InjuryType? injuryType;
  final String injuryOther;
  final LocalDay? injuryDate;

  ProfileDraft copyWith({
    String? name,
    InjuryType? injuryType,
    String? injuryOther,
    LocalDay? injuryDate,
  }) {
    return ProfileDraft(
      name: name ?? this.name,
      injuryType: injuryType ?? this.injuryType,
      injuryOther: injuryOther ?? this.injuryOther,
      injuryDate: injuryDate ?? this.injuryDate,
    );
  }

  /// Weicht der Entwurf vom gespeicherten Stand ab? Name und Freitext zählen
  /// nach `trim()`; der Freitext zählt nur, wenn „Anderes“ im Spiel ist.
  bool isDirty(AppState s) {
    final OnboardingState o = s.onboarding;
    if (name.trim() != o.name.trim()) return true;
    if (injuryType != o.injuryType) return true;
    if (injuryDate != o.injuryDate) return true;
    if (injuryType == InjuryType.other &&
        injuryOther.trim() != o.injuryOther.trim()) {
      return true;
    }
    return false;
  }

  /// Speichern erlaubt: geändert, Name nicht leer, Typ gewählt, Datum gesetzt
  /// und nicht in der Zukunft.
  bool canSave(AppState s, LocalDay today) =>
      isDirty(s) &&
      name.trim().isNotEmpty &&
      injuryType != null &&
      injuryDate != null &&
      !injuryDate!.isAfter(today);
}

class ProfileUpdate {
  const ProfileUpdate({
    required this.state,
    required this.nameChanged,
    required this.pathRecomputed,
  });

  final AppState state;
  final bool nameChanged;
  final bool pathRecomputed;
}

/// Wendet den Entwurf an. Ändern sich Typ **oder** Datum, wird der Pfad neu
/// abgeleitet (`completedUnitIds` leer, `pulsePending` leer, Feier nur
/// behalten, wenn ihre Unit im neuen Pfad erledigt ist). Name oder nur der
/// „Anderes“-Freitext lösen keine Neuberechnung aus (A-12). Streak, Freezes,
/// `day.*` (inkl. `done`) und `prefs.timeChoice` bleiben.
///
/// Der „Anderes“-Freitext wird gelöscht, wenn der Typ nicht „Anderes“ ist
/// (kein vergessener Freitext im Dokument).
ProfileUpdate applyProfile(AppState s, ProfileDraft draft, LocalDay today) {
  if (!draft.isDirty(s)) {
    return ProfileUpdate(state: s, nameChanged: false, pathRecomputed: false);
  }
  final OnboardingState o = s.onboarding;
  final bool nameChanged = draft.name.trim() != o.name.trim();
  final bool pathRecomputed =
      draft.injuryType != o.injuryType || draft.injuryDate != o.injuryDate;

  AppState next = s.copyWith(
    onboarding: o.copyWith(
      name: draft.name,
      injuryType: draft.injuryType,
      injuryOther: draft.injuryType == InjuryType.other
          ? draft.injuryOther
          : '',
      injuryDate: draft.injuryDate,
    ),
  );

  if (pathRecomputed) {
    final PathProgress progress = computePathProgress(
      injuryDate: draft.injuryDate,
      today: today,
      completedUnitIds: const <String>[],
    );
    final String? unitId = s.celebration?.unitId;
    final bool keepCelebration = unitId != null && progress.isDone(unitId);
    next = next.copyWith(
      path: const PathState(),
      clearCelebration: !keepCelebration,
    );
  }
  return ProfileUpdate(
    state: next,
    nameChanged: nameChanged,
    pathRecomputed: pathRecomputed,
  );
}
