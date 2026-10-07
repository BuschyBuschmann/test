// Werkzeuge für die statischen Code-Regeln (Plan 12.3, Test C): Kommentare
// entfernen, Aufrufe samt Argumenten finden, Zeilennummern. Kein vollständiger
// Dart-Parser, sondern ein verlässlicher Scanner für Klammern und Strings.

/// Ein Regelverstoß mit Fundstelle.
class Violation {
  const Violation(this.rule, this.path, this.line, this.message);

  final int rule;
  final String path;
  final int line;
  final String message;

  @override
  String toString() => 'Regel $rule: $path:$line: $message';
}

/// Ein Argument eines Aufrufs; `name` ist null bei positionalen Argumenten.
class Arg {
  const Arg(this.name, this.value, this.offset);

  final String? name;
  final String value;
  final int offset;
}

/// Ein gefundener Aufruf `Name(args…)`.
class Call {
  const Call(this.name, this.start, this.open, this.close, this.args);

  final String name;

  /// Offset des Namens.
  final int start;

  /// Offsets der öffnenden und schließenden Klammer.
  final int open;
  final int close;
  final List<Arg> args;

  Arg? named(String argName) {
    for (final Arg a in args) {
      if (a.name == argName) return a;
    }
    return null;
  }

  Arg? get firstPositional {
    for (final Arg a in args) {
      if (a.name == null) return a;
    }
    return null;
  }
}

int lineOf(String src, int offset) {
  int line = 1;
  final int end = offset < src.length ? offset : src.length;
  for (int i = 0; i < end; i++) {
    if (src.codeUnitAt(i) == 0x0A) line++;
  }
  return line;
}

bool _isQuote(int c) => c == 0x27 || c == 0x22; // ' "

/// Liefert den Offset hinter dem String-Literal, das bei `i` beginnt (`i`
/// zeigt auf ein Anführungszeichen oder ein `r` vor einem Anführungszeichen).
/// Berücksichtigt Raw-Strings, Triple-Quotes, Escapes und `${…}`.
int skipString(String s, int i) {
  bool raw = false;
  if (s.codeUnitAt(i) == 0x72 /* r */ ) {
    raw = true;
    i++;
  }
  final int quote = s.codeUnitAt(i);
  final bool triple =
      i + 2 < s.length &&
      s.codeUnitAt(i + 1) == quote &&
      s.codeUnitAt(i + 2) == quote;
  i += triple ? 3 : 1;
  while (i < s.length) {
    final int c = s.codeUnitAt(i);
    if (!raw && c == 0x5C /* \ */ ) {
      i += 2;
      continue;
    }
    if (!raw &&
        c == 0x24 /* $ */ &&
        i + 1 < s.length &&
        s.codeUnitAt(i + 1) == 0x7B) {
      i = _skipInterpolation(s, i + 2);
      continue;
    }
    if (c == quote) {
      if (!triple) return i + 1;
      if (i + 2 < s.length &&
          s.codeUnitAt(i + 1) == quote &&
          s.codeUnitAt(i + 2) == quote) {
        return i + 3;
      }
    }
    if (!triple && c == 0x0A) return i; // unterminiert: am Zeilenende stoppen
    i++;
  }
  return s.length;
}

/// `i` steht hinter `${`; liefert den Offset hinter der schließenden `}`.
int _skipInterpolation(String s, int i) {
  int depth = 1;
  while (i < s.length && depth > 0) {
    final int c = s.codeUnitAt(i);
    if (_startsString(s, i)) {
      i = skipString(s, i);
      continue;
    }
    if (c == 0x7B) depth++;
    if (c == 0x7D) depth--;
    i++;
  }
  return i;
}

bool _startsString(String s, int i) {
  final int c = s.codeUnitAt(i);
  if (_isQuote(c)) return true;
  if (c == 0x72 /* r */ &&
      i + 1 < s.length &&
      _isQuote(s.codeUnitAt(i + 1)) &&
      (i == 0 || !_isIdentChar(s.codeUnitAt(i - 1)))) {
    return true;
  }
  return false;
}

bool _isIdentChar(int c) =>
    (c >= 0x30 && c <= 0x39) ||
    (c >= 0x41 && c <= 0x5A) ||
    (c >= 0x61 && c <= 0x7A) ||
    c == 0x5F ||
    c == 0x24;

/// Ersetzt `//`- und `/* */`-Kommentare durch Leerzeichen (Zeilenumbrüche
/// bleiben, Offsets bleiben gültig). String-Literale bleiben unverändert.
String stripComments(String src) {
  final StringBuffer out = StringBuffer();
  int i = 0;
  while (i < src.length) {
    final int c = src.codeUnitAt(i);
    if (_startsString(src, i)) {
      final int end = skipString(src, i);
      out.write(src.substring(i, end));
      i = end;
      continue;
    }
    if (c == 0x2F && i + 1 < src.length) {
      final int n = src.codeUnitAt(i + 1);
      if (n == 0x2F) {
        while (i < src.length && src.codeUnitAt(i) != 0x0A) {
          out.write(' ');
          i++;
        }
        continue;
      }
      if (n == 0x2A) {
        int depth = 1;
        out.write('  ');
        i += 2;
        while (i < src.length && depth > 0) {
          if (src.startsWith('/*', i)) {
            depth++;
            out.write('  ');
            i += 2;
          } else if (src.startsWith('*/', i)) {
            depth--;
            out.write('  ');
            i += 2;
          } else {
            out.write(src.codeUnitAt(i) == 0x0A ? '\n' : ' ');
            i++;
          }
        }
        continue;
      }
    }
    out.writeCharCode(c);
    i++;
  }
  return out.toString();
}

