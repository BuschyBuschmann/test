// Gesamtzustand der App (Plan 6.1): unveränderlich, mit JSON.
import 'clock.dart';
import 'day_program.dart';
import 'equality.dart';
import 'injury_type.dart';
import 'json_support.dart';
import 'manny_state.dart';
import 'placeholder_pools.dart';
import 'streak.dart';

/// Onboarding (Schritt 0..3 = Schritt 1..4).
class OnboardingState {
  const OnboardingState({
    this.completed = false,
    this.step = 0,
    this.name = '',
    this.injuryType,
    this.injuryOther = '',
    this.injuryDate,
  });

  /// `completed` und `step` sind Pflichtfelder (Plan 6.2).
  factory OnboardingState.fromJson(Json j) {
    return OnboardingState(
      completed: reqBool(j, 'completed'),
      step: inRange(reqInt(j, 'step'), 0, 3, 'onboarding.step'),
      name: optString(j, 'name', ''),
      injuryType: InjuryType.fromJsonName(optStringOrNull(j, 'injuryType')),
      injuryOther: optString(j, 'injuryOther', ''),
      injuryDate: optDay(j, 'injuryDate'),
    );
  }

  final bool completed;
  final int step;

  /// Ungetrimmt gespeichert; Prüfungen laufen auf `trim()`.
  final String name;
  final InjuryType? injuryType;
  final String injuryOther;
  final LocalDay? injuryDate;

  /// Vorname für Texte (getrimmt).
  String get firstName => name.trim();

  OnboardingState copyWith({
    bool? completed,
    int? step,
    String? name,
    InjuryType? injuryType,
    bool clearInjuryType = false,
    String? injuryOther,
    LocalDay? injuryDate,
    bool clearInjuryDate = false,
  }) {
    return OnboardingState(
      completed: completed ?? this.completed,
      step: step ?? this.step,
      name: name ?? this.name,
      injuryType: clearInjuryType ? null : (injuryType ?? this.injuryType),
      injuryOther: injuryOther ?? this.injuryOther,
      injuryDate: clearInjuryDate ? null : (injuryDate ?? this.injuryDate),
    );
  }

  Json toJson() => <String, Object?>{
    'completed': completed,
    'step': step,
    'name': name,
    'injuryType': injuryType?.jsonName,
    'injuryOther': injuryOther,
    'injuryDate': injuryDate?.toString(),
  };

  @override
  bool operator ==(Object other) =>
      other is OnboardingState &&
      other.completed == completed &&
      other.step == step &&
      other.name == name &&
      other.injuryType == injuryType &&
      other.injuryOther == injuryOther &&
      other.injuryDate == injuryDate;

  @override
  int get hashCode =>
      Object.hash(completed, step, name, injuryType, injuryOther, injuryDate);
}

final RegExp _utcTimestamp = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,6}))?Z$',
);

/// Streng: nur `YYYY-MM-DDTHH:MM:SS[.ffffff]Z` (so wird geschrieben) und nur
/// echte Kalender-/Uhrzeitwerte. `DateTime.tryParse` allein rechnet ungültige
/// Angaben still um (z. B. Monat 13), das wäre kein „unlesbar“ (Plan 6.2).
DateTime _parseUtcTimestamp(String text) {
  final RegExpMatch? m = _utcTimestamp.firstMatch(text);
  if (m == null) unreadable('consent.acceptedAt: ungültiges Format');
  int g(int i) => int.parse(m.group(i)!);
  final DateTime t = DateTime.utc(g(1), g(2), g(3), g(4), g(5), g(6));
  if (t.year != g(1) ||
      t.month != g(2) ||
      t.day != g(3) ||
      t.hour != g(4) ||
      t.minute != g(5) ||
      t.second != g(6)) {
    unreadable('consent.acceptedAt: ungültiges Datum');
  }
  final String? frac = m.group(7);
  if (frac == null) return t;
  final String padded = frac.padRight(6, '0');
  return t.add(Duration(microseconds: int.parse(padded)));
}

/// Einwilligung (Schritt 2): Zeitstempel in UTC und Version.
class ConsentState {
  const ConsentState({required this.acceptedAt, required this.version});

