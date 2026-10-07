// Statische Code-Regeln 1–16 (Plan 12.3, Test C) als prüfbare Funktionen.
// Jede Regel bekommt die Dateien als `Map<Pfad, Quelltext>` (Pfade relativ zum
// Paketstamm, mit `/`, z. B. `lib/ui/components/glass_card.dart`) und liefert
// die Verstöße. `code_rules_test.dart` wendet sie auf `lib/` an und prüft sie
// zusätzlich an Beispielcode (Selbsttest), damit sie auch gegen eine leere UI
// belastbar sind.
import 'code_scan.dart';

// ---------------------------------------------------------------------------
// Allowlists (Begründung je Eintrag; neue Einträge nur mit Begründung)
// ---------------------------------------------------------------------------

/// Regel 4: Dateien, in denen `statusError`, `catFrist`, `tri*` stehen dürfen
/// (Fehler-/Status-Widgets). Dateinamen sind vorläufig und werden von U3a/U3b/
/// U4 beim Anlegen der Fehleransichten bestätigt bzw. angepasst.
const Set<String> kStatusTokenAllowlist = <String>{
  'lib/ui/path/path_error_view.dart', // Fehleransicht Pfad
  'lib/ui/today/today_error_view.dart', // Fehleransicht Heute
  'lib/ui/data_sheet/delete_error_notice.dart', // Löschfehler im Dialog
};

/// Regel 5: Dateien, deren Text nachweislich auf `bg` liegt und die `accent`
/// als Textfarbe verwenden dürfen (derzeit leer).
const Set<String> kAccentTextAllowlist = <String>{};

/// Regel 10: `Sie` am Satzanfang ist mehrdeutig; erlaubte Texte mit Begründung
/// (derzeit leer).
const Map<String, String> kSieAllowlist = <String, String>{};

/// Regel 11: Dateien, in denen `maxLines` erlaubt ist (mit Tooltip-Alternative;
/// derzeit leer).
const Set<String> kMaxLinesAllowlist = <String>{};

/// Regel 2: Dateien, in denen Painter-Geometrie Zahlen enthalten darf.
const Set<String> kNumberLiteralExempt = <String>{
  'lib/ui/components/manny.dart',
};

const String kStringsFile = 'lib/l10n/strings_de.dart';

// ---------------------------------------------------------------------------
// Hilfen
// ---------------------------------------------------------------------------

bool _isTheme(String path) => inDir(path, 'lib/theme');

Map<String, String> _stripped(Map<String, String> files) => <String, String>{
  for (final MapEntry<String, String> e in files.entries)
    e.key: stripComments(e.value),
};

void _addMatches(
  List<Violation> out,
  int rule,
  String path,
  String code,
  RegExp pattern,
  String message,
) {
  for (final RegExpMatch m in pattern.allMatches(code)) {
    out.add(
      Violation(
        rule,
        path,
        lineOf(code, m.start),
        '$message (${m.group(0)!.trim()})',
      ),
    );
  }
}

/// Variablen, denen ein Treffer von [token] zugewiesen wird
/// (`final c = colors.accent;`). Ihre Verwendung zählt wie das Token selbst
/// (False Negatives wiegen schwerer als False Positives, Plan 12.3).
Set<String> _aliasesOf(String code, RegExp token) {
  final Set<String> out = <String>{};
  final RegExp decl = RegExp(
    r'\b(?:final|var|const|Color|TextStyle|WidgetStateProperty\w*)(?:<[^>]*>)?\s+([A-Za-z_]\w*)\s*=\s*([^;]*);',
  );
  for (final RegExpMatch m in decl.allMatches(code)) {
    if (token.hasMatch(m.group(2)!)) out.add(m.group(1)!);
  }
  return out;
}

// ---------------------------------------------------------------------------
// Regel 1: Farben und Schriftgrößen nur aus lib/theme/
// ---------------------------------------------------------------------------

