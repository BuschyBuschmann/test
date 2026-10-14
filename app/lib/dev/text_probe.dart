// Text-Sonde der Prüfumgebung (Plan 12.5 `dumpText`): geht
// durch den Element-Baum und liefert zu jedem `RenderParagraph` das
// Text-Rechteck (globale Koordinaten), die Textfarbe, Schriftgröße und
// -gewicht und den Untergrund (`bg` = direkt auf der Welt, `glass` = Karte,
// Leiste, Blase, `opaque`). Dieselbe Sonde
// läuft in der Matrix und im Release-Build der Preview (Browser), darum
// arbeitet sie über Elemente und nicht über `debugCreator`.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../logic/path_model.dart' show UnitStatus;
import '../theme/world_painter.dart';
import '../ui/components/action_circle.dart';
import '../ui/components/floating_nav.dart';
import '../ui/components/glass_card.dart';
import '../ui/components/header_card.dart';
import '../ui/components/manny_bubble.dart';
import '../ui/components/node_hint.dart';
import '../ui/components/opaque_surface.dart';
import '../ui/components/orb_node.dart';
import '../ui/components/path_node.dart';
import '../ui/components/pill_button.dart';
import '../ui/components/status_chip.dart';
import '../ui/components/world_label_chip.dart';
import '../ui/components/category_card.dart';
import '../ui/components/cura_dialog.dart';
import '../ui/components/cura_snackbar.dart';
import '../ui/routes/cura_sheet_route.dart';

/// Untergrund eines Textes (Plan 8.2; seit Brief v2 „Text nie direkt auf der
/// Welt“).
enum TextGround {
  /// Text direkt auf der Welt (`bg`).
  bg,

  /// Karte (`GlassCard`, `card` 92 %, Blase); der Kontrast gilt im Worst Case
  /// über Schwarz, Weiß, Mandarine und Grau unter der Karte (Brief 3.2).
  glass,

  /// Fläche mit eigener, gemessener Farbpaarung: Kopf-Karte, Leiste, Label-
  /// Chip (Tabelle 3.1, `contrast_world_test`), Snackbar, Dialog, Sheet,
  /// Hinweis, Primär-/Neutral-Button, Status-Chip, Kugel.
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
    required this.onScreen,
    required this.isIcon,
    this.inOverlay = false,
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

  /// Das Rechteck schneidet die sichtbare Fläche.
  final bool onScreen;

  /// Symbol (Icon-Font, Zeichen im privaten Bereich), kein Text: gilt für
  /// Kontrast als Symbol (3:1), nicht für Schriftregeln.
  final bool isIcon;

  /// Der Text gehört zu einem markierten Overlay (`overlay:*`: Nav,
  /// Button-Gruppe, Reihe, Blase). Alle anderen Texte können unter einem
  /// Overlay verschwinden (scrollender Inhalt); die Pixelmessung im Browser
  /// lässt sie dann aus.
  final bool inOverlay;

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
    'onScreen': onScreen,
    'isIcon': isIcon,
    'inOverlay': inOverlay,
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
    required this.hasWorld,
    required this.worldDecor,
    required this.view,
  });

  final List<ProbedText> texts;

  /// Ein `WorldPainter` ist im Baum.
  final bool hasWorld;

  /// Die Welt zeigt Körnung, Dunst, Sterne und Sonne/Mond (aus bei Hoher
  /// Kontrast/Transparenz reduzieren).
  final bool worldDecor;
  final Size view;
}