  /// Version des Platzhalter-Datenschutztexts (Brief 6.0).
  static const String kVersion = 'prototype-0';

  factory ConsentState.fromJson(Json j) {
    final DateTime parsed = _parseUtcTimestamp(reqString(j, 'acceptedAt'));
    return ConsentState(
      acceptedAt: parsed,
      version: optString(j, 'version', kVersion),
    );
  }

  final DateTime acceptedAt;
  final String version;

  Json toJson() => <String, Object?>{
    'acceptedAt': acceptedAt.toUtc().toIso8601String(),
    'version': version,
  };

  @override
  bool operator ==(Object other) =>
      other is ConsentState &&
      other.acceptedAt.isAtSameMomentAs(acceptedAt) &&
      other.version == version;

  @override
  int get hashCode => Object.hash(acceptedAt.microsecondsSinceEpoch, version);
}

/// Pfadfortschritt zusätzlich zur Datumsableitung (Plan 7.2).
class PathState {
  const PathState({
    this.completedUnitIds = const <String>[],
    this.pulsePending,
  });

  factory PathState.fromJson(Json j) => PathState(
    completedUnitIds: optStringList(j, 'completedUnitIds'),
    pulsePending: optStringOrNull(j, 'pulsePending'),
  );

  final List<String> completedUnitIds;

  /// Unit-ID für den einmaligen Ring-Puls (gehört zur Feier).
  final String? pulsePending;

  PathState copyWith({
    List<String>? completedUnitIds,
    String? pulsePending,
    bool clearPulse = false,
  }) {
    return PathState(
      completedUnitIds: completedUnitIds ?? this.completedUnitIds,
      pulsePending: clearPulse ? null : (pulsePending ?? this.pulsePending),
    );
  }

  Json toJson() => <String, Object?>{
    'completedUnitIds': completedUnitIds,
    'pulsePending': pulsePending,
  };

  @override
  bool operator ==(Object other) =>
      other is PathState &&
      listEquals(other.completedUnitIds, completedUnitIds) &&
      other.pulsePending == pulsePending;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(completedUnitIds), pulsePending);
}

/// Vorlieben (Zeitwahl bleibt nach Tageswechsel, N-8).
class PrefsState {
  const PrefsState({this.timeChoice = kDefaultTimeChoice});

  factory PrefsState.fromJson(Json j) {
    final int t = optInt(j, 'timeChoice', kDefaultTimeChoice);
    if (!kTimeChoices.contains(t)) unreadable('prefs.timeChoice: $t');
    return PrefsState(timeChoice: t);
  }

  final int timeChoice;

  Json toJson() => <String, Object?>{'timeChoice': timeChoice};

  @override
  bool operator ==(Object other) =>
      other is PrefsState && other.timeChoice == timeChoice;

  @override
  int get hashCode => timeChoice.hashCode;
}

/// Ausstehende Feier (erst beim nächsten Pfad-Besuch nach dem Rückgängig-
/// Fenster, nur am selben Tag).
class CelebrationState {
  const CelebrationState({required this.day, this.unitId});

  factory CelebrationState.fromJson(Json j) => CelebrationState(
    day: reqDay(j, 'day'),
    unitId: optStringOrNull(j, 'unitId'),
  );

  final LocalDay day;

  /// Erledigte Unit; `null`, wenn keine mehr offen war (Endfall, A-11).
  final String? unitId;

  Json toJson() => <String, Object?>{'day': day.toString(), 'unitId': unitId};

  @override
  bool operator ==(Object other) =>
      other is CelebrationState && other.day == day && other.unitId == unitId;

  @override
  int get hashCode => Object.hash(day, unitId);
}

/// Schema des Dokuments; erhöht bei jeder inkompatiblen Änderung (Plan 6.2).
const int kCurrentSchema = 1;

/// Der gesamte persistierte Zustand.
class AppState {
  const AppState({
    required this.onboarding,
    required this.consent,
    required this.streak,
    required this.path,
    required this.day,
    required this.prefs,
    required this.manny,
    required this.celebration,
  });

