// Prüffunktionen der gestuften Matrix (Plan 12.2, M-Layout, M-Modus,
// M-Kontrast). Jede Funktion liefert Befunde statt zu werfen; die Tests
// sammeln sie je Fall und schlagen mit einer lesbaren Liste fehl. Befunde mit
// `advisory` sind Richtwerte (Plan 12.2): sie werden gemeldet, lassen den Test
// aber nicht scheitern („Befund an den ui-designer, nicht still umgestalten“).
import 'dart:ui' as ui;

import 'package:curaone/dev/scenarios.dart';
import 'package:curaone/dev/text_probe.dart';
import 'package:curaone/theme/contrast.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_motion.dart';
import 'package:curaone/theme/glow.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/components/glass_card.dart';
import 'package:curaone/ui/components/glow_background.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
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
    this.inScroll,
  );

  final String label;
  final Rect rect;
  final bool isTextField;

  /// Außerhalb der sichtbaren Fläche (Scroll) oder verdeckt markiert.
  final bool hidden;

  /// Liegt in einem scrollenden Bereich (darf unter Overlays durchlaufen).
  final bool inScroll;

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

/// Alle Knoten mit Tap-Aktion (auch außerhalb des Bildschirms, solange sie
/// gebaut sind). Zusammengeführte Knoten zählen nicht.
List<TapTarget> tapTargets(WidgetTester tester) {
  final RenderView view = tester.binding.renderViews.first;
  final SemanticsNode? root = view.owner!.semanticsOwner?.rootSemanticsNode;
  final List<TapTarget> out = <TapTarget>[];
  if (root == null) return out;
  final double dpr = tester.view.devicePixelRatio;
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
  return out;
}

/// Rechtecke der Overlays (Marker `overlay:*`), nach Namen ohne Präfix.
Map<String, Rect> overlayRects() {
  final Map<String, Rect> raw = probeKeyedRects(prefix: 'overlay:');
  return <String, Rect>{
    for (final MapEntry<String, Rect> e in raw.entries)
      e.key.substring('overlay:'.length): e.value,
  };
}

Rect? headerRect() => probeKeyedRects(prefix: 'header')['header'];

/// Ein Tap-Ziel gehört zu einem Overlay, wenn es (fast) ganz darin liegt.
bool _isOverlay(TapTarget t, Iterable<Rect> overlays) {
  final double area = t.rect.width * t.rect.height;
  if (area <= 0) return false;
  return overlays.any((Rect o) {
    final Rect i = o.intersect(t.rect);
    return i.width > 0 && i.height > 0 && i.width * i.height / area >= 0.95;
  });
}

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

/// Tap-Ziele ≥ 48 × 48 dp (Flutter-Leitlinie `androidTapTargetGuideline`).
Future<List<Finding>> checkTapTargetSize(WidgetTester tester) async {
  final Evaluation e = await androidTapTargetGuideline.evaluate(tester);
  return e.passed
      ? const <Finding>[]
      : <Finding>[Finding('Tap-Ziel ≥ 48 dp', e.reason ?? '')];
}

