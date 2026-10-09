// Text-Sonde der Prüfumgebung (Plan 12.5 `dumpText`, 8.2 Glow-Regel): geht
// durch den Element-Baum und liefert zu jedem `RenderParagraph` das
// Text-Rechteck (globale Koordinaten), die Textfarbe, Schriftgröße und
// -gewicht, den Untergrund (`bg`, `glass`, `opaque`) und den Glow-Alpha am
// dem Glow-Mittelpunkt nächstgelegenen Punkt des Rechtecks. Dieselbe Sonde
// läuft in der Matrix und im Release-Build der Preview (Browser), darum
// arbeitet sie über Elemente und nicht über `debugCreator`.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../logic/path_model.dart' show UnitStatus;
import '../theme/glow.dart';
import '../ui/components/action_circle.dart';
import '../ui/components/floating_nav.dart';
import '../ui/components/glass_card.dart';
import '../ui/components/glow_background.dart';
import '../ui/components/manny_bubble.dart';
import '../ui/components/node_hint.dart';
import '../ui/components/opaque_surface.dart';
import '../ui/components/path_node.dart';
import '../ui/components/pill_button.dart';
import '../ui/components/cura_dialog.dart';
import '../ui/components/cura_snackbar.dart';
import '../ui/routes/cura_sheet_route.dart';

/// Untergrund eines Textes (Errata E-1, Plan 8.2).
enum TextGround {
  /// Fläche `bg`, Glow scheint durch.
  bg,

  /// Glas-Fläche (`GlassCard`, E2: Nav, Blase, Sheet; A-35): Glow liegt
  /// darunter.
  glass,

  /// Deckende Fläche (Snackbar, Dialog, Hinweis, Primär-/Neutral-Button):
  /// glowfrei.
  opaque,
}

class ProbedText {
  const ProbedText({
    required this.text,
    required this.rect,
    required this.color,
    required this.sizeSp,
    required this.weight,
    required this.ground,
    required this.glowAlpha,
    required this.onScreen,
    required this.isIcon,
  });

  final String text;

  /// Rechteck der Textzeilen in globalen Koordinaten (dp).
  final Rect rect;

  /// Textfarbe inklusive Alpha (z. B. Disabled 38 %).
  final Color color;

  /// Kleinste Schriftgröße (sp, vor Skalierung) und kleinstes Gewicht
  /// (100 … 900) aller Teilspannen.
  final double sizeSp;
  final int weight;
  final TextGround ground;

  /// Glow-Alpha (0 … 1) am nächstgelegenen Punkt; 0 ohne Glow.
  final double glowAlpha;

  /// Das Rechteck schneidet die sichtbare Fläche.
  final bool onScreen;

  /// Symbol (Icon-Font, Zeichen im privaten Bereich), kein Text: gilt für
  /// Kontrast als Symbol (3:1), nicht für Schrift- und Glow-Regeln.
  final bool isIcon;

  Map<String, Object?> toJson() => <String, Object?>{
    'text': text,
    'x': rect.left,
    'y': rect.top,
    'w': rect.width,
    'h': rect.height,
    'color': _hex(color),
    'colorAlpha': color.a,
    'fontSize': sizeSp,
    'weight': weight,
    'ground': ground.name,
    'glowAlpha': glowAlpha,
    'onScreen': onScreen,
    'isIcon': isIcon,
  };
}