final RegExp _r1Color = RegExp(r'\bColor\s*\(\s*0x');
final RegExp _r1ColorFrom = RegExp(r'\bColor\s*\.\s*from\w*\s*\(');
final RegExp _r1Colors = RegExp(r'\bColors\s*\.\s*(?!transparent\b)\w+');
final RegExp _r1FontSize = RegExp(r'\bfontSize\s*:');

List<Violation> checkRule1(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  _stripped(files).forEach((String path, String code) {
    if (_isTheme(path)) return;
    const String m = 'Farbe/Schriftgröße außerhalb von lib/theme/';
    _addMatches(out, 1, path, code, _r1Color, m);
    _addMatches(out, 1, path, code, _r1ColorFrom, m);
    _addMatches(out, 1, path, code, _r1Colors, m);
    _addMatches(out, 1, path, code, _r1FontSize, m);
  });
  return out;
}

// ---------------------------------------------------------------------------
// Regel 2: keine Zahl-Literale in Layout-Konstruktoren außerhalb lib/theme/
// ---------------------------------------------------------------------------

class _NumRule {
  const _NumRule(this.pattern, [this.named]);

  final String pattern;

  /// Nur diese benannten Argumente prüfen; `null` = alle Argumente.
  final Set<String>? named;
}

const List<_NumRule> _r2Rules = <_NumRule>[
  _NumRule(r'\bEdgeInsets(?:Directional)?\s*\.\s*\w+\s*\('),
  _NumRule(r'\bSizedBox\s*\(', <String>{'width', 'height'}),
  _NumRule(
    r'\bBorderRadius(?:Directional)?\s*\.\s*(?:circular|only|all|vertical|horizontal)\s*\(',
  ),
  _NumRule(r'\bRadius\s*\.\s*(?:circular|elliptical)\s*\('),
  _NumRule(r'\bSizedBox\s*\.\s*(?:square|fromSize)\s*\('),
  _NumRule(r'\bSize\s*(?:\.\s*\w+)?\s*\('),
  _NumRule(r'\bDuration\s*\(', <String>{'milliseconds'}),
  _NumRule(r'\bPositioned\s*\(', <String>{
    'left',
    'top',
    'right',
    'bottom',
    'width',
    'height',
  }),
  _NumRule(r'\bContainer\s*\(', <String>{'width', 'height'}),
  _NumRule(r'\bBoxConstraints\s*\('),
  _NumRule(r'\bBoxShadow\s*\('),
  _NumRule(r'\bBorder\s*\.\s*all\s*\(', <String>{'width'}),
  _NumRule(r'\.\s*withValues\s*\(', <String>{'alpha'}),
  _NumRule(r'\.\s*withOpacity\s*\('),
];

List<Violation> checkRule2(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  _stripped(files).forEach((String path, String code) {
    if (_isTheme(path) || kNumberLiteralExempt.contains(path)) return;
    for (final _NumRule rule in _r2Rules) {
      for (final Call call in findCalls(code, RegExp(rule.pattern))) {
        for (final Arg arg in call.args) {
          if (rule.named != null && !rule.named!.contains(arg.name)) continue;
          for (final String n in nonZeroNumbers(arg.value)) {
            out.add(
              Violation(
                2,
                path,
                lineOf(code, arg.offset),
                'Zahl-Literal $n in ${call.name}(${arg.name ?? ''}…): Token aus lib/theme/ verwenden',
              ),
            );
          }
        }
      }
    }
  });
  return out;
}

// ---------------------------------------------------------------------------
// Regel 3: BackdropFilter und CuraBlur nur an festen Stellen
// ---------------------------------------------------------------------------

/// Vollständige Pfade (nicht nur Dateinamen): `lib/ui/today/cura_blur.dart`
/// darf keinen Blur enthalten.
const Set<String> _r3BackdropFiles = <String>{
  'lib/ui/components/cura_blur.dart',
};
const Set<String> _r3BlurFiles = <String>{
  'lib/ui/components/cura_blur.dart',
  'lib/ui/components/floating_nav.dart',
  'lib/ui/components/manny_bubble.dart',
  'lib/ui/routes/cura_sheet_route.dart',
};
final RegExp _r3Backdrop = RegExp(
  r'\b(?:BackdropFilter|ImageFiltered)\b|\bImageFilter\s*\.\s*blur\b',
);
final RegExp _r3Blur = RegExp(r'\bCuraBlur\b');

