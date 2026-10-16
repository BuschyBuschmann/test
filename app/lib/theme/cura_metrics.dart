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

  /// Manny-Text-Einzug in der Nachrichtenliste (Scheibe 48 dp plus 8 dp).
  static const double mannyTextIndent = 56;
}

/// Radien (Brief 3.4): Karte 28, Kopf-Karte 32, Bildkachel 18, Chip, Button
/// und Leiste Pille, Sheet oben 32, Kugeln rund.
abstract final class CuraRadius {
  static const double card = 28;
  static const double headerCard = 32;
  static const double imageTile = 18;
  static const double pill = 999;
  static const double chipInner = 12;
  static const double sheet = 32; // nur oben
  static const double iconTile = 7;

  // Ergänzung 1 und 2.
  static const double snackbar = 20;
  static const double dialog = 28;
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

  // --- Brief v2, 3.4: Größen der neuen Komponenten (F2-R2/R3 bauen sie) ----
  /// Seitenrand der Karten (Text: `CuraSpace.pageMargin` 16).
  static const double cardMargin = 14;

  /// Glas-Button 52 dp (Primärbutton `primaryButtonHeight` 56).
  static const double glassButtonHeight = 52;

  /// Smiley sichtbar 46 dp, Hit-Area 48.
  static const double ratingFace = 46;

  /// Leiste: 72 dp hoch, 14 dp Seitenabstand, 24 dp unten plus Safe Area;
  /// Tab 62 × 56 dp (Physio 76 × 56); Schleier darunter 150 dp.
  static const double navBarHeight = 72;
  static const double navBarSideMargin = 14;
  static const double navBarBottomMargin = 24;
  static const double navTabWidth = 62;
  static const double navTabWidthPhysio = 76;
  static const double navTabHeight = 56;
  static const double navVeilHeight = 150;

  /// Schleier über der festen Knopfzeile auf Heute: läuft auf 8 dp von 0 auf
  /// `navVeilAlpha` (`world-floor`) und deckt dahinter die Zeile selbst.
  static const double todayVeilFade = 8;

  /// Seitenleiste Physio am Rechner ab 840 dp Breite, 240 dp breit; Inhalt
  /// bis 1200 dp.
  static const double sideNavBreakpoint = 840;
  static const double sideNavWidth = 240;
  static const double physioContentMaxWidth = 1200;

  /// Pfad-Kugeln (`OrbNode`): Trainingstag, Wochenziel, Phasen-Abschluss,
  /// aktuell, Boss.
  static const double orbDay = 56;
  static const double orbWeekGoal = 62;
  static const double orbPhaseEnd = 80;
  static const double orbCurrent = 92;
  static const double orbBoss = 104;

  /// Zähler-Orb 150 dp, Bildkachel der Übungszeile 56 dp, Profil-Zeile ≥ 56.
  static const double counterOrb = 150;
  static const double exerciseTile = 56;
  static const double listRowMinHeight = 56;

  /// Schalter-Spur und -Knopf (Darstellung): Spur 52 × 32, Knopf 24.
  static const double switchTrackWidth = 52;
  static const double switchTrackHeight = 32;
  static const double switchKnob = 24;
  static const double switchTrackPadding = 4;

  /// Symbol-Kachel einer Listenzeile (Profil) und Abstand zum Text.
  static const double listRowTile = 48;

  // Leiste: Labels skalieren bis 130 % (Brief 3.3); Maße oben (`navBar*`).
  static const double navLabelMaxTextScale = 1.3;

  /// Aktiver Tab: Pille 56 dp hoch (Brief 4.1); Badge „Chats“ (Zähler).
  static const double navActivePill = navTabHeight;
  static const double navBadgeMin = 20;

  // Buttons und Felder.
  static const double primaryButtonHeight = 56;
  static const double chipHeight = 48; // Chip/Segment
  static const double chipVisibleHeight = 36; // Aktionschip, Hit-Area 48
  static const double textFieldHeight = 56;
  static const double micButton = 56;

  // Platzhalter-Kreise der Ladeansicht und Mindesthöhe des Ausblicks (die
  // Pfad-Kugeln selbst messen `orb*`).
  static const double unitSmall = 48;
  static const double unitMedium = 60;
  static const double unitLarge = 72;
  static const double unitBoss = 92;

