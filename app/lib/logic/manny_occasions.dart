// Manny-Anlässe (Plan 7.7, A-20 bis A-22, N-2): welche Blase wann, und die
// zentrale Abbildung Anlass/Pose -> Bilddatei (Brief-Ergänzung 1, 6.3).
import 'app_state.dart';
import 'clock.dart';
import 'manny_look.dart';
import 'manny_state.dart';

export 'manny_state.dart' show MannyOccasion;

/// „Abends“ beginnt um 18:00 Uhr Ortszeit (N-2).
const int kEveningHour = 18;

/// Anlass der Darstellung Mannys (Ergänzung 1, 6.3). Die Werte `neutral`,
/// `motiviert` und `feiernd` stammen aus Ausschnitt 1; die übrigen sind die
/// neuen Anlässe der Tabelle. Welche Bilddatei ein Anlass bekommt, steht
/// ausschließlich in [mannyImageFor].
enum MannyPose {
  /// Standard (Chat-Avatar groß, Pfad, Onboarding).
  neutral,

  /// Begrüßen (Tagesbeginn, Moin-Blase).
  gruessend,

  /// Feier (Session-Ende, Streak, Meilenstein).
  feiernd,

  /// Ziel (aktuelle Station, Boss).
  ziel,

  /// Erinnerung, freundlich (Neustart, Streak-Gefahr).
  motiviert,

  /// Training-Begleiter (Session, Packliste).
  training,

  /// Trösten (Schmerz melden, schlechter Tag).
  troestend,

  /// Denken (Chat „schreibt“, Laden).
  denkend,

  /// Schlafen (Ruhetag, Nacht).
  schlafend,
}

/// Die gelieferten Bilddateien je Variante (`<variante>/<name>.png`).
enum MannyImage {
  normal,
  freudig,
  traurig,

  /// Kopf als Rundform (Manny-Knopf, Chat-Liste, Avatare).
  kopf;

  /// Dateiname im Verzeichnis der Variante.
  String get fileName => '$name.png';
}

/// Zentrale Abbildung Anlass -> Körperbild (Ergänzung 1, 6.3, V2-70): Feier
/// und Begrüßen zeigen `freudig`, Trösten `traurig`, alle übrigen Anlässe
/// (auch die noch nicht eigens gezeichneten) fallen auf `normal` zurück.
/// Der Kopf ist kein Anlass, sondern ein Zuschnitt ([MannyImage.kopf]).
MannyImage mannyImageFor(MannyPose pose) => switch (pose) {
  MannyPose.gruessend || MannyPose.feiernd => MannyImage.freudig,
  MannyPose.troestend => MannyImage.traurig,
  MannyPose.neutral ||
  MannyPose.ziel ||
  MannyPose.motiviert ||
  MannyPose.training ||
  MannyPose.denkend ||
  MannyPose.schlafend => MannyImage.normal,
};

/// Verzeichnis der Assets (in `pubspec.yaml` deklariert).
const String kMannyAssetRoot = 'assets/manny';

/// Pfad des 1x-Bildes: `assets/manny/<brille|ohne>/<datei>.png`. Die Variante
/// gilt in jeder Pose (die Brille wird nie abgesetzt).
String mannyAssetPath(MannyLook look, MannyImage image) =>
    '$kMannyAssetRoot/${look.name}/${image.fileName}';

class BubbleDecision {
  const BubbleDecision({
    required this.occasion,
    required this.pose,
    this.pulseUnitId,
  });

  final MannyOccasion occasion;
  final MannyPose pose;

  /// Nur bei der Feier: Unit für den einmaligen Ring-Puls.
  final String? pulseUnitId;

  @override
  bool operator ==(Object other) =>
      other is BubbleDecision &&
      other.occasion == occasion &&
      other.pose == pose &&
      other.pulseUnitId == pulseUnitId;

  @override
  int get hashCode => Object.hash(occasion, pose, pulseUnitId);

