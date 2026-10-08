// Abstände, Radien, Größen und Schatten (Design-Brief v1 3.4/3.5, Ergänzung 1
// und 2). Die Werte der Brief-Ergänzung 2 stehen hier nur als Ablage der
// Brief-Werte (Plan 14, MINOR-6); es sind keine neuen Design-Tokens.
import 'package:flutter/painting.dart';

import 'tokens.dart';

/// Raster 4 dp (Brief 3.4): `space-1 = 4`, `2 = 8`, `3 = 12`, `4 = 16`,
/// `5 = 20`, `6 = 24`, `8 = 32`, `10 = 40`.
abstract final class CuraSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;

  /// Seitenrand.
  static const double pageMargin = 16;

  /// Abstand zwischen Nachrichten (Ergänzung 2, 2.2) und zwischen Blöcken
  /// gleichen Autors.
  static const double messageGap = 20;
  static const double blockGap = 8;

  /// Button-Gruppe (Ergänzung 2, 3.1): Abstand der Buttons zueinander und
  /// Primärbutton zu Manny-Button auf Heute.
  static const double clusterGap = 8;

  /// Snackbar: Abstand über der Button-Gruppe (Ergänzung 2, 3.1/UI-41).
  static const double snackbarGap = 12;

  /// Manny-Text-Einzug in der Nachrichtenliste (Ergänzung 2, 2.2).
  static const double mannyTextIndent = 36;
}

abstract final class CuraRadius {
  static const double card = 24;
  static const double pill = 999;
  static const double chipInner = 12;
  static const double sheet = 28; // nur oben
  static const double iconTile = 7;

  // Ergänzung 1 und 2.
  static const double snackbar = 20;
  static const double dialog = 24;
  static const double nodeHint = 16;
  static const double bubble = 20; // Sprechblase und Chat-Blasen
  static const double bubbleCorner = 6; // Ecke zur Absenderseite
  static const double notice = 16; // Hinweiskarte `ExampleNotice`
  static const double composer = 28; // Eingabeleiste
}

abstract final class CuraSize {
  // Touch-Ziele (Brief 3.4).
  static const double touchTarget = 48;
  static const double minTargetGap = 8;

  // Nav: 64 dp hoch, 16 dp Abstand zu den Seiten, 22 dp zum unteren Rand.
  static const double navHeight = 64;
  static const double navSideMargin = 16;
  static const double navBottomMargin = 22;
  static const double navActivePill = 48;
  static const double navLabelMaxTextScale = 1.3;

  // Buttons und Felder.
  static const double primaryButtonHeight = 56;
  static const double chipHeight = 48; // Chip/Segment
  static const double chipVisibleHeight = 36; // Aktionschip, Hit-Area 48
  static const double textFieldHeight = 56;
  static const double micButton = 56;

  // Pfad-Units (Durchmesser) und Ring.
  static const double unitSmall = 48;
  static const double unitMedium = 60;
  static const double unitLarge = 72;
  static const double unitBoss = 92;
  static const double unitRingGap = 9;
  static const double unitRingWidth = 1.5;

  // Manny.
  static const double mannyPathHeight = 80;
  static const double mannyOnboardingMinHeight = 56;
  static const double mannyOnboardingMaxHeight = 64;

  // Button-Gruppe (Ergänzung 2, 2 und 3.1).
  static const double mannyChatButton = 56;
  static const double messagesButton = 48;
  static const double mannyHeadInButton = 38;
  static const double mannyHitMargin = 8;
  static const double sendCircle = 40; // Hit-Area 48
  static const double sendCircleHitArea = 48;

  // Eingabeleiste und Blasen.
  static const double composerMinHeight = 56;
  static const double noticePaddingVertical = 10;
  static const double noticePaddingHorizontal = 14;
  static const double bubblePaddingVertical = 12;
  static const double bubblePaddingHorizontal = 16;

  // Avatare und Embleme.
  static const double avatar = 48;
  static const double avatarHeader = 36; // Kopf: 32 bis 36
  static const double avatarHeaderMin = 32;
  static const double emblemMessage = 26;
  static const double emblemHeader = 34;

  // Zeilen und Längen.
  static const double lineLengthMax = 560; // Zeilenlänge und ContentFrame
  static const double contactRowMin = 72;

  // Schwellen.
  static const double bubbleWidthFactor = 0.80;
  static const double chatFooterMaxFraction = 0.40;
  static const double textScaleScrollAlong = 1.5;

  /// Routen-Schiebung (Vollbild-Routen, Onboarding-Seitenwechsel).
  static const double routeSlide = MotionTokens.routeSlide;

  // Karten, Dialog, Hinweise, Sheet (Brief 5, Ergänzung 1).
  static const double cardPadding = 16;
  static const double cardPaddingWithStripe = 22;
  static const double categoryStripe = 4;
  static const double categoryIconTile = 20;
  static const double dialogMaxWidth = 400;
  static const double nodeHintMaxWidth = 240;
  static const double nodeHintArrow = 8;
  static const double sheetMaxHeightFraction = 0.90;
  static const double choiceCardMinHeight = 64;

  // Linien und Ränder (dp).
  static const double hairline = 1;
  static const double controlBorder = 1.5;
  static const double selectedBorder = 2;
  static const double focusRingWidth = 2;
  static const double focusRingGap = 2;
  static const double pathLine = 3;
  static const double stepBarHeight = 4;
}

/// Schatten (Brief 3.5 und Ergänzung 2). Farben aus `tokens.dart`.
abstract final class CuraShadow {
  static const Color _black = Color(0xFF000000);

  /// Primärbutton: Schein 0/8/28 `accent` 28 %.
  static final List<BoxShadow> primaryGlow = <BoxShadow>[
    BoxShadow(
      color: Palette.accent.withValues(alpha: Palette.primaryGlowAlpha),
      offset: const Offset(0, 8),
      blurRadius: 28,
    ),
  ];

  /// Nav und Sheet: 0/10/30 Schwarz 45 %.
  static final List<BoxShadow> floating = <BoxShadow>[
    BoxShadow(
      color: _black.withValues(alpha: Palette.navShadowAlpha),
      offset: const Offset(0, 10),
      blurRadius: 30,
    ),
  ];

  /// Manny- und Nachrichten-Button: 0/6/16 Schwarz 40 % (Ergänzung 2). Bleibt
  /// bei hohem Kontrast bestehen.
  static final List<BoxShadow> actionButton = <BoxShadow>[
    BoxShadow(
      color: _black.withValues(alpha: Palette.actionButtonShadowAlpha),
      offset: const Offset(0, 6),
      blurRadius: 16,
    ),
  ];
}