  // Pfad-Kugeln: Ring um die aktuelle Kugel (Durchmesser siehe `orb*`).
  static const double unitRingGap = 9;
  static const double unitRingWidth = 1.5;

  // Pfad-Layout (Brief 5.5, 6.2; pfad-v4.png, Plan 4.6, 7.3). Ablage der
  // Brief-Werte, keine neuen Design-Tokens.
  /// Manny steht **neben** der aktuellen Kugel (Brief 7.1), die Füße auf Höhe
  /// ihrer Unterkante. Waagerechter Abstand zwischen Kugel und Zeichnung:
  /// Trefferrand (8) plus Mindestabstand der Ziele (8), damit die Tippfläche
  /// Mannys die der Kugel nicht berührt.
  static const double mannyBesideGap = 16;

  /// Kleinster lichter Abstand zweier Kugeln. Der Pfad vergrößert ihn, damit
  /// der Label-Chip unter einer Kugel Platz hat.
  static const double pathUnitGapMin = 84;

  /// Abstand zwischen Unit und ihrer Beschriftung (`caption`).
  static const double pathLabelGap = 4;

  /// Luft zwischen Manny (bzw. Beschriftung) und der Unit darüber.
  static const double pathUnitAir = 4;

  /// Die Linie läuft um Units und Beschriftungen herum: so weit reicht die
  /// Aussparung über den Rand hinaus.
  static const double pathLineClipUnit = 1;
  static const double pathLineClipLabel = 2;

  /// Abstand der Punkte der Zukunftslinie (Mitte zu Mitte, Linienstärke 3).
  static const double pathDotSpacing = 9;

  /// Ausblick `PathOutlook` (Ergänzung 3, 2.1): Höchstbreite, Strich und
  /// Lücke des gestrichelten Rands, Schloss-Kreis, Abstände. Mindesthöhe ist
  /// `unitLarge`.
  static const double outlookMaxWidth = 300;
  static const double outlookDash = 6;
  static const double outlookDashGap = 4;
  static const double outlookLock = 36;
  static const double outlookLockGap = 12;
  static const double outlookPaddingVertical = 14;
  static const double outlookPaddingHorizontal = 16;

  /// Symbolgröße in der Unit als Anteil des Durchmessers.
  static const double unitIconFactor = 0.5;

  /// Weicher Schein der aktuellen Unit und Ring-Puls reichen so weit über den
  /// Ring hinaus (dp).
  static const double unitGlowExtent = 28;
  static const double unitPulseExtent = 24;
  static const double unitPulseWidth = 3;

  /// Luft auf gemessene Textbreiten (Gleitkomma-Rundung): sonst bricht der Text
  /// im Widget in eine weitere Zeile um.
  static const double measureSlack = 1;

  /// Kopf-Karte des Pfads läuft bei vergrößerter Schrift mit, wenn der
  /// Bildschirm niedriger ist als dieser Wert.
  static const double pathHeaderAlongMaxHeight = 600;

  // Chips der Kopf-Karte und Label-Chips (Innenabstand, Symbol).
  static const double statPillGap = 4;
  static const double statPillPaddingH = 12;
  static const double statPillPaddingV = 6;
  static const double statPillIcon = 20;

  // NodeHint (Ergänzung 1, 3.5): wenn oben weniger als 64 dp frei sind,
  // erscheint er unter der Unit.
  static const double hintMinSpaceAbove = 64;
  static const double hintPaddingVertical = 12;
  static const double hintPaddingHorizontal = 16;
  static const double hintMinSideWidth = 120;

  /// Ab dieser Textskalierung steht die Blase über Manny statt rechts daneben
  /// (rechts bliebe kaum Breite für den Text).
  static const double bubbleAboveTextScale = 1.5;

  // Manny (Brief-Ergänzung 1, 6.2): Leinwand des Körpers 158 x 193 dp (1x),
  // Kopf 110 x 110 dp; unten 8 dp Rand, die Figur steht auf der Fußlinie.
  // Kein Bild wird größer als seine Leinwand dargestellt.
  static const double mannyBodyWidth = 158;
  static const double mannyBodyHeight = 193;
  static const double mannyHeadCanvas = 110;
  static const double mannyBottomMargin = 8;

