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

  // Pfad-Layout (Brief 5.5, 6.2; pfad-v4.png, Plan 4.6, 7.3). Ablage der
  // Brief-Werte, keine neuen Design-Tokens.
  /// Manny sitzt mit den Füßen so weit auf der Unit (Überlappung der
  /// Fußunterkante mit dem oberen Rand des Kreises).
  static const double mannyPerchOverlap = 6;

  /// Kleinster lichter Abstand zweier Units (pfad-v4.png). Der Pfad vergrößert
  /// ihn, damit Manny und die Beschriftung darüber Platz haben.
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

  // Kopfzeile Pfad (Ergänzung 1, 3.1). Umbruch-Layout, wenn der Textblock
  // links weniger als 150 dp bekäme.
  static const double pathHeaderWrapMinText = 150;
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

  // Manny.
  static const double mannyPathHeight = 80;
  static const double mannyOnboardingMinHeight = 56;
  static const double mannyOnboardingMaxHeight = 64;
  // Onboarding Schritt 1: Manny groß (Brief 6.1, „ca. 120 dp“).
  static const double mannyOnboardingStep1Height = 120;

  // Button-Gruppe (Ergänzung 2, 2 und 3.1).
  static const double mannyChatButton = 56;
  static const double messagesButton = 48;
  static const double mannyHeadInButton = 38;
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
  static const double emblemMessage = 26;
  static const double emblemHeader = 34;

  /// Der große Titel im Kopf (`title`, „Nachrichten“) skaliert bis 150 % mit:
  /// bei 200 % auf 320 dp bräche er mitten im Wort (A-U3, B3). Umbrüche nur an
  /// Wortgrenzen, nichts wird abgeschnitten.
  static const double headerTitleMaxTextScale = 1.5;

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
  static const double dialogMaxWidth = 400;
  static const double nodeHintMaxWidth = 240;
  static const double nodeHintArrow = 8;
  static const double sheetMaxHeightFraction = 0.90;
  // Wischgeste des Sheets (A-36): Schließen ab 30 % der Höhe oder bei einem
  // Fling über 700 dp/s nach unten.
  static const double sheetCloseFraction = 0.30;
  static const double sheetFlingVelocity = 700;
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
