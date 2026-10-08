// UI-3: Kontraste der Brief-Tabelle 3.1, der Errata-Tabelle E-1/E-2 und der
// Ergänzung 1 (Abschnitt 4), aus den Tokens per Alpha-Komposition berechnet.
// Schwellen: Text 4,5, Symbol/Rand 3. Schlägt fehl, wenn ein als Text
// verwendetes Paar darunter liegt.
import 'dart:ui';

import 'package:curaone/theme/contrast.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/glow.dart';
import 'package:curaone/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

enum Use {
  /// Als Text verwendet: mindestens 4,5.
  text,

  /// Symbol, Rand oder große Fläche: mindestens 3.
  symbol,

  /// Paar, das **nicht** als Text verwendet werden darf (liegt unter 4,5).
  notForText,
}

class Case {
  const Case(this.name, this.fg, this.bg, this.use, {this.reference, this.tol});

  final String name;
  final Color fg;
  final Color bg;
  final Use use;

  /// Wert aus dem Brief (falls genannt) und Toleranz für Rundung/Hex-Näherung.
  final double? reference;
  final double? tol;

  double get ratio => contrastOver(fg, bg);
  double get minimum => use == Use.text ? 4.5 : 3.0;
}

const double _tableTol = 0.05;
const double _roughTol = 0.10;

/// Paare, die als Text verwendet werden, aber unter 4,5 liegen.
List<Case> failingTextPairs(Iterable<Case> cases) {
  return cases
      .where((Case c) => c.use == Use.text && c.ratio < 4.5)
      .toList(growable: false);
}