  /// Darstellungsgrößen (Leinwandhöhe): Pfad 88 (Figur ca. 80), Onboarding
  /// Name-Schritt 120, Auswahlkarten höchstens 190.
  static const double mannyPathHeight = 88;
  static const double mannyOnboardingMinHeight = 56;
  static const double mannyOnboardingMaxHeight = 64;
  static const double mannyOnboardingStep1Height = 120;
  static const double mannyChoiceMaxHeight = 190;

  /// Kein Manny-Kopf kleiner als 40 dp (6.5); die Scheibe misst `Kopf / 0,86`.
  static const double mannyHeadMin = 40;
  static const double mannyDiscHeadFactor = 0.86;

  /// Halo in der Welt Nacht: Durchmesser 1,15 x Leinwandbreite.
  static const double mannyHaloScale = 1.15;

  /// Anteil des Halo-Radius, bis zu dem er voll deckt (danach weicher Auslauf).
  static const double mannyHaloSolid = 0.72;

  /// Look-Auswahlkarten (6a): Mindesthöhe 300, Radio-Kreis 28, Rand 3 dp;
  /// untereinander (Bild links 120 dp), wenn die Breite unter 360 dp liegt
  /// oder die Systemschrift über 130 %.
  static const double mannyChoiceMinHeight = 300;
  static const double mannyChoiceRadio = 28;
  static const double mannyChoiceBorder = 3;
  static const double mannyChoiceStackedImage = 120;
  static const double mannyChoiceStackBelowWidth = 360;
  static const double mannyChoiceStackAboveTextScale = 1.3;

  /// „Ausgewählt“ skaliert höchstens bis 130 % mit (gleich der Stapelgrenze):
  /// Das Wort bräche in der schmalen Textspalte (108 dp bei 320 dp Breite,
  /// gestapelt) darüber mitten im Wort; der Zustand steht zusätzlich als Haken,
  /// Rand und Screenreader-Text.
  static const double mannyChoiceStateMaxTextScale = 1.3;

  // Manny-Knopf (Brief 5): Kopf, 56 dp, rechts 18 dp, 16 dp über der Leiste.
  static const double mannyChatButton = 56;
  static const double mannyButtonSideMargin = 18;
  static const double mannyButtonNavGap = 16;
  static const double mannyHitMargin = 8;
  static const double sendCircle = 40; // Hit-Area 48
  static const double sendCircleHitArea = 48;

  // Eingabeleiste und Blasen.
  static const double noticeIcon = 20; // Info-Icon der Hinweiskarte
  static const double hintIcon = 18; // Info-Icon der Hinweiszeile
  static const double composerMinHeight = 56;
  static const double noticePaddingVertical = 10;
  static const double noticePaddingHorizontal = 14;
  static const double bubblePaddingVertical = 12;
  static const double bubblePaddingHorizontal = 16;

  // Avatare und Embleme.
  /// Avatar-Kugel in der Kopf-Karte des Profils (Brief 7.6).
  static const double avatarOrb = 56;
  static const double avatar = 48;
  static const double avatarHeader = 36; // Kopf: 32 bis 36
  static const double avatarHeaderMin = 32;

  /// Initialen im Avatar skalieren bis 130 % mit (im festen Kreis, sonst
  /// berühren sie den Ring). Eigene Konstante, nicht die der Nav-Beschriftung.
  static const double avatarInitialsMaxTextScale = 1.3;

  /// Im Kopf-Avatar (36 dp, Innenkreis 32 dp) bis 115 %: breite Paare wie
  /// „DW“ berühren sonst bei 130 % den Ring (A-U3, B4). Die Initialen sind
  /// dekorativ, der Name steht daneben in voller Skalierung.
  static const double avatarCompactInitialsMaxTextScale = 1.15;
  // Manny-Köpfe stehen auf der hellen Scheibe, der Kopf darin misst 86 %; die
  // kleinste Scheibe ist daher 48 dp (Kopf 41 dp, Mindestgröße 40 dp).
  static const double emblemMessage = 48;
  static const double emblemHeader = 56;

  /// Der große Titel im Kopf (`title`, „Nachrichten“) skaliert bis 150 % mit:
  /// bei 200 % auf 320 dp bräche er mitten im Wort (A-U3, B3). Umbrüche nur an
  /// Wortgrenzen, nichts wird abgeschnitten.
  static const double headerTitleMaxTextScale = 1.5;