List<Violation> checkRule3(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  _stripped(files).forEach((String path, String code) {
    if (!_r3BackdropFiles.contains(path)) {
      _addMatches(
        out,
        3,
        path,
        code,
        _r3Backdrop,
        'BackdropFilter/Blur nur in lib/ui/components/cura_blur.dart',
      );
    }
    if (!_r3BlurFiles.contains(path)) {
      _addMatches(
        out,
        3,
        path,
        code,
        _r3Blur,
        'CuraBlur nur in floating_nav, manny_bubble, cura_sheet_route',
      );
    }
  });
  return out;
}

// ---------------------------------------------------------------------------
// Regel 4: Status-Tokens nur in Fehler-/Status-Widgets, nie in Handlungselementen
// ---------------------------------------------------------------------------

final RegExp _r4Token = RegExp(
  r'\b(?:statusError|catFrist|tri(?:Gruen|Gelb|Orange|Rot))\b',
);
final RegExp _r4Accent = RegExp(r'\baccent(?:Hi)?\b');
final RegExp _anyCall = RegExp(r'\b[A-Za-z_]\w*(?:\s*\.\s*[A-Za-z_]\w*)*\s*\(');
final RegExp _handlerArg = RegExp(r'^on(?:Pressed|Tap)\w*$');
const Set<String> _r4ActionFiles = <String>{
  'pill_button.dart',
  'cura_chip.dart',
};

List<Violation> checkRule4(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  _stripped(files).forEach((String path, String code) {
    if (_isTheme(path)) return;
    final List<RegExpMatch> hits = _r4Token.allMatches(code).toList();
    for (final String alias in _aliasesOf(code, _r4Token)) {
      // Erste Fundstelle ist die Zuweisung selbst; sie ist schon ein Treffer.
      hits.addAll(RegExp('\\b$alias\\b').allMatches(code).skip(1));
    }
    if (hits.isEmpty && !kStatusTokenAllowlist.contains(path)) return;

    if (kStatusTokenAllowlist.contains(path)) {
      _addMatches(
        out,
        4,
        path,
        code,
        _r4Accent,
        'accent/accentHi nicht in Fehler-/Status-Widgets',
      );
    }
    if (hits.isEmpty) return;

    if (_r4ActionFiles.contains(baseName(path))) {
      for (final RegExpMatch m in hits) {
        out.add(
          Violation(
            4,
            path,
            lineOf(code, m.start),
            'Status-Token in PillButton/CuraChip (${m.group(0)})',
          ),
        );
      }
      return;
    }
    if (!kStatusTokenAllowlist.contains(path)) {
      for (final RegExpMatch m in hits) {
        out.add(
          Violation(
            4,
            path,
            lineOf(code, m.start),
            'Status-Token ${m.group(0)} nur in Fehler-/Status-Widgets (Allowlist)',
          ),
        );
      }
      return;
    }
    // Allowlist-Datei: das Token darf nicht in einem Widget mit onPressed/onTap stehen.
    final List<Call> calls = findCalls(code, _anyCall);
    for (final RegExpMatch m in hits) {
      for (final Call c in calls) {
        if (c.open < m.start &&
            m.start < c.close &&
            c.args.any(
              (Arg a) => a.name != null && _handlerArg.hasMatch(a.name!),
            )) {
          out.add(
            Violation(
              4,
              path,
              lineOf(code, m.start),
              'Status-Token ${m.group(0)} in ${c.name}(…) mit onPressed/onTap',
            ),
          );
          break;
        }
      }
    }
  });
  return out;
}

// ---------------------------------------------------------------------------
// Regel 5: accent nie als Textfarbe (Brief-E-2)
// ---------------------------------------------------------------------------