List<Case> buildCases() {
  final CuraColors c = CuraColors.dark;
  final Color bg = c.bg;
  final Color glass = glassWithGlow(c);
  final Color opaque = c.surfaceOpaque;
  final Color nav = floatOverBg(c);
  final List<Case> cases = <Case>[];

  void both(
    String name,
    Color fg, {
    required double onBg,
    required double onGlass,
    Use glassUse = Use.text,
    double? onGlassRef,
  }) {
    cases
      ..add(
        Case('$name auf bg', fg, bg, Use.text, reference: onBg, tol: _tableTol),
      )
      ..add(
        Case(
          '$name auf Glas',
          fg,
          glass,
          glassUse,
          reference: onGlassRef ?? onGlass,
          tol: _tableTol,
        ),
      );
  }

  // Brief 3.1, Tabelle „Gemessene Kontraste“ (Glas: Errata-Spalte 0 %).
  both('text-1', c.text1, onBg: 16.37, onGlass: 13.21);
  both('text-2', c.text2, onBg: 8.54, onGlass: 6.89);
  both('text-3', c.text3, onBg: 7.24, onGlass: 5.85);
  // accent als Text nur auf bg (E-2); auf Glas nur Fläche/Icon.
  both('accent', c.accent, onBg: 5.09, onGlass: 4.11, glassUse: Use.symbol);
  both('accent-hi', c.accentHi, onBg: 6.45, onGlass: 5.20);
  both('cat-physio', c.catPhysio, onBg: 6.84, onGlass: 5.52);
  both('cat-arzt', c.catArzt, onBg: 6.94, onGlass: 5.60);
  both('cat-uebung', c.catUebung, onBg: 10.55, onGlass: 8.51);
  both('cat-frist', c.catFrist, onBg: 6.23, onGlass: 5.03);
  both('tri-rot', c.triRot, onBg: 6.23, onGlass: 5.03);
  both('status-error', c.statusError, onBg: 6.23, onGlass: 5.03);
  both('tri-orange', c.triOrange, onBg: 9.53, onGlass: 7.69);
  cases.add(
    Case(
      'tri-gelb auf bg',
      c.triGelb,
      bg,
      Use.text,
      reference: 13.95,
      tol: _tableTol,
    ),
  );
  cases.add(
    Case('streak-freeze auf bg (Symbol)', c.streakFreeze, bg, Use.symbol),
  );
  cases
    ..add(
      Case(
        'on-accent auf accent',
        c.onAccent,
        c.accent,
        Use.text,
        reference: 5.09,
        tol: _tableTol,
      ),
    )
    ..add(
      Case(
        'on-accent auf Pressed',
        c.onAccent,
        c.accentPressed,
        Use.text,
        reference: 5.82,
        tol: _tableTol,
      ),
    )
    ..add(
      Case(
        'border-control auf bg',
        c.borderControl,
        bg,
        Use.symbol,
        reference: 3.80,
        tol: _tableTol,
      ),
    )
    ..add(
      Case(
        'border-control auf Glas',
        c.borderControl,
        glass,
        Use.symbol,
        reference: 3.64,
        tol: _tableTol,
      ),
    );

  // Auswahlflächen (accent-soft über Glas) und Nav.
  final Color softOnGlass = compose(c.accentSoft, glass);
  final Color navActive = compose(c.accentSoft, nav);
  cases
    ..add(
      Case(
        'text-1 auf accent-soft-Fläche',
        c.text1,
        softOnGlass,
        Use.text,
        reference: 11.03,
        tol: _roughTol,
      ),
    )
    ..add(
      Case(
        'accent-hi Icon auf accent-soft-Fläche',
        c.accentHi,
        softOnGlass,
        Use.symbol,
        reference: 4.35,
        tol: _roughTol,
      ),
    )
    ..add(
      Case(
        'text-1 auf Nav-aktiv',
        c.text1,
        navActive,
        Use.text,
        reference: 12.30,
        tol: _tableTol,
      ),
    )
    ..add(
      Case(
        'text-2 auf Nav',
        c.text2,
        nav,
        Use.text,
        reference: 7.70,
        tol: _tableTol,
      ),
    );

  // Manny.
  cases
    ..add(
      Case(
        'Manny: Rand Weiß 35 % auf bg',
        c.mannyOutline,
        bg,
        Use.symbol,
        reference: 3.22,
        tol: _tableTol,
      ),
    )
    ..add(
      Case(
        'Manny: Bauch auf Körper',
        c.mannyBelly,
        c.mannyBody,
        Use.symbol,
        reference: 8.82,
        tol: _tableTol,
      ),
    );

  // Triage-Karten: text-1 auf Tönung 18 % über bg.
  for (final MapEntry<String, (Color, double)> e in <String, (Color, double)>{
    'grün': (c.triGruen, 11.36),
    'gelb': (c.triGelb, 10.49),
    'orange': (c.triOrange, 11.77),
    'rot': (c.triRot, 13.05),
  }.entries) {
    cases.add(
      Case(
        'text-1 auf Triage-Karte ${e.key}',
        c.text1,
        compose(e.value.$1.withValues(alpha: 0.18), bg),
        Use.text,
        reference: e.value.$2,
        tol: _roughTol,
      ),
    );
  }

  // Schloss-Symbol Weiß 50 % auf Glas (Brief 5.5).
  cases.add(
    Case(
      'Schloss Weiß 50 % auf Glas',
      const Color(0xFFFFFFFF).withValues(alpha: 0.5),
      glass,
      Use.symbol,
      reference: 4.87,
      tol: _tableTol,
    ),
  );

  // Ergänzung 1, Abschnitt 4: opake Flächen und Sheet.
  cases
    ..add(
      Case(
        'text-1 auf surface-opaque',
        c.text1,
        opaque,
        Use.text,
        reference: 14.23,
        tol: _tableTol,
      ),
    )
    ..add(
      Case(
        'text-2 auf surface-opaque',
        c.text2,
        opaque,
        Use.text,
        reference: 7.42,
        tol: _tableTol,
      ),
    )
    ..add(
      Case(
        'accent-hi auf surface-opaque',
        c.accentHi,
        opaque,
        Use.text,
        reference: 5.60,
        tol: _tableTol,
      ),
    )
    ..add(Case('text-2 auf surface-float (Nav-Wert)', c.text2, nav, Use.text))
    ..add(
      Case(
        'border-control auf Glas über surface-float (Sheet)',
        c.borderControl,
        compose(c.surfaceGlassTop, nav),
        Use.symbol,
        reference: 3.4,
        tol: 0.15,
      ),
    );

  // E-2: accent auf surface-opaque ist **kein** Textpaar (4,42).
  cases.add(
    Case(
      'accent auf surface-opaque (nicht für Text)',
      c.accent,
      opaque,
      Use.notForText,
      reference: 4.42,
      tol: _tableTol,
    ),
  );

  // Hoher Kontrast: Ränder ≥ 4,3 (gemessen 4,37), Text auf opak.
  final CuraColors hc = CuraColors.darkHighContrast;
  cases
    ..add(
      Case(
        'HC: border-control-hc auf surface-opaque',
        hc.controlBorder,
        hc.surfaceOpaque,
        Use.symbol,
        reference: 4.37,
        tol: 0.02,
      ),
    )
    ..add(Case('HC: text-1 auf Karte', hc.text1, hc.cardFillTop, Use.text))
    ..add(Case('HC: text-2 auf Karte', hc.text2, hc.cardFillTop, Use.text))
    ..add(Case('HC: text-3 auf Karte', hc.text3, hc.cardFillTop, Use.text));

  // Errata E-1: Kontraste über Glow.
  // Glow-Alpha in Promille (Schlüssel) -> Referenzwerte je Spalte.
  const List<int> glows = <int>[0, 120, 153, 160, 179, 240];
  // Spalten: text-1, text-2, text-3, accent-hi, cat-physio, cat-arzt, cat-frist
  final List<(String, Color)> fgs = <(String, Color)>[
    ('text-1', c.text1),
    ('text-2', c.text2),
    ('text-3', c.text3),
    ('accent-hi', c.accentHi),
    ('cat-physio', c.catPhysio),
    ('cat-arzt', c.catArzt),
    ('cat-frist', c.catFrist),
  ];
  const Map<int, List<double>> onBgRef = <int, List<double>>{
    0: <double>[16.37, 8.54, 7.24, 6.45, 6.84, 6.94, 6.23],
    120: <double>[14.17, 7.39, 6.27, 5.58, 5.93, 6.01, 5.39],
    153: <double>[13.46, 7.02, 5.96, 5.30, 5.63, 5.71, 5.12],
    160: <double>[13.30, 6.94, 5.89, 5.24, 5.56, 5.64, 5.06],
    179: <double>[12.88, 6.72, 5.70, 5.08, 5.39, 5.47, 4.90],
    240: <double>[11.53, 6.02, 5.10, 4.54, 4.82, 4.89, 4.39],
  };
  const Map<int, List<double>> onGlassRef = <int, List<double>>{
    0: <double>[13.18, 6.88, 5.83, 5.19, 5.51, 5.59, 5.01],
    120: <double>[11.00, 5.74, 4.87, 4.34, 4.60, 4.67, 4.19],
    153: <double>[10.41, 5.43, 4.61, 4.10, 4.35, 4.42, 3.96],
    160: <double>[10.28, 5.37, 4.55, 4.05, 4.30, 4.36, 3.91],
    179: <double>[9.95, 5.19, 4.40, 3.92, 4.16, 4.22, 3.78],
    240: <double>[8.91, 4.65, 3.94, 3.51, 3.73, 3.78, 3.39],
  };
  for (final int key in glows) {
    final double g = key / 1000;
    final Color gBg = backgroundWithGlow(c, glow: g);
    final Color gGlass = glassWithGlow(c, glow: g);
    final String pct = '${(g * 100).toStringAsFixed(1)} %';
    for (int i = 0; i < fgs.length; i++) {
      final (String name, Color fg) = fgs[i];
      final bool plainText = i <= 2; // text-1/2/3
      final double bgRef = onBgRef[key]![i];
      final double glassRef = onGlassRef[key]![i];

      // Auf bg: Text bis 24 % Glow (E-1 Punkt 2), sofern der Brief ≥ 4,5 nennt.
      cases.add(
        Case(
          '$name auf bg über Glow $pct',
          fg,
          gBg,
          bgRef >= 4.5 ? Use.text : Use.notForText,
          reference: bgRef,
          tol: _tableTol,
        ),
      );

      // Auf Glas: text-1/2/3 bis 16 %, farbiger Text und accent-hi bis 12 %
      // (E-1 Punkte 3 und 4) und nur, wenn zusätzlich ≥ 4,5 berechnet ist (N-19).
      final double limit = plainText
          ? GlowTokens.maxTextOnGlass
          : GlowTokens.maxColoredOnGlass;
      if (g <= limit + 1e-9 && glassRef >= 4.5) {
        cases.add(
          Case(
            '$name auf Glas über Glow $pct',
            fg,
            gGlass,
            Use.text,
            reference: glassRef,
            tol: _tableTol,
          ),
        );
      } else if (glassRef < 4.5) {
        cases.add(
          Case(
            '$name auf Glas über Glow $pct',
            fg,
            gGlass,
            Use.notForText,
            reference: glassRef,
            tol: _tableTol,
          ),
        );
      }
    }
  }
  return cases;
}

