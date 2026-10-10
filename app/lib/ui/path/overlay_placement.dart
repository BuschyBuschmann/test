// Platzierung von Manny-Blase und `NodeHint` auf dem Pfad (Plan 4.6, UI-75):
// reine Geometrie ohne Widgets, damit sie sich in Tests Stufe für Stufe
// prüfen lässt. Alle Rechtecke liegen in den Koordinaten der Pfad-Sichtfläche
// (Ursprung oben links unter der Kopfzeile).
//
// Beide Overlays überdecken die Button-Gruppe nie: ihre Unterkante liegt
// mindestens 8 dp über der Oberkante der Gruppe (bzw. der Nachrichten-
// Buttons), und das gilt über die ganze Breite (die Zone unten rechts und
// unten links bleibt frei, UI-24).
//
// Rückfallkette der Blase (Plan 4.6, MINOR-5): rechts neben Manny (nicht ab
// Textskalierung 1,5 und nicht bei weniger als 140 dp Platz) → über Manny →
// Pfad scrollt nach unten, damit über Manny Platz ist → Blase wird auf die
// freie Fläche begrenzt, der Text scrollt innen.
//
// Rückfallkette des Hinweises: über der Unit (wenn dort mindestens 64 dp frei
// sind) → unter der Unit → seitlich der Unit → Pfad scrollt die Unit in die
// obere Hälfte und setzt den Hinweis darunter → auf die freie Fläche begrenzt
// mit innerem Scrollen.
import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../components/manny_bubble.dart' show BubbleArrow, MannyBubble;
import '../components/node_hint.dart' show HintArrow;

/// Obere Grenze der Overlays in der Sichtfläche (Standard). Läuft die
/// Kopfzeile in der Scrollfläche mit, bleibt oben der Platz für ihr
/// Bedienelement „Deine Daten“ frei (`CuraSize.touchTarget`), damit es beim
/// Hochscrollen nie unter einem Overlay liegt.
const double kOverlayTopLimit = CuraSpace.s2;

/// Pfeilspitze der Blase sitzt in dieser Höhe der Manny-Form (Anteil von oben).
const double _bubbleTipAtManny = 0.4;

/// Unterkante des Overlays: `cluster.top` abzüglich 8 dp; ohne Gruppe der
/// Rand der Sichtfläche.
double bottomLimitFor(Size viewport, Rect? cluster) =>
    cluster == null ? viewport.height : cluster.top - CuraSize.minTargetGap;

// ---------------------------------------------------------------------------
// Blase
// ---------------------------------------------------------------------------

/// Maße der ganzen Blase (samt Pfeil) für einen Pfeil und eine Höchstbreite.
typedef BubbleMeasure = Size Function(BubbleArrow arrow, double maxWidth);

class BubblePlacement {
  const BubblePlacement({
    required this.arrow,
    required this.rect,
    required this.arrowOffset,
    this.maxBodyHeight,
    this.scrollOffsetDelta = 0,
  });

  final BubbleArrow arrow;

  /// Ganze Blase samt Pfeil.
  final Rect rect;

  /// Wie `MannyBubble.arrowOffset`: Abstand des Pfeilanfangs vom Anfang der
  /// Kante (oben bei `left`, links bei `down`).
  final double arrowOffset;

  /// Höhe des Körpers, wenn die Blase begrenzt ist (Text scrollt innen).
  final double? maxBodyHeight;

  /// Der Pfad soll vorher um so viel scrollen (positiv: Offset wächst, der
  /// Inhalt wandert nach oben).
  final double scrollOffsetDelta;

  bool get limited => maxBodyHeight != null;
}

