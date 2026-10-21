// „Heute“ aus dem Plan (Plan 8.4, 6.7, O-10): Freigabe, Füllregel und
// Tausch-Kandidaten. Reine Dart-Logik; der Tag ist immer der lokale Tag des
// Geräts (`local_day`, Plan 6.7 Nr. 1).
import 'clock.dart';
import 'exercise_duration.dart';
import 'framework.dart';

/// Zeitwahlen für „Heute“ (Minuten).
const List<int> kPlanTimeChoices = <int>[10, 20, 30];

/// „Freigegeben“ ist eine Anzeige- und Auswahlregel, keine Zugriffsregel
/// (Plan 6.7 Nr. 2): Eine Position ist freigegeben, wenn sie
/// - `active` ist, **oder**
/// - `prepared` ist und `release_on ≤ localDay`, **oder**
/// - `prepared` ist und `release_with_phase_id` auf eine Phase zeigt, deren
///   Position ≤ der Position der aktuellen Phase ist.
/// Ob die Position zur aktuellen Phase gehört, prüft [releasedItemsOfCurrentPhase].
bool isReleased(PlanItem item, Plan plan, LocalDay localDay) {
  switch (item.release) {
    case Release.active:
      return true;
    case Release.prepared:
      final LocalDay? on = item.releaseOn;
      if (on != null) return !on.isAfter(localDay);
      final String? withPhase = item.releaseWithPhaseId;
      if (withPhase == null) return false;
      final Phase? target = plan.phaseById(withPhase);
      final Phase? current = plan.currentPhase;
      if (target == null || current == null) return false;
      return target.position <= current.position;
  }
}

/// Freigegebene Positionen der aktuellen Phase in Physio-Reihenfolge.
List<PlanItem> releasedItemsOfCurrentPhase(Plan plan, LocalDay localDay) {
  final Phase? phase = plan.currentPhase;
  if (phase == null) return const <PlanItem>[];
  return <PlanItem>[
    for (final PlanItem i in plan.itemsOfPhase(phase.id))
      if (isReleased(i, plan, localDay)) i,
  ];
}

/// Die Liste für „Heute“.
class TodayPlan {
  const TodayPlan({required this.items, required this.totalMinutes});

  static const TodayPlan empty = TodayPlan(
    items: <PlanItem>[],
    totalMinutes: 0,
  );

  final List<PlanItem> items;

  /// Summe der Schätzungen („ca. N Min“).
  final int totalMinutes;

  bool get isEmpty => items.isEmpty;
}

/// Füllregel (Plan 8.4): freigegebene Positionen der aktuellen Phase der Reihe
/// nach, solange die Summe der Schätzungen ≤ [timeChoice] bleibt; mindestens
/// eine (ist schon die erste länger, wird nur sie gezeigt). Die Füllung hört
/// bei der ersten Position auf, die nicht mehr passt (Reihenfolge des
/// Physios bleibt erhalten, Annahme).
TodayPlan buildTodayPlan({
  required Plan plan,
  required LocalDay localDay,
  required int timeChoice,
}) {
  final List<PlanItem> candidates = releasedItemsOfCurrentPhase(plan, localDay);
  final List<PlanItem> picked = <PlanItem>[];
  int total = 0;
  for (final PlanItem item in candidates) {
    final int minutes = estimateItemMinutes(item);
    if (picked.isNotEmpty && total + minutes > timeChoice) break;
    picked.add(item);
    total += minutes;
  }
  return TodayPlan(
    items: List<PlanItem>.unmodifiable(picked),
    totalMinutes: total,
  );
}

/// Tausch-Kandidaten (A-2 AK 2): übrige freigegebene Positionen der aktuellen
/// Phase, die heute nicht in der Liste stehen. Leer → Tauschen wird nicht
/// angeboten.
List<PlanItem> swapCandidates({
  required Plan plan,
  required LocalDay localDay,
  required Iterable<String> listedItemIds,
}) {
  final Set<String> listed = listedItemIds.toSet();
  return <PlanItem>[
    for (final PlanItem i in releasedItemsOfCurrentPhase(plan, localDay))
      if (!listed.contains(i.id)) i,
  ];
}

/// Liste nach dem Tauschen: [outId] wird an gleicher Stelle durch [inId]
/// ersetzt. Unbekannte [outId] → unverändert.
List<String> swapListed(List<String> listed, String outId, String inId) {
  final int at = listed.indexOf(outId);
  if (at < 0) return listed;
  return <String>[...listed]..[at] = inId;
}

/// Gesamtschätzung einer Liste von Positionen.
int totalMinutesOf(Iterable<PlanItem> items) {
  int sum = 0;
  for (final PlanItem i in items) {
    sum += estimateItemMinutes(i);
  }
  return sum;
}