final RegExp _r5Accent = RegExp(r'\baccent\b');
final RegExp _r5Calls = RegExp(
  r'\b(?:TextStyle|ButtonStyle|DefaultTextStyle)\s*\(|\.\s*(?:copyWith|apply|merge|styleFrom)\s*\(',
);
const Set<String> _r5Args = <String>{
  'color',
  'foregroundColor',
  'textColor',
  'labelColor',
  'unselectedLabelColor',
};

List<Violation> checkRule5(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  _stripped(files).forEach((String path, String code) {
    if (kAccentTextAllowlist.contains(path)) return;
    final Set<String> aliases = _aliasesOf(code, _r5Accent);
    final RegExp? aliasUse = aliases.isEmpty
        ? null
        : RegExp('\\b(?:${aliases.join('|')})\\b');
    for (final Call call in findCalls(code, _r5Calls)) {
      for (final Arg arg in call.args) {
        if (arg.name == null || !_r5Args.contains(arg.name)) continue;
        if (_r5Accent.hasMatch(arg.value) ||
            (aliasUse != null && aliasUse.hasMatch(arg.value))) {
          out.add(
            Violation(
              5,
              path,
              lineOf(code, arg.offset),
              'accent als Textfarbe in ${call.name}(${arg.name}: …): accentHi oder text1 verwenden',
            ),
          );
        }
      }
    }
  });
  return out;
}

// ---------------------------------------------------------------------------
// Regel 6: ChoiceCard, CuraTextField, DateCard genau einmal definiert
// ---------------------------------------------------------------------------

const List<String> kSharedWidgetClasses = <String>[
  'ChoiceCard',
  'CuraTextField',
  'DateCard',
];

