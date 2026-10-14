// Rohwerte der Design-Tokens (Design-Brief v2, Abschnitt 3: Inhaltsflächen
// Hell/Dunkel 3.2, Typografie 3.3, Blur-Budget 3.5, Bewegung 3.6; die Welt
// je Tageszeit steht in `world_tokens.dart`). Hier stehen Hex-Werte und Zahlen;
// Abstände, Radien und Größen liegen in `cura_metrics.dart`. Außerhalb von
// `lib/theme/` gilt KONVENTIONEN Regel 1.
import 'package:flutter/animation.dart';

/// Farbwerte der Inhaltsflächen (Brief 3.2) in Hell und Dunkel. Alphas sind
/// als Anteil 0..1 angegeben und werden in `cura_colors.dart` zu
/// `Color`-Werten.
abstract final class Palette {
  // --- Karte (E1, Pseudo-Glas ohne Blur): Weiß bzw. #241D18, 92 % ----------
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF241D18);
  static const double cardAlpha = 0.92;

  // Grund unter der Welt (`world-floor` bei Tag bzw. Nacht), Scaffold-Farbe.
  static const Color bgLight = Color(0xFFF7F2EB);
  static const Color bgDark = Color(0xFF1C1620);

  // --- Text: ink-1/ink-2 (Hell), text-1/text-2 (Dunkel) --------------------
  static const Color text1Light = Color(0xFF211B16);
  static const Color text2Light = Color(0xFF5A5048);
  static const Color text1Dark = Color(0xFFF5EFE8);
  static const Color text2Dark = Color(0xFFCFC5BB);

  // --- Akzent Mandarine ------------------------------------------------------
  static const Color accent = Color(0xFFFF7A2E);
  // Obere Farbe des Akzentverlaufs (`#FFA063` → `#FF7A2E`).
  static const Color accentTop = Color(0xFFFFA063);
  static const Color onAccent = Color(0xFF211B16);
  // Gedrückte Akzentfüllung (Annahme: etwas dunkler als Mandarine; Kontrast
  // mit `on-accent` per Test ≥ 4,5).
  static const Color accentPressed = Color(0xFFF06E22);
  static const double accentSoftAlpha = 0.16;

  // Orange als Text: nur der dunkle Ton (E-2, V2-32).
  static const Color accentTextLight = Color(0xFFA83F0B);
  static const Color accentTextDark = Color(0xFFFF9A62);

  // --- Status- und Kategorietöne ---------------------------------------------
  static const Color successTextLight = Color(0xFF1B6E47);
  static const Color successTextDark = Color(0xFF5FD39A);
  static const Color errorLight = Color(0xFFB3261E);
  static const Color errorDark = Color(0xFFFF8A80);

  static const Color catPhysioLight = Color(0xFF2A62B0);
  static const Color catPhysioDark = Color(0xFF8DB8FF);
  static const Color catArztLight = Color(0xFF6B49C9);
  static const Color catArztDark = Color(0xFFB9A4FF);
  static const Color catUebungLight = successTextLight;
  static const Color catUebungDark = successTextDark;
  static const Color catFristLight = errorLight;
  static const Color catFristDark = errorDark;

  // Triage-Töne (v1, nur Triage/Fristen; Brief 2: Orange nie Statusfarbe).
  // Dunkel wie v1; Hell sind abgedunkelte Annahmen mit ≥ 4,5:1 auf der Karte.
  static const Color triGruenDark = Color(0xFF3DDC97);
  static const Color triGelbDark = Color(0xFFF7E04A);
  static const Color triOrangeDark = Color(0xFFFFA62B);
  static const Color triRotDark = errorDark;
  static const Color triGruenLight = successTextLight;
  static const Color triGelbLight = Color(0xFF6B5200);
  static const Color triOrangeLight = Color(0xFF8F4300);
  static const Color triRotLight = errorLight;

  // Freeze-Symbol (Streak-Freeze): Hell wie `cat-physio`, Dunkel v1-Wert.
  static const Color streakFreezeLight = catPhysioLight;
  static const Color streakFreezeDark = Color(0xFF8FBBFF);

  // --- Chips (Brief 3.2) ------------------------------------------------------
  static const double chipNeutralLightAlpha = 0.07; // ink-1 7 % auf Karte
  static const double chipNeutralDarkAlpha = 0.10; // Weiß 10 % auf Karte
  static const Color chipSuccessFillLight = Color(0xFFDDF3E6);
  static const Color chipSuccessTextLight = Color(0xFF14532D);
  static const Color chipWarnFillLight = Color(0xFFFFE3DD);
  static const Color chipWarnTextLight = Color(0xFF7A1A12);
  // Dunkel: „getönte dunkle Chips, Text ≥ 4,5:1 (Test)“. Die Werte nennt der
  // Brief nicht; Annahme, per Test geprüft.
  static const Color chipSuccessFillDark = Color(0xFF1E3A2C);
  static const Color chipSuccessTextDark = Color(0xFF9BE8C4);
  static const Color chipWarnFillDark = Color(0xFF4A211C);
  static const Color chipWarnTextDark = Color(0xFFFFB4AB);

  // --- Ränder und Fokus --------------------------------------------------------
  // `border-control`: ink-1 55 % (Hell), text-1 45 % (Dunkel).
  static const double borderControlLightAlpha = 0.55;
  static const double borderControlDarkAlpha = 0.45;
  // Hoher Kontrast / Transparenz reduzieren: Rand ≥ 4,3:1 auf der opaken
  // Karte (Brief 3.5); hier ink-1/text-1 mit 75 % (Annahme, per Test).
  static const double borderControlHcAlpha = 0.75;
  // Haarlinie um Karten.
  static const double borderHairLightAlpha = 0.10;
  static const double borderHairDarkAlpha = 0.14;

  // `focus-ring`: 3 dp `ink-1`/`text-1` mit 2 dp Außenrand in der Gegenfarbe.
  static const Color focusRingOuterLight = Color(0xFFFFFFFF);
  static const Color focusRingOuterDark = Color(0xFF241D18);

  // --- Gold (Fortschritt, Ziel) ---------------------------------------------------
  static const Color gold = Color(0xFFFFC23D);
  static const Color onGold = Color(0xFF8A3A0C);

  // --- Scrim ---------------------------------------------------------------------
  // Dialog-Scrim `ink-1` 45 % (Brief 4). Hoher Kontrast: 72 % wie v1
  // (Annahme, Brief nennt keinen eigenen Wert).
  static const Color scrimBase = Color(0xFF211B16);
  static const double scrimAlpha = 0.45;
  static const double scrimAlphaHighContrast = 0.72;

  // --- Karte als Fläche schwebender Elemente ----------------------------------------
  // Übergang: schwebende Flächen mit `card` 82 % (nur noch Sheet-Kompakt,
  // Knoten-Hinweis); Leiste, Kopf-Karte und Manny-Knopf nutzen die Welt-Tokens.
  static const double floatAlpha = 0.82;

  // --- Karte E1 (Brief 3.5): Schatten 0/18/30, negativer Spread, warm getönt
  // (Annahme der Zahlen: Spread -12, Deckkraft 16 % Hell / 45 % Dunkel).
  static const Color cardShadowTint = Color(0xFF2A211C);
  static const double cardShadowLightAlpha = 0.16;
  static const double cardShadowDarkAlpha = 0.45;

  // --- Buttons (Brief 4) ---------------------------------------------------------------
  // GlassPill: Weiß 90 % ohne Blur; Primär deaktiviert: Weiß 50 %.
  static const double glassPillAlpha = 0.90;
  static const double primaryDisabledAlpha = 0.50;
  // Schein und Lichtkante des Primärbuttons.
  static const double primaryEdgeAlpha = 0.55;

  // --- Kopf-Karte (Brief 3.1): Text immer `#FFFFFF`; Chips darin Weiß 18 %.
  static const Color headerInk = Color(0xFFFFFFFF);
  static const double headerChipFillAlpha = 0.18;
  static const double headerTrackAlpha = 0.30;

  // --- Leiste (Brief 4.1) ----------------------------------------------------------------
  // Badge „Chats“: `#B3261E` mit weißem Text und Rand.
  static const Color navBadge = Color(0xFFB3261E);
  static const Color navBadgeInk = Color(0xFFFFFFFF);

  // --- Pfad-Kugeln `OrbNode` (Brief 4, Glas-Objekte) ------------------------------------
  // Radialverlauf (Glanz oben links -> Körper -> Rand), je Zustand.
  static const Color orbPearlHigh = Color(0xFFFFFFFF);
  static const Color orbPearlBody = Color(0xFFF1EAF5);
  static const Color orbPearlEdge = Color(0xFFC9BDD3);
  static const Color orbMandarinHigh = Color(0xFFFFB98A);
  static const Color orbMandarinEdge = Color(0xFFE5651A);
  static const Color orbGoldHigh = Color(0xFFFFE08A);
  static const Color orbGoldEdge = Color(0xFFF2BC3A);
  static const Color orbGlassLightHigh = Color(0xFFF1EEF3);
  static const Color orbGlassLightBody = Color(0xFFD7D2DC);
  static const Color orbGlassLightEdge = Color(0xFFB1A9BA);
  static const Color orbGlassDarkHigh = Color(0xFF5A5360);
  static const Color orbGlassDarkBody = Color(0xFF433D49);
  static const Color orbGlassDarkEdge = Color(0xFF2E2933);
  // Stern auf Gold, Flagge/Haken siehe `onGold` / `onAccent`.
  static const Color orbStar = Color(0xFFB8470F);
  static const Color orbCheck = onGold;
  static const double orbGlossAlpha = 0.55;
  static const double orbEdgeAlpha = 0.70;
  static const double orbInnerShadowAlpha = 0.22;
  static const double orbGroundShadowAlpha = 0.28;
  static const double orbHaloAlpha = 0.45;

  // --- Sheet (Brief 4): Griff ---------------------------------------------------------------
  static const double sheetHandleAlpha = 0.28;

  // --- Manny (Brief-Ergänzung 1, 6.4) -------------------------------------------------
  // Helle Scheibe unter dem Kopf (Avatar, Chat-Kopf) in Hell und Dunkel gleich;
  // Halo hinter der Figur auf der Welt Nacht: Weiß 28 %.
  static const Color mannyDisc = Color(0xFFFBF3E4);
  static const double mannyHaloAlpha = 0.28;

  // Gewählte Look-Karte: Fläche `#FFF1E4` (Hell); im Thema Dunkel eine dunkle,
  // warm getönte Fläche (Annahme: Brief nennt nur den Hell-Wert).
  static const Color mannyChoiceSelectedLight = Color(0xFFFFF1E4);
  static const Color mannyChoiceSelectedDark = Color(0xFF3A2A1F);

  // Manny-Knopf: Glas Weiß 78 %, wie die Leiste im Zustand Aktiv (auch Nacht).
  static const double mannyButtonGlassAlpha = 0.78;

  // Weitere Deckkraftwerte aus dem Brief (Ablage, keine neuen Design-Tokens).
  static const double lightEdgeLightAlpha = 0.60; // Lichtkante oben, Hell
  static const double lightEdgeDarkAlpha = 0.10; // Lichtkante oben, Dunkel
  static const double pressedOverlayAlpha = 0.10; // Pressed: ink/text 10 %
  static const double disabledContentAlpha = 0.38;
  static const double disabledFillAlpha = 0.10;
  static const double lockedBorderAlpha = 0.20;
  static const double lockedIconAlpha = 0.50;
  static const double futureLineAlpha = 0.22;
  // Spur von Balken und Reglern: ink-1 14 % (Brief 3.2).
  static const double progressOffAlpha = 0.14;
  static const double avatarRingNeutralAlpha = 0.30;
  static const double accentRingAlpha = 0.40;
  static const double accentUnitGlowAlpha = 0.50;
  static const double bossBorderAlpha = 0.55;
  static const double navActiveBorderAlpha = 0.60;
  // Schein unter dem Primärbutton: Mandarine 70 % (Brief 4, `PrimaryPill`).
  static const double primaryGlowAlpha = 0.70;
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

  /// Untergrenzen aus Brief 3.3: nichts unter 13 sp, nichts unter 400.
  static const double minFontSize = 13;
  static const int minFontWeight = 400;

  // Titel und Zahlen: Bricolage Grotesque, Gewicht 800 (Brief 3.3).
  static const TypeSpec display = TypeSpec(bricolage, 36, 38, 800);
  // Titel der Kopf-Karte 30/32.
  static const TypeSpec titleHeader = TypeSpec(bricolage, 30, 32, 800);
  static const TypeSpec title = TypeSpec(bricolage, 24, 28, 800);
  static const TypeSpec heading = TypeSpec(bricolage, 20, 23, 800);
  // Zähler-Orb 52/52, Einheit 30.
  static const TypeSpec counter = TypeSpec(bricolage, 52, 52, 800);
  static const TypeSpec counterUnit = TypeSpec(bricolage, 30, 30, 800);
  // Zahl in Kacheln 28/30; kleine Zahl 17–18.
  static const TypeSpec numeral = TypeSpec(bricolage, 28, 30, 800);
  static const TypeSpec numeralSmall = TypeSpec(bricolage, 18, 24, 800);
  // Uhrzeit auf Karten (24/28).
  static const TypeSpec numeralLarge = TypeSpec(bricolage, 24, 28, 800);
  static const TypeSpec button = TypeSpec(bricolage, 18, 24, 800);
  // Text: DM Sans.
  static const TypeSpec body = TypeSpec(dmSans, 16, 24, 400);
  static const TypeSpec bodyStrong = TypeSpec(dmSans, 16, 24, 700);
  static const TypeSpec secondary = TypeSpec(dmSans, 14, 20, 500);
  // meta / chip 13/16, 600–700.
  static const TypeSpec label = TypeSpec(
    dmSans,
    13,
    16,
    700,
    letterSpacingEm: 0.06,
  );
  static const TypeSpec caption = TypeSpec(dmSans, 13, 16, 600);
  static const TypeSpec chip = TypeSpec(dmSans, 13, 16, 700);
  // Sprechblase (14,5 sp aufwärts). Zeilenhöhe 20 ist Annahme (analog
  // `secondary`), im Brief nicht genannt.
  static const TypeSpec bubble = TypeSpec(dmSans, 14.5, 20, 400);
  // Segment (A-23): nicht gewählt = body, gewählt 700.
  static const TypeSpec segment = TypeSpec(dmSans, 16, 24, 400);
  static const TypeSpec segmentSelected = TypeSpec(dmSans, 16, 24, 700);
}

