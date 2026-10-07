// Persistierter Manny-Zustand (Plan 6.1 `manny`) und die Anlässe.
import 'clock.dart';
import 'equality.dart';
import 'json_support.dart';

/// Anlässe für Mannys Sprechblase auf dem Pfad (Priorität: Reihenfolge der
/// Konstanten, A-20). [name] ist der Schlüssel im Dokument.
enum MannyOccasion { celebration, restart, greeting, streakDanger, fact }

class MannyState {
  const MannyState({
    this.lastShown = const <MannyOccasion, LocalDay>{},
    this.greetingPending = false,
  });

  factory MannyState.fromJson(Json j) {
    final Json shown = optJson(j, 'lastShown') ?? <String, Object?>{};
    final Map<MannyOccasion, LocalDay> map = <MannyOccasion, LocalDay>{};
    for (final MapEntry<String, Object?> e in shown.entries) {
      MannyOccasion? occasion;
      for (final MannyOccasion o in MannyOccasion.values) {
        if (o.name == e.key) occasion = o;
      }
      final Object? v = e.value;
      if (v is! String) unreadable('manny.lastShown: Text erwartet');
      final LocalDay day =
          LocalDay.tryParse(v) ??
          unreadable('manny.lastShown: ungültiges Datum');
      // Unbekannte Anlässe (spätere Version) werden ignoriert.
      if (occasion != null) map[occasion] = day;
    }
    return MannyState(
      lastShown: map,
      greetingPending: optBool(j, 'greetingPending', false),
    );
  }

  /// Anlass → Tag, an dem er zuletzt gezeigt wurde (höchstens einmal pro Tag).
  final Map<MannyOccasion, LocalDay> lastShown;
  final bool greetingPending;

  bool shownOn(MannyOccasion o, LocalDay day) => lastShown[o] == day;

  bool anyShownOn(LocalDay day) =>
      lastShown.values.any((LocalDay d) => d == day);

  MannyState copyWith({
    Map<MannyOccasion, LocalDay>? lastShown,
    bool? greetingPending,
  }) {
    return MannyState(
      lastShown: lastShown ?? this.lastShown,
      greetingPending: greetingPending ?? this.greetingPending,
    );
  }

  Json toJson() => <String, Object?>{
    'lastShown': <String, Object?>{
      for (final MapEntry<MannyOccasion, LocalDay> e in lastShown.entries)
        e.key.name: e.value.toString(),
    },
    'greetingPending': greetingPending,
  };

  @override
  bool operator ==(Object other) =>
      other is MannyState &&
      mapEquals(other.lastShown, lastShown) &&
      other.greetingPending == greetingPending;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(lastShown.entries.map((e) => Object.hash(e.key, e.value))),
    greetingPending,
  );
}
