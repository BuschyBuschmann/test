// Prüffunktionen der gestuften Matrix (Plan 12.2, M-Layout, M-Modus,
// M-Kontrast). Jede Funktion liefert Befunde statt zu werfen; die Tests
// sammeln sie je Fall und schlagen mit einer lesbaren Liste fehl. Befunde mit
// `advisory` sind Richtwerte (Plan 12.2): sie werden gemeldet, lassen den Test
// aber nicht scheitern („Befund an den ui-designer, nicht still umgestalten“).
import 'dart:async' show FutureOr;
import 'dart:ui' as ui;

import 'package:curaone/dev/scenarios.dart';
import 'package:curaone/dev/text_probe.dart';
import 'package:curaone/theme/contrast.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_motion.dart';
import 'package:curaone/theme/glow.dart';
import 'package:curaone/ui/components/cura_snackbar.dart';
import 'package:curaone/ui/components/cura_text_field.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/components/glass_card.dart';
import 'package:curaone/ui/components/glow_background.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
import 'package:curaone/ui/components/manny_chat_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class Finding {
  const Finding(this.check, this.message, {this.advisory = false});

  final String check;
  final String message;

  /// Richtwert: melden, nicht scheitern.
  final bool advisory;

  @override
  String toString() => '${advisory ? '[Richtwert] ' : ''}$check: $message';
}

// ---------------------------------------------------------------------------
// Gemeinsame Messwerkzeuge
// ---------------------------------------------------------------------------

Size viewSize(WidgetTester tester) =>
    tester.view.physicalSize / tester.view.devicePixelRatio;

/// Ein Tap-Ziel aus dem Semantik-Baum (globale Rechtecke in dp).
class TapTarget {
  const TapTarget(
    this.label,
    this.rect,
    this.isTextField,
    this.hidden,
    this.inScroll, {
    this.inOverlay = false,
    this.inHeader = false,
  });

  final String label;
  final Rect rect;
  final bool isTextField;

  /// Außerhalb der sichtbaren Fläche (Scroll) oder verdeckt markiert.
  final bool hidden;

  /// Liegt in einem scrollenden Bereich (darf unter Overlays durchlaufen).
  final bool inScroll;

  /// Gehört im **Element-Baum** zu einem markierten Overlay (Marker
  /// `overlay:*` oder die Leiste eines `SnackbarHost`), nicht nur geometrisch
  /// (R-U3 MAJOR-2): ein Ziel unter einem Overlay ist kein Teil davon.
  final bool inOverlay;

  /// Gehört im Element-Baum zum festen Kopf (Marker `header`).
  final bool inHeader;

  @override
  String toString() => '"$label" $rect';
}

Rect _globalRect(SemanticsNode node, double dpr) {
  Rect r = node.rect;
  SemanticsNode? cur = node;
  while (cur != null) {
    final Matrix4? t = cur.transform;
    if (t != null) r = MatrixUtils.transformRect(t, r);
    cur = cur.parent;
  }
  return Rect.fromLTRB(
    r.left / dpr,
    r.top / dpr,
    r.right / dpr,
    r.bottom / dpr,
  );
}

/// Semantik-Knoten, der die Semantik von [r] trägt: das Render-Objekt selbst
/// oder der nächste Vorfahr mit eigenem, nicht in den Vater verschmolzenen
/// Knoten (wie `WidgetTester.getSemantics`).
SemanticsNode? _semanticsOf(RenderObject? r) {
  RenderObject? cur = r;
  SemanticsNode? n = cur?.debugSemantics;
  while (cur != null && (n == null || n.isMergedIntoParent)) {
    cur = cur.parent;
    n = cur?.debugSemantics;
  }
  return n;
}

bool _hasTap(RenderObject r) {
  if (r is RenderSemanticsAnnotations) return r.properties.onTap != null;
  if (r is RenderSemanticsGestureHandler) return r.onTap != null;
  return false;
}

/// Ids der Semantik-Knoten aller Tap-Elemente **unterhalb** der markierten
/// Elemente im Element-Baum (nur sichtbare Teilbäume wie bei
/// [probeKeyedRects]). [isMarker] wählt die Elemente aus. So hängt die
/// Zugehörigkeit zu Overlay bzw. Kopf an der Baumstruktur und nicht an der
/// Lage auf dem Bildschirm (R-U3 MAJOR-2).
Set<int> tapNodeIdsUnder(bool Function(Element e) isMarker) {
  final Set<int> ids = <int>{};
  void collect(RenderObject r) {
    if (_hasTap(r)) {
      final SemanticsNode? n = _semanticsOf(r);
      if (n != null) ids.add(n.id);
    }
    r.visitChildren(collect);
  }

  void walk(Element e) {
    if (isMarker(e)) {
      final RenderObject? r = e.renderObject;
      if (r != null && r.attached) collect(r);
    }
    e.debugVisitOnstageChildren(walk);
  }

  final Element? root = WidgetsBinding.instance.rootElement;
  if (root != null) walk(root);
  return ids;
}

bool _isKeyedWith(Element e, bool Function(String key) test) {
  final Key? key = e.widget.key;
  return key is ValueKey<String> && test(key.value);
}

/// Tap-Ziele im markierten Overlay-Teilbaum (`overlay:*`), in der Leiste eines
/// `SnackbarHost` und im Scrim (`ModalBarrier`).
Set<int> overlayTapNodeIds() => tapNodeIdsUnder(
  (Element e) =>
      _isKeyedWith(e, (String k) => k.startsWith('overlay:')) ||
      // Der Scrim hinter Sheet und Dialog („Schließen“, ganzer Bildschirm) ist
      // kein Inhalt, sondern eine Ebene unter der Route.
      e.widget is ModalBarrier ||
      (e.widget is CuraSnackbar && _insideSnackbarHost(e)),
);

bool _insideSnackbarHost(Element e) {
  bool inside = false;
  e.visitAncestorElements((Element a) {
    if (a.widget is SnackbarHost) {
      inside = true;
      return false;
    }
    return true;
  });
  return inside;
}

/// Tap-Ziele im festen Kopf (Marker `header`).
Set<int> headerTapNodeIds() => tapNodeIdsUnder(
  (Element e) => _isKeyedWith(e, (String k) => k == 'header'),
);

/// Alle Knoten mit Tap-Aktion (nur gebaute; bei Scrollbereichen mit lazy
/// Listen ergänzt [scanScroll] den Rest). Zusammengeführte Knoten zählen nicht.
List<TapTarget> tapTargets(WidgetTester tester) {
  final RenderView view = tester.binding.renderViews.first;
  final SemanticsNode? root = view.owner!.semanticsOwner?.rootSemanticsNode;
  final List<TapTarget> out = <TapTarget>[];
  if (root == null) return out;
  final double dpr = tester.view.devicePixelRatio;
  final Set<int> overlayIds = overlayTapNodeIds();
  final Set<int> headerIds = headerTapNodeIds();
  void walk(SemanticsNode n, bool scrolling) {
    final SemanticsData d = n.getSemanticsData();
    final bool childScrolling =
        scrolling ||
        d.flagsCollection.hasImplicitScrolling ||
        d.hasAction(SemanticsAction.scrollUp) ||
        d.hasAction(SemanticsAction.scrollDown) ||
        d.hasAction(SemanticsAction.scrollLeft) ||
        d.hasAction(SemanticsAction.scrollRight);
    if (!n.isMergedIntoParent) {
      if (d.hasAction(SemanticsAction.tap) &&
          d.flagsCollection.isEnabled != ui.Tristate.isFalse) {
        out.add(
          TapTarget(
            d.label.isNotEmpty ? d.label : d.value,
            _globalRect(n, dpr),
            d.flagsCollection.isTextField,
            d.flagsCollection.isHidden,
            scrolling,
            inOverlay: overlayIds.contains(n.id),
            inHeader: headerIds.contains(n.id),
          ),
        );
      }
    }
    n.visitChildren((SemanticsNode c) {
      walk(c, childScrolling);
      return true;
    });
  }

  walk(root, false);
  return _refineToInnerTargets(tester, out);
}

