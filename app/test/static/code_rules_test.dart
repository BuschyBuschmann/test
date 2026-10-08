// Test C (Plan 12.3): statische Code-Regeln 1–16 gegen `lib/`.
// Anfangs läuft er gegen eine fast leere UI; damit die Regeln trotzdem
// belastbar sind, prüft ein Selbsttest je Regel Beispielcode (Verstoß wird
// erkannt, erlaubte Form nicht).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'code_rules.dart';
import 'code_scan.dart';

/// Liest alle `.dart`-Dateien unter `lib/` (Pfade relativ zum Paketstamm).
Map<String, String> readLib() {
  final Map<String, String> files = <String, String>{};
  for (final FileSystemEntity e in Directory('lib').listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) {
      files[normalizePath(e.path)] = e.readAsStringSync();
    }
  }
  return files;
}

void expectNoViolations(List<Violation> v) {
  expect(v, isEmpty, reason: v.join('\n'));
}

void main() {
  final Map<String, String> lib = readLib();

  test('Scanner sieht lib/ (mindestens die Theme-Dateien)', () {
    expect(lib.keys, contains('lib/theme/tokens.dart'));
    expect(lib.keys, contains('lib/main.dart'));
  });

  group('lib/ verletzt keine Regel', () {
    for (final MapEntry<int, List<Violation> Function(Map<String, String>)> r
        in kRules.entries) {
      test('Regel ${r.key}', () => expectNoViolations(r.value(lib)));
    }
  });

  group('Scanner', () {
    test('Kommentare entfernen, Strings und Zeilen erhalten', () {
      const String src =
          "final a = 'http://x'; // Color(0xFF)\n/* Colors.red */ final b = \"//\";\n";
      final String out = stripComments(src);
      expect(out, contains("'http://x'"));
      expect(out, contains('"//"'));
      expect(out.contains('Color(0xFF)'), isFalse);
      expect(out.contains('Colors.red'), isFalse);
      expect(out.length, src.length);
      expect(out.split('\n').length, src.split('\n').length);
    });

    test('Interpolation und Triple-Quotes', () {
      const String src =
          "final a = 'x \${b ? 'y' : \"z\"} // kein Kommentar';\nfinal c = '''\n// auch keiner\n''';\n";
      final String out = stripComments(src);
      expect(out, src);
    });

    test('Aufrufe und Argumente (positional/benannt, verschachtelt)', () {
      const String code = "Foo(1, bar: Baz(2, 3), c: 'a,b)', d)";
      final List<Call> calls = findCalls(code, RegExp(r'\bFoo\s*\('));
      expect(calls.length, 1);
      final List<Arg> args = calls.single.args;
      expect(args.length, 4);
      expect(args[0].name, isNull);
      expect(args[1].name, 'bar');
      expect(args[1].value.trim(), 'Baz(2, 3)');
      expect(args[2].name, 'c');
      expect(args[3].value.trim(), 'd');
    });

    test('Zahl-Literale: Hex und Exponent zählen, Null nicht (MINOR-2)', () {
      expect(nonZeroNumbers('0xFF112233'), <String>['0xFF112233']);
      expect(nonZeroNumbers('0x10'), <String>['0x10']);
      expect(nonZeroNumbers('1e1'), <String>['1e1']);
      expect(nonZeroNumbers('2.5E-3'), <String>['2.5E-3']);
      expect(nonZeroNumbers('0x0'), isEmpty);
      expect(nonZeroNumbers('0e0'), isEmpty);
      expect(nonZeroNumbers('0'), isEmpty);
      expect(nonZeroNumbers('0.0'), isEmpty);
      expect(nonZeroNumbers('x2 + CuraSpace.s4 * 3'), <String>['3']);
      expect(nonZeroNumbers('12.5, 8'), <String>['12.5', '8']);
    });
  });

  group('Selbsttest je Regel', () {
    test('Regel 1: Farben und fontSize nur in lib/theme/', () {
      expect(
        checkRule1(<String, String>{
          'lib/ui/a.dart': 'final c = Color(0xFF000000);',
        }),
        hasLength(1),
      );
      expect(
        checkRule1(<String, String>{
          'lib/ui/a.dart': 'final c = Color.fromARGB(1, 2, 3, 4);',
        }),
        hasLength(1),
      );
      expect(
        checkRule1(<String, String>{'lib/ui/a.dart': 'final c = Colors.red;'}),
        hasLength(1),
      );
      expect(
        checkRule1(<String, String>{
          'lib/ui/a.dart': 'final s = TextStyle(fontSize: 12);',
        }),
        hasLength(1),
      );
      // erlaubt
      expect(
        checkRule1(<String, String>{
          'lib/ui/a.dart':
              'final c = Colors.transparent; final d = CuraColors.dark;',
        }),
        isEmpty,
      );
      expect(
        checkRule1(<String, String>{
          'lib/theme/t.dart': 'final c = Color(0xFF000000); fontSize: 12',
        }),
        isEmpty,
      );
      expect(
        checkRule1(<String, String>{
          'lib/ui/a.dart': '// Color(0xFF000000) und fontSize: 12 im Kommentar',
        }),
        isEmpty,
      );
    });

    test('Regel 2: Zahl-Literale in Layout-Konstruktoren', () {
      Map<String, String> f(String code) => <String, String>{
        'lib/ui/a.dart': code,
      };
      expect(checkRule2(f('final p = EdgeInsets.all(16);')), hasLength(1));
      expect(
        checkRule2(
          f(
            'final p = EdgeInsets.symmetric(horizontal: 8, vertical: CuraSpace.s2);',
          ),
        ),
        hasLength(1),
      );
      expect(
        checkRule2(f('final w = SizedBox(width: 12, child: x);')),
        hasLength(1),
      );
      expect(
        checkRule2(f('final r = BorderRadius.circular(24);')),
        hasLength(1),
      );
      expect(
        checkRule2(f('final d = Duration(milliseconds: 200);')),
        hasLength(1),
      );
      expect(checkRule2(f('Positioned(left: 4, child: x)')), hasLength(1));
      expect(checkRule2(f('Container(height: 40)')), hasLength(1));
      expect(checkRule2(f('BoxConstraints(maxWidth: 560)')), hasLength(1));
      expect(checkRule2(f('BoxShadow(blurRadius: 8)')), hasLength(1));
      expect(checkRule2(f('Border.all(width: 2)')), hasLength(1));
      expect(checkRule2(f('c.withValues(alpha: 0.5)')), hasLength(1));
      expect(checkRule2(f('c.withOpacity(0.5)')), hasLength(1));
      // erlaubt: Tokens, Null, EdgeInsets.zero, SizedBox.shrink, andere Argumente
      expect(checkRule2(f('EdgeInsets.all(CuraSpace.s4)')), isEmpty);
      expect(checkRule2(f('EdgeInsets.all(0)')), isEmpty);
      expect(checkRule2(f('EdgeInsets.zero')), isEmpty);
      expect(checkRule2(f('SizedBox.shrink()')), isEmpty);
      expect(
        checkRule2(
          f('SizedBox(key: Key(\'a1\'), width: CuraSize.touchTarget)'),
        ),
        isEmpty,
      );
      expect(checkRule2(f('Duration(seconds: 4)')), isEmpty);
      expect(
        checkRule2(
          f('Positioned(left: CuraSpace.s4, child: Opacity(opacity: 0.5))'),
        ),
        isEmpty,
      );
      // Ausnahmen: lib/theme und manny.dart
      expect(
        checkRule2(<String, String>{'lib/theme/x.dart': 'EdgeInsets.all(16)'}),
        isEmpty,
      );
      expect(
        checkRule2(<String, String>{
          'lib/ui/components/manny.dart': 'BoxConstraints(maxWidth: 560)',
        }),
        isEmpty,
      );
    });

    test('Regel 3: BackdropFilter und CuraBlur an festen Stellen', () {
      expect(
        checkRule3(<String, String>{
          'lib/ui/a.dart': 'BackdropFilter(filter: f)',
        }),
        hasLength(1),
      );
      expect(
        checkRule3(<String, String>{'lib/ui/a.dart': 'CuraBlur(child: x)'}),
        hasLength(1),
      );
      expect(
        checkRule3(<String, String>{
          'lib/ui/components/cura_blur.dart': 'BackdropFilter(filter: f)',
        }),
        isEmpty,
      );
      expect(
        checkRule3(<String, String>{
          'lib/ui/components/floating_nav.dart': 'CuraBlur(child: x)',
        }),
        isEmpty,
      );
      expect(
        checkRule3(<String, String>{
          'lib/ui/components/manny_bubble.dart': 'CuraBlur(child: x)',
        }),
        isEmpty,
      );
      expect(
        checkRule3(<String, String>{
          'lib/ui/routes/cura_sheet_route.dart': 'CuraBlur(child: x)',
        }),
        isEmpty,
      );
      expect(
        checkRule3(<String, String>{
          'lib/ui/components/glass_card.dart': 'CuraBlur(child: x)',
        }),
        hasLength(1),
      );
      expect(
        checkRule3(<String, String>{
          'lib/ui/components/floating_nav.dart': 'BackdropFilter(filter: f)',
        }),
        hasLength(1),
      );
    });

    test('Regel 4: Status-Tokens', () {
      const String errView = 'lib/ui/path/path_error_view.dart';
      // nicht erlaubte Datei
      expect(
        checkRule4(<String, String>{
          'lib/ui/a.dart': 'Icon(color: c.statusError)',
        }),
        hasLength(1),
      );
      // in Allowlist: erlaubt
      expect(
        checkRule4(<String, String>{
          errView: 'Icon(Icons.error, color: c.statusError)',
        }),
        isEmpty,
      );
      // aber nicht in einem Widget mit onPressed/onTap
      expect(
        checkRule4(<String, String>{
          errView: 'PillButton(color: c.statusError, onPressed: retry)',
        }),
        hasLength(1),
      );
      expect(
        checkRule4(<String, String>{
          errView: 'GestureDetector(onTap: f, child: Icon(color: c.triRot))',
        }),
        hasLength(1),
      );
      // nie in PillButton/CuraChip
      expect(
        checkRule4(<String, String>{
          'lib/ui/components/pill_button.dart': 'final c = x.catFrist;',
        }),
        hasLength(1),
      );
      expect(
        checkRule4(<String, String>{
          'lib/ui/components/cura_chip.dart': 'final c = x.triGelb;',
        }),
        hasLength(1),
      );
      // accent/accentHi nicht in Fehler-/Status-Widgets
      expect(
        checkRule4(<String, String>{errView: 'Icon(color: c.accentHi)'}),
        hasLength(1),
      );
      expect(
        checkRule4(<String, String>{errView: 'Icon(color: c.accent)'}),
        hasLength(1),
      );
      // lib/theme ausgenommen (Definition der Tokens)
      expect(
        checkRule4(<String, String>{
          'lib/theme/cura_colors.dart': 'statusError: Palette.statusError',
        }),
        isEmpty,
      );
    });

    test('Regel 5: accent nie als Textfarbe', () {
      Map<String, String> f(String code, [String p = 'lib/ui/a.dart']) =>
          <String, String>{p: code};
      expect(
        checkRule5(f('Text(x, style: TextStyle(color: c.accent))')),
        hasLength(1),
      );
      expect(
        checkRule5(f('final s = base.copyWith(color: colors.accent);')),
        hasLength(1),
      );
      expect(
        checkRule5(
          f(
            'TextButton.styleFrom(foregroundColor: colors.accent)',
            'lib/theme/cura_theme.dart',
          ),
        ),
        hasLength(1),
      );
      // erlaubt
      expect(checkRule5(f('TextStyle(color: c.accentHi)')), isEmpty);
      expect(checkRule5(f('TextStyle(color: c.text1)')), isEmpty);
      expect(
        checkRule5(f('BoxDecoration(color: c.accent)')),
        isEmpty,
      ); // Fläche
      expect(
        checkRule5(f('Icon(Icons.flag, color: c.accent)')),
        isEmpty,
      ); // Symbol
      expect(
        checkRule5(f('TextButton.styleFrom(foregroundColor: colors.accentHi)')),
        isEmpty,
      );
    });

    test('Regel 6: genau eine Klassendefinition der geteilten Widgets', () {
      expect(
        checkRule6(<String, String>{
          'lib/ui/components/choice_card.dart': 'class ChoiceCard {}',
        }),
        isEmpty,
      );
      expect(
        checkRule6(<String, String>{
          'lib/ui/components/choice_card.dart': 'class ChoiceCard {}',
          'lib/ui/data_sheet/x.dart': 'class _ChoiceCard {}',
        }),
        hasLength(1),
      );
      expect(
        checkRule6(<String, String>{
          'lib/ui/a.dart': 'class ChoiceCardState {}',
        }),
        isEmpty,
      );
      // beide Orte vorhanden: beide müssen die Klasse nutzen
      final Map<String, String> both = <String, String>{
        'lib/ui/components/date_card.dart': 'class DateCard {}',
        'lib/ui/onboarding/step4.dart': 'DateCard()',
        'lib/ui/data_sheet/sheet.dart': 'Text(x)',
      };
      expect(checkRule6(both), hasLength(1));
      both['lib/ui/data_sheet/sheet.dart'] = 'DateCard()';
      expect(checkRule6(both), isEmpty);
    });

    test('Regel 7: lib/logic und lib/l10n ohne Flutter und dart:ui', () {
      expect(
        checkRule7(<String, String>{
          'lib/logic/a.dart': "import 'package:flutter/material.dart';",
        }),
        hasLength(1),
      );
      expect(
        checkRule7(<String, String>{'lib/logic/a.dart': "import 'dart:ui';"}),
        hasLength(1),
      );
      expect(
        checkRule7(<String, String>{
          'lib/l10n/strings_de.dart':
              "import 'package:flutter_localizations/x.dart';",
        }),
        hasLength(1),
      );
      expect(
        checkRule7(<String, String>{
          'lib/logic/a.dart': "export 'package:flutter/foundation.dart';",
        }),
        hasLength(1),
      );
      expect(
        checkRule7(<String, String>{
          'lib/logic/a.dart': "import 'dart:math'; import 'clock.dart';",
        }),
        isEmpty,
      );
      expect(
        checkRule7(<String, String>{
          'lib/ui/a.dart': "import 'package:flutter/material.dart';",
        }),
        isEmpty,
      );
      expect(
        checkRule7(<String, String>{
          'lib/logic/a.dart': "// import 'package:flutter/material.dart';",
        }),
        isEmpty,
      );
    });

    test('Regel 8: Texte nur aus strings_de.dart', () {
      Map<String, String> f(String code) => <String, String>{
        'lib/ui/a.dart': code,
      };
      expect(checkRule8(f("Text('Hallo')")), hasLength(1));
      expect(checkRule8(f('Text("Hallo")')), hasLength(1));
      expect(
        checkRule8(f("const Text('Hallo \$name', style: s)")),
        hasLength(1),
      );
      expect(
        checkRule8(f("Semantics(label: 'Zurück', child: x)")),
        hasLength(1),
      );
      expect(checkRule8(f("Tooltip(message: 'Info', child: x)")), hasLength(1));
      expect(checkRule8(f("InputDecoration(hintText: 'Name')")), hasLength(1));
      expect(checkRule8(f('InputDecoration(labelText: "Name")')), hasLength(1));
      expect(checkRule8(f("Image(semanticsLabel: 'Bild')")), hasLength(1));
      // erlaubt
      expect(checkRule8(f('Text(S.hello, key: Key(\'k\'))')), isEmpty);
      expect(checkRule8(f('Semantics(label: S.back, child: x)')), isEmpty);
      expect(checkRule8(f('Tooltip(message: S.info, child: x)')), isEmpty);
      expect(checkRule8(f("Semantics(identifier: 'x', child: x)")), isEmpty);
      expect(checkRule8(f("SelectableText('x')")), isEmpty);
      expect(
        checkRule8(<String, String>{
          kStringsFile: "static const a = Text('x');",
        }),
        isEmpty,
      );
    });

    test('Regel 9: keine Animation in glow_background.dart und manny.dart', () {
      for (final String name in <String>[
        'glow_background.dart',
        'manny.dart',
      ]) {
        final String p = 'lib/ui/components/$name';
        expect(
          checkRule9(<String, String>{p: 'late AnimationController c;'}),
          hasLength(1),
        );
        expect(
          checkRule9(<String, String>{
            p: 'class X extends State with SingleTickerProviderStateMixin {}',
          }),
          hasLength(1),
        );
        expect(
          checkRule9(<String, String>{p: 'final t = Ticker(cb);'}),
          hasLength(1),
        );
        expect(
          checkRule9(<String, String>{p: 'CustomPaint(painter: p)'}),
          isEmpty,
        );
      }
      expect(
        checkRule9(<String, String>{
          'lib/ui/components/path_node.dart': 'AnimationController c;',
        }),
        isEmpty,
      );
    });

    test('Regel 10: Ton in strings_de.dart', () {
      Map<String, String> f(String code) => <String, String>{
        kStringsFile: code,
      };
      expect(
        checkRule10(f("static const a = 'Haben Sie Ihre Übung gemacht?';")),
        isNotEmpty,
      );
      expect(
        checkRule10(f("static const a = 'Das ist Ihr Pfad.';")),
        hasLength(1),
      );
      expect(
        checkRule10(f("static const a = 'Sag uns, ob Sie bereit sind.';")),
        hasLength(1),
      ); // mitten im Satz
      expect(
        checkRule10(f("static const a = 'Sie kommt gleich.';")),
        hasLength(1),
      ); // Satzanfang: Allowlist nötig
      expect(
        checkRule10(f("static const a = 'Das ist gut. Sie kommt gleich.';")),
        hasLength(1),
      );
      expect(
        checkRule10(f("static const a = 'Dein Patient wartet.';")),
        hasLength(1),
      );
      expect(
        checkRule10(f("static const a = 'Der Therapieplan steht.';")),
        hasLength(1),
      );
      expect(
        checkRule10(f("static const a = 'Compliance zählt.';")),
        hasLength(1),
      );
      // Stufe 1 (erweitert): verboten
      for (final String w in <String>[
        'Adhärenz',
        'Adhaerenz',
        'Kontraindikation',
        'Behandlungsplan',
        'Klient',
        'Rehabilitand',
        'Pathologie',
        'Anamnese',
      ]) {
        expect(
          checkRule10(f("static const a = 'Das $w zählt.';")),
          hasLength(1),
          reason: w,
        );
      }
      // Stufe 2: Beobachtungsliste, ohne Allowlist-Eintrag Fehler
      for (final String w in <String>[
        'Diagnose',
        'Symptom',
        'Befund',
        'Medikation',
        'Dosierung',
        'Läsion',
        'Ruptur',
      ]) {
        expect(
          checkRule10(f("static const a = 'Die $w zählt.';")),
          hasLength(1),
          reason: w,
        );
      }
      // „Therapie“ allein und Physiotherapie bleiben erlaubt
      expect(
        checkRule10(f("static const a = 'Physiotherapie, Praxis Müller';")),
        isEmpty,
      );
      expect(
        checkRule10(f("static const a = 'Die Therapie läuft.';")),
        isEmpty,
      );
      expect(
        checkRule10(f("static const a = 'Indikation und Proband.';")),
        hasLength(2),
      );
      // erlaubt
      expect(
        checkRule10(
          f(
            "static const a = 'Schön, dass du da bist. Wie geht es dir?'; // Ihre",
          ),
        ),
        isEmpty,
      );
      expect(
        checkRule10(f("static const a = 'Ich sehe sie gleich.';")),
        isEmpty,
      );
      expect(
        checkRule10(<String, String>{'lib/ui/a.dart': "Text('Ihr Patient')"}),
        isEmpty,
      ); // nur strings_de.dart
      expect(checkRule10(<String, String>{}), isEmpty); // Datei fehlt
    });

    test('Regel 11: kein Abschneiden', () {
      Map<String, String> f(String code) => <String, String>{
        'lib/ui/a.dart': code,
      };
      expect(
        checkRule11(f('Text(x, overflow: TextOverflow.ellipsis)')),
        hasLength(1),
      );
      expect(
        checkRule11(f('Text(x, overflow: TextOverflow.clip)')),
        hasLength(1),
      );
      expect(
        checkRule11(f('Text(x, overflow: TextOverflow.fade)')),
        hasLength(1),
      );
      expect(checkRule11(f('FittedBox(child: Text(x))')), hasLength(1));
      expect(checkRule11(f('FittedBox(child: Icon(Icons.add))')), isEmpty);
      expect(checkRule11(f('Text(x, maxLines: 2)')), hasLength(1));
      expect(
        checkRule11(f('Text(x, overflow: TextOverflow.visible)')),
        isEmpty,
      );
    });

    test('Regel 12: Ergänzung 2 (Chat, Button-Gruppe)', () {
      Map<String, String> f(String path, String code) => <String, String>{
        path: code,
      };
      const String cluster = 'lib/ui/components/action_cluster.dart';
      expect(checkRule12(f(cluster, 'c.accent')), hasLength(1));
      expect(checkRule12(f(cluster, 'c.accentHi')), hasLength(1));
      expect(
        checkRule12(
          f('lib/ui/components/manny_chat_button.dart', 'CuraBlur(child: x)'),
        ),
        hasLength(1),
      );
      expect(
        checkRule12(f('lib/ui/components/chat_header.dart', 'c.statusError')),
        hasLength(1),
      );
      expect(
        checkRule12(
          f('lib/ui/components/chat_composer.dart', 'GlowBackground()'),
        ),
        hasLength(1),
      );
      expect(
        checkRule12(
          f('lib/ui/components/chat_screen_scaffold.dart', 'GlowBackground()'),
        ),
        isEmpty,
      );
      expect(
        checkRule12(
          f(
            'lib/ui/chat/manny_chat_screen.dart',
            'Icon(Icons.mic_none_rounded)',
          ),
        ),
        hasLength(1),
      );
      expect(
        checkRule12(
          f('lib/ui/chat/manny_chat_screen.dart', 'Icon(Icons.menu_rounded)'),
        ),
        hasLength(1),
      );
      expect(
        checkRule12(
          f('lib/ui/chat/manny_chat_screen.dart', "final a = 'Neuer Chat';"),
        ),
        hasLength(1),
      );
      // Mikro im Onboarding bleibt erlaubt, außerhalb der Chat-Gruppe
      expect(
        checkRule12(
          f(
            'lib/ui/components/mic_button.dart',
            'Icon(Icons.mic_none_rounded)',
          ),
        ),
        isEmpty,
      );
      expect(
        checkRule12(f('lib/ui/messages/contact_row.dart', 'c.accent')),
        hasLength(1),
      );
      // chat_*.dart außerhalb lib/ui ist keine Chat-Gruppe (z. B. Modell)
      expect(checkRule12(f('lib/logic/chat_model.dart', 'accent')), isEmpty);
      expect(
        checkRule12(
          f('lib/ui/chat/a.dart', 'Icon(Icons.chat_bubble_outline_rounded)'),
        ),
        isEmpty,
      );
    });

    test('Regel 13: Kommentar in lib/ui/messages', () {
      const String p = 'lib/ui/messages/contact_row.dart';
      expect(
        checkRule13(<String, String>{
          p: '// Unverbindlicher Platzhalter, keine Spec\nclass A {}',
        }),
        isEmpty,
      );
      expect(
        checkRule13(<String, String>{
          p: '\n\n// Unverbindlicher Platzhalter, keine Spec (K10)\nclass A {}',
        }),
        isEmpty,
      );
      expect(checkRule13(<String, String>{p: 'class A {}'}), hasLength(1));
      expect(
        checkRule13(<String, String>{
          p: "import 'x.dart';\n// Unverbindlicher Platzhalter, keine Spec",
        }),
        hasLength(1),
      );
      expect(
        checkRule13(<String, String>{'lib/ui/chat/a.dart': 'class A {}'}),
        isEmpty,
      );
    });

    test('Regel 14: Nachrichten teilen kein Datenmodell mit dem Chat', () {
      const String p = 'lib/ui/messages/messages_screen.dart';
      expect(
        checkRule14(<String, String>{
          p: "import '../../logic/chat_model.dart';",
        }),
        hasLength(1),
      );
      expect(
        checkRule14(<String, String>{
          p: "import '../../data/manny_chat_source.dart';",
        }),
        hasLength(1),
      );
      expect(
        checkRule14(<String, String>{p: 'final m = ChatMessage();'}),
        hasLength(1),
      );
      expect(
        checkRule14(<String, String>{p: "import 'example_contacts.dart';"}),
        isEmpty,
      );
      expect(
        checkRule14(<String, String>{
          'lib/ui/chat/a.dart': "import '../../logic/chat_model.dart';",
        }),
        isEmpty,
      );
    });

    test('Regel 15: Chat/Nachrichten ohne Speicher und Mutationen', () {
      const String chat = 'lib/ui/chat/manny_chat_screen.dart';
      expect(
        checkRule15(<String, String>{chat: 'final s = StateStore();'}),
        hasLength(1),
      );
      expect(
        checkRule15(<String, String>{chat: 'SharedPreferencesAsync()'}),
        hasLength(1),
      );
      expect(
        checkRule15(<String, String>{chat: 'PrefsStateStore()'}),
        hasLength(1),
      );
      expect(
        checkRule15(<String, String>{chat: 'AppScope.of(context).deleteAll()'}),
        hasLength(1),
      );
      expect(
        checkRule15(<String, String>{
          'lib/ui/messages/a.dart': 'controller.logTraining(forDay: d)',
        }),
        hasLength(1),
      );
      expect(
        checkRule15(<String, String>{
          'lib/data/manny_chat_source.dart': 'c.setName("x")',
        }),
        hasLength(1),
      );
      expect(
        checkRule15(<String, String>{
          chat: 'final n = AppScope.of(context).state.name;',
        }),
        isEmpty,
      );
      expect(
        checkRule15(<String, String>{'lib/ui/path/a.dart': 'c.logTraining()'}),
        isEmpty,
      );
    });

    test('Regel 16: ChatComposer nur deaktiviert', () {
      const String p = 'lib/ui/components/chat_composer.dart';
      expect(checkRule16(<String, String>{p: 'TextField()'}), hasLength(1));
      expect(checkRule16(<String, String>{p: 'EditableText()'}), hasLength(1));
      expect(
        checkRule16(<String, String>{p: 'final bool canSend;'}),
        hasLength(1),
      );
      expect(
        checkRule16(<String, String>{p: 'final VoidCallback onSend;'}),
        hasLength(1),
      );
      expect(
        checkRule16(<String, String>{p: 'final bool active;'}),
        hasLength(1),
      );
      expect(
        checkRule16(<String, String>{
          p: 'ExcludeFocus(child: Semantics(enabled: false))',
        }),
        isEmpty,
      );
      expect(
        checkRule16(<String, String>{'lib/ui/a.dart': 'TextField()'}),
        isEmpty,
      );
    });
  });
  group('Selbsttest R-U1 MINOR-2: bisher übersehene Muster', () {
    const String u = 'lib/ui/today/a.dart';
    List<Violation> r(int rule, String code, [String path = u]) =>
        kRules[rule]!(<String, String>{path: code});

    test(
      'Regel 8: Text.rich/TextSpan, tooltip, announce, Semantics hint/value',
      () {
        expect(r(8, "Text.rich(TextSpan(text: 'Hallo'))"), isNotEmpty);
        expect(
          r(8, "RichText(text: TextSpan(children: [TextSpan(text: 'x')]))"),
          isNotEmpty,
        );
        expect(r(8, "IconButton(tooltip: 'Schließen')"), isNotEmpty);
        expect(r(8, "SemanticsService.announce('Gespeichert', d)"), isNotEmpty);
        expect(r(8, "Semantics(hint: 'Doppeltippen')"), isNotEmpty);
        expect(r(8, "Semantics(value: '3 von 4')"), isNotEmpty);
        expect(
          r(8, "InputDecoration(helperText: 'x', errorText: \"y\")"),
          hasLength(2),
        );
        // erlaubt
        expect(r(8, 'Text.rich(TextSpan(text: S.title))'), isEmpty);
        expect(r(8, 'IconButton(tooltip: S.close)'), isEmpty);
        expect(r(8, 'SemanticsService.announce(S.saved, d)'), isEmpty);
        expect(r(8, 'Semantics(hint: S.hint)'), isEmpty);
      },
    );

    test('Regel 2: BorderRadius.only, Radius, SizedBox.square, Size, Hex, Exponent', () {
      expect(
        r(2, 'BorderRadius.only(topLeft: Radius.circular(20))'),
        isNotEmpty,
      );
      expect(r(2, 'BorderRadius.all(Radius.circular(8))'), isNotEmpty);
      expect(r(2, 'SizedBox.square(dimension: 8)'), isNotEmpty);
      expect(r(2, 'Size(48, 48)'), isNotEmpty);
      expect(r(2, 'Size.fromHeight(56)'), isNotEmpty);
      expect(r(2, 'EdgeInsets.all(0x10)'), isNotEmpty);
      expect(r(2, 'EdgeInsets.all(1e1)'), isNotEmpty);
      expect(r(2, 'BorderRadius.only(topLeft: CuraRadius.card)'), isEmpty);
      expect(r(2, 'SizedBox.square(dimension: CuraSpace.s2)'), isEmpty);
      expect(r(2, 'Size.zero'), isEmpty);
    });

    test('Regel 5: apply(color:), ButtonStyle(foregroundColor:), Alias', () {
      expect(r(5, 'type.body.apply(color: colors.accent)'), isNotEmpty);
      expect(
        r(
          5,
          'ButtonStyle(foregroundColor: WidgetStatePropertyAll(colors.accent))',
        ),
        isNotEmpty,
      );
      expect(
        r(5, 'final c = colors.accent;\nfinal s = TextStyle(color: c);'),
        isNotEmpty,
      );
      expect(
        r(
          5,
          'final c = colors.accent;\nfinal s = type.body.copyWith(color: c);',
        ),
        isNotEmpty,
      );
      expect(r(5, 'type.body.apply(color: colors.accentHi)'), isEmpty);
      expect(r(5, 'final c = colors.accentHi;\nTextStyle(color: c)'), isEmpty);
      // accent als Fläche/Symbol bleibt erlaubt
      expect(r(5, 'Icon(Icons.add, color: colors.accent)'), isEmpty);
      expect(
        r(5, 'DecoratedBox(decoration: BoxDecoration(color: colors.accent))'),
        isEmpty,
      );
    });

    test('Regel 15: Tear-off und neue Methoden', () {
      const String p = 'lib/ui/chat/a.dart';
      expect(r(15, 'onPressed: c.markBubbleShown', p), isNotEmpty);
      expect(r(15, 'AppScope.of(context).completeDeletion()', p), isNotEmpty);
      expect(r(15, 'c.clearStartNotice();', p), isNotEmpty);
      expect(r(15, 'await c.load();', p), isNotEmpty);
      expect(r(15, 'c..setName(x)', p), isNotEmpty);
      expect(r(15, 'final n = c.state.onboarding.name;', p), isEmpty);
    });

    test('Regel 3: Pfad statt Dateiname', () {
      expect(
        r(3, 'BackdropFilter(filter: f)', 'lib/ui/today/cura_blur.dart'),
        isNotEmpty,
      );
      expect(
        r(3, 'CuraBlur(child: x)', 'lib/ui/today/floating_nav.dart'),
        isNotEmpty,
      );
      expect(r(3, 'ImageFilter.blur(sigmaX: 1)', 'lib/ui/a.dart'), isNotEmpty);
      expect(
        r(3, 'ImageFiltered(imageFilter: f)', 'lib/ui/a.dart'),
        isNotEmpty,
      );
      expect(
        r(3, 'BackdropFilter(filter: f)', 'lib/ui/components/cura_blur.dart'),
        isEmpty,
      );
      expect(
        r(3, 'CuraBlur(child: x)', 'lib/ui/components/floating_nav.dart'),
        isEmpty,
      );
      expect(
        r(3, 'CuraBlur(child: x)', 'lib/ui/routes/cura_sheet_route.dart'),
        isEmpty,
      );
    });

    test('Regel 4: Status-Token über Variable und in Handlungselement', () {
      expect(
        r(4, 'final c = colors.statusError;\nFoo(onPressed: x, color: c)'),
        isNotEmpty,
      );
      expect(
        r(4, 'final c = colors.statusError;\nText(style: TextStyle(color: c))'),
        isNotEmpty,
      );
      expect(r(4, 'final c = colors.text1;'), isEmpty);
    });

    test('Regel 7: transitiver Flutter-Import in lib/logic', () {
      final Map<String, String> files = <String, String>{
        'lib/logic/a.dart': "import '../theme/t.dart';",
        'lib/theme/t.dart': "import 'package:flutter/material.dart';",
      };
      final List<Violation> v = checkRule7(files);
      expect(v, hasLength(1));
      expect(
        v.single.message,
        contains('lib/logic/a.dart -> lib/theme/t.dart'),
      );
      // über zwei Stufen und per package:-Import
      expect(
        checkRule7(<String, String>{
          'lib/logic/a.dart': "import 'package:curaone/data/b.dart';",
          'lib/data/b.dart': "import 'c.dart';",
          'lib/data/c.dart': "import 'dart:ui';",
        }),
        hasLength(1),
      );
      // sauber, Zyklen enden
      expect(
        checkRule7(<String, String>{
          'lib/logic/a.dart': "import 'b.dart';",
          'lib/logic/b.dart': "import 'a.dart'; import 'dart:async';",
        }),
        isEmpty,
      );
    });
  });
}