  /// Ausgangszustand (Erststart, nach Löschen): Streak 0, Freezes 2, Zeitwahl
  /// 20, Tagesprogramm für [today].
  factory AppState.initial(LocalDay today) => AppState(
    onboarding: const OnboardingState(),
    consent: null,
    streak: const StreakState(),
    path: const PathState(),
    day: DayProgramState.fresh(today),
    prefs: const PrefsState(),
    manny: const MannyState(),
    celebration: null,
  );

  /// Liest ein **bereits auf [kCurrentSchema] migriertes** Dokument
  /// (`migrations.dart`). Fehlende optionale Felder → Standard, Unbekanntes
  /// wird ignoriert; sonst [UnreadableDataException]. [today] ersetzt einen
  /// fehlenden `day.dayKey`.
  factory AppState.fromJson(Json j, LocalDay today) {
    final Json? consentJson = optJson(j, 'consent');
    final Json? celebration = optJson(j, 'celebration');
    final OnboardingState onboarding = OnboardingState.fromJson(
      reqJson(j, 'onboarding'),
    );
    final ConsentState? consent = consentJson == null
        ? null
        : ConsentState.fromJson(consentJson);
    // Widersprüchlich: abgeschlossenes Onboarding ohne seine Pflichtangaben.
    // Es gibt keine sinnvolle Reparatur (Name, Typ, Datum und Einwilligung
    // lassen sich nicht erraten); deshalb unlesbar, also Neustart (N-12).
    if (onboarding.completed &&
        (onboarding.firstName.isEmpty ||
            onboarding.injuryType == null ||
            onboarding.injuryDate == null ||
            consent == null)) {
      unreadable(
        'onboarding.completed ohne Name, Typ, Datum oder Einwilligung',
      );
    }
    return AppState(
      onboarding: onboarding,
      consent: consent,
      streak: StreakState.fromJson(optJson(j, 'streak') ?? <String, Object?>{}),
      path: PathState.fromJson(optJson(j, 'path') ?? <String, Object?>{}),
      day: DayProgramState.fromJson(
        optJson(j, 'day') ?? <String, Object?>{},
        today,
      ),
      prefs: PrefsState.fromJson(optJson(j, 'prefs') ?? <String, Object?>{}),
      manny: MannyState.fromJson(optJson(j, 'manny') ?? <String, Object?>{}),
      celebration: celebration == null
          ? null
          : CelebrationState.fromJson(celebration),
    );
  }

  final OnboardingState onboarding;
  final ConsentState? consent;
  final StreakState streak;
  final PathState path;
  final DayProgramState day;
  final PrefsState prefs;
  final MannyState manny;
  final CelebrationState? celebration;

  AppState copyWith({
    OnboardingState? onboarding,
    ConsentState? consent,
    StreakState? streak,
    PathState? path,
    DayProgramState? day,
    PrefsState? prefs,
    MannyState? manny,
    CelebrationState? celebration,
    bool clearCelebration = false,
  }) {
    return AppState(
      onboarding: onboarding ?? this.onboarding,
      consent: consent ?? this.consent,
      streak: streak ?? this.streak,
      path: path ?? this.path,
      day: day ?? this.day,
      prefs: prefs ?? this.prefs,
      manny: manny ?? this.manny,
      celebration: clearCelebration ? null : (celebration ?? this.celebration),
    );
  }

  Json toJson() => <String, Object?>{
    'schema': kCurrentSchema,
    'onboarding': onboarding.toJson(),
    'consent': consent?.toJson(),
    'streak': streak.toJson(),
    'path': path.toJson(),
    'day': day.toJson(),
    'prefs': prefs.toJson(),
    'manny': manny.toJson(),
    'celebration': celebration?.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is AppState &&
      other.onboarding == onboarding &&
      other.consent == consent &&
      other.streak == streak &&
      other.path == path &&
      other.day == day &&
      other.prefs == prefs &&
      other.manny == manny &&
      other.celebration == celebration;

  @override
  int get hashCode => Object.hash(
    onboarding,
    consent,
    streak,
    path,
    day,
    prefs,
    manny,
    celebration,
  );
}