/// Blur-Budget und Weichzeichnung (Brief 3.5).
abstract final class BlurTokens {
  /// Obergrenze: höchstens 3 gleichzeitig sichtbare `BackdropFilter` je
  /// Screen (Leiste, Kopf-Karte, Manny-Knopf).
  static const int maxPerScreen = 3;

  /// Übergangswert der Bestandsflächen (Blase, Sheet), bis F2-R2 sie ersetzt.
  static const double sigma = 16;

  /// Leiste (Ruhe und Aktiv): σ 30.
  static const double navSigma = 30;

  /// Kopf-Karte: σ 24.
  static const double headerSigma = 24;
}

abstract final class MotionTokens {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);

  /// Obergrenze der Feier (Manny hüpft, Sterne, Zähler zählt hoch).
  static const Duration celebrate = Duration(milliseconds: 1800);

  /// Feder: einmaliges Überschwingen, höchstens 8 %, höchstens 600 ms; nur
  /// für Fortschrittsfüllung, Kugel-Pop und Zähler-Orb.
  static const Duration springMax = Duration(milliseconds: 600);
  static const double springOvershoot = 0.08;

  /// Überblendung der Welt an einer Phasengrenze: 30 Minuten linear.
  static const Duration worldFade = Duration(minutes: 30);

  /// Die Welt wird im Hintergrund minütlich neu berechnet (nie animiert).
  static const Duration worldTick = Duration(minutes: 1);

  /// Zeit ohne Interaktion, nach der die Leiste in die Ruhe zurückkehrt.
  static const Duration navRestDelay = Duration(seconds: 2);

  // Fortschrittskreis eines laufenden Vorgangs: sichtbar erst nach dieser
  // Verzögerung (Erratum E-3, Löschen-Dialog UI-52).
  static const Duration busyDelay = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOutCubic;

  /// Die Feder-Kurve (einmaliges Überschwingen um [springOvershoot]).
  static const Curve spring = CuraSpringCurve();

  // Reduzierte Bewegung: höchstens `fast`.
  static const Duration reducedMax = fast;
  // Schiebung Onboarding-Seitenwechsel und Vollbild-Routen (dp).
  static const double routeSlide = 24;
  // Schiebung Sprechblase, Snackbar (dp).
  static const double bubbleSlide = 8;
}