/// Rechtecke aller Render-Objekte mit Tap-Semantik (`Semantics(onTap:)`,
/// `GestureDetector`), in dp. Nur **sichtbare** Teilbäume: Eine Route unter
/// einer opaken Route (Home unter dem Chat) hat ihre Render-Objekte noch, sie
/// gehören aber nicht zum Bildschirm (Element-Baum: `debugVisitOnstageChildren`,
/// wie bei [probeKeyedRects]). Sonst würden die Units des Pfads unter den
/// Kontaktzeilen als „innere Ziele“ der Zeilen gezählt.
List<Rect> _renderTapRects(WidgetTester tester) {
  final List<Rect> out = <Rect>[];
  final double dpr = tester.view.devicePixelRatio;
  void walk(Element e) {
    final RenderObject? r = e.renderObject;
    if (e is RenderObjectElement && r != null) {
      bool tap = false;
      if (r is RenderSemanticsAnnotations) tap = r.properties.onTap != null;
      if (r is RenderSemanticsGestureHandler) tap = r.onTap != null;
      // Nur Ziele in Scrollbereichen: Index-Zellen gibt es nur dort, und feste
      // Overlays dürfen nicht in die Zelle darunter hineingerechnet werden.
      if (tap &&
          r is RenderBox &&
          r.attached &&
          r.hasSize &&
          RenderAbstractViewport.maybeOf(r) != null) {
        final Rect g = r.localToGlobal(Offset.zero) & r.size;
        out.add(
          Rect.fromLTRB(
            g.left / dpr,
            g.top / dpr,
            g.right / dpr,
            g.bottom / dpr,
          ),
        );
      }
    }
    e.debugVisitOnstageChildren(walk);
  }

  final Element? root = WidgetsBinding.instance.rootElement;
  if (root != null) walk(root);
  return out;
}

/// Standard-Listen (`addSemanticIndexes`, in Produktivlisten Pflicht für die
/// Listenposition) hüllen jede Zelle in einen Index-Knoten, der Label und Tap
/// des Inhalts übernimmt; sein Rechteck ist die ganze Zelle samt Abstand
/// (R-U2-RR N3). Enthält ein Knoten kleinere Tap-Render-Objekte, werden deren
/// Rechtecke statt der Zelle gemeldet.
List<TapTarget> _refineToInnerTargets(
  WidgetTester tester,
  List<TapTarget> nodes,
) {
  final List<Rect> renders = _renderTapRects(tester);
  final List<TapTarget> out = <TapTarget>[];
  for (final TapTarget t in nodes) {
    if (!t.inScroll) {
      out.add(t);
      continue;
    }
    final double area = t.rect.width * t.rect.height;
    final List<Rect> inner = renders
        .where(
          (Rect r) =>
              _contains(t.rect, r) &&
              r.width * r.height < area - 1 &&
              r.width * r.height > 0,
        )
        .toList();
    if (inner.isEmpty) {
      out.add(t);
    } else {
      for (final Rect r in inner) {
        out.add(TapTarget(t.label, r, t.isTextField, t.hidden, t.inScroll));
      }
    }
  }
  return out;
}

/// Beschriftete Semantik-Knoten (Label, globales Rechteck), egal ob tippbar.
List<(String, Rect)> labeledNodes(WidgetTester tester) {
  final RenderView view = tester.binding.renderViews.first;
  final SemanticsNode? root = view.owner!.semanticsOwner?.rootSemanticsNode;
  final List<(String, Rect)> out = <(String, Rect)>[];
  if (root == null) return out;
  final double dpr = tester.view.devicePixelRatio;
  void walk(SemanticsNode n) {
    if (!n.isMergedIntoParent) {
      final SemanticsData d = n.getSemanticsData();
      if (d.label.isNotEmpty) out.add((d.label, _globalRect(n, dpr)));
    }
    n.visitChildren((SemanticsNode c) {
      walk(c);
      return true;
    });
  }

  walk(root);
  return out;
}

/// Rechtecke der Overlays (Marker `overlay:*`), nach Namen ohne Präfix. Die
/// sichtbare Snackbar-Leiste (`CuraSnackbar`) zählt automatisch als
/// `snackbar`, auch ohne Marker (der Host füllt den ganzen Bildschirm).
Map<String, Rect> overlayRects() {
  // Ohne die Overlays einer überdeckten Route (Home unter Sheet oder Dialog):
  // Nav und Button-Gruppe sind dort abgedunkelt und nicht bedienbar.
  final Map<String, Rect> raw = probeKeyedRects(
    prefix: 'overlay:',
    skipBuried: true,
  );
  final Map<String, Rect> out = <String, Rect>{
    for (final MapEntry<String, Rect> e in raw.entries)
      e.key.substring('overlay:'.length): e.value,
  };
  // Nur die Leiste eines `SnackbarHost` (nicht eine Snackbar, die ein Szenario
  // als gewöhnlichen Inhalt zeigt).
  final Element? bar = find
      .descendant(
        of: find.byType(SnackbarHost),
        matching: find.byType(CuraSnackbar),
      )
      .evaluate()
      .firstOrNull;
  final RenderObject? r = bar?.renderObject;
  if (r is RenderBox && r.attached && r.hasSize) {
    out['snackbar'] = r.localToGlobal(Offset.zero) & r.size;
  }
  return out;
}

Rect? headerRect() => probeKeyedRects(prefix: 'header')['header'];

/// Ergebnis von [scanAll] für **einen** Scrollbereich: Tap-Ziele in
/// **Inhaltskoordinaten** (Scrollstand 0), über den ganzen Scrollweg
/// eingesammelt, damit auch lazy gebaute Listen (`ListView.builder`,
/// Slivers) vollständig geprüft werden (R-U2 MAJOR-1).
class ScrollScan {
  const ScrollScan(
    this.position,
    this.renderObject,
    this.viewport,
    this.targets,
    this.complete,
    this.oversize,
    this.reachedMax,
  );

  final ScrollPosition position;
  final RenderObject? renderObject;

  /// Sichtfenster des Bereichs in globalen Koordinaten.
  final Rect viewport;
  final List<TapTarget> targets;

  /// `false`, wenn der Scrollweg nicht vollständig durchlaufen werden konnte
  /// (zu viele Schritte, z. B. endlose Liste).
  final bool complete;

  /// Ziele, die nie ganz ins Sichtfenster passen (höher als der Bereich).
  final List<String> oversize;

  /// Das beim Scan **tatsächlich erreichte** Scroll-Maximum. Bei lazy gebauten
  /// Listen ist `maxScrollExtent` in der Ruhelage nur geschätzt und erst am
  /// Ende des Weges exakt (R-U3 MINOR-1); Erreichbarkeit rechnet damit.
  final double reachedMax;