/// Abstand ≥ 8 dp zwischen Tap-Ziel-Rechtecken, paarweise ohne verschachtelte
/// (UI-32). Overlay und Inhalt dürfen sich beim Scrollen überlagern, das
/// prüft [checkReachability].
List<Finding> checkTapTargetGaps(WidgetTester tester) {
  final List<TapTarget> all = tapTargets(tester);
  final List<Finding> out = <Finding>[];
  for (int i = 0; i < all.length; i++) {
    for (int j = i + 1; j < all.length; j++) {
      final TapTarget a = all[i];
      final TapTarget b = all[j];
      if (_contains(a.rect, b.rect) || _contains(b.rect, a.rect)) continue;
      if (a.inScroll != b.inScroll) continue;
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
List<Finding> checkPrimary(WidgetTester tester, Scenario scenario) {
  final Finder f = find.byKey(PreviewKeys.primary);
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
/// Nav; Blase und Hinweis überdecken die Gruppe nicht.
List<Finding> checkZones(WidgetTester tester) {
  final Map<String, Rect> o = overlayRects();
  final Rect? cluster = o['cluster'];
  final List<Finding> out = <Finding>[];
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
    for (final MapEntry<String, Rect> e in o.entries) {
      if (e.key == 'nav' || e.key == 'cluster') continue;
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

/// Mindest-Sichtfläche zwischen Kopf und den Overlays über volle Breite
/// (Nav, Primärbutton-Reihe, Snackbar) ≥ 120 dp. **Richtwert** (Plan 12.2).
List<Finding> checkVisibleArea(WidgetTester tester) {
  final Rect? header = headerRect();
  if (header == null) return const <Finding>[];
  final Size view = viewSize(tester);
  double top = view.height;
  for (final Rect r in overlayRects().values) {
    if (r.width >= view.width * 0.6 && r.top < top) top = r.top;
  }
  final double free = top - header.bottom;
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

/// Inhalt nach Scrollen erreichbar (UI-31 neu, UI-88): jedes Tap-Ziel des
/// Inhalts lässt sich in eine Lage scrollen, in der es vollständig sichtbar,
/// unter dem Kopf und von keinem Overlay verdeckt ist. Ohne Scrollbereich muss
/// es in der Ruhelage so liegen.
Future<List<Finding>> checkReachability(WidgetTester tester) async {
  final Size view = viewSize(tester);
  final Rect screen = Offset.zero & view;
  final Map<String, Rect> o = overlayRects();
  final Rect? header = headerRect();
  // Inhalt: alles in Scrollbereichen; außerhalb davon, was nicht selbst
  // Overlay ist (feste Inhalte ohne Scrollbereich).
  final List<TapTarget> targets = tapTargets(tester)
      .where((TapTarget t) => t.inScroll || !_isOverlay(t, o.values))
      .toList();
  final List<Finding> out = <Finding>[];

  bool free(Rect r) {
    if (!_contains(screen, r)) return false;
    if (header != null && r.top < header.bottom - 0.5) return false;
    return !o.values.any((Rect ov) => ov.overlaps(r.deflate(0.5)));
  }

  final Finder scroll = find.byKey(PreviewKeys.scroll);
  ScrollPosition? position;
  if (scroll.evaluate().isNotEmpty) {
    final Finder scrollables = find.descendant(
      of: scroll,
      matching: find.byType(Scrollable),
    );
    final Finder scrollable = scrollables.evaluate().isNotEmpty
        ? scrollables
        : find.ancestor(of: scroll, matching: find.byType(Scrollable));
    if (scrollable.evaluate().isNotEmpty) {
      position = tester.state<ScrollableState>(scrollable.first).position;
    }
  }

  for (final TapTarget t in targets) {
    if (position == null) {
      if (!free(t.rect)) {
        out.add(
          Finding(
            'Inhalt erreichbar',
            '$t ist in der Ruhelage verdeckt oder außerhalb',
          ),
        );
      }
      continue;
    }
    final double start = position.pixels;
    final double max = position.maxScrollExtent;
    double? hit;
    for (double offset = 0; offset <= max + 0.001; offset += 2) {
      if (free(t.rect.shift(Offset(0, start - offset)))) {
        hit = offset;
        break;
      }
    }
    if (hit == null && max > 0 && free(t.rect.shift(Offset(0, start - max)))) {
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
    final Offset center = t.rect.center.translate(0, start - hit);
    final HitTestResult result = tester.hitTestOnBinding(center);
    final RenderObject? sr = scroll.evaluate().first.renderObject;
    bool onContent = false;
    for (final HitTestEntry e in result.path) {
      RenderObject? p = e.target is RenderObject
          ? e.target as RenderObject
          : null;
      while (p != null) {
        if (p == sr || (sr == null)) {
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

/// Chat-Fuß ≤ 40 % der Höhe (Ergänzung 2, 3.2).
List<Finding> checkChatFooter(WidgetTester tester) {
  final Rect? footer = overlayRects()['chat-footer'];
  if (footer == null) return const <Finding>[];
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
/// (Disabled) ist ausgenommen.
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

/// Bekannte Eigenheit von `textContrastGuideline` (U2a): Im aktiven Nav-Eintrag
/// wertet sie die Icon-Pixel als Text und meldet fälschlich ca. 2,27:1. Die
/// Nav-Paare (`accent-hi`/`text-1`/`text-2` auf `floatFill`) sind stattdessen
/// in `test/theme/contrast_test.dart` aus den Tokens geprüft. Ausgenommen
/// werden nur Meldungen, die sich auf einen Knoten innerhalb der Nav beziehen.
/// Alles andere bleibt scharf.
Future<List<Finding>> checkTextContrast(WidgetTester tester) async {
  final Evaluation e = await textContrastGuideline.evaluate(tester);
  if (e.passed) return const <Finding>[];
  final Rect? nav = overlayRects()['nav'];
  final List<String> navLabels = <String>[
    for (final Element el in find.byType(FloatingNav).evaluate())
      ...(el.widget as FloatingNav).items.map((NavItem i) => i.label),
  ];
  final List<Finding> out = <Finding>[];
  // Meldungen sind durch Leerzeilen/„SemanticsNode#“ getrennt.
  final List<String> blocks = (e.reason ?? '').split(
    RegExp(r'\n(?=SemanticsNode#)'),
  );
  for (final String b in blocks) {
    if (b.trim().isEmpty) continue;
    final bool inNav =
        nav != null &&
        navLabels.any(
          (String l) => b.contains('label: "$l"') || b.contains('"$l"'),
        );
    if (inNav && b.contains('found 2.')) continue;
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
