// `HeaderCard` (Design-Brief v2, 4 und 3.1): Kopf-Karte der Ebene E2. Glas aus
// `header-tint` der Welt (Deckkraft 66 %, Nacht 58 %) mit Blur über `CuraBlur`
// (σ 24), Radius 32. Aufbau: Titel (`title`, 30/32), Untertitel (`secondary`),
// Chips (Streak, Freeze) und optional ein Fortschritt. **Aller Text steht in
// `#FFFFFF`** (kein Grauton, Gewicht ≥ 500), der Kontrast gegen reines Weiß
// unter dem Glas ist je Welt gemessen (Brief 3.1, `contrast_world_test`).
//
// Eine der drei zulässigen Blur-Flächen (Leiste, Kopf-Karte, Manny-Knopf).
// „Transparenz reduzieren“/Hoher Kontrast: `header-tint` zu 100 %, kein Blur,
// Rand `border-control-hc`. Die Kopf-Karte ist erlaubter Vorfahre für Text
// (V2-5); `HeaderChip` und `HeaderProgress` sind ihre Bausteine.
import 'package:flutter/material.dart';

import '../../state/world_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../../theme/tokens.dart';
import '../../theme/world_tokens.dart';
import 'cura_blur.dart';

class HeaderCard extends StatelessWidget {
  const HeaderCard({
    super.key,
    required this.title,
    this.subtitle,
    this.chips = const <Widget>[],
    this.progress,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// `HeaderChip`s (Streak, Freeze); umbrechen bei großer Schrift.
  final List<Widget> chips;

  /// Wochenbalken „N von 7 Tagen“ (`HeaderProgress`).
  final Widget? progress;

  /// Schaltfläche oben rechts (z. B. „Deine Daten“).
  final Widget? trailing;

  /// Füllung der Kopf-Karte: `header-tint` mit Deckkraft, bei Hohem Kontrast
  /// zu 100 %.
  static Color fillOf(BuildContext context) {
    final WorldPalette world = WorldScope.paletteOf(context);
    return CuraColors.of(context).highContrast
        ? world.headerTintOpaque
        : world.headerTint;
  }

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final BorderRadius shape = BorderRadius.circular(CuraRadius.headerCard);
    final Widget titleText = Semantics(
      header: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: CuraSize.headerTitleMaxTextScale,
        child: Text(
          title,
          style: type.titleHeader.copyWith(color: colors.headerInk),
        ),
      ),
    );
    return CuraBlur(
      borderRadius: shape,
      sigma: BlurTokens.headerSigma,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fillOf(context),
          borderRadius: shape,
          border: Border.all(
            // Hoher Kontrast: weißer Rand (≥ 4,3:1 gegen die opake Tönung).
            color: colors.highContrast
                ? colors.headerInk
                : colors.headerChipFill,
            width: colors.highContrast
                ? CuraSize.controlBorder
                : CuraSize.hairline,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(CuraSize.cardPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (trailing == null)
                titleText
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: titleText),
                    const SizedBox(width: CuraSpace.s2),
                    trailing!,
                  ],
                ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: type.secondary.copyWith(color: colors.headerInk),
                ),
              if (chips.isNotEmpty) ...<Widget>[
                const SizedBox(height: CuraSpace.s3),
                Wrap(
                  spacing: CuraSpace.s2,
                  runSpacing: CuraSpace.s2,
                  children: chips,
                ),
              ],
              if (progress != null) ...<Widget>[
                const SizedBox(height: CuraSpace.s3),
                progress!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip in der Kopf-Karte (Streak „Flamme 12“, Freeze „❄ 1“): Symbol **und**
/// Text, Weiß 18 % auf dem Glas, Text `#FFFFFF` 13 sp/700, Radius Pille.
class HeaderChip extends StatelessWidget {
  const HeaderChip({
    super.key,
    required this.icon,
    required this.label,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;

  /// Screenreader-Text, wenn er vom sichtbaren Text abweicht.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Semantics(
      container: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.headerChipFill,
          borderRadius: BorderRadius.circular(CuraRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CuraSize.statPillPaddingH,
            vertical: CuraSize.statPillPaddingV,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: CuraSize.statPillIcon, color: colors.headerInk),
              const SizedBox(width: CuraSize.statPillGap),
              Flexible(
                child: Text(
                  label,
                  style: type.chip.copyWith(color: colors.headerInk),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fortschrittsbalken der Kopf-Karte (Brief 3.2): Spur Weiß 30 % mit 1 dp Rand,
/// Füllung Gold; der Wert steht **immer auch als Text** („4 von 7 Tagen“),
/// weil Füllung gegen Spur keine 3:1 erreicht.
class HeaderProgress extends StatelessWidget {
  const HeaderProgress({super.key, required this.value, required this.label})
    : assert(value >= 0 && value <= 1);

  /// Anteil 0 … 1.
  final double value;

  /// Wert als Text („4 von 7 Tagen“).
  final String label;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.headerTrack,
              borderRadius: BorderRadius.circular(CuraRadius.pill),
              border: Border.all(
                color: colors.headerInk,
                width: CuraSize.hairline,
              ),
            ),
            child: SizedBox(
              height: CuraSize.headerProgressHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: value,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.gold,
                      borderRadius: BorderRadius.circular(CuraRadius.pill),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: CuraSpace.s1),
          Text(label, style: type.secondary.copyWith(color: colors.headerInk)),
        ],
      ),
    );
  }
}