String _hex(Color c) {
  String two(double v) =>
      (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${two(c.r)}${two(c.g)}${two(c.b)}'.toUpperCase();
}

/// Ergebnis einer Sonde.
class TextProbe {
  const TextProbe({
    required this.texts,
    required this.hasGlow,
    required this.view,
  });

  final List<ProbedText> texts;

  /// Ein `GlowPainter` ist im Baum.
  final bool hasGlow;
  final Size view;
}

/// Sonde über den ganzen Baum ab [root] (Standard: Wurzel-Element).
TextProbe probeTexts({Element? root, required Size view}) {
  final Element? start = root ?? WidgetsBinding.instance.rootElement;
  if (start == null) {
    return TextProbe(texts: const <ProbedText>[], hasGlow: false, view: view);
  }
  GlowGeometry? glow;
  Offset glowOrigin = Offset.zero;

  // 1. Glow suchen.
  void findGlow(Element e) {
    if (glow != null) return;
    final Widget w = e.widget;
    if (w is CustomPaint && w.painter is GlowPainter) {
      final RenderObject? r = e.renderObject;
      if (r is RenderBox && r.attached && r.hasSize) {
        glowOrigin = r.localToGlobal(Offset.zero);
        glow = GlowGeometry(r.size.width, r.size.height);
        return;
      }
    }
    e.visitChildren(findGlow);
  }

  findGlow(start);

  // 2. Texte einsammeln.
  final List<ProbedText> out = <ProbedText>[];
  final Rect screen = Offset.zero & view;

  void walk(Element e, TextGround ground, bool covered) {
    final Widget w = e.widget;
    if (w is Offstage && w.offstage) return;
    TextGround g = ground;
    if (w is GlassCard || w is FloatingNav || w is MannyBubble) {
      g = TextGround.glass;
    } else if (w is CuraSnackbar ||
        w is CuraDialog ||
        w is ActionCircle ||
        w is NodeHint ||
        w is OpaqueSurface) {
      g = TextGround.opaque;
    } else if (w is PillButton) {
      g = (w.variant == PillButtonVariant.outline || w.onPressed == null)
          ? TextGround.bg
          : TextGround.opaque;
    } else if (w is PathNode) {
      // Erledigte und aktuelle Units haben eine deckende Füllung (`text-1`,
      // `accent`); gesperrte sind Glas (Brief 5.5).
      g = w.status == UnitStatus.locked ? TextGround.glass : TextGround.opaque;
    } else if (w is CuraSheetFrame) {
      // Sheet: E2 (`surface-float` mit Blur), streng wie Glas (A-35).
      g = TextGround.glass;
    }
    // Weitere Flächentypen ordnen die Pakete, die sie einführen, mit einer
    // `is`-Prüfung ein (nie über `runtimeType`: Release-Builds minifizieren
    // die Typnamen): `NodeHint` ist deckend; `ExampleNotice` und die Blase
    // des Gegenübers sind `GlassCard`s (Glas, schon erkannt), Eingabeleiste und
    // eigene Blasen `OpaqueSurface`s (deckend, oben).
    // Texte unter einer anderen Route (Dialog, Sheet mit Scrim) oder in einer
    // verdeckten Route zählen nicht als sichtbar (R-U2 Punkt 12).
    bool c = covered;
    if (w is RichText) {
      if (!c && _isBuriedRoute(e)) c = true;
      final RenderObject? r = e.renderObject;
      if (r is RenderParagraph && r.attached && r.hasSize) {
        final ProbedText? p = _probe(r, g, glow, glowOrigin, screen, c);
        if (p != null) out.add(p);
      }
    }
    e.visitChildren((Element child) => walk(child, g, c));
  }

  walk(start, TextGround.bg, false);
  return TextProbe(texts: out, hasGlow: glow != null, view: view);
}

ProbedText? _probe(
  RenderParagraph r,
  TextGround ground,
  GlowGeometry? glow,
  Offset glowOrigin,
  Rect screen,
  bool covered,
) {
  final String plain = r.text.toPlainText(includePlaceholders: false);
  if (plain.trim().isEmpty) return null;
  final List<TextBox> boxes = r.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: plain.length),
  );
  Rect local = Offset.zero & r.size;
  if (boxes.isNotEmpty) {
    local = boxes.first.toRect();
    for (final TextBox b in boxes.skip(1)) {
      local = local.expandToInclude(b.toRect());
    }
  }
  final Offset origin = r.localToGlobal(Offset.zero);
  Rect rect = local.shift(origin);
  // Ein scrollender Bereich schneidet seinen Inhalt ab: Text außerhalb des
  // Sichtfensters ist unsichtbar, teilweise sichtbarer Text zählt mit seinem
  // sichtbaren Teil (Glow- und Pixel-Messung sonst über fremden Pixeln, etwa
  // unter der Mikrofon-Zeile).
  bool clipped = false;
  for (RenderObject? node = r.parent; node != null; node = node.parent) {
    if (node is! RenderAbstractViewport) continue;
    final RenderObject viewport = node;
    if (viewport is! RenderBox || !viewport.attached || !viewport.hasSize) {
      continue;
    }
    final Rect visible = rect.intersect(
      viewport.localToGlobal(Offset.zero) & viewport.size,
    );
    if (visible.width <= 0 || visible.height <= 0) {
      clipped = true;
      break;
    }
    rect = visible;
  }

  Color? color;
  double fontSize = double.infinity;
  int weight = 1000;
  void visit(InlineSpan span, TextStyle? inherited) {
    final TextStyle? style = span.style == null
        ? inherited
        : (inherited?.merge(span.style) ?? span.style);
    if (span is TextSpan && (span.text?.trim().isNotEmpty ?? false)) {
      color ??= style?.color;
      final double fs = style?.fontSize ?? 14;
      if (fs < fontSize) fontSize = fs;
      final int wt = style?.fontWeight?.value ?? 400;
      if (wt < weight) weight = wt;
    }
    if (span is TextSpan) {
      for (final InlineSpan child in span.children ?? const <InlineSpan>[]) {
        visit(child, style);
      }
    }
  }

  visit(r.text, null);
  if (fontSize == double.infinity) return null;

  double alpha = 0;
  if (glow != null && ground != TextGround.opaque) {
    final Rect rel = rect.shift(-glowOrigin);
    alpha = glow.alphaForRect(rel.left, rel.top, rel.right, rel.bottom);
  }
  return ProbedText(
    text: plain,
    rect: rect,
    color: color ?? Colors.transparent,
    sizeSp: fontSize,
    weight: weight,
    ground: ground,
    glowAlpha: alpha,
    onScreen: !covered && !clipped && rect.overlaps(screen),
    isIcon: _isIcon(plain),
  );
}