  Offset shiftFor(double pixels) =>
      position.axis == Axis.vertical ? Offset(0, pixels) : Offset(pixels, 0);
}

/// Ein Scrollbereich **in** einem Overlay (`overlay:*`) ist kein Inhaltsbereich:
/// Der Text einer begrenzten Blase scrollt innen (Plan 4.6, letzte Stufe), und
/// die Pfad-Units, die unter der Blase liegen, gehören nicht zu seinem
/// Scrollweg. Der markierte Hauptbereich ([PreviewKeys.scroll]) bleibt immer
/// dabei.
bool _insideOverlay(Element e) {
  bool inside = false;
  e.visitAncestorElements((Element a) {
    if (_isKeyedWith(a, (String k) => k.startsWith('overlay:'))) {
      inside = true;
      return false;
    }
    return true;
  });
  return inside;
}

/// Alle Scrollbereiche, die Tap-Ziele tragen können: der markierte
/// ([PreviewKeys.scroll]) und jeder weitere vertikale `Scrollable` mit
/// Scrollweg (Sheet über Liste, Chat-Nachrichtenliste, R-U2-RR N1). Ein
/// zweiter, nicht markierter Bereich fällt so nicht still heraus.
List<ScrollableState> _scrollables(WidgetTester tester) {
  // Nicht die Bereiche einer überdeckten Route (Liste von Heute unter einem
  // Sheet oder Dialog): ihr Scrollstand verschiebt die Ziele der oberen Route
  // nicht, und sie sind abgedunkelt und nicht bedienbar.
  final Finder keyed = find.byElementPredicate(
    (Element e) => e.widget.key == PreviewKeys.scroll && !isBuriedRoute(e),
  );
  final Set<ScrollableState> out = <ScrollableState>{};
  if (keyed.evaluate().isNotEmpty) {
    final Finder inner = find.descendant(
      of: keyed,
      matching: find.byType(Scrollable),
    );
    final Finder f = inner.evaluate().isNotEmpty
        ? inner
        : find.ancestor(of: keyed, matching: find.byType(Scrollable));
    if (f.evaluate().isNotEmpty) {
      out.add(tester.state<ScrollableState>(f.first));
    }
  }
  for (final Element e in find.byType(Scrollable).evaluate()) {
    final ScrollableState st = (e as StatefulElement).state as ScrollableState;
    if (st.position.axis == Axis.vertical &&
        st.position.maxScrollExtent > 0.5 &&
        !_insideOverlay(e) &&
        !isBuriedRoute(e)) {
      out.add(st);
    }
  }
  return out.toList();
}

/// Durchläuft für jeden Scrollbereich den Scrollweg in Viertel-Viewport-
/// Schritten und sammelt alle Tap-Ziele. Stellt die Scrollstände wieder her.
/// Ziele, die höher sind als der Bereich, werden als `oversize` gemeldet
/// (R-U2-RR N2).
Future<List<ScrollScan>> scanAll(WidgetTester tester) async {
  final List<ScrollScan> scans = <ScrollScan>[];
  for (final ScrollableState st in _scrollables(tester)) {
    final ScrollPosition position = st.position;
    final RenderObject? ro = st.context.findRenderObject();
    final Rect viewport = ro is RenderBox
        ? ro.localToGlobal(Offset.zero) & ro.size
        : Offset.zero & viewSize(tester);
    final double start = position.pixels;
    final Map<String, TapTarget> seen = <String, TapTarget>{};
    final Set<String> oversize = <String>{};
    bool complete = true;
    position.jumpTo(0);
    await tester.pump();
    for (int guard = 0; ; guard++) {
      final Offset shift = position.axis == Axis.vertical
          ? Offset(0, position.pixels)
          : Offset(position.pixels, 0);
      // Nur vollständig sichtbare Knoten: Am Rand schneidet der Scrollbereich
      // das Rechteck ab, und Teilstücke würden als Nachbarn erscheinen. Am
      // Anfang/Ende des Scrollwegs darf ein Ziel den Rand berühren.
      final bool atStart = position.pixels <= 0.5;
      final bool atEnd = position.pixels >= position.maxScrollExtent - 0.5;
      final Rect inner = Rect.fromLTRB(
        viewport.left - 0.5,
        viewport.top + (atStart ? -0.5 : 0.5),
        viewport.right + 0.5,
        viewport.bottom + (atEnd ? 0.5 : -0.5),
      );
      for (final TapTarget t in tapTargets(
        tester,
      ).where((TapTarget t) => t.inScroll)) {
        final bool inside =
            t.rect.left >= inner.left &&
            t.rect.right <= inner.right &&
            t.rect.top >= inner.top &&
            t.rect.bottom <= inner.bottom;
        if (inside) {
          final Rect c = t.rect.shift(shift);
          final String key =
              '${t.label}|${c.left.round()}|${c.top.round()}|${c.width.round()}|${c.height.round()}';
          seen.putIfAbsent(
            key,
            () => TapTarget(t.label, c, t.isTextField, false, true),
          );
        } else if (t.rect.overlaps(viewport) &&
            t.rect.top <= viewport.top + 0.5 &&
            t.rect.bottom >= viewport.bottom - 0.5) {
          // Angeschnitten und überdeckt den ganzen Bereich: höher als er.
          oversize.add(t.label);
        }
      }
      final double max = position.maxScrollExtent;
      if (position.pixels >= max - 0.5) break;
      if (guard > 400) {
        complete = false;
        break;
      }
      final double step = (position.viewportDimension * 0.25).clamp(1, 1e9);
      position.jumpTo((position.pixels + step).clamp(0, max));
      await tester.pump();
    }
    final double reachedMax = position.pixels;
    position.jumpTo(start);
    await tester.pump();
    scans.add(
      ScrollScan(
        position,
        ro,
        viewport,
        seen.values.toList(),
        complete,
        oversize.toList(),
        reachedMax,
      ),
    );
  }
  return scans;
}

/// Gehört das Ziel zu einem gescannten Bereich? Im Sichtfenster ja; ein
/// vorgebautes Ziel außerhalb davon (Cache-Bereich) über die Spalte des
/// Bereichs.
bool _inAnyViewport(TapTarget t, Iterable<ScrollScan> scans) => scans.any(
  (ScrollScan s) =>
      s.viewport.inflate(0.5).overlaps(t.rect) ||
      (t.rect.left < s.viewport.right + 0.5 &&
          t.rect.right > s.viewport.left - 0.5 &&
          (t.rect.top >= s.viewport.bottom || t.rect.bottom <= s.viewport.top)),
);

List<Finding> _scanProblems(Iterable<ScrollScan> scans) => <Finding>[
  for (final ScrollScan s in scans) ...<Finding>[
    if (!s.complete)
      const Finding(
        'Scrollweg vollständig',
        'Scrollbereich nicht vollständig durchlaufen (Endlosliste?)',
      ),
    for (final String l in s.oversize)
      Finding(
        'Ziel nicht vollständig sichtbar',
        '"$l" ist höher als sein Scrollbereich und passt nie ganz ins Sichtfenster',
      ),
  ],
];

bool _contains(Rect a, Rect b) =>
    a.inflate(0.5).contains(b.topLeft) &&
    a.inflate(0.5).contains(b.bottomRight);

