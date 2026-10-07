// KS-1: Textquelle für Mannys Blasen (synchron, rein) und KS-2 (Fakten).
import '../l10n/strings_de.dart';
import 'manny_context.dart';
import 'manny_state.dart';
import 'placeholder_pools.dart';
import 'plural.dart';

/// Austauschbare Quelle für Blasentexte und Fakten. Die Anlasslogik
/// (`nextBubble`) bleibt unverändert; nur der Text kommt von hier.
abstract class MannyTextSource {
  String bubbleText(MannyOccasion occasion, MannyContext ctx);

  FactRef fact(MannyContext ctx);
}

/// Liefert die festen Platzhaltertexte (Brief 6.2).
class PlaceholderMannyTextSource implements MannyTextSource {
  const PlaceholderMannyTextSource();

  @override
  String bubbleText(MannyOccasion occasion, MannyContext ctx) {
    switch (occasion) {
      case MannyOccasion.celebration:
        return S.bubbleCelebration(ctx.firstName, ctx.streak);
      case MannyOccasion.restart:
        return S.bubbleRestart(ctx.firstName);
      case MannyOccasion.greeting:
        return S.bubbleGreeting(ctx.firstName);
      case MannyOccasion.streakDanger:
        return S.bubbleStreakDanger(tagen(ctx.streak));
      case MannyOccasion.fact:
        return fact(ctx).text;
    }
  }

  @override
  FactRef fact(MannyContext ctx) => kExampleFact;
}
