// Abgeleitete Farbrollen und Maße der geteilten Bausteine (U2a). Ablage der
// Brief-Werte aus Brief 3.1/3.5/5 und Ergänzung 1/2 (Plan 14, MINOR-6): keine
// neuen Design-Tokens, sondern Namen für Brief-Werte. Teils stehen sie schon
// in `tokens.dart`/`cura_metrics.dart`; einige Maße (z. B. 280, 140, 2,5,
// 100 ms) sind hier erstmals als Literale abgelegt und stammen aus den Briefs
// (Sprechblase 5.6, Fortschrittskreis, Snackbar-Takt). Außerhalb von
// `lib/theme/` gilt KONVENTIONEN Regel 1.
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

import 'cura_colors.dart';
import 'cura_metrics.dart';
import 'tokens.dart';

Color _white(double alpha) => const Color(0xFFFFFFFF).withValues(alpha: alpha);

/// Drei Töne einer Kugel: Glanz (oben links), Körper, Rand.
@immutable
class OrbShades {
  const OrbShades({required this.high, required this.body, required this.edge});

  final Color high;
  final Color body;
  final Color edge;
}

extension CuraColorRoles on CuraColors {
  /// Pressed: Überlagerung `ink-1`/`text-1` 10 % (Brief 5, Ergänzung 2).
  Color get pressedOverlay =>
      text1.withValues(alpha: Palette.pressedOverlayAlpha);

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

  // --- Manny (Ergänzung 1, 6.4) -------------------------------------------

  /// Helle Scheibe unter dem Kopf, in Hell und Dunkel gleich.
  Color get mannyDisc => Palette.mannyDisc;

  /// Halo hinter der Figur in der Welt Nacht: Weiß 28 %; mit „Transparenz
  /// reduzieren“/Hoher Kontrast opak `card`.
  Color get mannyHalo =>
      highContrast ? surfaceOpaque : _white(Palette.mannyHaloAlpha);

  /// Fläche des Halos bei Nacht-Anteil [amount] (0 … 1): Weiß 28 % mit weichem
  /// Auslauf, bei Hohem Kontrast opak.
  BoxDecoration mannyHaloDecoration(double amount) {
    final Color base = mannyHalo.withValues(alpha: mannyHalo.a * amount);
    return BoxDecoration(
      shape: BoxShape.circle,
      color: highContrast ? base : null,
      gradient: highContrast
          ? null
          : RadialGradient(
              colors: <Color>[base, base, base.withValues(alpha: 0)],
              stops: const <double>[0, CuraSize.mannyHaloSolid, 1],
            ),
    );
  }

  /// Manny-Knopf: Glas Weiß 78 % (wie die Leiste Aktiv). Hoher Kontrast: opak;
  /// die Scheibe bleibt hell (Annahme: Kopf immer auf heller Scheibe, 6.4, hat
  /// Vorrang vor `card` im Thema Dunkel).
  Color get mannyButtonGlass =>
      highContrast ? Palette.mannyDisc : _white(Palette.mannyButtonGlassAlpha);

  /// Gewählte Look-Karte (Ergänzung 1, 6a): Fläche `#FFF1E4`.
  Color get mannyChoiceSelectedFill => isDark
      ? Palette.mannyChoiceSelectedDark
      : Palette.mannyChoiceSelectedLight;

  // --- Kopf-Karte (Brief 3.1) ---------------------------------------------

  /// Text der Kopf-Karte: immer `#FFFFFF`, kein Grauton.
  Color get headerInk => Palette.headerInk;

  /// Rand und Druck-Überlagerung auf der Kopf-Karte (Weiß 18 %).
  Color get headerEdge => _white(Palette.headerChipFillAlpha);

  /// Füllung der Chips in der Kopf-Karte: dunkle Tönung, damit weißer Text
  /// 4,5:1 sicher erreicht (Brief 3.1, V2-3).
  Color get headerChipFill =>
      Palette.headerChipShade.withValues(alpha: Palette.headerChipShadeAlpha);
  Color get headerTrack => _white(Palette.headerTrackAlpha);

  // --- Buttons (Brief 4) ----------------------------------------------------

