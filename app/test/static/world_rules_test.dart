// Statische Prüfungen zu Welt und Glow (Design-Brief v2, 2, 3.1, 4, 9; Plan
// 3.2): Glow entfällt vollständig, `WorldBackground` ersetzt ihn an allen
// Verwendungsstellen, es gibt genau eine Weltfunktion mit Uhr, und die Welt
// wird nur über das Token-Verzeichnis gefärbt.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'code_scan.dart';

Map<String, String> _lib() {
  final Map<String, String> out = <String, String>{};
  for (final FileSystemEntity e in Directory('lib').listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.dart')) {
      out[e.path.replaceAll('\\', '/')] = stripComments(e.readAsStringSync());
    }
  }
  return out;
}

void main() {
  final Map<String, String> lib = _lib();

  test('Glow entfällt: keine Dateien und keine Bezeichner mehr', () {
    expect(File('lib/theme/glow.dart').existsSync(), isFalse);
    expect(
      File('lib/ui/components/glow_background.dart').existsSync(),
      isFalse,
    );
    expect(File('test/theme/glow_test.dart').existsSync(), isFalse);
    expect(File('test/golden/goldens/glow.png').existsSync(), isFalse);
    final RegExp glow = RegExp(
      r'\b(?:GlowBackground|GlowPainter|GlowGeometry|GlowSpot|GlowTokens|'
      r'GlowBackdrop|glowEmber|glowEnabled|maxGlowAlphaFor|backgroundWithGlow|'
      r'glassWithGlow)\b',
    );
    final List<String> hits = <String>[
      for (final MapEntry<String, String> e in lib.entries)
        if (glow.hasMatch(e.value)) e.key,
    ];
    expect(hits, isEmpty, reason: hits.join(', '));
  });

  test('WorldBackground ersetzt GlowBackground an den Verwendungsstellen', () {
    expect(
      lib['lib/ui/components/screen_frame.dart'],
      contains('WorldBackground()'),
    );
    expect(lib['lib/dev/scenarios.dart'], contains('WorldBackground()'));
    final List<String> users = <String>[
      for (final MapEntry<String, String> e in lib.entries)
        if (e.value.contains('WorldBackground()')) e.key,
    ];
    expect(
      users,
      containsAll(<String>[
        'lib/ui/components/screen_frame.dart',
        'lib/dev/scenarios.dart',
      ]),
    );
  });

  test('Welt: gecachte Ebene und ohne Semantik (V2-14, Brief 4)', () {
    final String bg = lib['lib/ui/components/world_background.dart']!;
    expect(bg, contains('RepaintBoundary'));
    expect(bg, contains('ExcludeSemantics'));
    expect(bg, contains('IgnorePointer'));
  });

  test('genau eine Weltfunktion, Uhr nur in world_time.dart definiert', () {
    final List<String> clockDefs = <String>[
      for (final MapEntry<String, String> e in lib.entries)
        if (RegExp(r'\bclass\s+WorldClock\b').hasMatch(e.value)) e.key,
    ];
    expect(clockDefs, <String>['lib/logic/world_time.dart']);
    final List<String> mixFns = <String>[
      for (final MapEntry<String, String> e in lib.entries)
        if (RegExp(r'\bWorldMix\s+worldMixAt\b').hasMatch(e.value)) e.key,
    ];
    expect(mixFns, <String>['lib/logic/world_time.dart']);
  });

  test('Weltfunktion ohne Flutter-Import (KONVENTIONEN Regel 3)', () {
    final String src = lib['lib/logic/world_time.dart']!;
    expect(src, isNot(contains('package:flutter')));
    expect(src, isNot(contains('dart:ui')));
  });

  test('Welt-Farben stehen nur in lib/theme/ (V2-1)', () {
    final RegExp hex = RegExp(r'0x[0-9A-Fa-f]{8}');
    final List<String> hits = <String>[
      for (final MapEntry<String, String> e in lib.entries)
        if (!e.key.startsWith('lib/theme/') && hex.hasMatch(e.value)) e.key,
    ];
    expect(hits, isEmpty, reason: hits.join(', '));
  });
}