String _describe(Case c) =>
    '${c.name}: ${c.ratio.toStringAsFixed(2)} (Ziel ${c.minimum})';

void main() {
  final List<Case> cases = buildCases();

  test('berechnete Kontraste stimmen mit den Angaben im Brief überein', () {
    final List<String> bad = <String>[];
    for (final Case c in cases) {
      if (c.reference == null) continue;
      if ((c.ratio - c.reference!).abs() > c.tol!) {
        bad.add('${_describe(c)}, Brief ${c.reference} (Toleranz ${c.tol})');
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('als Text verwendete Paare erreichen 4,5, Symbole und Ränder 3', () {
    final List<String> bad = <String>[
      for (final Case c in cases)
        if (c.use != Use.notForText && c.ratio < c.minimum) _describe(c),
    ];
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('Paare „nicht für Text“ liegen tatsächlich unter 4,5 (E-1, E-2)', () {
    final List<String> bad = <String>[
      for (final Case c in cases)
        if (c.use == Use.notForText && c.ratio >= 4.5) _describe(c),
    ];
    expect(bad, isEmpty, reason: bad.join('\n'));
    // Die im Plan genannten Kernfälle sind enthalten.
    final Set<String> names = cases
        .where((Case c) => c.use == Use.notForText)
        .map((Case c) => c.name)
        .toSet();
    expect(names, contains('accent auf surface-opaque (nicht für Text)'));
    expect(names, contains('accent-hi auf Glas über Glow 12.0 %'));
    expect(names, contains('cat-frist auf Glas über Glow 12.0 %'));
  });

  test('Prüffunktion schlägt an, wenn ein Textpaar unter 4,5 fällt', () {
    expect(failingTextPairs(cases), isEmpty);
    final CuraColors c = CuraColors.dark;
    final List<Case> broken = <Case>[
      ...cases,
      // accent auf Glas als Text deklariert (4,11): muss auffallen.
      Case('accent auf Glas als Text', c.accent, glassWithGlow(c), Use.text),
      // accent auf surface-opaque als Text (4,42): muss auffallen (E-2).
      Case(
        'accent auf surface-opaque als Text',
        c.accent,
        c.surfaceOpaque,
        Use.text,
      ),
    ];
    expect(failingTextPairs(broken).map((Case x) => x.name), <String>[
      'accent auf Glas als Text',
      'accent auf surface-opaque als Text',
    ]);
  });

  test('Glow-Schwellen 24/16/12 % tragen die Kontrastziele (UI-7, E-1)', () {
    final CuraColors c = CuraColors.dark;
    // text-1/2/3 auf bg bei 24 %, auf Glas bei 16 %.
    for (final Color fg in <Color>[c.text1, c.text2, c.text3]) {
      expect(
        contrastRatio(
          fg,
          backgroundWithGlow(c, glow: maxGlowAlphaFor(GlowBackdrop.bg)),
        ),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(
          fg,
          glassWithGlow(c, glow: maxGlowAlphaFor(GlowBackdrop.glass)),
        ),
        greaterThanOrEqualTo(4.5),
      );
    }
    // Farbiger Text auf Glas bei 12 %: physio und arzt tragen, accent-hi und
    // frist nicht (Zusatzbedingung N-19).
    final double colored = maxGlowAlphaFor(GlowBackdrop.coloredOnGlass);
    final Color glass12 = glassWithGlow(c, glow: colored);
    expect(contrastRatio(c.catPhysio, glass12), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(c.catArzt, glass12), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(c.accentHi, glass12), lessThan(4.5));
    expect(contrastRatio(c.catFrist, glass12), lessThan(4.5));
  });

  test('größter Glow-Alpha je Farbe auf Glas (praktische Grenzen, Plan 8.2)', () {
    final CuraColors c = CuraColors.dark;
    final double accentHi = maxGlowAlphaForContrast(
      c.accentHi,
      c,
      onGlass: true,
    )!;
    final double physio = maxGlowAlphaForContrast(
      c.catPhysio,
      c,
      onGlass: true,
    )!;
    // Plan 8.2: accent-hi auf Glas praktisch nur bei ≤ 9 %, cat-physio ≤ 13 %.
    expect(accentHi, inInclusiveRange(0.08, 0.10));
    expect(physio, inInclusiveRange(0.12, 0.14));
    // Ohne Glow schon darunter: null (accent auf Glas ist Symbol, 4,11).
    expect(maxGlowAlphaForContrast(c.accent, c, onGlass: true), isNull);
  });

  test('Kontrastfunktionen: Grenzwerte', () {
    const Color black = Color(0xFF000000);
    const Color white = Color(0xFFFFFFFF);
    expect(contrastRatio(white, black), closeTo(21, 1e-9));
    expect(contrastRatio(white, white), closeTo(1, 1e-9));
    expect(contrastRatio(black, white), closeTo(21, 1e-9));
  });
}