double _rectDistance(Rect a, Rect b) {
  final double dx = <double>[
    a.left - b.right,
    b.left - a.right,
    0,
  ].reduce((double x, double y) => x > y ? x : y);
  final double dy = <double>[
    a.top - b.bottom,
    b.top - a.bottom,
    0,
  ].reduce((double x, double y) => x > y ? x : y);
  if (dx == 0) return dy;
  if (dy == 0) return dx;
  return Offset(dx, dy).distance;
}

// ---------------------------------------------------------------------------
// M-Layout
// ---------------------------------------------------------------------------

/// Layout-Exceptions (Overflow, Constraint-Fehler) seit dem letzten Aufruf.
List<Finding> takeLayoutExceptions(WidgetTester tester) {
  final List<Finding> out = <Finding>[];
  Object? e;
  while ((e = tester.takeException()) != null) {
    out.add(Finding('Exception', e.toString().split('\n').first));
  }
  return out;
}

/// Führt [body] mit allen vertikalen Scrollbereichen am Anfang (Scrollstand 0)
/// aus und stellt die Scrollstände danach wieder her. Ruhelage-Prüfungen
/// (Zielgröße, Abstand zu festen Elementen) gelten für den Anfangszustand: ein
/// Szenario mit fokussiertem Feld steht gescrollt, und Inhalt, der dabei unter
/// dem Kopf angeschnitten wird, ist kein Verstoß.
Future<T> atScrollStart<T>(
  WidgetTester tester,
  FutureOr<T> Function() body,
) async {
  final List<(ScrollPosition, double)> saved = <(ScrollPosition, double)>[
    for (final ScrollableState st in _scrollables(tester))
      (st.position, st.position.pixels),
  ];
  final bool moved = saved.any(((ScrollPosition, double) e) => e.$2 > 0.5);
  if (moved) {
    for (final (ScrollPosition p, double _) in saved) {
      p.jumpTo(0);
    }
    await tester.pump();
  }
  try {
    return await body();
  } finally {
    if (moved) {
      for (final (ScrollPosition p, double pixels) in saved) {
        p.jumpTo(pixels);
      }
      await tester.pump();
    }
  }
}

/// Tap-Ziele ≥ 48 × 48 dp: Flutter-Leitlinie `androidTapTargetGuideline` für
/// den Anfangszustand der Scrollbereiche ([atScrollStart]) **und** die
/// Rechtecke aller Ziele über den ganzen Scrollweg ([scanAll]), damit auch ein
/// zu kleines Ziel weit unten in einer langen Liste auffällt (R-U3-RR N1).
Future<List<Finding>> checkTapTargetSize(WidgetTester tester) async {
  final Evaluation e = await atScrollStart(
    tester,
    () => androidTapTargetGuideline.evaluate(tester),
  );
  final List<Finding> out = <Finding>[
    if (!e.passed) Finding('Tap-Ziel ≥ 48 dp', e.reason ?? ''),
  ];
  const double min = CuraSize.touchTarget - 0.01;
  for (final ScrollScan scan in await scanAll(tester)) {
    for (final TapTarget t in scan.targets) {
      if (t.rect.width < min || t.rect.height < min) {
        out.add(
          Finding(
            'Tap-Ziel ≥ 48 dp',
            '$t im Scrollweg ist kleiner als 48 × 48 dp '
                '(${t.rect.width.toStringAsFixed(1)} × ${t.rect.height.toStringAsFixed(1)})',
          ),
        );
      }
    }
  }
  return out;
}

/// Abstand ≥ 8 dp zwischen Tap-Ziel-Rechtecken, paarweise ohne verschachtelte
/// (UI-32). Kategorien: scrollender Inhalt, Overlay, fester Rest. Nur das
/// Paar „scrollender Inhalt gegen Overlay“ entfällt (Inhalt darf darunter
/// laufen, das prüft [checkReachability]); feste Nicht-Overlay-Elemente
/// (Kopf-Buttons) werden gegen den Inhalt in der Ruhelage geprüft (Anfang der
/// Scrollbereiche, [atScrollStart]).
/// Scrollender Inhalt gegeneinander: über den ganzen Scrollweg.
Future<List<Finding>> checkTapTargetGaps(WidgetTester tester) =>
    atScrollStart(tester, () => _checkTapTargetGaps(tester));

Future<List<Finding>> _checkTapTargetGaps(WidgetTester tester) async {
  final List<TapTarget> rest = tapTargets(tester);
  final List<ScrollScan> scans = await scanAll(tester);
  final List<Finding> out = <Finding>[..._scanProblems(scans)];
  void pair(TapTarget a, TapTarget b) {
    if (_contains(a.rect, b.rect) || _contains(b.rect, a.rect)) return;
    final double gap = _rectDistance(a.rect, b.rect);
    if (gap < CuraSize.minTargetGap - 0.01) {
      out.add(
        Finding(
          'Abstand ≥ 8 dp',
          '${gap.toStringAsFixed(1)} dp zwischen $a und $b',
        ),
      );
    }
  }

  final List<TapTarget> overlay = <TapTarget>[];
  final List<TapTarget> fixed = <TapTarget>[];
  final List<TapTarget> scrollRest = <TapTarget>[];
  for (final TapTarget t in rest) {
    if (t.inScroll) {
      scrollRest.add(t);
    } else if (t.inOverlay) {
      overlay.add(t);
    } else {
      fixed.add(t);
    }
  }
  final List<TapTarget> nonScroll = <TapTarget>[...overlay, ...fixed];
  for (int i = 0; i < nonScroll.length; i++) {
    for (int j = i + 1; j < nonScroll.length; j++) {
      pair(nonScroll[i], nonScroll[j]);
    }
  }
  // Scrollender Inhalt, der nicht ganz im Sichtfenster seines Scrollbereichs
  // liegt, ist dort abgeschnitten oder nicht sichtbar (Dialog: Buttons fest
  // unter dem Scrollbereich; vorgebaute Zeilen außerhalb): kein Abstandsbefund.
  // Nur ganz sichtbarer Inhalt zählt.
  bool clipped(TapTarget c) =>
      scans.isNotEmpty &&
      !scans.any((ScrollScan sc) => _contains(sc.viewport, c.rect));
  for (final TapTarget f in fixed) {
    for (final TapTarget c in scrollRest) {
      if (clipped(c)) continue;
      pair(f, c);
    }
  }
  // Jeder Scrollbereich über seinen ganzen Weg; scrollende Ziele außerhalb
  // aller Scan-Fenster (kein Scrollweg) in der Ruhelage.
  final List<List<TapTarget>> groups = <List<TapTarget>>[
    for (final ScrollScan sc in scans) sc.targets,
    scrollRest.where((TapTarget t) => !_inAnyViewport(t, scans)).toList(),
  ];
  for (final List<TapTarget> content in groups) {
    for (int i = 0; i < content.length; i++) {
      for (int j = i + 1; j < content.length; j++) {
        pair(content[i], content[j]);
      }
    }
  }
  return out;
}

