// Rohwerte der Design-Tokens (Design-Brief v1 Abschnitt 3 samt Errata,
// Ergänzung 1 und 2). Hier stehen Hex-Werte und Zahlen der Schrift-, Farb-,
// Glow-, Blur- und Motion-Tokens; Abstände, Radien und Größen liegen in
// `cura_metrics.dart`. Außerhalb von `lib/theme/` gilt KONVENTIONEN Regel 1.
import 'package:flutter/animation.dart';

/// Farbwerte (Dunkel). Alphas sind als Anteil 0..1 angegeben und werden in
/// `cura_colors.dart` zu `Color`-Werten.
abstract final class Palette {
  static const Color bg = Color(0xFF0E131A);

  // Glas: Weiß über `bg` (Brief 3.1).
  static const double glassTopWhiteAlpha = 0.085;
  static const double glassBottomWhiteAlpha = 0.04;

  // `surface-float`: #18202A mit 82 % Deckkraft.
  static const Color surfaceFloatRgb = Color(0xFF18202A);
  static const double surfaceFloatAlpha = 0.82;
  static const Color surfaceOpaque = Color(0xFF1B2129);

  static const double borderHairAlpha = 0.14;
  static const double borderControlAlpha = 0.40;
  static const double borderControlHcAlpha = 0.45;

  static const Color text1 = Color(0xFFF2F0EB);
  static const Color text2 = Color(0xFFA9B0BC);
  static const Color text3 = Color(0xFF9AA2AF);

  static const Color accent = Color(0xFFD9622B);
  static const Color accentHi = Color(0xFFE8794A);
  static const double accentSoftAlpha = 0.16;
  // Pressed-Zustand der Akzentfüllung (Brief 3.1, Plan 8.4).
  static const Color accentPressed = Color(0xFFDD7240);
  static const Color onAccent = Color(0xFF0E131A);
  static const Color focusRing = Color(0xFFF2F0EB);

  static const Color catPhysio = Color(0xFF5B9DFF);
  static const Color catArzt = Color(0xFFA98BFF);
  static const Color catUebung = Color(0xFF3DDC97);
  static const Color catFrist = Color(0xFFFF5C70);

  static const Color triGruen = Color(0xFF3DDC97);
  static const Color triGelb = Color(0xFFF7E04A);
  static const Color triOrange = Color(0xFFFFA62B);
  static const Color triRot = Color(0xFFFF5C70);

  static const Color statusError = Color(0xFFFF5C70);
  static const Color streakFreeze = Color(0xFF8FBBFF);
  static const Color glowEmber = Color(0xFFFF6A3D);

  // Manny (Brief 3.1 und 5.6): Körper, Bauch, Rand Weiß 35 %.
  static const Color mannyBody = Color(0xFF34425F);
  static const Color mannyBelly = Color(0xFFF2F0EB);
  static const double mannyOutlineAlpha = 0.35;

  // Scrim (Ergänzung 1, Abschnitt 2): Schwarz 60 %, bei hohem Kontrast 72 %.
  static const double scrimAlpha = 0.60;
  static const double scrimAlphaHighContrast = 0.72;

  // Weitere Deckkraftwerte aus dem Brief (Ablage, keine neuen Design-Tokens).
  static const double lightEdgeAlpha = 0.10; // innere Lichtkante E1
  static const double pressedOverlayAlpha = 0.10; // Pressed: Weiß 10 %
  static const double chipFillAlpha = 0.07; // Aktionschip
  static const double disabledContentAlpha = 0.38;
  static const double disabledFillAlpha = 0.10;
  static const double lockedBorderAlpha = 0.20;
  static const double lockedIconAlpha = 0.50;
  static const double futureLineAlpha = 0.22;
  static const double progressOffAlpha = 0.18;
  static const double avatarRingNeutralAlpha = 0.30;
  static const double accentRingAlpha = 0.40;
  static const double accentUnitGlowAlpha = 0.50;
  static const double bossBorderAlpha = 0.55;
  static const double navActiveBorderAlpha = 0.60;
  static const double primaryGlowAlpha = 0.28;
  static const double navShadowAlpha = 0.45;
  static const double actionButtonShadowAlpha = 0.40;
}

/// Beschreibung eines Textstils (Brief 3.3). Größe und Zeilenhöhe in sp.
class TypeSpec {
  const TypeSpec(
    this.family,
    this.size,
    this.lineHeight,
    this.weight, {
    this.letterSpacingEm = 0,
  });

