// Tagesprogramm (Plan 7.5): Zustand, Ableitung der Übungsliste, Tauschen,
// Entfernen, Eigene Übung, Überschrift.
import '../l10n/strings_de.dart';
import 'clock.dart';
import 'equality.dart';
import 'json_support.dart';
import 'placeholder_pools.dart';

/// Eigene Übung (persistiert in `day.custom`).
class CustomExercise {
  const CustomExercise({
    required this.id,
    required this.name,
    required this.reps,
    required this.minutes,
  });

  /// Baut aus Eingaben des Dialogs (N-16): Name ist Pflicht (getrimmt, sonst
  /// `null`); leere Wiederholungen → Vorgabe „3 × 10“; Dauer keine positive
  /// ganze Zahl → Vorgabe 5.
  static CustomExercise? fromInput({
    required String id,
    required String name,
    String reps = '',
    String minutes = '',
  }) {
    final String n = name.trim();
    if (n.isEmpty) return null;
    final String r = reps.trim();
    final int? m = int.tryParse(minutes.trim());
    return CustomExercise(
      id: id,
      name: n,
      reps: r.isEmpty ? S.customDefaultReps : r,
      minutes: (m == null || m <= 0) ? S.customDefaultMinutes : m,
    );
  }

  factory CustomExercise.fromJson(Json j) {
    final int minutes = reqInt(j, 'minutes');
    if (minutes < 0) unreadable('custom.minutes: negativ');
    return CustomExercise(
      id: reqString(j, 'id'),
      name: reqString(j, 'name'),
      reps: reqString(j, 'reps'),
      minutes: minutes,
    );
  }

  final String id;
  final String name;
  final String reps;
  final int minutes;

  Json toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'reps': reps,
    'minutes': minutes,
  };

  @override
  bool operator ==(Object other) =>
      other is CustomExercise &&
      other.id == id &&
      other.name == name &&
      other.reps == reps &&
      other.minutes == minutes;

  @override
  int get hashCode => Object.hash(id, name, reps, minutes);
}

/// Eine angezeigte Übung (abgeleitet, nicht gespeichert).
class DisplayedExercise {
  const DisplayedExercise({
    required this.id,
    required this.name,
    required this.reps,
    required this.minutes,
    required this.isCustom,
  });

  /// Basis-ID (auch nach „Tauschen“) bzw. ID der eigenen Übung.
  final String id;
  final String name;
  final String reps;
  final int minutes;
  final bool isCustom;

  /// Eigene Übungen haben keine Alternativen (kein „Tauschen“).
  bool get canSwap => !isCustom;

  @override
  bool operator ==(Object other) =>
      other is DisplayedExercise &&
      other.id == id &&
      other.name == name &&
      other.reps == reps &&
      other.minutes == minutes &&
      other.isCustom == isCustom;

  @override
  int get hashCode => Object.hash(id, name, reps, minutes, isCustom);
}

/// Programm eines Kalendertags. `dayKey` ist die **einzige** Quelle für den
/// zuletzt gesehenen Tag (Plan 6.1).
class DayProgramState {
  const DayProgramState({
    required this.dayKey,
    this.removed = const <String>[],
    this.swaps = const <String, int>{},
    this.custom = const <CustomExercise>[],
    this.done = false,
  });

  /// Frisches Programm ohne Tagesänderungen.
  factory DayProgramState.fresh(LocalDay day) => DayProgramState(dayKey: day);

  /// [fallbackDay] wird nur benutzt, wenn `dayKey` im Dokument fehlt.
  factory DayProgramState.fromJson(Json j, LocalDay fallbackDay) {
    final Json swapsJson = optJson(j, 'swaps') ?? <String, Object?>{};
    final Map<String, int> swaps = <String, int>{};
    for (final MapEntry<String, Object?> e in swapsJson.entries) {
      final Object? v = e.value;
      if (v is! int || v < 0) unreadable('day.swaps: Zahl ≥ 0 erwartet');
      swaps[e.key] = v;
    }
    return DayProgramState(
      dayKey: optDay(j, 'dayKey') ?? fallbackDay,
      removed: optStringList(j, 'removed'),
      swaps: swaps,
      custom: <CustomExercise>[
        for (final Json c in optJsonList(j, 'custom'))
          CustomExercise.fromJson(c),
      ],
      done: optBool(j, 'done', false),
    );
  }