  /// `GlassPill`: Weiß 90 % ohne Blur (Hoher Kontrast: opak), Text und Rand in
  /// der dunklen Tinte in beiden Themen (die Pille bleibt hell).
  Color get glassPillFill =>
      highContrast ? pureWhite : _white(Palette.glassPillAlpha);
  Color get glassPillInk => Palette.text1Light;
  Color get glassPillBorder => lightSurfaceBorder;

  /// Rand auf einer hellen Fläche (GlassPill, Manny-Scheibe), die in beiden
  /// Themen hell bleibt: dunkle Tinte 55 % (Hoher Kontrast 75 %, ≥ 4,3:1).
  Color get lightSurfaceBorder => Palette.text1Light.withValues(
    alpha: highContrast
        ? Palette.borderControlHcAlpha
        : Palette.borderControlLightAlpha,
  );
  Color get glassPillPressed =>
      Color.alphaBlend(Palette.text1Light.withValues(alpha: 0.10), pureWhite);

  /// `PrimaryPill` deaktiviert: Weiß 50 % mit `ink-2`-Text und Rand.
  Color get primaryDisabledFill => _white(Palette.primaryDisabledAlpha);
  Color get primaryDisabledInk => Palette.text2Light;

  /// Lichtkante oben auf der Primär-Pille.
  Color get primaryEdge => _white(Palette.primaryEdgeAlpha);

  // --- Leiste (Brief 4.1) ----------------------------------------------------

  Color get navBadgeFill => Palette.navBadge;
  Color get navBadgeInk => Palette.navBadgeInk;

  // --- Kategorie-Kachel (Brief 3.2) ------------------------------------------

  /// Symbol auf der Kategorie-Kachel: im Thema Hell sind die Kategorietöne
  /// dunkel (Weiß ≥ 5:1), im Thema Dunkel hell (`on-accent`).
  Color get onCategory => isDark ? onAccent : pureWhite;

  // --- Pfad-Kugeln `OrbNode` (Brief 4, Glas-Objekte) ---------------------------

  /// Erledigt: Perlglas.
  OrbShades get orbPearl => const OrbShades(
    high: Palette.orbPearlHigh,
    body: Palette.orbPearlBody,
    edge: Palette.orbPearlEdge,
  );

  /// Aktuell: Mandarine-Kugel.
  OrbShades get orbMandarin => const OrbShades(
    high: Palette.orbMandarinHigh,
    body: Palette.accent,
    edge: Palette.orbMandarinEdge,
  );

  /// Ziel/Boss: Gold.
  OrbShades get orbGold => const OrbShades(
    high: Palette.orbGoldHigh,
    body: Palette.gold,
    edge: Palette.orbGoldEdge,
  );

  /// Gesperrt: Grauglas (Thema Hell hell, Thema Dunkel dunkel).
  OrbShades get orbGlass => isDark
      ? const OrbShades(
          high: Palette.orbGlassDarkHigh,
          body: Palette.orbGlassDarkBody,
          edge: Palette.orbGlassDarkEdge,
        )
      : const OrbShades(
          high: Palette.orbGlassLightHigh,
          body: Palette.orbGlassLightBody,
          edge: Palette.orbGlassLightEdge,
        );

  /// Haken auf Perlglas, Stern auf Gold, Glanz, Kante, Innenschatten, Boden.
  Color get orbCheck => Palette.orbCheck;
  Color get orbStar => Palette.orbStar;
  Color get orbGloss => _white(Palette.orbGlossAlpha);
  Color get orbEdge => _white(Palette.orbEdgeAlpha);
  Color get orbInnerShadow =>
      Palette.cardShadowTint.withValues(alpha: Palette.orbInnerShadowAlpha);
  Color get orbGroundShadow =>
      Palette.cardShadowTint.withValues(alpha: Palette.orbGroundShadowAlpha);
  Color get orbHalo => accent.withValues(alpha: Palette.orbHaloAlpha);

  // --- Sheet ----------------------------------------------------------------

  Color get sheetHandle => text1.withValues(alpha: Palette.sheetHandleAlpha);
}

/// Maße einzelner Bausteine, soweit sie in `CuraSize`/`CuraSpace` fehlen.
abstract final class CuraComponent {
  // Icons (Brief 5, Abschnitt 9 des Plans).
  static const double iconSize = 24;
  static const double dialogIconSize = 28;

  // Gedrückter Primärbutton: 2 % kleiner (Brief 4).
  static const double primaryPressedScale = 0.98;

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
