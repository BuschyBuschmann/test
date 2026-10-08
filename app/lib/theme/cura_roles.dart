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
  /// Pressed: Überlagerung Weiß 10 % (Brief 5, Ergänzung 2).
  Color get pressedOverlay => _white(Palette.pressedOverlayAlpha);

  /// Innere Lichtkante der Glas-Karte E1 (Brief 3.5): Weiß 10 %.
  Color get lightEdge => _white(Palette.lightEdgeAlpha);

  /// Disabled: Füllung Weiß 10 %, Inhalt `text-1` 38 % (Brief 5).
  Color get disabledFill => _white(Palette.disabledFillAlpha);
  Color get disabledContent =>
      text1.withValues(alpha: Palette.disabledContentAlpha);

  /// Pressed-Füllung „Neutral hell“: reines Weiß (Ergänzung 1, Abschnitt 2).
  Color get pureWhite => _white(1);

  /// Offene Segmente der Fortschrittsanzeige: Weiß 18 % (Brief 5.8).
  Color get progressOff => _white(Palette.progressOffAlpha);

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
