// Reine Weltfunktion (Design-Brief v2, 3.1 „Zeitregel“, Plan 2.3 F2-R1):
// aus einer festen Uhr die Tageszeit-Phase oder die Mischung zweier Phasen.
// Kein Flutter-Import (KONVENTIONEN Regel 3). Die Uhr für die Welt kommt nur
// über diese Datei ([WorldClock]); Tests setzen eine feste Uhr.
//
// Zeitregel (lokale Gerätezeit): Morgen 5–10, Mittag 10–17, Abend 17–21,
// Nacht 21–5 Uhr. An jeder Grenze T wird linear über 30 Minuten von T − 15 min
// bis T + 15 min zwischen den beiden Phasen überblendet. Das Fenster ist
// halboffen: bei T − 15 min ist es noch die reine frühere Phase (Anteil 0),
// bei T + 15 min schon die reine spätere Phase.
import 'clock.dart';

/// Die vier Tageszeiten der Welt.
enum WorldPhase { morning, midday, evening, night }

/// Auswahl „Welt“ (Profil → Darstellung): Automatisch (Standard) oder ein
/// fester Look ohne Überblendung.
enum WorldChoice {
  automatic,
  morning,
  midday,
  evening,
  night;

  /// Name im Speicher (`curaone.display.v1`).
  String get jsonName => name;

  static WorldChoice fromJsonName(Object? value) {
    for (final WorldChoice c in WorldChoice.values) {
      if (c.name == value) return c;
    }
    return WorldChoice.automatic;
  }

  /// Fester Look; `null` bei „Automatisch“.
  WorldPhase? get fixedPhase => switch (this) {
    WorldChoice.automatic => null,
    WorldChoice.morning => WorldPhase.morning,
    WorldChoice.midday => WorldPhase.midday,
    WorldChoice.evening => WorldPhase.evening,
    WorldChoice.night => WorldPhase.night,
  };
}

/// Stunde (lokal, volle Stunde), ab der eine Phase beginnt.
const Map<WorldPhase, int> kWorldPhaseStartHour = <WorldPhase, int>{
  WorldPhase.morning: 5,
  WorldPhase.midday: 10,
  WorldPhase.evening: 17,
  WorldPhase.night: 21,
};

/// Breite des Überblendfensters um jede Grenze (T − 15 min … T + 15 min).
const Duration kWorldBlendWindow = Duration(minutes: 30);

/// Reihenfolge der Phasen im Tageslauf.
const List<WorldPhase> kWorldPhaseOrder = <WorldPhase>[
  WorldPhase.morning,
  WorldPhase.midday,
  WorldPhase.evening,
  WorldPhase.night,
];

/// Mischung zweier Phasen: [t] ist der Anteil von [to] (0 … 1). Bei `t == 0`
/// ist es die reine Phase [from]; ein fester Look ist [WorldMix.pure].
class WorldMix {
  const WorldMix(this.from, this.to, this.t);

  const WorldMix.pure(WorldPhase phase) : from = phase, to = phase, t = 0;

  final WorldPhase from;
  final WorldPhase to;
  final double t;

  /// Reine Phase, keine Überblendung.
  bool get isPure => t <= 0 || from == to;

  /// Die Phase mit dem größeren Anteil (bei 50:50 die frühere).
  WorldPhase get dominant => t > 0.5 ? to : from;

  @override
  bool operator ==(Object other) =>
      other is WorldMix &&
      other.from == from &&
      other.to == to &&
      (other.t - t).abs() < 1e-12;

  @override
  int get hashCode => Object.hash(from, to, (t * 1e9).round());

  @override
  String toString() => isPure
      ? 'WorldMix(${from.name})'
      : 'WorldMix(${from.name} → ${to.name}, t=${t.toStringAsFixed(4)})';
}

/// Phase, die zu [minuteOfDay] (0 … 1440, auch gebrochen) ohne Überblendung
/// gilt.
WorldPhase worldPhaseAtMinute(double minuteOfDay) {
  // Die Nacht läuft über Mitternacht: vor 5 Uhr gilt noch sie.
  WorldPhase result = WorldPhase.night;
  for (final WorldPhase p in kWorldPhaseOrder) {
    if (minuteOfDay >= kWorldPhaseStartHour[p]! * 60) result = p;
  }
  return result;
}

/// Phase bzw. Mischung zur lokalen Zeit [time] (Sekunden zählen mit, damit
/// die Überblendung stetig läuft).
WorldMix worldMixAt(DateTime time) {
  final double m =
      time.hour * 60.0 +
      time.minute +
      time.second / 60 +
      time.millisecond / 60000;
  const double half = 15; // Minuten vor/nach der Grenze
  for (int i = 0; i < kWorldPhaseOrder.length; i++) {
    final WorldPhase next = kWorldPhaseOrder[i];
    final WorldPhase previous =
        kWorldPhaseOrder[(i + kWorldPhaseOrder.length - 1) %
            kWorldPhaseOrder.length];
    final double boundary = kWorldPhaseStartHour[next]! * 60.0;
    final double start = boundary - half;
    final double end = boundary + half;
    if (m >= start && m < end) {
      final double t = (m - start) / (end - start);
      return t <= 0 ? WorldMix.pure(previous) : WorldMix(previous, next, t);
    }
  }
  return WorldMix.pure(worldPhaseAtMinute(m));
}

/// Welt für eine Auswahl: fester Look ohne Überblendung oder die Zeitregel.
WorldMix resolveWorld(WorldChoice choice, DateTime now) {
  final WorldPhase? fixed = choice.fixedPhase;
  return fixed == null ? worldMixAt(now) : WorldMix.pure(fixed);
}

/// Die Uhr der Welt: der einzige Ort, an dem die Welt die Gerätezeit liest.
/// Produktion `WorldClock()` (Systemuhr), Tests eine feste Uhr.
class WorldClock {
  const WorldClock([this._clock = DateTime.now]);

  final Clock _clock;

  DateTime now() => _clock();

  WorldMix mixFor(WorldChoice choice) => resolveWorld(choice, now());
}