  final String family;
  final double size;
  final double lineHeight;
  final int weight;
  final double letterSpacingEm;
}

abstract final class TypeScale {
  static const String bricolage = 'BricolageGrotesque';
  static const String dmSans = 'DMSans';

  // Achsen der variablen Fonts (opsz = Schriftgröße, begrenzt auf die Achse).
  static const double dmSansOpszMin = 9;
  static const double dmSansOpszMax = 40;
  static const double bricolageOpszMin = 12;
  static const double bricolageOpszMax = 96;
  static const double bricolageWidth = 100;

  /// Untergrenzen aus Brief 3.3 und UI-5: nichts unter 13 sp, nichts unter 400.
  static const double minFontSize = 13;
  static const int minFontWeight = 400;

  static const TypeSpec display = TypeSpec(bricolage, 32, 36, 500);
  static const TypeSpec title = TypeSpec(bricolage, 24, 28, 500);
  static const TypeSpec heading = TypeSpec(bricolage, 18, 24, 500);
  static const TypeSpec numeral = TypeSpec(bricolage, 20, 24, 600);
  // Uhrzeit auf Karten (Brief 3.3: „Uhrzeit (24/28)“).
  static const TypeSpec numeralLarge = TypeSpec(bricolage, 24, 28, 600);
  static const TypeSpec button = TypeSpec(bricolage, 18, 24, 600);
  static const TypeSpec body = TypeSpec(dmSans, 16, 24, 400);
  static const TypeSpec bodyStrong = TypeSpec(dmSans, 16, 24, 600);
  static const TypeSpec secondary = TypeSpec(dmSans, 14, 20, 500);
  static const TypeSpec label = TypeSpec(
    dmSans,
    13,
    16,
    600,
    letterSpacingEm: 0.06,
  );
  static const TypeSpec caption = TypeSpec(dmSans, 13, 16, 500);
  // Sprechblase (Brief 5.6: 14,5 sp aufwärts). Zeilenhöhe 20 ist Annahme
  // (analog `secondary`), im Brief nicht genannt.
  static const TypeSpec bubble = TypeSpec(dmSans, 14.5, 20, 400);
  // Segment (A-23): nicht gewählt = body, gewählt 700.
  static const TypeSpec segment = TypeSpec(dmSans, 16, 24, 400);
  static const TypeSpec segmentSelected = TypeSpec(dmSans, 16, 24, 700);
}

/// Glow-Parameter (Brief 3.2, Errata E-1). Maße in dp.
abstract final class GlowTokens {
  // Oben links: Mitte (-30, 40), Radius 260, Spitze 24 %.
  static const double topLeftCenterX = -30;
  static const double topLeftCenterY = 40;
  static const double topLeftRadius = 260;
  static const double topLeftPeak = 0.24;

  // Unten rechts: Mitte 50 dp rechts neben und 24 dp über dem unteren Rand,
  // Radius 300, Spitze 14 %.
  static const double bottomRightOffsetX = 50;
  static const double bottomRightOffsetY = 24;
  static const double bottomRightRadius = 300;
  static const double bottomRightPeak = 0.14;

  // Der Verlauf erreicht bei 70 % des Radius null.
  static const double zeroStop = 0.7;

  // Schwellen nach Untergrund (Errata E-1, UI-7 neu).
  static const double maxOnBg = 0.24;
  static const double maxTextOnGlass = 0.16;
  static const double maxColoredOnGlass = 0.12;
}

abstract final class BlurTokens {
  static const double sigma = 16;
}

abstract final class MotionTokens {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
  static const Curve curve = Curves.easeOutCubic;
  // Reduzierte Bewegung: höchstens `fast`.
  static const Duration reducedMax = fast;
  // Schiebung Onboarding-Seitenwechsel und Vollbild-Routen (dp).
  static const double routeSlide = 24;
  // Schiebung Sprechblase, Snackbar (dp).
  static const double bubbleSlide = 8;
}

abstract final class SnackbarTokens {
  static const Duration short = Duration(seconds: 4);
  static const Duration medium = Duration(seconds: 5);
  static const Duration long = Duration(seconds: 8);
  // Aktion rutscht ab dieser Textskalierung unter den Text (Ergänzung 1, 4).
  static const double actionBelowTextScale = 1.3;
}