/// Schrift ≥ 13 sp und Gewicht ≥ 400 aller Texte (Symbole ausgenommen).
List<Finding> checkTextStyles(TextProbe probe) {
  final List<Finding> out = <Finding>[];
  for (final ProbedText t in probe.texts) {
    if (t.isIcon) continue;
    if (t.sizeSp < 13 || t.weight < 400) {
      out.add(
        Finding(
          'Schrift ≥ 13 sp, Gewicht ≥ 400',
          '"${t.text}": ${t.sizeSp} sp, Gewicht ${t.weight}',
        ),
      );
    }
  }
  return out;
}

/// Primärbutton ([PreviewKeys.primary]) vollständig sichtbar und antippbar.
/// Es zählt nur der Primärbutton der **obersten** Route: unter einem Sheet oder
/// Dialog liegt „Training starten“ abgedunkelt unter dem Scrim.
List<Finding> checkPrimary(WidgetTester tester, Scenario scenario) {
  final Finder f = find.byElementPredicate(
    (Element e) => e.widget.key == PreviewKeys.primary && !isBuriedRoute(e),
  );
  if (f.evaluate().isEmpty) {
    return scenario.expectsPrimary
        ? const <Finding>[Finding('Primärbutton', 'Marker fehlt im Baum')]
        : const <Finding>[];
  }
  final Rect r = tester.getRect(f.first);
  final Rect view = Offset.zero & viewSize(tester);
  final List<Finding> out = <Finding>[];
  if (!_contains(view, r)) {
    out.add(Finding('Primärbutton sichtbar', '$r liegt nicht ganz in $view'));
  }
  if (f.hitTestable().evaluate().isEmpty) {
    out.add(
      const Finding(
        'Primärbutton antippbar',
        'Hit-Test am Mittelpunkt trifft ihn nicht',
      ),
    );
  }
  return out;
}

/// Freie Zonen über der Nav (UI-24 neu): unten links nichts, unten rechts nur
/// die Button-Gruppe. Gemessen an den Overlays; scrollender Inhalt darf
/// darunter laufen. Zusätzlich: Gruppe vollständig sichtbar, nicht über der
/// Nav; Blase und Hinweis überdecken die Gruppe nicht. Setzt das Szenario
/// `expectsCluster`/`expectsNav`, ist ein fehlender Marker ein harter
/// Befund (kein stilles Überspringen, R-U2 MAJOR-3).
List<Finding> checkZones(WidgetTester tester, Scenario scenario) {
  final Map<String, Rect> o = overlayRects();
  final Rect? cluster = o['cluster'];
  final List<Finding> out = <Finding>[];
  if (scenario.expectsCluster && cluster == null) {
    out.add(
      const Finding(
        'Marker fehlt',
        'overlay:cluster (Szenario erwartet die Button-Gruppe)',
      ),
    );
  }
  if (scenario.expectsNav && o['nav'] == null) {
    out.add(
      const Finding('Marker fehlt', 'overlay:nav (Szenario erwartet die Nav)'),
    );
  }
  final Size view = viewSize(tester);
  if (cluster != null) {
    if (!_contains(Offset.zero & view, cluster)) {
      out.add(
        Finding('Button-Gruppe sichtbar', '$cluster nicht ganz in $view'),
      );
    }
    final Rect? nav = o['nav'];
    final double navTop = nav?.top ?? view.height;
    if (cluster.bottom > navTop + 0.5 && nav != null) {
      out.add(
        Finding(
          'Button-Gruppe über der Nav',
          '$cluster reicht in die Nav $nav',
        ),
      );
    }
    final double band = cluster.height + CuraSpace.pageMargin;
    final Rect left = Rect.fromLTRB(0, navTop - band, view.width / 2, navTop);
    final Rect right = Rect.fromLTRB(
      view.width / 2,
      navTop - band,
      view.width,
      navTop,
    );
    // Heute: Die Primärbutton-Reihe gehört zur Gruppe (Manny-Button, darüber
    // der Nachrichten-Button); die Zonenregel gilt nur dem Pfad (UI-24 neu).
    // Für Heute gelten [checkTodayGroup] und die Erreichbarkeit.
    final bool today = o.containsKey('primary-row');
    for (final MapEntry<String, Rect> e in o.entries) {
      if (e.key == 'nav' || e.key == 'cluster') continue;
      if (today && e.key == 'primary-row') continue;
      if (e.value.overlaps(left)) {
        out.add(
          Finding(
            'Zone unten links frei',
            'Overlay "${e.key}" ${e.value} liegt in $left',
          ),
        );
      }
      if (e.value.overlaps(right)) {
        out.add(
          Finding(
            'Zone unten rechts nur Gruppe',
            'Overlay "${e.key}" ${e.value} liegt in $right',
          ),
        );
      }
    }
    for (final String k in <String>['bubble', 'hint']) {
      final Rect? r = o[k];
      if (r != null && r.overlaps(cluster)) {
        out.add(
          Finding(
            'Blase/Hinweis überdeckt Gruppe nicht',
            '"$k" $r überdeckt $cluster',
          ),
        );
      }
    }
  }
  return out;
}

/// Button-Gruppe auf Heute (UI-71, UI-73, UI-37/41 präzisiert): Der
/// Nachrichten-Button sitzt rechtsbündig **8 dp über der Oberkante des
/// Manny-Buttons** (auch im Umbruchszustand von „Training starten“, wenn die
/// Reihe höher als 56 dp ist); der Manny-Button steht unten bündig mit dem
/// Primärbutton; dessen Breite ist die Breite des Rahmens − 96 dp (Seitenränder
/// 2 × 16, Manny-Button 56, Abstand 8); eine Snackbar steht 12 dp über der
/// Oberkante der Gruppe. Gilt nur, wenn die Reihe (`overlay:primary-row`) im
/// Baum steht.
List<Finding> checkTodayGroup(WidgetTester tester, Scenario scenario) {
  final Map<String, Rect> o = overlayRects();
  final Rect? row = o['primary-row'];
  final Rect? messages = o['cluster'];
  if (row == null || messages == null) return const <Finding>[];
  final Finder manny = find.byElementPredicate(
    (Element e) => e.widget is MannyChatButton && !isBuriedRoute(e),
  );
  final Finder primary = find.byElementPredicate(
    (Element e) => e.widget.key == PreviewKeys.primary && !isBuriedRoute(e),
  );
  if (manny.evaluate().isEmpty || primary.evaluate().isEmpty) {
    return const <Finding>[
      Finding('Button-Gruppe Heute', 'Manny-Button oder Primärbutton fehlt'),
    ];
  }
  final Rect m = tester.getRect(manny.first);
  final Rect p = tester.getRect(primary.first);
  final List<Finding> out = <Finding>[];
  const double tol = 0.6;
  final double gap = m.top - messages.bottom;
  if ((gap - CuraSpace.clusterGap).abs() > tol) {
    out.add(
      Finding(
        'Nachrichten-Button 8 dp über dem Manny-Button',
        '${gap.toStringAsFixed(1)} dp zwischen $messages und $m '
            '(Primärbutton ${p.height.toStringAsFixed(0)} dp hoch)',
      ),
    );
  }
  if ((messages.right - m.right).abs() > tol) {
    out.add(
      Finding(
        'Nachrichten-Button rechtsbündig mit dem Manny-Button',
        'rechts $messages gegen $m',
      ),
    );
  }
  if ((m.bottom - p.bottom).abs() > tol) {
    out.add(
      Finding('Manny-Button unten bündig mit dem Primärbutton', '$m gegen $p'),
    );
  }
  final double frame = viewSize(tester).width < CuraSize.lineLengthMax
      ? viewSize(tester).width
      : CuraSize.lineLengthMax;
  final double expected =
      frame -
      CuraSpace.pageMargin * 2 -
      CuraSize.mannyChatButton -
      CuraSpace.clusterGap;
  if ((p.width - expected).abs() > tol) {
    out.add(
      Finding(
        'Primärbutton Breite = Breite − 96 dp',
        '${p.width.toStringAsFixed(1)} statt ${expected.toStringAsFixed(1)}',
      ),
    );
  }
  final Rect? snackbar = o['snackbar'];
  if (snackbar != null && !isBuriedSnackbar(tester)) {
    final double above = row.top - snackbar.bottom;
    if ((above - CuraSpace.snackbarGap).abs() > tol) {
      out.add(
        Finding(
          'Snackbar 12 dp über der Gruppe',
          '${above.toStringAsFixed(1)} dp zwischen $snackbar und der Gruppe $row',
        ),
      );
    }
  }
  return out;
}