  final LocalDay dayKey;

  /// Entfernte Basis-IDs (bleiben beim Zeitwechsel erhalten).
  final List<String> removed;

  /// Basis-ID → Anzahl Tausch-Schritte.
  final Map<String, int> swaps;
  final List<CustomExercise> custom;
  final bool done;

  DayProgramState copyWith({
    List<String>? removed,
    Map<String, int>? swaps,
    List<CustomExercise>? custom,
    bool? done,
  }) {
    return DayProgramState(
      dayKey: dayKey,
      removed: removed ?? this.removed,
      swaps: swaps ?? this.swaps,
      custom: custom ?? this.custom,
      done: done ?? this.done,
    );
  }

  Json toJson() => <String, Object?>{
    'dayKey': dayKey.toString(),
    'removed': removed,
    'swaps': swaps,
    'custom': <Json>[for (final CustomExercise c in custom) c.toJson()],
    'done': done,
  };

  @override
  bool operator ==(Object other) =>
      other is DayProgramState &&
      other.dayKey == dayKey &&
      listEquals(other.removed, removed) &&
      mapEquals(other.swaps, swaps) &&
      listEquals(other.custom, custom) &&
      other.done == done;

  @override
  int get hashCode => Object.hash(
    dayKey,
    Object.hashAll(removed),
    Object.hashAll(swaps.entries.map((e) => Object.hash(e.key, e.value))),
    Object.hashAll(custom),
    done,
  );
}

/// Übungsliste: Basis je Zeitwahl, minus `removed`, mit `swaps` ersetzt, plus
/// `custom` am Ende.
List<DisplayedExercise> deriveExercises(DayProgramState d, int timeChoice) {
  final List<ExerciseFamily> base =
      kBaseExercises[timeChoice] ?? kBaseExercises[kDefaultTimeChoice]!;
  return <DisplayedExercise>[
    for (final ExerciseFamily f in base)
      if (!d.removed.contains(f.base.id))
        _displayed(f.atSwapSteps(d.swaps[f.base.id] ?? 0)),
    for (final CustomExercise c in d.custom)
      DisplayedExercise(
        id: c.id,
        name: c.name,
        reps: c.reps,
        minutes: c.minutes,
        isCustom: true,
      ),
  ];
}

DisplayedExercise _displayed(ExerciseDef e) => DisplayedExercise(
  id: e.id,
  name: e.name,
  reps: e.reps,
  minutes: e.minutes,
  isCustom: false,
);

/// Summe der Dauern der angezeigten Übungen (B-6, N-15).
int totalMinutes(List<DisplayedExercise> list) =>
    list.fold(0, (int sum, DisplayedExercise e) => sum + e.minutes);

/// Überschrift „Übungen · ca. N Min“; bei leerer Liste nur „Übungen“ (B-6).
String exercisesHeading(List<DisplayedExercise> list) => list.isEmpty
    ? S.exercisesHeadingEmpty
    : S.exercisesHeading(totalMinutes(list));

/// Ein Tausch-Schritt für die Basisübung [id]. Unbekannte IDs und eigene
/// Übungen bleiben unverändert (A-15).
DayProgramState swapExercise(DayProgramState d, String id) {
  if (familyById(id) == null) return d;
  return d.copyWith(
    swaps: <String, int>{...d.swaps, id: (d.swaps[id] ?? 0) + 1},
  );
}

/// Entfernt eine Basisübung (nur ID merken) oder eine eigene Übung.
DayProgramState removeExercise(DayProgramState d, String id) {
  if (d.custom.any((CustomExercise c) => c.id == id)) {
    return d.copyWith(
      custom: <CustomExercise>[
        for (final CustomExercise c in d.custom)
          if (c.id != id) c,
      ],
    );
  }
  if (familyById(id) == null || d.removed.contains(id)) return d;
  return d.copyWith(removed: <String>[...d.removed, id]);
}

/// Hängt eine eigene Übung am Ende an.
DayProgramState addCustom(DayProgramState d, CustomExercise e) =>
    d.copyWith(custom: <CustomExercise>[...d.custom, e]);
