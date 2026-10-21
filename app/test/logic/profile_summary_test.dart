// Kennzahlen für Kopf-Karte und Profil (Brief 7.1, 7.6; F2-R3).
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/path_generator.dart';
import 'package:curaone/logic/path_layout.dart';
import 'package:curaone/logic/path_model.dart';
import 'package:curaone/logic/profile_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nameInitial: erster Buchstabe groß, leer bleibt leer', () {
    expect(nameInitial('jakob'), 'J');
    expect(nameInitial('  Änne '), 'Ä');
    expect(nameInitial(''), '');
    expect(nameInitial('   '), '');
  });

  test('dayInPathWeek: Tag 1 bis 7 der Pfadwoche, Randfälle', () {
    const LocalDay injury = LocalDay(2026, 9, 3);
    expect(dayInPathWeek(injury, injury), 1);
    expect(dayInPathWeek(injury, injury.addDays(6)), 7);
    expect(dayInPathWeek(injury, injury.addDays(7)), 1);
    expect(dayInPathWeek(injury, injury.addDays(30)), 3);
    expect(dayInPathWeek(injury, injury.addDays(-5)), 1, reason: 'Zukunft');
    expect(dayInPathWeek(null, injury), 1);
    expect(dayInPathWeek(injury, injury.addDays(kPathWeeks * 7)), 7);
    expect(dayInPathWeek(injury, injury.addDays(400)), 7);
  });

  test('trainingDaysDone: zählt erledigte Trainingstage, keine Ziele', () {
    const LocalDay injury = LocalDay(2026, 9, 3);
    final PathProgress week1 = computePathProgress(
      injuryDate: injury,
      today: injury,
      completedUnitIds: const <String>[],
    );
    expect(trainingDaysDone(week1), 0);
    final PathProgress week5 = computePathProgress(
      injuryDate: injury,
      today: injury.addDays(30),
      completedUnitIds: const <String>['w5-d1'],
    );
    // Wochen 1 bis 4 je 3 Trainingstage plus w5-d1.
    expect(trainingDaysDone(week5), 13);
  });

  test('layoutPath: die aktuelle Unit misst metrics.current, der Boss nie', () {
    const PathLayoutMetrics m = PathLayoutMetrics(
      small: 56,
      medium: 62,
      large: 80,
      boss: 104,
      current: 92,
      sideMargin: 16,
      verticalGap: 84,
    );
    expect(m.diameterFor(UnitKind.trainingDay), 56);
    expect(m.diameterFor(UnitKind.trainingDay, isCurrent: true), 92);
    expect(m.diameterFor(UnitKind.boss, isCurrent: true), 104);
    final List<PathUnit> units = kSamplePath.take(4).toList();
    final PathLayout l = layoutPath(
      units: units,
      width: 390,
      viewportHeight: 700,
      metrics: m,
      currentIndex: 1,
    );
    expect(l.placements[0].diameter, 56);
    expect(l.placements[1].diameter, 92);
    expect(l.placements[3].diameter, 62);
  });
}