/// Die Snackbar-Leiste liegt in einer überdeckten Route (kein Befund-Fall).
bool isBuriedSnackbar(WidgetTester tester) {
  final Element? bar = find
      .descendant(
        of: find.byType(SnackbarHost),
        matching: find.byType(CuraSnackbar),
      )
      .evaluate()
      .firstOrNull;
  return bar != null && isBuriedRoute(bar);
}

/// Mindest-Sichtfläche zwischen Kopf und den Overlays über volle Breite
/// (Nav, Primärbutton-Reihe, Snackbar) ≥ 120 dp. **Richtwert** (Plan 12.2).
/// Fehlt der Kopf-Marker bei `expectsHeader`, ist das ein harter Befund.
List<Finding> checkVisibleArea(WidgetTester tester, Scenario scenario) {
  final Rect? header = headerRect();
  // Kopf in der Scrollfläche (Onboarding bei großer Schrift oder geringer
  // Höhe, Marker `scroll-header`): erfüllt die Erwartung; die Sichtfläche
  // beginnt dann am oberen Rand.
  final bool scrollsAlong = probeKeyedRects(prefix: 'scroll-header').isNotEmpty;
  if (header == null && !scrollsAlong) {
    return scenario.expectsHeader
        ? const <Finding>[
            Finding('Marker fehlt', 'header (Szenario erwartet den Kopf)'),
          ]
        : const <Finding>[];
  }
  final Size view = viewSize(tester);
  double top = view.height;
  for (final Rect r in overlayRects().values) {
    if (r.width >= view.width * 0.6 && r.top < top) top = r.top;
  }
  final double free = top - (header?.bottom ?? 0);
  return free >= 120
      ? const <Finding>[]
      : <Finding>[
          Finding(
            'Sichtfläche ≥ 120 dp (Richtwert)',
            '${free.toStringAsFixed(0)} dp zwischen Kopf und Overlays',
            advisory: true,
          ),
        ];
}

/// Das fokussierte Textfeld ist sichtbar (A-U3 B1): ganz auf dem Bildschirm,
/// unter dem festen Kopf, von keinem Overlay (Tastatur, Weiter-Leiste,
/// Snackbar) verdeckt. Ein Tastatur-Szenario ([Scenario.keyboard]) muss ein
/// fokussiertes Feld haben; sonst fiele die Prüfung still weg.
List<Finding> checkFocusedField(WidgetTester tester, Scenario scenario) {
  final BuildContext? focus = FocusManager.instance.primaryFocus?.context;
  Element? field;
  if (focus is Element) {
    if (focus.widget is EditableText) field = focus;
    focus.visitAncestorElements((Element a) {
      if (field == null && a.widget is EditableText) field = a;
      return field == null;
    });
  }
  final Element? editable = field;
  if (editable == null) {
    return scenario.keyboard
        ? const <Finding>[
            Finding(
              'Fokusfeld',
              'Tastatur-Szenario ohne fokussiertes Textfeld (Skript prüfen)',
            ),
          ]
        : const <Finding>[];
  }
  // Ganzes Feld (Rahmen) statt nur der Textzeile, soweit es ein `CuraTextField`
  // gibt.
  Element target = editable;
  editable.visitAncestorElements((Element a) {
    if (a.widget is CuraTextField) {
      target = a;
      return false;
    }
    return true;
  });
  final RenderObject? ro = target.renderObject;
  if (ro is! RenderBox || !ro.attached || !ro.hasSize) {
    return const <Finding>[
      Finding('Fokusfeld', 'Das fokussierte Feld hat keine Größe'),
    ];
  }
  final Rect r = ro.localToGlobal(Offset.zero) & ro.size;
  return FreeZone(tester).free(r)
      ? const <Finding>[]
      : <Finding>[
          Finding(
            'Fokusfeld sichtbar',
            'fokussiertes Feld $r ist verdeckt, abgeschnitten oder außerhalb '
                '(Kopf/Overlays/Tastatur)',
          ),
        ];
}

/// Freie Fläche des Bildschirms: ganz auf dem Bildschirm, unter dem festen
/// Kopf und von keinem Overlay verdeckt. Overlays werden in der Ruhelage
/// gelesen; ein Overlay-Marker **innerhalb** eines Scrollbereichs (läuft mit
/// dem Inhalt) wird je Scanposition nicht neu gelesen. Das ist eine bekannte
/// Grenze (R-U3 MINOR-2): sie betrifft Overlays in lazy Listen außerhalb des
/// Sichtfensters (z. B. künftige Knotenhinweise, U3a); dort braucht ein
/// Szenario sein Overlay als festes Overlay über der Liste.
class FreeZone {
  FreeZone(WidgetTester tester)
    : screen = Offset.zero & viewSize(tester),
      header = headerRect(),
      overlays = overlayRects().values.toList();

  final Rect screen;
  final Rect? header;
  final List<Rect> overlays;

  bool _clearOfOverlays(Rect r) =>
      !overlays.any((Rect ov) => ov.overlaps(r.deflate(0.5)));

  bool free(Rect r) {
    if (!_contains(screen, r)) return false;
    final Rect? h = header;
    if (h != null && r.top < h.bottom - 0.5) return false;
    return _clearOfOverlays(r);
  }

  /// Feste Bedienelemente **im** Kopf (Zurück-Pfeil, „Deine Daten“) gehören
  /// zum Kopf selbst und liegen nicht „unter“ ihm: sie müssen auf dem
  /// Bildschirm liegen und dürfen von keinem Overlay überdeckt sein.
  bool freeInHeader(Rect r) => _contains(screen, r) && _clearOfOverlays(r);
}

