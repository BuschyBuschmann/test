// Prüfumgebung (U2p): URL-Parameter, Overrides im `MaterialApp.builder`
// (HC, RM, Skalierung; Override **und** Systemsignal, Plan 8.1), Registry,
// Konsistenz mit `tool/screens/scenarios.json`, Trennung von `main.dart`.
import 'dart:convert';
import 'dart:io';

import 'package:curaone/dev/preview_app.dart';
import 'package:curaone/dev/scenarios.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

CuraColors _colors(WidgetTester tester) =>
    CuraColors.of(tester.element(find.byType(Scaffold).first));

CuraMotion _motion(WidgetTester tester) =>
    CuraMotion.of(tester.element(find.byType(Scaffold).first));

void main() {
  group('PreviewConfig.fromQuery (Plan 12.5)', () {
    test('liest alle Parameter', () {
      final PreviewConfig c = PreviewConfig.fromQuery(<String, String>{
        'scenario': 'cmp-forms',
        'now': '2026-10-07T12:00:00',
        'scale': '2.0',
        'hc': '1',
        'rm': '1',
        'a11y': '1',
        'dumpText': '1',
      });
      expect(c.scenarioId, 'cmp-forms');
      expect(c.now, DateTime(2026, 10, 7, 12));
      expect(c.textScale, 2);
      expect(c.highContrast, isTrue);
      expect(c.reduceMotion, isTrue);
      expect(c.semantics, isTrue);
      expect(c.dumpText, isTrue);
    });

    test('Standardwerte und ungültige Eingaben', () {
      final PreviewConfig c = PreviewConfig.fromQuery(<String, String>{
        'scale': 'abc',
        'now': 'kein Datum',
        'hc': '0',
      });
      expect(c.scenarioId, isNull);
      expect(c.now, isNull);
      expect(c.textScale, 1);
      expect(c.highContrast, isFalse);
      expect(c.reduceMotion, isFalse);
    });
  });

  group('Overrides im MaterialApp.builder', () {
    Future<void> pump(WidgetTester tester, PreviewConfig config) async {
      setViewport(tester, Viewports.phone);
      await tester.pumpWidget(PreviewApp(config: config));
      await tester.pumpAndSettle();
    }

    testWidgets('Normal: dunkler Token-Satz, keine reduzierte Bewegung', (
      WidgetTester tester,
    ) async {
      await pump(tester, const PreviewConfig(scenarioId: 'cmp-buttons'));
      expect(_colors(tester).highContrast, isFalse);
      expect(_motion(tester).reduced, isFalse);
      final MediaQueryData mq = MediaQuery.of(
        tester.element(find.byType(Scaffold).first),
      );
      expect(mq.textScaler.scale(10), 10);
    });

    testWidgets('hc=1 wirkt über den Override (Wechsel nach pumpAndSettle)', (
      WidgetTester tester,
    ) async {
      await pump(tester, const PreviewConfig(scenarioId: 'cmp-buttons'));
      expect(_colors(tester).highContrast, isFalse);
      await tester.pumpWidget(
        const PreviewApp(
          config: PreviewConfig(scenarioId: 'cmp-buttons', highContrast: true),
        ),
      );
      // CuraColors.lerp/AnimatedTheme 200 ms: erst nach dem Einschwingen gültig.
      await tester.pumpAndSettle();
      expect(_colors(tester).highContrast, isTrue);
    });

    testWidgets('Systemsignal Hoher Kontrast kommt an (Produktionsweg)', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(highContrast: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pump(tester, const PreviewConfig(scenarioId: 'cmp-buttons'));
      expect(_colors(tester).highContrast, isTrue);
    });

    testWidgets('rm=1: Override setzt reduziert und disableAnimations', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const PreviewConfig(scenarioId: 'cmp-buttons', reduceMotion: true),
      );
      expect(_motion(tester).reduced, isTrue);
      expect(
        MediaQuery.disableAnimationsOf(
          tester.element(find.byType(Scaffold).first),
        ),
        isTrue,
      );
    });

    testWidgets(
      'Systemsignale reduceMotion und disableAnimations (Produktionsweg)',
      (WidgetTester tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await pump(tester, const PreviewConfig(scenarioId: 'cmp-buttons'));
        expect(_motion(tester).reduced, isTrue);
      },
    );

    testWidgets('scale=2 skaliert die Schrift linear', (
      WidgetTester tester,
    ) async {
      await pump(
        tester,
        const PreviewConfig(scenarioId: 'cmp-buttons', textScale: 2),
      );
      final MediaQueryData mq = MediaQuery.of(
        tester.element(find.byType(Scaffold).first),
      );
      expect(mq.textScaler.scale(10), 20);
    });

    testWidgets('unbekanntes Szenario zeigt die Liste', (
      WidgetTester tester,
    ) async {
      await pump(tester, const PreviewConfig(scenarioId: 'gibt-es-nicht'));
      for (final Scenario s in kScenarios) {
        expect(find.text(s.id), findsOneWidget);
      }
    });
  });

  group('Registry', () {
    test('Kennungen sind eindeutig und URL-tauglich', () {
      final List<String> ids = kScenarios.map((Scenario s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final String id in ids) {
        expect(id, matches(RegExp(r'^[a-z0-9-]+$')));
        expect(scenarioById(id), isNotNull);
      }
      expect(scenarioById('gibt-es-nicht'), isNull);
    });

    testWidgets('jedes Szenario baut ohne Exception (390x844, normal)', (
      WidgetTester tester,
    ) async {
      for (final Scenario s in kScenarios) {
        setViewport(tester, Viewports.phone);
        await tester.pumpWidget(
          PreviewApp(config: PreviewConfig(scenarioId: s.id)),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: s.id);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });

  group('tool/screens/scenarios.json', () {
    final Map<String, dynamic> json = jsonDecode(
      File('tool/screens/scenarios.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final Set<String> registry = kScenarios.map((Scenario s) => s.id).toSet();

    Set<String> ids(Object? list) => <String>{
      for (final dynamic e in list! as List<dynamic>) e as String,
    };

    test('jedes Szenario der Registry steht in der Liste und umgekehrt', () {
      expect(ids(json['scenarios']), registry);
    });

    test('Tablet-, Querformat- und Simulationslisten sind Teilmengen', () {
      final Map<String, dynamic> tablet =
          json['tablet'] as Map<String, dynamic>;
      final Map<String, dynamic> land =
          json['landscape'] as Map<String, dynamic>;
      final Map<String, dynamic> sim =
          json['simulations'] as Map<String, dynamic>;
      final Map<String, dynamic> blind =
          sim['colorBlind'] as Map<String, dynamic>;
      expect(registry.containsAll(ids(tablet['scenarios'])), isTrue);
      expect(registry.containsAll(ids(land['scenarios'])), isTrue);
      expect(registry.containsAll(ids(blind['scenarios'])), isTrue);
      expect(
        registry,
        contains((json['pipette'] as Map<String, dynamic>)['scenario']),
      );
    });

    test('Szenarien mit festem Skalierungswert stehen in fixedScale', () {
      final Set<String> fromRegistry = <String>{
        for (final Scenario s in kScenarios)
          if (s.fixedTextScale != null) s.id,
      };
      expect(ids(json['fixedScale']), fromRegistry);
    });

    test('Tablet-Szenarien entsprechen dem Flag der Registry', () {
      final Set<String> fromRegistry = <String>{
        for (final Scenario s in kScenarios)
          if (s.tablet) s.id,
      };
      final Map<String, dynamic> tablet =
          json['tablet'] as Map<String, dynamic>;
      expect(ids(tablet['scenarios']), fromRegistry);
    });
  });

  test('main.dart und lib/ (außer lib/dev und main_preview) importieren lib/dev nicht', () {
    final List<String> offenders = <String>[];
    for (final FileSystemEntity e in Directory(
      'lib',
    ).listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final String path = e.path.replaceAll('\\', '/');
      if (path.startsWith('lib/dev/') || path == 'lib/main_preview.dart') {
        continue;
      }
      if (RegExp(r'''(?:import|export|part)\s+['"][^'"]*(dev/|main_preview)''')
          .hasMatch(e.readAsStringSync())) {
        offenders.add(path);
      }
    }
    expect(offenders, isEmpty);
  });
}