final RegExp _argName = RegExp(r'^\s*([A-Za-z_]\w*)\s*:(?!:)');

/// Findet alle Aufrufe, deren Name (inklusive öffnender Klammer) zu `pattern`
/// passt. `pattern` muss mit `\(` enden, z. B. `r'\bText\s*\('`.
List<Call> findCalls(String code, RegExp pattern) {
  final List<Call> calls = <Call>[];
  for (final RegExpMatch m in pattern.allMatches(code)) {
    final int open = m.end - 1;
    final Call? call = _parseCall(code, m.start, open, m.group(0)!);
    if (call != null) calls.add(call);
  }
  return calls;
}

Call? _parseCall(String code, int start, int open, String matched) {
  int depth = 0;
  int i = open;
  int argStart = open + 1;
  final List<Arg> args = <Arg>[];
  void pushArg(int end) {
    final String text = code.substring(argStart, end);
    if (text.trim().isEmpty) return;
    final RegExpMatch? nm = _argName.firstMatch(text);
    args.add(
      Arg(nm?.group(1), nm == null ? text : text.substring(nm.end), argStart),
    );
  }

  while (i < code.length) {
    final int c = code.codeUnitAt(i);
    if (_startsString(code, i)) {
      i = skipString(code, i);
      continue;
    }
    if (c == 0x28 || c == 0x5B || c == 0x7B) depth++;
    if (c == 0x29 || c == 0x5D || c == 0x7D) {
      depth--;
      if (depth == 0) {
        pushArg(i);
        return Call(
          matched.replaceAll(RegExp(r'\s*\($'), ''),
          start,
          open,
          i,
          args,
        );
      }
    }
    if (c == 0x2C && depth == 1) {
      pushArg(i);
      argStart = i + 1;
    }
    i++;
  }
  return null;
}

/// Enthält der Ausdruck ein String-Literal?
bool hasStringLiteral(String expr) {
  for (int i = 0; i < expr.length; i++) {
    if (_startsString(expr, i)) return true;
  }
  return false;
}

/// Inhalte aller String-Literale (ohne Anführungszeichen), mit Offset.
List<(String, int)> extractStringLiterals(String code) {
  final List<(String, int)> out = <(String, int)>[];
  int i = 0;
  while (i < code.length) {
    if (_startsString(code, i)) {
      final int end = skipString(code, i);
      final String lit = code.substring(i, end);
      final int q = lit.indexOf(RegExp('[\'"]'));
      final bool triple =
          lit.length >= q + 6 &&
          lit.codeUnitAt(q + 1) == lit.codeUnitAt(q) &&
          lit.codeUnitAt(q + 2) == lit.codeUnitAt(q);
      final int skip = triple ? 3 : 1;
      final int bodyEnd = lit.length - skip >= q + skip
          ? lit.length - skip
          : lit.length;
      out.add((lit.substring(q + skip, bodyEnd), i));
      i = end;
      continue;
    }
    i++;
  }
  return out;
}

/// Zahl-Literale (ohne Hex), die ungleich 0 sind.
final RegExp _numberLiteral = RegExp(
  r'(?<![\w.$])(?:\d+\.\d+|\d+|\.\d+)(?![\w])',
);

List<String> nonZeroNumbers(String expr) {
  final List<String> out = <String>[];
  for (final RegExpMatch m in _numberLiteral.allMatches(expr)) {
    final double? v = double.tryParse(m.group(0)!);
    if (v != null && v != 0) out.add(m.group(0)!);
  }
  return out;
}

/// Pfadhelfer: normalisiert auf `lib/…` mit `/`.
String normalizePath(String p) => p.replaceAll('\\', '/');

String baseName(String path) => path.substring(path.lastIndexOf('/') + 1);

bool inDir(String path, String dir) =>
    path.startsWith(dir.endsWith('/') ? dir : '$dir/');

/// Ende des Ausdrucks, der bei `from` beginnt: Offset des ersten Kommas auf
/// Tiefe 0 oder der schließenden Klammer des umgebenden Aufrufs.
int expressionEnd(String code, int from) {
  int depth = 0;
  int i = from;
  while (i < code.length) {
    final int c = code.codeUnitAt(i);
    if (_startsString(code, i)) {
      i = skipString(code, i);
      continue;
    }
    if (c == 0x28 || c == 0x5B || c == 0x7B) depth++;
    if (c == 0x29 || c == 0x5D || c == 0x7D) {
      if (depth == 0) return i;
      depth--;
    }
    if (c == 0x2C && depth == 0) return i;
    if (c == 0x3B && depth == 0) return i;
    i++;
  }
  return code.length;
}