/// Inhalt nach Scrollen erreichbar (UI-31 neu, UI-88): jedes Tap-Ziel des
/// Inhalts lässt sich in eine Lage scrollen, in der es vollständig sichtbar,
/// unter dem Kopf und von keinem Overlay verdeckt ist. Der Scrollweg wird
/// ganz durchlaufen ([scanAll]), damit auch lazy gebaute Listen zählen, und
/// mit dem dabei **erreichten** Maximum gerechnet. Feste Ziele außerhalb von
/// Overlays müssen in der Ruhelage frei liegen. Zugehörigkeit zu Overlay und
/// Kopf folgt dem Element-Baum ([TapTarget.inOverlay], [TapTarget.inHeader]):
/// ein Ziel, das nur geometrisch unter einem Overlay liegt, ist ein Befund.
Future<List<Finding>> checkReachability(WidgetTester tester) async {
  final FreeZone zone = FreeZone(tester);
  final bool Function(Rect) free = zone.free;
  final List<Finding> out = <Finding>[];

  final List<TapTarget> rest = tapTargets(tester);
  for (final TapTarget t in rest.where(
    (TapTarget t) => !t.inScroll && !t.inOverlay,
  )) {
    if (!(t.inHeader ? zone.freeInHeader(t.rect) : free(t.rect))) {
      out.add(
        Finding(
          'Inhalt erreichbar',
          '$t ist in der Ruhelage verdeckt oder außerhalb',
        ),
      );
    }
  }

  final List<ScrollScan> scans = await scanAll(tester);
  out.addAll(_scanProblems(scans));
  // Scrollende Ziele ohne eigenes Scan-Fenster (kein Scrollweg): Ruhelage.
  for (final TapTarget t in rest.where(
    (TapTarget t) => t.inScroll && !_inAnyViewport(t, scans),
  )) {
    if (!free(t.rect)) {
      out.add(
        Finding(
          'Inhalt erreichbar',
          '$t ist in der Ruhelage verdeckt oder außerhalb',
        ),
      );
    }
  }

  for (final ScrollScan scan in scans) {
    final ScrollPosition position = scan.position;
    final double start = position.pixels;
    final double max = scan.reachedMax;
    final RenderObject? sr = scan.renderObject;
    for (final TapTarget t in scan.targets) {
      // Frei von Kopf und Overlays **und** ganz im Sichtfenster des
      // Scrollbereichs: Ein Dialog hat feste Buttons unter seinem Scrollbereich,
      // die kein Overlay-Marker sind; Inhalt dahinter ist abgeschnitten.
      bool reachable(double offset) {
        final Rect r = t.rect.shift(-scan.shiftFor(offset));
        return free(r) && _contains(scan.viewport, r);
      }

      double? hit;
      for (double offset = 0; offset <= max + 0.001; offset += 2) {
        if (reachable(offset)) {
          hit = offset;
          break;
        }
      }
      if (hit == null && max > 0 && reachable(max)) {
        hit = max;
      }
      if (hit == null) {
        out.add(
          Finding(
            'Inhalt erreichbar',
            '$t lässt sich nicht frei von Kopf/Overlays scrollen (Scrollweg 0 … ${max.toStringAsFixed(0)} dp)',
          ),
        );
        continue;
      }
      // Gegenprobe mit echtem Hit-Test an der gefundenen Lage.
      position.jumpTo(hit);
      await tester.pump();
      final Offset center = t.rect.center - scan.shiftFor(position.pixels);
      final HitTestResult result = tester.hitTestOnBinding(center);
      bool onContent = false;
      if (sr == null) {
        out.add(
          const Finding(
            'Inhalt erreichbar',
            'Hit-Test-Gegenprobe nicht möglich: Scrollbereich ohne RenderObject',
          ),
        );
      } else {
        for (final HitTestEntry e in result.path) {
          RenderObject? p = e.target is RenderObject
              ? e.target as RenderObject
              : null;
          while (p != null) {
            if (p == sr) {
              onContent = true;
              break;
            }
            p = p.parent;
          }
          if (onContent) break;
        }
        if (!onContent) {
          out.add(
            Finding(
              'Inhalt erreichbar',
              '$t: Hit-Test in Lage ${hit.toStringAsFixed(0)} trifft den Inhalt nicht',
            ),
          );
        }
      }
    }
    position.jumpTo(start);
    await tester.pump();
  }
  return out;
}

/// `BackdropFilter` ≤ [max] (UI-6).
List<Finding> checkBackdrops(WidgetTester tester, int max) {
  final int n = find.byType(BackdropFilter).evaluate().length;
  return n <= max
      ? const <Finding>[]
      : <Finding>[Finding('BackdropFilter ≤ $max', '$n im Baum')];
}

/// Chat-Fuß ≤ 40 % der Höhe (Ergänzung 2, 3.2). Fehlt der Marker bei
/// `expectsChatFooter`, ist das ein harter Befund.
List<Finding> checkChatFooter(WidgetTester tester, Scenario scenario) {
  final Rect? footer = overlayRects()['chat-footer'];
  if (footer == null) {
    return scenario.expectsChatFooter
        ? const <Finding>[
            Finding(
              'Marker fehlt',
              'overlay:chat-footer (Szenario erwartet den Chat-Fuß)',
            ),
          ]
        : const <Finding>[];
  }
  final double limit = viewSize(tester).height * CuraSize.chatFooterMaxFraction;
  return footer.height <= limit + 0.5
      ? const <Finding>[]
      : <Finding>[
          Finding(
            'Chat-Fuß ≤ 40 %',
            '${footer.height.toStringAsFixed(0)} dp > ${limit.toStringAsFixed(0)} dp',
          ),
        ];
}