  /// Titel der Ausblick-Marke (`heading` 20 sp, Gewicht 800): bis 125 %, sonst
  /// bräche „Gesundheitssport“ auf 320 dp mitten im Wort.
  static const double outlookTitleMaxTextScale = 1.25;

  // Zeilen und Längen.
  static const double lineLengthMax = 560; // Zeilenlänge und ContentFrame
  static const double contactRowMin = 72;

  // Schwellen.
  static const double bubbleWidthFactor = 0.80;
  static const double chatFooterMaxFraction = 0.40;
  static const double textScaleScrollAlong = 1.5;

  /// K6: unter dieser verfügbaren Höhe (Route ohne Systemleisten und ohne
  /// Tastatur) scrollen Hinweiskarte, Hinweiszeile und Disclaimer mit.
  static const double chatScrollAlongMaxHeight = 400;

  /// Onboarding (A-U3 B1): ab Textskalierung 1,5 oder bei einer Resthöhe
  /// (Route ohne Systemleisten und ohne Tastatur) unter 400 dp wandert der
  /// Kopf (Zurück, Fortschritt) als erstes Element in die Scrollfläche.
  static const double onboardingHeaderScrollMaxHeight = 400;

  /// Leiste des Onboardings (Ergänzung 1, 6a): „Zurück“ mindestens 112 dp
  /// breit, 12 dp Abstand zu „Weiter“.
  static const double onboardingBackWidth = 112;
  static const double onboardingButtonGap = 12;

  /// Routen-Schiebung (Vollbild-Routen, Onboarding-Seitenwechsel).
  static const double routeSlide = MotionTokens.routeSlide;

  // Karten, Dialog, Hinweise, Sheet (Brief 5, Ergänzung 1).
  static const double cardPadding = 16;
  static const double cardPaddingWithStripe = 22;
  static const double categoryStripe = 4;
  static const double categoryIconTile = 20;

  /// Kategorie-Karte (Brief 5.2): Streifen 4 dp vom Kartenrand, 14 dp Abstand
  /// oben und unten; Symbol in der Kachel; Abstand Kachel zu Label.
  static const double categoryStripeEdge = 4;
  static const double categoryStripeInset = 14;
  static const double categoryIconGlyph = 14;

  /// Gestrichelte Aktion „+ Eigene Übung“ (Brief 5.3): Strichlänge und Lücke.
  static const double dashLength = 6;
  static const double dashGap = 4;

  /// Heute (Brief 6.3, Ergänzung 2): Abstand der Zeitwahl-Segmente und Luft
  /// zwischen Listenende und Button-Gruppe.
  static const double segmentGap = 12;
  static const double todayEndAir = 8;

  /// Statische Platzhalterkarten der Ladeansicht Heute (Brief 6.3).
  static const double placeholderCardHeight = 96;

  /// Dialog: unter dieser Höhe (Bildschirm abzüglich Rand, Safe Area und
  /// Tastatur) scrollt der ganze Dialog samt Buttons statt nur sein Inhalt;
  /// sonst bliebe für Felder bei eingeblendeter Tastatur kein Platz.
  static const double dialogCompactMaxHeight = 420;

  /// Ab dieser Textskalierung (F-4) scrollt der ganze Dialog samt Buttons
  /// (`compact`), der Titel skaliert höchstens mit [headerTitleMaxTextScale],
  /// Dialog-Buttons zeigen kein Symbol mehr und der Seitenrand der
  /// `PillButton`s sinkt von `s6` auf `s4`.
  static const double textScaleDialogCompact = 1.5;
  static const double dialogMaxWidth = 400;
  static const double nodeHintMaxWidth = 240;
  static const double nodeHintArrow = 8;
  static const double sheetMaxHeightFraction = 0.90;

  /// Griff oben am Sheet (Brief 4).
  static const double sheetHandleWidth = 36;
  static const double sheetHandleHeight = 4;

  /// Abstand zwischen Bildschirmoberkante und Sheet-Oberkante (Mindestwert):
  /// Der Titel steht dann unterhalb des stärksten Lichtflecks (Text auf Glas
  /// höchstens 16 % Glow, Errata E-1). Auf hohen Bildschirmen ohne Tastatur ist
  /// die 90-%-Grenze ohnehin knapper.
  static const double sheetTopClearance = 64;