/// Wählt Seite und Lage der Blase.
///
/// [manny] ist die gezeichnete Form; [mannyBelowExtra] der Teil der Unit
/// unterhalb der Standlinie (er darf beim Scrollen nicht in die Gruppe
/// geraten). [scrollOffset] ist der aktuelle Offset (der Pfad kann nur bis 0
/// zurück). Mit [allowScroll] darf die Platzierung den Pfad scrollen lassen
/// (nur beim Erscheinen der Blase; danach folgt sie Manny nur noch).
BubblePlacement placeBubble({
  required Rect manny,
  required Size viewport,
  required Rect? cluster,
  required double textScale,
  required BubbleMeasure measure,
  double mannyBelowExtra = 0,
  double scrollOffset = 0,
  bool allowScroll = false,
  double topLimit = kOverlayTopLimit,
}) {
  final double bottomLimit = bottomLimitFor(viewport, cluster);
  const double margin = CuraSpace.pageMargin;

  // 1. Rechts neben Manny.
  final double spaceRight = viewport.width - margin - manny.right;
  if (textScale < CuraSize.bubbleAboveTextScale &&
      MannyBubble.arrowFor(spaceRight) == BubbleArrow.left) {
    final double maxW = math.min(
      CuraComponent.bubbleMaxWidth,
      spaceRight - CuraSpace.s1,
    );
    final Size s = measure(BubbleArrow.left, maxW);
    const double arrowOffset = CuraSpace.s6;
    final double tipY = manny.top + manny.height * _bubbleTipAtManny;
    final Rect r = Rect.fromLTWH(
      manny.right + CuraSpace.s1,
      tipY - arrowOffset - CuraComponent.bubbleArrowBase / 2,
      s.width,
      s.height,
    );
    if (r.top >= topLimit &&
        r.bottom <= bottomLimit + 0.01 &&
        r.right <= viewport.width - margin + 0.01) {
      return BubblePlacement(
        arrow: BubbleArrow.left,
        rect: r,
        arrowOffset: arrowOffset,
      );
    }
  }

  // 2. Über Manny.
  final double maxW = math.min(
    CuraComponent.bubbleMaxWidth,
    viewport.width - 2 * margin,
  );
  final Size s = measure(BubbleArrow.down, maxW);
  final double left = (manny.center.dx - s.width / 2).clamp(
    margin,
    math.max(margin, viewport.width - margin - s.width),
  );
  const double arrowEdge =
      CuraRadius.bubble; // Pfeil bleibt auf der geraden Kante
  final double arrowOffset =
      (manny.center.dx - left - CuraComponent.bubbleArrowBase / 2).clamp(
        arrowEdge,
        math.max(
          arrowEdge,
          s.width - arrowEdge - CuraComponent.bubbleArrowBase,
        ),
      );
  Rect above(double dy) =>
      Rect.fromLTWH(left, manny.top + dy - s.height, s.width, s.height);

  Rect r = above(0);
  if (r.top >= topLimit) {
    return BubblePlacement(
      arrow: BubbleArrow.down,
      rect: r,
      arrowOffset: arrowOffset,
    );
  }

  // 3. Der Pfad scrollt nach unten (Inhalt wandert nach unten, Offset sinkt).
  double down = 0;
  if (allowScroll) {
    final double needed = topLimit - r.top;
    final double room = bottomLimit - (manny.bottom + mannyBelowExtra);
    down = math.max(0, math.min(needed, math.min(scrollOffset, room)));
    r = above(down);
    if (r.top >= topLimit - 0.01) {
      return BubblePlacement(
        arrow: BubbleArrow.down,
        rect: r,
        arrowOffset: arrowOffset,
        scrollOffsetDelta: -down,
      );
    }
  }

  // 4. Begrenzt auf die freie Fläche über Manny, Text scrollt innen.
  final double free = math.max(
    CuraSize.touchTarget + CuraComponent.bubbleArrow,
    manny.top + down - topLimit,
  );
  final double height = math.min(s.height, free);
  return BubblePlacement(
    arrow: BubbleArrow.down,
    rect: Rect.fromLTWH(left, manny.top + down - height, s.width, height),
    arrowOffset: arrowOffset,
    maxBodyHeight: height - CuraComponent.bubbleArrow,
    scrollOffsetDelta: -down,
  );
}

// ---------------------------------------------------------------------------
// NodeHint
// ---------------------------------------------------------------------------

/// Maße des Körpers (ohne Pfeil) bei einer Höchstbreite.
typedef HintMeasure = Size Function(double maxWidth);

class HintPlacement {
  const HintPlacement({
    required this.arrow,
    required this.rect,
    required this.arrowCenter,
    this.maxBodyHeight,
    this.scrollOffsetDelta = 0,
  });

  final HintArrow arrow;

  /// Ganzer Hinweis samt Pfeil.
  final Rect rect;

  /// Mitte des Pfeils entlang seiner Kante (vom Anfang der Kante).
  final double arrowCenter;
  final double? maxBodyHeight;

  /// Der Pfad soll vorher um so viel scrollen (positiv: Offset wächst).
  final double scrollOffsetDelta;

  bool get limited => maxBodyHeight != null;
}

HintPlacement _shifted(HintPlacement p, double scroll) => HintPlacement(
  arrow: p.arrow,
  rect: p.rect,
  arrowCenter: p.arrowCenter,
  maxBodyHeight: p.maxBodyHeight,
  scrollOffsetDelta: scroll,
);