/// Feder mit genau einem Überschwingen: steigt in `easeOutCubic` auf
/// `1 + overshoot` und kehrt weich auf 1 zurück. Anfangs- und Endwert 0 und 1,
/// an Gipfel und Ende Steigung 0.
class CuraSpringCurve extends Curve {
  const CuraSpringCurve({
    this.overshoot = MotionTokens.springOvershoot,
    this.peakAt = 0.55,
  });

  /// Anteil über 1 am Gipfel (0,08 = 8 %).
  final double overshoot;

  /// Zeitpunkt (0 … 1) des Gipfels.
  final double peakAt;

  @override
  double transformInternal(double t) {
    if (t <= peakAt) {
      return (1 + overshoot) * Curves.easeOutCubic.transform(t / peakAt);
    }
    final double u = (t - peakAt) / (1 - peakAt);
    return 1 + overshoot * (1 - Curves.easeInOutCubic.transform(u));
  }
}

abstract final class SnackbarTokens {
  /// Brief v2, 4: „Eingetragen. Rückgängig“ bleibt 6 s stehen.
  static const Duration standard = Duration(seconds: 6);
  static const Duration short = Duration(seconds: 4);
  static const Duration medium = Duration(seconds: 5);
  static const Duration long = Duration(seconds: 8);
  // Aktion rutscht ab dieser Textskalierung unter den Text (Ergänzung 1, 4).
  static const double actionBelowTextScale = 1.3;
}