  @override
  String toString() => 'BubbleDecision($occasion)';
}

/// Entscheidet beim Sichtbarwerden des Pfads, welche Blase erscheint. Der
/// Text kommt aus der `MannyTextSource`; hier nur der **Anlass**.
///
/// Priorität: 1. Feier, 2. Neustart, 3. Begrüßung, 4. Streak-Gefahr,
/// 5. Beispielfakt. Jeder Anlass höchstens einmal pro Tag (`lastShown`);
/// nicht gezeigte Anlässe bleiben fällig. [undoWindowOpen]: Während des
/// Rückgängig-Fensters gibt es keine Feier (UI-40).
BubbleDecision? nextBubble(
  AppState s,
  DateTime now, {
  bool undoWindowOpen = false,
}) {
  final LocalDay today = LocalDay.from(now);
  final MannyState manny = s.manny;

  final CelebrationState? celebration = s.celebration;
  if (celebration != null &&
      celebration.day == today &&
      !undoWindowOpen &&
      !manny.shownOn(MannyOccasion.celebration, today)) {
    return BubbleDecision(
      occasion: MannyOccasion.celebration,
      pose: MannyPose.feiernd,
      // Puls nur, wenn er vorgemerkt ist (Profiländerung leert ihn, n3).
      pulseUnitId: s.path.pulsePending,
    );
  }

  if (s.streak.resetNoticePending &&
      !manny.shownOn(MannyOccasion.restart, today)) {
    return const BubbleDecision(
      occasion: MannyOccasion.restart,
      pose: MannyPose.motiviert,
    );
  }

  if (manny.greetingPending && !manny.shownOn(MannyOccasion.greeting, today)) {
    return const BubbleDecision(
      occasion: MannyOccasion.greeting,
      pose: MannyPose.gruessend,
    );
  }

  if (now.hour >= kEveningHour &&
      !s.day.done &&
      s.streak.count > 0 &&
      !manny.shownOn(MannyOccasion.streakDanger, today)) {
    return const BubbleDecision(
      occasion: MannyOccasion.streakDanger,
      pose: MannyPose.motiviert,
    );
  }

  // Beispielfakt (A-22): beim ersten Pfad-Besuch des Tages, wenn kein anderer
  // Anlass fällig ist und heute noch nicht trainiert wurde. „Erster Besuch“:
  // heute wurde noch keine Blase gezeigt.
  if (!s.day.done &&
      !manny.shownOn(MannyOccasion.fact, today) &&
      !manny.anyShownOn(today)) {
    return const BubbleDecision(
      occasion: MannyOccasion.fact,
      pose: MannyPose.neutral,
    );
  }
  return null;
}

/// Vermerkt, dass [occasion] heute gezeigt wurde, und nimmt die zugehörige
/// Fälligkeit zurück (Begrüßung, Neustart-Nachricht). Die Feier selbst wird
/// zusätzlich über `consumeCelebration` verbraucht.
AppState markBubbleShown(AppState s, MannyOccasion occasion, LocalDay today) {
  final Map<MannyOccasion, LocalDay> shown = <MannyOccasion, LocalDay>{
    ...s.manny.lastShown,
    occasion: today,
  };
  AppState next = s.copyWith(
    manny: s.manny.copyWith(
      lastShown: shown,
      greetingPending: occasion == MannyOccasion.greeting
          ? false
          : s.manny.greetingPending,
    ),
  );
  if (occasion == MannyOccasion.restart) {
    next = next.copyWith(
      streak: next.streak.copyWith(resetNoticePending: false),
    );
  }
  return next;
}

/// Verbraucht die Feier samt Puls (nach dem Zeigen).
AppState consumeCelebration(AppState s) => s.celebration == null
    ? s
    : s.copyWith(
        clearCelebration: true,
        path: s.path.copyWith(clearPulse: true),
      );