/// Rechtecke aller Widgets mit einem Marker-Schlüssel `ValueKey<String>` mit
/// dem Präfix [prefix] (z. B. `probe:`) in globalen Koordinaten.
Map<String, Rect> probeKeyedRects({Element? root, required String prefix}) {
  final Map<String, Rect> out = <String, Rect>{};
  final Element? start = root ?? WidgetsBinding.instance.rootElement;
  if (start == null) return out;
  void walk(Element e) {
    final Key? key = e.widget.key;
    if (key is ValueKey<String> && key.value.startsWith(prefix)) {
      final RenderObject? r = e.renderObject;
      if (r is RenderBox && r.attached && r.hasSize) {
        out[key.value] = r.localToGlobal(Offset.zero) & r.size;
      }
    }
    // Nur sichtbare Teilbäume: Routen unter einer opaken Route (Home unter
    // dem Chat) und inaktive Tabs (`Offstage`) behalten ihre alten Rechtecke,
    // zählen aber nicht (sonst stünde die Nav des verdeckten Home im Chat).
    e.debugVisitOnstageChildren(walk);
  }

  walk(start);
  return out;
}

/// Icon-Fonts legen ihre Glyphen in den privaten Unicode-Bereich.
bool _isIcon(String text) {
  final String t = text.trim();
  return t.isNotEmpty &&
      t.runes.every((int r) => r >= 0xE000 && r <= 0xF8FF || r >= 0xF0000);
}

/// Der Text liegt in einer Route, über der eine weitere Route liegt
/// (`ModalRoute.isCurrent == false`, z. B. unter Dialog oder Sheet mit
/// Scrim). Ohne Route (kein Navigator) gilt er als sichtbar.
// `ModalRoute.of` legt je Text eine Abhängigkeit an (nur ein Neubau des Textes
// bei Routenwechsel). Das ist hier bewusst hingenommen: Die Sonde läuft nur
// in Tests und der Preview, und der Scope-Typ ist privat (`_ModalScopeStatus`),
// ein Weg ohne Abhängigkeit existiert nicht öffentlich.
bool _isBuriedRoute(Element e) {
  try {
    final ModalRoute<dynamic>? route = ModalRoute.of(e);
    return route != null && !route.isCurrent;
  } catch (_) {
    return false;
  }
}
