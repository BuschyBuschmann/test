// Abgeleitete Farbrollen und Maße der geteilten Bausteine (U2a). Ablage der
// Brief-Werte aus Brief 3.1/3.5/5 und Ergänzung 1/2 (Plan 14, MINOR-6): keine
// neuen Design-Tokens, sondern Namen für Brief-Werte. Teils stehen sie schon
// in `tokens.dart`/`cura_metrics.dart`; einige Maße (z. B. 280, 140, 2,5,
// 100 ms) sind hier erstmals als Literale abgelegt und stammen aus den Briefs
// (Sprechblase 5.6, Fortschrittskreis, Snackbar-Takt). Außerhalb von
// `lib/theme/` gilt KONVENTIONEN Regel 1.
import 'package:flutter/painting.dart';

import 'cura_colors.dart';
import 'cura_metrics.dart';
import 'tokens.dart';

Color _white(double alpha) => const Color(0xFFFFFFFF).withValues(alpha: alpha);

extension CuraColorRoles on CuraColors {
  /// Pressed: Überlagerung `ink-1`/`text-1` 10 % (Brief 5, Ergänzung 2).
  Color get pressedOverlay =>
      text1.withValues(alpha: Palette.pressedOverlayAlpha);

  /// Pressed auf dunklen Figuren (Manny-Platzhalter): Weiß 10 %.
  Color get pressedOverlayLight => _white(Palette.pressedOverlayAlpha);

  /// Innere Lichtkante der Karte E1 (Brief 3.5): Weiß 60 % (Hell) bzw. 10 %
  /// (Dunkel).
  Color get lightEdge =>
      _white(isDark ? Palette.lightEdgeDarkAlpha : Palette.lightEdgeLightAlpha);

  /// Aktionschip (Brief 5.3): neutraler Chip auf der Karte (`chip-neutral`).
  Color get chipFill => chipNeutralFill;

  /// Disabled: Füllung `ink-1`/`text-1` 10 %, Inhalt `text-1` 38 % (Brief 5).
  Color get disabledFill => text1.withValues(alpha: Palette.disabledFillAlpha);
  Color get disabledContent =>
      text1.withValues(alpha: Palette.disabledContentAlpha);

  /// Pressed-Füllung „Neutral hell“: reines Weiß (Ergänzung 1, Abschnitt 2).
  Color get pureWhite => _white(1);

  /// Spur von Fortschrittsbalken und Reglern: `ink-1` 14 % (Brief 3.2).
  Color get progressOff => text1.withValues(alpha: Palette.progressOffAlpha);

  /// Neutraler Avatar-Ring (Familie, Freunde): `text-1` 30 % (Ergänzung 2, 3.3).
  Color get avatarRingNeutral =>
      text1.withValues(alpha: Palette.avatarRingNeutralAlpha);

  /// Pfad-Units (Brief 5.5): Rand gesperrter Units `text-1` 20 % (Hoher
  /// Kontrast: `border-control-hc`), Schloss/Stern 50 %, zukünftige Strecke
  /// 22 %, Ring der aktuellen Unit `accent` 40 %, ihr Schein `accent` 50 %,
  /// Rand der Boss-Unit `accent` 55 %.
  Color get lockedBorder => highContrast
      ? controlBorder
      : text1.withValues(alpha: Palette.lockedBorderAlpha);
  Color get lockedIcon => text1.withValues(alpha: Palette.lockedIconAlpha);
  Color get futureLine => text1.withValues(alpha: Palette.futureLineAlpha);
  Color get accentRing => accent.withValues(alpha: Palette.accentRingAlpha);
  Color get accentUnitGlow =>
      accent.withValues(alpha: Palette.accentUnitGlowAlpha);
  Color get bossBorder => accent.withValues(alpha: Palette.bossBorderAlpha);

  /// Ende des Scheins der aktuellen Unit (voll durchsichtig).
  Color get accentUnitGlowClear => accentUnitGlow.withValues(alpha: 0);

  /// Ring-Puls nach der Feier: blendet mit [t] (0 … 1) aus.
  Color unitPulse(double t) => accent.withValues(alpha: 1 - t);

  /// Rand der aktiven Nav-Pill: `accent` 60 % (Brief 5.4).
  Color get navActiveBorder =>
      accent.withValues(alpha: Palette.navActiveBorderAlpha);
}

/// Maße einzelner Bausteine, soweit sie in `CuraSize`/`CuraSpace` fehlen.
abstract final class CuraComponent {
  // Icons (Brief 5, Abschnitt 9 des Plans).
  static const double iconSize = 24;
  static const double dialogIconSize = 28;

  // PillButton: Innenabstand und Fortschrittskreis (Brief 5.3, Ergänzung 1).
  static const double pillIconGap = 8;
  static const double progressSize = 24;
  static const double progressStroke = 2.5;

  // Nav: Verlauf über der Pill.
  static const double navFadeExtra = CuraSpace.s4;

  // Sprechblase (Brief 5.6).
  static const double bubbleMaxWidth = 280;
  static const double bubbleMinSideSpace = 140;
  static const double bubbleArrow = 8;
  static const double bubbleArrowBase = 16;

  // Dialog und Snackbar (Ergänzung 1, Abschnitt 2).
  static const double snackbarPadding = 16;
  static const Duration snackbarTick = Duration(milliseconds: 100);
  static const double snackbarActionPadding = CuraSpace.s3;
  static const double dialogPadding = CuraSpace.s6;
  static const double dialogGap = CuraSpace.s3;

  // Auswahlkarte: Icon-Abstand.
  static const double choiceIconGap = CuraSpace.s3;
  static const double choiceInnerMinHeight =
      CuraSize.choiceCardMinHeight - CuraSpace.s3 * 2;

  // Eingabefeld: Radius wie `radius-card` (Annahme, Brief nennt keinen).
  static const double fieldRadius = CuraRadius.card;
  static const double fieldGap = CuraSpace.s2;

  // Fortschrittsbalken (Brief 5.8).
  static const int stepSegments = 4;
}