  /// Verfügbare Höhe (Bildschirm abzüglich Tastatur) unter der das Sheet den
  /// ganzen Platz nimmt und sein Kopf mit dem Inhalt scrollt (kleines Gerät mit
  /// Tastatur, Querformat; gleiche Schwelle wie Onboarding und Chat). Der
  /// Fuß mit der Hauptaktion bleibt fest.
  static const double sheetCompactAvailHeight = 440;
  // Wischgeste des Sheets (A-36): Schließen ab 30 % der Höhe oder bei einem
  // Fling über 700 dp/s nach unten.
  static const double sheetCloseFraction = 0.30;
  static const double sheetFlingVelocity = 700;
  static const double choiceCardMinHeight = 64;

  // Linien und Ränder (dp).
  static const double hairline = 1;

  /// Bezugsgröße (1 sp), an der ein `TextScaler` den Skalierungsfaktor liefert:
  /// `scaler.scale(CuraSize.textScaleUnit)`. Bewusst nicht `hairline`: Das ist
  /// eine Linienstärke und könnte sich unabhängig davon ändern.
  static const double textScaleUnit = 1;
  static const double controlBorder = 1.5;
  static const double selectedBorder = 2;

  /// Fokusring (Brief 3.2): 3 dp Tinte mit 2 dp Außenrand in der Gegenfarbe.
  static const double focusRingWidth = 3;
  static const double focusRingOuterWidth = 2;
  static const double focusRingGap = 2;
  static const double pathLine = 3;
  static const double stepBarHeight = 4;

  /// Fortschrittsbalken der Kopf-Karte (Wochenbalken).
  static const double headerProgressHeight = 8;
}

/// Schatten (Brief 3.5 und Ergänzung 2). Farben aus `tokens.dart`.
abstract final class CuraShadow {
  static const Color _black = Color(0xFF000000);

  /// Primärbutton (Brief 4): Schein unten 0/14/24, Mandarine 70 %.
  static final List<BoxShadow> primaryGlow = <BoxShadow>[
    BoxShadow(
      color: Palette.accent.withValues(alpha: Palette.primaryGlowAlpha),
      offset: const Offset(0, 14),
      blurRadius: 24,
    ),
  ];

  /// Gedrückt: Schein halb so stark.
  static final List<BoxShadow> primaryGlowPressed = <BoxShadow>[
    BoxShadow(
      color: Palette.accent.withValues(alpha: Palette.primaryGlowAlpha / 2),
      offset: const Offset(0, 14),
      blurRadius: 24,
    ),
  ];

  /// Karte E1 (Brief 3.5): 0/18/30 mit negativem Spread, warm getönt.
  static List<BoxShadow> card({required bool dark}) => <BoxShadow>[
    BoxShadow(
      color: Palette.cardShadowTint.withValues(
        alpha: dark
            ? Palette.cardShadowDarkAlpha
            : Palette.cardShadowLightAlpha,
      ),
      offset: const Offset(0, 18),
      blurRadius: 30,
      spreadRadius: -12,
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

/// Geometrie der Glas-Kugeln (`OrbNode`, Brief 4/3.5) als Anteile des
/// Durchmessers: Glanzpunkt oben links, Innenschatten unten, Bodenschatten.
abstract final class OrbGeometry {
  /// Lichtpunkt des Radialverlaufs (Alignment-Koordinaten −1 … 1).
  static const double highX = -0.38;
  static const double highY = -0.42;
  static const double gradientRadius = 1.0;
  static const List<double> gradientStops = <double>[0, 0.58, 1];

  /// Glanzfleck: Lage und Größe als Anteil des Durchmessers, Neigung in Grad.
  static const double glossLeft = 0.17;
  static const double glossTop = 0.09;
  static const double glossWidth = 0.40;
  static const double glossHeight = 0.22;
  static const double glossTiltDegrees = -28;

  /// Innenschatten: beginnt auf dieser Höhe (Anteil) und dunkelt nach unten.
  static const double innerShadowFrom = 0.55;

  /// Bodenschatten: Ellipse unter der Kugel (Breite, Höhe, Abstand zur Kante
  /// als Anteil des Durchmessers) und ihre Weichzeichnung (dp).
  static const double groundWidth = 0.78;
  static const double groundHeight = 0.14;
  static const double groundOffset = 0.04;
  static const double groundBlur = 6;
}