List<Violation> checkRule6(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  final Map<String, String> code = _stripped(files);
  final bool onboarding = code.keys.any(
    (String p) => inDir(p, 'lib/ui/onboarding'),
  );
  final bool dataSheet = code.keys.any(
    (String p) => inDir(p, 'lib/ui/data_sheet'),
  );
  for (final String cls in kSharedWidgetClasses) {
    final RegExp def = RegExp('\\bclass\\s+_?$cls\\b');
    final RegExp use = RegExp('\\b$cls\\b');
    final List<String> defining = <String>[];
    int count = 0;
    code.forEach((String path, String src) {
      final int n = def.allMatches(src).length;
      if (n > 0) defining.add(path);
      count += n;
    });
    if (count > 1) {
      out.add(
        Violation(
          6,
          defining.join(', '),
          1,
          '$cls hat $count Klassendefinitionen (genau eine erlaubt)',
        ),
      );
    }
    // Sobald beide Orte existieren, müssen beide die eine Klasse nutzen.
    if (count == 1 && onboarding && dataSheet) {
      for (final String dir in <String>[
        'lib/ui/onboarding',
        'lib/ui/data_sheet',
      ]) {
        final bool used = code.entries.any(
          (MapEntry<String, String> e) =>
              inDir(e.key, dir) &&
              !defining.contains(e.key) &&
              use.hasMatch(e.value),
        );
        if (!used) {
          out.add(
            Violation(
              6,
              dir,
              1,
              '$cls wird hier nicht verwendet (eine Implementierung für Onboarding und Sheet)',
            ),
          );
        }
      }
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Regel 7: lib/logic und lib/l10n ohne Flutter und dart:ui
// ---------------------------------------------------------------------------

final RegExp _r7Import = RegExp(
  r'''\b(?:import|export)\s+['"](?:package:flutter[^'"]*|dart:ui)['"]''',
);

final RegExp _importUri = RegExp(r'''\b(?:import|export)\s+['"]([^'"]+)['"]''');

/// Löst einen Import-URI auf einen Pfad `lib/…` auf; `null` für fremde Pakete
/// und `dart:`-Bibliotheken.
String? _resolveImport(String from, String uri) {
  if (uri.startsWith('package:curaone/')) {
    return 'lib/${uri.substring('package:curaone/'.length)}';
  }
  if (uri.contains(':')) return null;
  final List<String> parts = from.split('/')..removeLast();
  for (final String seg in uri.split('/')) {
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (seg != '.') {
      parts.add(seg);
    }
  }
  return parts.join('/');
}

List<Violation> checkRule7(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  final Map<String, String> code = _stripped(files);
  code.forEach((String path, String src) {
    if (!inDir(path, 'lib/logic') && !inDir(path, 'lib/l10n')) return;
    _addMatches(
      out,
      7,
      path,
      src,
      _r7Import,
      'Flutter-/dart:ui-Import in reiner Logik',
    );
    // Transitiv: kein Import (innerhalb lib/) führt zu einer Datei mit
    // Flutter-/dart:ui-Import.
    final Set<String> seen = <String>{path};
    final List<List<String>> queue = <List<String>>[
      <String>[path],
    ];
    while (queue.isNotEmpty) {
      final List<String> chain = queue.removeAt(0);
      final String current = chain.last;
      for (final RegExpMatch m in _importUri.allMatches(code[current] ?? '')) {
        final String? target = _resolveImport(current, m.group(1)!);
        if (target == null || !seen.add(target)) continue;
        final String? targetSrc = code[target];
        if (targetSrc == null) continue;
        final List<String> next = <String>[...chain, target];
        if (_r7Import.hasMatch(targetSrc)) {
          out.add(
            Violation(
              7,
              path,
              1,
              'importiert transitiv Flutter/dart:ui: ${next.join(' -> ')}',
            ),
          );
        } else {
          queue.add(next);
        }
      }
    }
  });
  return out;
}

// ---------------------------------------------------------------------------
// Regel 8: sichtbare Texte nur aus strings_de.dart
// ---------------------------------------------------------------------------

final RegExp _r8Text = RegExp(r'\bText\s*\(');
final RegExp _r8Semantics = RegExp(r'\bSemantics\s*\(');
final RegExp _r8Tooltip = RegExp(r'\bTooltip\s*\(');
final RegExp _r8Named = RegExp(
  r'\b(hintText|labelText|semanticsLabel|semanticLabel|tooltip|helperText|errorText|counterText|prefixText|suffixText|onTapHint|onLongPressHint|increasedValue|decreasedValue)\s*:\s*',
);
final RegExp _r8TextSpan = RegExp(r'\bTextSpan\s*\(');
final RegExp _r8Announce = RegExp(r'\bSemanticsService\s*\.\s*\w+\s*\(');

List<Violation> checkRule8(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  _stripped(files).forEach((String path, String code) {
    if (path == kStringsFile) return;
    for (final Call c in findCalls(code, _r8Text)) {
      final Arg? a = c.firstPositional;
      if (a != null && hasStringLiteral(a.value)) {
        out.add(
          Violation(
            8,
            path,
            lineOf(code, a.offset),
            'String-Literal in Text(…): Text aus strings_de.dart',
          ),
        );
      }
    }
    for (final Call c in findCalls(code, _r8Semantics)) {
      for (final String name in <String>['label', 'hint', 'value']) {
        final Arg? a = c.named(name);
        if (a != null && hasStringLiteral(a.value)) {
          out.add(
            Violation(
              8,
              path,
              lineOf(code, a.offset),
              'String-Literal in Semantics($name:): Text aus strings_de.dart',
            ),
          );
        }
      }
    }
    for (final Call c in findCalls(code, _r8TextSpan)) {
      final Arg? a = c.named('text') ?? c.firstPositional;
      if (a != null && hasStringLiteral(a.value)) {
        out.add(
          Violation(
            8,
            path,
            lineOf(code, a.offset),
            'String-Literal in TextSpan(text:): Text aus strings_de.dart',
          ),
        );
      }
    }
    for (final Call c in findCalls(code, _r8Announce)) {
      final Arg? a = c.firstPositional;
      if (a != null && hasStringLiteral(a.value)) {
        out.add(
          Violation(
            8,
            path,
            lineOf(code, a.offset),
            'String-Literal in SemanticsService: Text aus strings_de.dart',
          ),
        );
      }
    }
    for (final Call c in findCalls(code, _r8Tooltip)) {
      final Arg? a = c.named('message');
      if (a != null && hasStringLiteral(a.value)) {
        out.add(
          Violation(
            8,
            path,
            lineOf(code, a.offset),
            'String-Literal in Tooltip(message:): Text aus strings_de.dart',
          ),
        );
      }
    }
    for (final RegExpMatch m in _r8Named.allMatches(code)) {
      final String expr = code.substring(m.end, expressionEnd(code, m.end));
      if (hasStringLiteral(expr)) {
        out.add(
          Violation(
            8,
            path,
            lineOf(code, m.start),
            'String-Literal in ${m.group(1)}: Text aus strings_de.dart',
          ),
        );
      }
    }
  });
  return out;
}

// ---------------------------------------------------------------------------
// Regel 9: keine Animation in glow_background.dart und manny.dart
// ---------------------------------------------------------------------------

final RegExp _r9Anim = RegExp(
  r'\b(?:Ticker\w*|AnimationController|\w*TickerProviderStateMixin)\b',
);

List<Violation> checkRule9(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  _stripped(files).forEach((String path, String code) {
    final String name = baseName(path);
    if (name != 'glow_background.dart' && name != 'manny.dart') return;
    _addMatches(
      out,
      9,
      path,
      code,
      _r9Anim,
      'Ticker/AnimationController in statischem Baustein',
    );
  });
  return out;
}

// ---------------------------------------------------------------------------
// Regel 10: Ton in strings_de.dart (Sie-Form, klinische Begriffe)
// ---------------------------------------------------------------------------

final RegExp _r10Ihr = RegExp(
  r'\b(?:Ihr|Ihre|Ihren|Ihrem|Ihrer|Ihres|Ihnen)\b',
);
final RegExp _r10Sie = RegExp(r'\bSie\b');
final RegExp _r10Clinical = RegExp(
  r'\b(?:patient|indikation|therapieplan|compliance|proband)',
  caseSensitive: false,
);

List<Violation> checkRule10(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  final String? raw = files[kStringsFile];
  if (raw == null) return out;
  final String code = stripComments(raw);
  for (final (String text, int offset) in extractStringLiterals(code)) {
    final int line = lineOf(code, offset);
    for (final RegExpMatch m in _r10Ihr.allMatches(text)) {
      out.add(
        Violation(
          10,
          kStringsFile,
          line,
          'Sie-Form „${m.group(0)}“ in „$text“',
        ),
      );
    }
    for (final RegExpMatch m in _r10Sie.allMatches(text)) {
      final String before = text.substring(0, m.start).trimRight();
      final bool sentenceStart =
          before.isEmpty || '.!?\n„"»('.contains(before[before.length - 1]);
      if (!sentenceStart) {
        out.add(
          Violation(10, kStringsFile, line, '„Sie“ mitten im Satz in „$text“'),
        );
      } else if (!kSieAllowlist.containsKey(text)) {
        out.add(
          Violation(
            10,
            kStringsFile,
            line,
            '„Sie“ am Satzanfang in „$text“ (mehrdeutig, Allowlist mit Begründung nötig)',
          ),
        );
      }
    }
    for (final RegExpMatch m in _r10Clinical.allMatches(text)) {
      out.add(
        Violation(
          10,
          kStringsFile,
          line,
          'klinischer Begriff „${m.group(0)}“ in „$text“',
        ),
      );
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// Regel 11: kein Abschneiden (B-9)
// ---------------------------------------------------------------------------

final RegExp _r11Overflow = RegExp(
  r'\bTextOverflow\s*\.\s*(?:ellipsis|clip|fade)\b',
);
final RegExp _r11FittedBox = RegExp(r'\bFittedBox\s*\(');
final RegExp _r11TextInside = RegExp(r'\b(?:Text|RichText|CuraLabel)\b\s*[.(]');
final RegExp _r11MaxLines = RegExp(r'\bmaxLines\s*:');

List<Violation> checkRule11(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  _stripped(files).forEach((String path, String code) {
    _addMatches(
      out,
      11,
      path,
      code,
      _r11Overflow,
      'Text wird abgeschnitten (B-9: umbrechen)',
    );
    for (final Call c in findCalls(code, _r11FittedBox)) {
      if (_r11TextInside.hasMatch(code.substring(c.open, c.close))) {
        out.add(
          Violation(11, path, lineOf(code, c.start), 'FittedBox um Text (B-9)'),
        );
      }
    }
    if (!kMaxLinesAllowlist.contains(path)) {
      _addMatches(
        out,
        11,
        path,
        code,
        _r11MaxLines,
        'maxLines nur in der Allowlist',
      );
    }
  });
  return out;
}

// ---------------------------------------------------------------------------
// Regel 12: Ergänzung 2 (UI-72, UI-78, UI-85)
// ---------------------------------------------------------------------------

const Set<String> _r12Files = <String>{
  'manny_chat_button.dart',
  'messages_button.dart',
  'action_cluster.dart',
  'example_notice.dart',
};
final RegExp _r12Accent = RegExp(r'\baccent(?:Hi|Soft)?\b');
final RegExp _r12Blur = RegExp(r'\b(?:CuraBlur|BackdropFilter)\b');
final RegExp _r12Glow = RegExp(r'\bGlowBackground\b');
final RegExp _r12Status = RegExp(
  r'\b(?:statusError|catFrist|tri(?:Gruen|Gelb|Orange|Rot))\b',
);
final RegExp _r12Mic = RegExp(r'\bIcons\s*\.\s*mic\w*');
final RegExp _r12Menu = RegExp(
  r'\bIcons\s*\.\s*(?:menu|more_vert|more_horiz|more)\w*',
);
final RegExp _r12NewChat = RegExp(
  r'Neuer\s+Chat|neuerChat|newChat',
  caseSensitive: false,
);

bool _inChatGroup(String path) {
  final String name = baseName(path);
  return _r12Files.contains(name) ||
      inDir(path, 'lib/ui/chat') ||
      inDir(path, 'lib/ui/messages') ||
      (inDir(path, 'lib/ui') &&
          name.startsWith('chat_') &&
          name.endsWith('.dart'));
}

List<Violation> checkRule12(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  _stripped(files).forEach((String path, String code) {
    if (!_inChatGroup(path)) return;
    _addMatches(
      out,
      12,
      path,
      code,
      _r12Accent,
      'kein Akzent in Chat-/Button-Gruppen-Bausteinen',
    );
    _addMatches(
      out,
      12,
      path,
      code,
      _r12Blur,
      'kein Blur in Chat-/Button-Gruppen-Bausteinen',
    );
    if (baseName(path) != 'chat_screen_scaffold.dart') {
      _addMatches(
        out,
        12,
        path,
        code,
        _r12Glow,
        'GlowBackground nur im ChatScreenScaffold',
      );
    }
    _addMatches(
      out,
      12,
      path,
      code,
      _r12Status,
      'kein Status-Token in Chat-/Button-Gruppen-Bausteinen',
    );
    if (inDir(path, 'lib/ui/chat')) {
      _addMatches(out, 12, path, code, _r12Mic, 'kein Mikrofon im Manny-Chat');
      _addMatches(
        out,
        12,
        path,
        code,
        _r12Menu,
        'kein Menü-Icon im Manny-Chat',
      );
      _addMatches(
        out,
        12,
        path,
        code,
        _r12NewChat,
        'kein „Neuer Chat“ im Manny-Chat',
      );
    }
  });
  return out;
}

// ---------------------------------------------------------------------------
// Regel 13: Kommentar „Unverbindlicher Platzhalter, keine Spec“ (UI-84)
// ---------------------------------------------------------------------------

const String kPlaceholderComment = 'Unverbindlicher Platzhalter, keine Spec';

List<Violation> checkRule13(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  files.forEach((String path, String raw) {
    if (!inDir(path, 'lib/ui/messages')) return;
    final String first = raw.trimLeft().split('\n').first;
    if (!first.startsWith('//') || !first.contains(kPlaceholderComment)) {
      out.add(
        Violation(
          13,
          path,
          1,
          'Datei beginnt nicht mit dem Kommentar „$kPlaceholderComment“',
        ),
      );
    }
  });
  return out;
}

// ---------------------------------------------------------------------------
// Regel 14: Nachrichten teilen kein Datenmodell mit dem Manny-Chat (UI-83)
// ---------------------------------------------------------------------------

final RegExp _r14 = RegExp(
  r'chat_model\.dart|manny_chat_source\.dart|\b(?:ChatMessage|MannyChatSource|ExampleMannyChatSource)\b',
);

List<Violation> checkRule14(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  _stripped(files).forEach((String path, String code) {
    if (!inDir(path, 'lib/ui/messages')) return;
    _addMatches(
      out,
      14,
      path,
      code,
      _r14,
      'Nachrichten-Platzhalter teilen kein Datenmodell mit dem Manny-Chat',
    );
  });
  return out;
}

// ---------------------------------------------------------------------------
// Regel 15: Chat und Nachrichten ohne Speicher und ohne mutierende Controller-Methoden
// ---------------------------------------------------------------------------

const List<String> kMutatingControllerMethods = <String>[
  'setName',
  'setStep',
  'acceptConsent',
  'selectInjury',
  'setInjuryOther',
  'setInjuryDate',
  'completeOnboarding',
  'selectTime',
  'swapExercise',
  'removeExercise',
  'undoRemove',
  'addCustomExercise',
  'logTraining',
  'undoTraining',
  'checkDayChange',
  'onPathVisible',
  'markBubbleShown',
  'consumeCelebration',
  'updateProfile',
  'deleteAll',
  'retryLoad',
  'load',
  'completeDeletion',
  'clearStartNotice',
];
final RegExp _r15Storage = RegExp(
  r'\b(?:StateStore|PrefsStateStore|SharedPreferences\w*|DataEraser)\b',
);
final RegExp _r15Mutator = RegExp(
  '\\.\\s*(?:${kMutatingControllerMethods.join('|')})\\b',
);

List<Violation> checkRule15(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  _stripped(files).forEach((String path, String code) {
    final bool inScope =
        inDir(path, 'lib/ui/chat') ||
        inDir(path, 'lib/ui/messages') ||
        path == 'lib/data/manny_chat_source.dart';
    if (!inScope) return;
    _addMatches(
      out,
      15,
      path,
      code,
      _r15Storage,
      'Chat/Nachrichten speichern nichts',
    );
    _addMatches(
      out,
      15,
      path,
      code,
      _r15Mutator,
      'mutierende AppController-Methode im Chat/in Nachrichten',
    );
  });
  return out;
}

// ---------------------------------------------------------------------------
// Regel 16: ChatComposer nur deaktiviert
// ---------------------------------------------------------------------------

final RegExp _r16 = RegExp(
  r'\b(?:TextField|TextFormField|CupertinoTextField|EditableText|TextEditingController|canSend|onSend|onSubmitted|onChanged|isActive|active|variant)\b',
);

List<Violation> checkRule16(Map<String, String> files) {
  final List<Violation> out = <Violation>[];
  _stripped(files).forEach((String path, String code) {
    if (baseName(path) != 'chat_composer.dart') return;
    _addMatches(
      out,
      16,
      path,
      code,
      _r16,
      'ChatComposer ist nur deaktiviert: keine Eingabe, keine aktive Variante',
    );
  });
  return out;
}

/// Alle Regeln in Reihenfolge.
final Map<int, List<Violation> Function(Map<String, String>)> kRules =
    <int, List<Violation> Function(Map<String, String>)>{
      1: checkRule1,
      2: checkRule2,
      3: checkRule3,
      4: checkRule4,
      5: checkRule5,
      6: checkRule6,
      7: checkRule7,
      8: checkRule8,
      9: checkRule9,
      10: checkRule10,
      11: checkRule11,
      12: checkRule12,
      13: checkRule13,
      14: checkRule14,
      15: checkRule15,
      16: checkRule16,
    };