/// Wählt Lage und Pfeil des Hinweises an [unit] (Rechteck des Kreises).
///
/// [scrollOffset] und [maxScrollOffset] begrenzen das Scrollen der Stufe 4
/// (nur mit [allowScroll], beim Erscheinen des Hinweises).
HintPlacement placeHint({
  required Rect unit,
  required Size viewport,
  required Rect? cluster,
  required HintMeasure measure,
  double scrollOffset = 0,
  double maxScrollOffset = 0,
  bool allowScroll = false,
  double topLimit = kOverlayTopLimit,
}) {
  final double bottomLimit = bottomLimitFor(viewport, cluster);
  const double margin = CuraSpace.pageMargin;
  const double arrow = CuraSize.nodeHintArrow;
  final double fullW = math.min(
    CuraSize.nodeHintMaxWidth,
    viewport.width - 2 * margin,
  );

  double clampLeft(double left, double width) =>
      left.clamp(margin, math.max(margin, viewport.width - margin - width));

  HintPlacement? stages(Rect u) {
    // 1. Über der Unit, wenn dort mindestens 64 dp frei sind.
    final Size b = measure(fullW);
    final double w = b.width;
    final double h = b.height + arrow;
    final double left = clampLeft(u.center.dx - w / 2, w);
    if (u.top >= CuraSize.hintMinSpaceAbove &&
        u.top - h >= topLimit - 0.01 &&
        u.top <= bottomLimit + 0.01) {
      return HintPlacement(
        arrow: HintArrow.down,
        rect: Rect.fromLTWH(left, u.top - h, w, h),
        arrowCenter: u.center.dx - left,
      );
    }
    // 2. Unter der Unit.
    if (u.bottom + h <= bottomLimit + 0.01 && u.bottom >= 0) {
      return HintPlacement(
        arrow: HintArrow.up,
        rect: Rect.fromLTWH(left, u.bottom, w, h),
        arrowCenter: u.center.dx - left,
      );
    }
    // 3. Seitlich: links der Unit (Units der rechten Bahn), sonst rechts.
    for (final bool leftSide in <bool>[true, false]) {
      final double room = leftSide
          ? u.left - margin - arrow
          : viewport.width - margin - u.right - arrow;
      if (room < CuraSize.hintMinSideWidth) continue;
      final Size sb = measure(math.min(fullW, room));
      final double sw = sb.width + arrow;
      final double top = u.center.dy - sb.height / 2;
      if (top < topLimit - 0.01 || top + sb.height > bottomLimit + 0.01) {
        continue;
      }
      return HintPlacement(
        arrow: leftSide ? HintArrow.right : HintArrow.left,
        rect: Rect.fromLTWH(
          leftSide ? u.left - sw : u.right,
          top,
          sw,
          sb.height,
        ),
        arrowCenter: u.center.dy - top,
      );
    }
    return null;
  }

  final HintPlacement? first = stages(unit);
  if (first != null) return first;

  // 4. Der Pfad scrollt die Unit in die obere Hälfte; der Hinweis steht
  //    darunter.
  Rect u = unit;
  double scroll = 0;
  final Size body = measure(fullW);
  final double block = unit.height + arrow + body.height;
  final double free = bottomLimit - topLimit;
  if (allowScroll && block <= free) {
    final double wantedTop = topLimit + (free - block) / 2;
    final double want = unit.top - wantedTop;
    final double next = (scrollOffset + want).clamp(0, maxScrollOffset);
    scroll = next - scrollOffset;
    u = unit.shift(Offset(0, -scroll));
    final HintPlacement? second = stages(u);
    if (second != null) return _shifted(second, scroll);
  }

  // 5. Auf die freie Fläche begrenzt, Text scrollt innen. Passen Unit und
  //    Hinweis nicht zusammen in die freie Fläche (hohe Marke bei großer
  //    Schrift), schiebt der Pfad die Unit so, dass der Hinweis darüber
  //    mindestens 48 dp Text zeigt: ihre Unterkante an die Unterkante der
  //    freien Fläche, ist sie dafür zu hoch, ihre Oberkante nach unten.
  if (allowScroll && scroll == 0) {
    const double minAbove = arrow + CuraSize.touchTarget;
    final double wantedTop = unit.height + minAbove <= free
        ? bottomLimit - unit.height
        : topLimit + minAbove;
    final double next = (scrollOffset + unit.top - wantedTop).clamp(
      0,
      maxScrollOffset,
    );
    scroll = next - scrollOffset;
    u = unit.shift(Offset(0, -scroll));
  }
  final double roomBelow = bottomLimit - u.bottom - arrow;
  final double roomAbove = u.top - topLimit - arrow;
  final bool below = roomBelow >= roomAbove;
  final double bodyMax = math.max(
    CuraSize.touchTarget,
    below ? roomBelow : roomAbove,
  );
  final Size b = measure(fullW);
  final double bodyH = math.min(b.height, bodyMax);
  final double left = clampLeft(u.center.dx - b.width / 2, b.width);
  final double h = bodyH + arrow;
  return HintPlacement(
    arrow: below ? HintArrow.up : HintArrow.down,
    rect: below
        ? Rect.fromLTWH(left, u.bottom, b.width, h)
        : Rect.fromLTWH(left, u.top - h, b.width, h),
    arrowCenter: u.center.dx - left,
    maxBodyHeight: bodyH < b.height ? bodyH : null,
    scrollOffsetDelta: scroll,
  );
}