/// Sonde über den ganzen Baum ab [root] (Standard: Wurzel-Element).
TextProbe probeTexts({Element? root, required Size view}) {
  final Element? start = root ?? WidgetsBinding.instance.rootElement;
  if (start == null) {
    return TextProbe(
      texts: const <ProbedText>[],
      hasWorld: false,
      worldDecor: false,
      view: view,
    );
  }
  WorldPainter? world;

  // 1. Welt suchen.
  void findWorld(Element e) {
    if (world != null) return;
    final Widget w = e.widget;
    if (w is CustomPaint) {
      final CustomPainter? painter = w.painter;
      if (painter is WorldPainter) {
        world = painter;
        return;
      }
    }
    e.visitChildren(findWorld);
  }

  findWorld(start);

  // 2. Texte einsammeln.
  final List<ProbedText> out = <ProbedText>[];
  final Rect screen = Offset.zero & view;

  void walk(Element e, TextGround ground, bool covered, bool inOverlay) {
    final Widget w = e.widget;
    if (w is Offstage && w.offstage) return;
    TextGround g = ground;
    if (w is GlassCard || w is MannyBubble) {
      g = TextGround.glass;
    } else if (w is HeaderCard ||
        w is FloatingNav ||
        w is WorldLabelChip ||
        w is StatusChip ||
        w is OrbNode ||
        w is CuraSnackbar ||
        w is CuraDialog ||
        w is ActionCircle ||
        w is NodeHint ||
        w is CategoryIconTile ||
        w is OpaqueSurface) {
      g = TextGround.opaque;
    } else if (w is PillButton) {
      // Primär und Glas haben eine eigene Fläche (auch deaktiviert); der
      // Umriss behält den Untergrund dahinter.
      g = w.variant == PillButtonVariant.outline ? ground : TextGround.opaque;
    } else if (w is PathNode) {
      // Erledigte und aktuelle Units haben eine deckende Füllung (`text-1`,
      // `accent`); gesperrte sind Glas (Brief 5.5).
      g = w.status == UnitStatus.locked ? TextGround.glass : TextGround.opaque;
    } else if (w is CuraSheetFrame) {
      // Sheet: `card` zu 100 % opak, kein Blur (Brief v2, 4).
      g = TextGround.opaque;
    }
    // Weitere Flächentypen ordnen die Pakete, die sie einführen, mit einer
    // `is`-Prüfung ein (nie über `runtimeType`: Release-Builds minifizieren
    // die Typnamen): `NodeHint` ist deckend; `ExampleNotice` und die Blase
    // des Gegenübers sind `GlassCard`s (Glas, schon erkannt), Eingabeleiste und
    // eigene Blasen `OpaqueSurface`s (deckend, oben).
    // Texte unter einer anderen Route (Dialog, Sheet mit Scrim) oder in einer
    // verdeckten Route zählen nicht als sichtbar (R-U2 Punkt 12).
    bool c = covered;
    final Key? key = w.key;
    final bool o =
        inOverlay ||
        (key is ValueKey<String> && key.value.startsWith('overlay:'));
    if (w is RichText) {
      if (!c && _isBuriedRoute(e)) c = true;
      final RenderObject? r = e.renderObject;
      if (r is RenderParagraph && r.attached && r.hasSize) {
        final ProbedText? p = _probe(r, g, screen, c, o);
        if (p != null) out.add(p);
      }
    }
    e.visitChildren((Element child) => walk(child, g, c, o));
  }

  walk(start, TextGround.bg, false, false);
  return TextProbe(
    texts: out,
    hasWorld: world != null,
    worldDecor: world?.decor ?? false,
    view: view,
  );
}

ProbedText? _probe(
  RenderParagraph r,
  TextGround ground,
  Rect screen,
  bool covered,
  bool inOverlay,
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
  // sichtbaren Teil (Pixel-Messung sonst über fremden Pixeln, etwa
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

  return ProbedText(
    text: plain,
    rect: rect,
    color: color ?? Colors.transparent,
    sizeSp: fontSize,
    weight: weight,
    ground: ground,
    onScreen: !covered && !clipped && rect.overlaps(screen),
    isIcon: _isIcon(plain),
    inOverlay: inOverlay,
  );
}

/// Rechtecke aller Widgets mit einem Marker-Schlüssel `ValueKey<String>` mit
/// dem Präfix [prefix] (z. B. `probe:`) in globalen Koordinaten. Mit
/// [skipBuried] zählen Elemente nicht, deren Route von einer weiteren Route
/// überdeckt wird (Home unter Sheet oder Dialog mit Scrim): ihre Nav und
/// Button-Gruppe sind dort abgedunkelt und nicht bedienbar, also kein Overlay
/// über dem Inhalt der oberen Route.
Map<String, Rect> probeKeyedRects({
  Element? root,
  required String prefix,
  bool skipBuried = false,
}) {
  final Map<String, Rect> out = <String, Rect>{};
  final Element? start = root ?? WidgetsBinding.instance.rootElement;
  if (start == null) return out;
  void walk(Element e) {
    final Key? key = e.widget.key;
    if (key is ValueKey<String> &&
        key.value.startsWith(prefix) &&
        !(skipBuried && _isBuriedRoute(e))) {
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
bool isBuriedRoute(Element e) => _isBuriedRoute(e);

bool _isBuriedRoute(Element e) {
  try {
    final ModalRoute<dynamic>? route = ModalRoute.of(e);
    return route != null && !route.isCurrent;
  } catch (_) {
    return false;
  }
}