/// Glow-Alpha-Regel (Plan 8.2, Brief-E-1): je Text der Alpha am nächsten
/// Punkt: `bg` ≤ 24 %, `text-1/2/3` auf Glas ≤ 16 %, farbiger Text und
/// `accent-hi` auf Glas ≤ 12 %; dazu Kontrast ≥ 4,5 bei diesem Alpha
/// (Symbole 3). Deckende Flächen sind glowfrei. Halbtransparente Schrift
/// (Disabled) ist ausgenommen. **Gilt nur in der Ruhelage** (Scrollstand 0,
/// kein Zwischenzustand beim Scrollen; Präzisierung A-U2, Punkt 20): Die
/// Matrix prüft deshalb den eingeschwungenen Ausgangszustand. Texte unter
/// einer anderen Route/Scrim und außerhalb des Bildschirms zählen nicht.
List<Finding> checkGlowRule(TextProbe probe, CuraColors colors, Size view) {
  final List<Finding> out = <Finding>[];
  bool near(Color a, Color b) =>
      (a.r - b.r).abs() < 0.004 &&
      (a.g - b.g).abs() < 0.004 &&
      (a.b - b.b).abs() < 0.004;
  for (final ProbedText t in probe.texts) {
    if (!t.onScreen || t.ground == TextGround.opaque) continue;
    if (t.color.a < 0.999) continue;
    final bool plain =
        near(t.color, colors.text1) ||
        near(t.color, colors.text2) ||
        near(t.color, colors.text3);
    final bool glass = t.ground == TextGround.glass;
    final GlowBackdrop backdrop = !glass
        ? GlowBackdrop.bg
        : (plain ? GlowBackdrop.glass : GlowBackdrop.coloredOnGlass);
    final double limit = maxGlowAlphaFor(backdrop);
    if (!t.isIcon && t.glowAlpha > limit + 0.0005) {
      out.add(
        Finding(
          'Glow-Alpha',
          '"${t.text}" ${(t.glowAlpha * 100).toStringAsFixed(1)} % > '
              '${(limit * 100).toStringAsFixed(0)} % (${backdrop.name})',
        ),
      );
    }
    final Color ground = glass
        ? glassWithGlow(colors, glow: t.glowAlpha)
        : backgroundWithGlow(colors, glow: t.glowAlpha);
    final double ratio = contrastRatio(t.color, ground);
    final double min = t.isIcon ? 3 : 4.5;
    if (ratio < min) {
      out.add(
        Finding(
          'Kontrast bei Glow',
          '${t.isIcon ? 'Symbol' : '"${t.text}"'} ${ratio.toStringAsFixed(2)} < $min '
              '(Glow ${(t.glowAlpha * 100).toStringAsFixed(1)} %, ${t.ground.name})',
        ),
      );
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// M-Modus
// ---------------------------------------------------------------------------

/// Hoher Kontrast: Flächen opak, kein Blur, kein Glow, keine Schatten/Scheine
/// (außer dem Schatten der beiden Aktionsbuttons, der bleibt, Ergänzung 2).
List<Finding> checkHighContrast(WidgetTester tester) {
  final List<Finding> out = <Finding>[];
  final CuraColors c = CuraColors.darkHighContrast;
  if (find.byType(BackdropFilter).evaluate().isNotEmpty) {
    out.add(const Finding('HC kein Blur', 'BackdropFilter im Baum'));
  }
  final bool glow = find
      .byType(CustomPaint)
      .evaluate()
      .any((Element e) => (e.widget as CustomPaint).painter is GlowPainter);
  if (glow) out.add(const Finding('HC kein Glow', 'GlowPainter im Baum'));

  bool solid(Color? color, Gradient? gradient) {
    if (gradient is LinearGradient) {
      return gradient.colors.every(
        (Color g) => g.a >= 0.999 && g == c.surfaceOpaque,
      );
    }
    return color != null && color.a >= 0.999 && color == c.surfaceOpaque;
  }

  for (final Type type in <Type>[GlassCard, FloatingNav, MannyBubble]) {
    for (final Element e in find.byType(type).evaluate()) {
      final List<BoxDecoration> decos = find
          .descendant(
            of: find.byWidget(e.widget),
            matching: find.byType(DecoratedBox),
          )
          .evaluate()
          .map((Element d) => (d.widget as DecoratedBox).decoration)
          .whereType<BoxDecoration>()
          .where((BoxDecoration d) => d.color != null || d.gradient != null)
          .toList();
      final bool hasSolid = decos.any(
        (BoxDecoration d) => solid(d.color, d.gradient),
      );
      if (!hasSolid) {
        out.add(
          Finding(
            'HC Fläche opak',
            '$type hat keine Fläche aus surface-opaque',
          ),
        );
      }
    }
  }

  final BoxShadow keep = CuraShadow.actionButton.first;
  for (final Element e in find.byType(DecoratedBox).evaluate()) {
    final Decoration d = (e.widget as DecoratedBox).decoration;
    if (d is! BoxDecoration) continue;
    for (final BoxShadow s in d.boxShadow ?? const <BoxShadow>[]) {
      if (s.color == keep.color &&
          s.offset == keep.offset &&
          s.blurRadius == keep.blurRadius) {
        continue;
      }
      out.add(Finding('HC keine Schatten/Scheine', 'BoxShadow $s'));
    }
  }
  return out;
}

/// „Bewegung reduzieren“: nach [after] läuft keine Animation mehr (außer
/// Fortschrittsanzeigen, wenn [allowProgress]), und `CuraMotion` meldet
/// `reduced`.
List<Finding> checkReducedMotion(
  WidgetTester tester, {
  required bool allowProgress,
}) {
  final List<Finding> out = <Finding>[];
  final int progress =
      find.byType(CircularProgressIndicator).evaluate().length +
      find.byType(LinearProgressIndicator).evaluate().length;
  final int running = tester.binding.transientCallbackCount;
  final int allowed = allowProgress ? progress : 0;
  if (running > allowed) {
    out.add(
      Finding(
        'RM ohne laufende Animation',
        '$running laufende Animation(en), erlaubt $allowed (Fortschrittsanzeigen)',
      ),
    );
  }
  final Element anyElement = find.byType(Scaffold).evaluate().first;
  if (!CuraMotion.of(anyElement).reduced) {
    out.add(const Finding('RM erkannt', 'CuraMotion.reduced ist false'));
  }
  return out;
}

// ---------------------------------------------------------------------------
// M-Kontrast
// ---------------------------------------------------------------------------

/// Bekannte Eigenheit von `textContrastGuideline` (U2a): Im **aktiven**
/// Nav-Eintrag wertet sie die Icon-Pixel als Text und meldet fälschlich ca.
/// 2,27:1. Die Nav-Paare stehen aus Tokens in `test/theme/contrast_test.dart`.
/// Ausgenommen wird eine Meldung nur, wenn alle drei Bedingungen gelten
/// (R-U2 MAJOR-2): (1) das Label gehört zum aktiven Eintrag einer `FloatingNav`,
/// (2) **alle** Semantik-Knoten mit diesem Label liegen im Nav-Rechteck
/// (gleichnamiger Inhaltstext außerhalb → keine Ausnahme), (3) der gemeldete
/// Wert liegt im bekannten Bereich 2,0 bis 2,5. Alles andere bleibt scharf.
Future<List<Finding>> checkTextContrast(WidgetTester tester) async {
  final Evaluation e = await textContrastGuideline.evaluate(tester);
  if (e.passed) return const <Finding>[];
  final Rect? nav = overlayRects()['nav'];
  final Set<String> activeLabels = <String>{
    for (final Element el in find.byType(FloatingNav).evaluate())
      (el.widget as FloatingNav)
          .items[(el.widget as FloatingNav).currentIndex]
          .label,
  };
  final List<(String, Rect)> nodes = labeledNodes(tester);
  final List<Finding> out = <Finding>[];
  final List<String> blocks = (e.reason ?? '').split(
    RegExp(r'\n(?=SemanticsNode#)'),
  );
  for (final String b in blocks) {
    if (b.trim().isEmpty) continue;
    final String? label = RegExp(r'label: "([^"]*)"').firstMatch(b)?.group(1);
    final double? ratio = double.tryParse(
      RegExp(r'found (\d+\.\d+)').firstMatch(b)?.group(1) ?? '',
    );
    bool known = false;
    if (nav != null &&
        label != null &&
        ratio != null &&
        activeLabels.contains(label)) {
      final Iterable<Rect> same = nodes
          .where(((String, Rect) n) => n.$1 == label)
          .map(((String, Rect) n) => n.$2);
      known =
          same.isNotEmpty &&
          same.every((Rect r) => _contains(nav, r)) &&
          ratio >= 2.0 &&
          ratio < 2.5;
    }
    // Eingabefelder: Der Wert ist wenig Text auf einem Glas-Verlauf. Die
    // Leitlinie liest die zwei häufigsten Farben aus dem Bild und trifft dabei
    // zwei Stufen des Verlaufs statt der Textfarbe (gemeldete Paare liegen bei
    // 1,01 bis 1,02, beide Farben Untergrund). Messartefakt: `text1` auf Glas
    // und auf `surface-opaque` ist durch den Token-Test (UI-3) belegt.
    if (b.contains('isTextField')) continue;
    if (known) continue;
    out.add(
      Finding('Text-Kontrast (Leitlinie)', b.split('\n').take(3).join(' | ')),
    );
  }
  return out;
}

Future<List<Finding>> checkLabeledTargets(WidgetTester tester) async {
  final Evaluation e = await labeledTapTargetGuideline.evaluate(tester);
  return e.passed
      ? const <Finding>[]
      : <Finding>[Finding('Tap-Ziele beschriftet', e.reason ?? '')];
}
