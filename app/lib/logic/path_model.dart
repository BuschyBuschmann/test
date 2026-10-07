// Pfad-Modell (Plan 7.2): Units, Art, Status.

/// Art der Unit; bestimmt Größe (klein/mittel/groß/Boss) und Beschriftung.
enum UnitKind { trainingDay, weekGoal, phaseEnd, boss }

enum UnitStatus { done, current, locked }

class PathUnit {
  const PathUnit({
    required this.id,
    required this.kind,
    required this.week,
    required this.phase,
    this.dayNumber = 0,
  });

  /// Stabile ID: `w{W}-d{1..3}`, `w{W}-goal`, `p{P}-end`, `boss`.
  final String id;
  final UnitKind kind;

  /// Woche 1..12 (Boss und Phasen-Abschluss gehören zu Woche 12 bzw. 4/8/12).
  final int week;

  /// Phase 1..3.
  final int phase;

  /// Trainingstag 1..3 bei [UnitKind.trainingDay], sonst 0.
  final int dayNumber;

  @override
  bool operator ==(Object other) =>
      other is PathUnit &&
      other.id == id &&
      other.kind == kind &&
      other.week == week &&
      other.phase == phase &&
      other.dayNumber == dayNumber;

  @override
  int get hashCode => Object.hash(id, kind, week, phase, dayNumber);

  @override
  String toString() => 'PathUnit($id)';
}
