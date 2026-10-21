// WorldBackground (Design-Brief v2, 4, 3.1, 3.5; V2-2, V2-7, V2-8, V2-12,
// V2-14): eine gecachte Ebene, Zeitregel, Einstellung „Welt“, Thema unabhängig
// von der Welt, Transparenz reduzieren, kein Timer bei reduzierter Bewegung.
import 'package:curaone/app.dart';
import 'package:curaone/logic/display_settings.dart';
import 'package:curaone/logic/world_time.dart';
import 'package:curaone/state/display_controller.dart';
import 'package:curaone/state/display_scope.dart';
import 'package:curaone/state/world_scope.dart';
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/world_painter.dart';
import 'package:curaone/theme/world_tokens.dart';
import 'package:curaone/ui/components/world_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_clock.dart';
import '../support/pump_app.dart';
import '../support/backdrops.dart';

WorldPainter _painter(WidgetTester tester) {
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((CustomPaint p) => p.painter)
      .whereType<WorldPainter>()
      .single;
}

/// Baut `DisplayScope` → `MaterialApp` → `WorldHost` → `CuraThemeSelector` → Welt
/// wie die App.
Widget _app(
  DisplayController display, {
  bool reduceMotion = false,
  Brightness platform = Brightness.light,
  Widget? extra,
}) {
  return DisplayScope(
    controller: display,
    child: MaterialApp(
      locale: const Locale('de'),
      supportedLocales: const <Locale>[Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext context, Widget? app) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
            platformBrightness: platform,
          ),
          child: WorldHost(child: CuraThemeSelector(child: app!)),
        );
      },
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            const Positioned.fill(child: WorldBackground()),
            ?extra,
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('ohne Scope: Mittag, eine RepaintBoundary, ohne Semantik', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const Stack(
        children: <Widget>[Positioned.fill(child: WorldBackground())],
      ),
    );
    final WorldPainter p = _painter(tester);
    expect(p.palette, WorldPalette.midday);
    expect(p.decor, isTrue);
    expect(p.calm, isFalse);
    expect(
      find.ancestor(
        of: find.byWidget(
          tester
              .widgetList<CustomPaint>(find.byType(CustomPaint))
              .firstWhere((CustomPaint c) => c.painter is WorldPainter),
        ),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byType(WorldBackground),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
    expect(activeBackdrops(), findsNothing);
  });

  testWidgets('ruhige Welt (Physio) wird durchgereicht', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const Stack(
        children: <Widget>[Positioned.fill(child: WorldBackground(calm: true))],
      ),
    );
    expect(_painter(tester).calm, isTrue);
  });

  testWidgets('V2-12: Hoher Kontrast/Transparenz reduzieren: Welt ohne Dekor', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      const Stack(
        children: <Widget>[Positioned.fill(child: WorldBackground())],
      ),
      highContrast: true,
    );
    expect(_painter(tester).decor, isFalse);
  });

  group('Zeitregel mit fester Uhr', () {
    testWidgets('Automatisch: Phase nach Uhr, Minuten-Timer rechnet neu', (
      WidgetTester tester,
    ) async {
      setViewport(tester, Viewports.phone);
      final FakeClock clock = FakeClock(DateTime(2026, 10, 14, 9, 40));
      final DisplayController d = DisplayController(
        worldClock: WorldClock(clock.call),
      );
      await tester.pumpWidget(_app(d));
      await tester.pump();
      expect(_painter(tester).palette, WorldPalette.morning);

      // 10:00: Mitte der Überblendung Morgen → Mittag.
      clock.set(DateTime(2026, 10, 14, 10, 0));
      await tester.pump(const Duration(minutes: 1));
      expect(
        _painter(tester).palette,
        WorldPalette.forMix(
          const WorldMix(WorldPhase.morning, WorldPhase.midday, 0.5),
        ),
      );

      // 10:30: reiner Mittag.
      clock.set(DateTime(2026, 10, 14, 10, 30));
      await tester.pump(const Duration(minutes: 1));
      expect(_painter(tester).palette, WorldPalette.midday);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('fester Look: keine Überblendung, Timer ruht', (
      WidgetTester tester,
    ) async {
      setViewport(tester, Viewports.phone);
      final FakeClock clock = FakeClock(DateTime(2026, 10, 14, 10, 0));
      final DisplayController d = DisplayController(
        worldClock: WorldClock(clock.call),
        initial: const DisplaySettings(world: WorldChoice.evening),
      );
      await tester.pumpWidget(_app(d));
      await tester.pump();
      expect(_painter(tester).palette, WorldPalette.evening);
      clock.set(DateTime(2026, 10, 14, 3, 0));
      await tester.pump(const Duration(minutes: 5));
      expect(_painter(tester).palette, WorldPalette.evening);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('V2-7: Einstellung „Welt“ wirkt sofort', (
      WidgetTester tester,
    ) async {
      setViewport(tester, Viewports.phone);
      final DisplayController d = DisplayController(
        worldClock: WorldClock(FakeClock(DateTime(2026, 10, 14, 13)).call),
      );
      await tester.pumpWidget(_app(d));
      await tester.pump();
      expect(_painter(tester).palette, WorldPalette.midday);
      for (final (WorldChoice, WorldPalette) c in <(WorldChoice, WorldPalette)>[
        (WorldChoice.night, WorldPalette.night),
        (WorldChoice.morning, WorldPalette.morning),
        (WorldChoice.evening, WorldPalette.evening),
        (WorldChoice.midday, WorldPalette.midday),
        (WorldChoice.automatic, WorldPalette.midday),
      ]) {
        d.setWorld(c.$1);
        await tester.pump();
        expect(_painter(tester).palette, c.$2, reason: c.$1.name);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Bewegung reduzieren: kein Timer, Welt springt beim Öffnen', (
      WidgetTester tester,
    ) async {
      setViewport(tester, Viewports.phone);
      final FakeClock clock = FakeClock(DateTime(2026, 10, 14, 13));
      final DisplayController d = DisplayController(
        worldClock: WorldClock(clock.call),
      );
      await tester.pumpWidget(_app(d, reduceMotion: true));
      await tester.pump();
      expect(_painter(tester).palette, WorldPalette.midday);
      // Ohne Timer läuft nach einer Minute nichts: kein ausstehender Timer.
      clock.set(DateTime(2026, 10, 14, 22));
      await tester.pump(const Duration(minutes: 3));
      expect(_painter(tester).palette, WorldPalette.midday);
      expect(tester.binding.transientCallbackCount, 0);
      // Beim Öffnen eines (neuen) Screens wird neu gerechnet: ein neues
      // WorldBackground ruft `refresh`.
      await tester.pumpWidget(
        _app(
          d,
          reduceMotion: true,
          extra: const Positioned.fill(
            child: IgnorePointer(child: WorldBackground(calm: true)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      final Iterable<WorldPainter> painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((CustomPaint p) => p.painter)
          .whereType<WorldPainter>();
      expect(painters.length, 2);
      for (final WorldPainter p in painters) {
        expect(p.palette, WorldPalette.night);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Rückkehr in den Vordergrund rechnet neu', (
      WidgetTester tester,
    ) async {
      setViewport(tester, Viewports.phone);
      final FakeClock clock = FakeClock(DateTime(2026, 10, 14, 13));
      final DisplayController d = DisplayController(
        worldClock: WorldClock(clock.call),
      );
      await tester.pumpWidget(_app(d, reduceMotion: true));
      await tester.pump();
      clock.set(DateTime(2026, 10, 14, 19));
      for (final AppLifecycleState s in <AppLifecycleState>[
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(s);
      }
      await tester.pump();
      expect(_painter(tester).palette, WorldPalette.evening);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('V2-8: Welt und Thema sind unabhängig', () {
    CuraColors colorsOf(WidgetTester tester) =>
        CuraColors.of(tester.element(find.byType(WorldBackground)));

    testWidgets('Welt Nacht mit Thema Hell: helle Karten (Weiß 92 %)', (
      WidgetTester tester,
    ) async {
      setViewport(tester, Viewports.phone);
      final DisplayController d = DisplayController(
        initial: const DisplaySettings(
          world: WorldChoice.night,
          theme: ThemeChoice.light,
        ),
      );
      await tester.pumpWidget(_app(d, platform: Brightness.dark));
      await tester.pump();
      expect(_painter(tester).palette, WorldPalette.night);
      final CuraColors c = colorsOf(tester);
      expect(c.isDark, isFalse);
      expect(c.card.withValues(alpha: 1).toARGB32(), 0xFFFFFFFF);
      expect(c.card.a, closeTo(0.92, 1e-9));
      // Kopf-Karte und Leiste dunkel: aus der Welt, nicht aus dem Thema.
      expect(WorldPalette.night.headerTint.a, closeTo(0.58, 1e-9));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Welt Mittag mit Thema Dunkel: dunkle Karten', (
      WidgetTester tester,
    ) async {
      setViewport(tester, Viewports.phone);
      final DisplayController d = DisplayController(
        initial: const DisplaySettings(
          world: WorldChoice.midday,
          theme: ThemeChoice.dark,
        ),
      );
      await tester.pumpWidget(_app(d));
      await tester.pump();
      expect(_painter(tester).palette, WorldPalette.midday);
      final CuraColors c = colorsOf(tester);
      expect(c.isDark, isTrue);
      expect(c.card.withValues(alpha: 1).toARGB32(), 0xFF241D18);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Thema „System“ folgt der Plattformhelligkeit', (
      WidgetTester tester,
    ) async {
      setViewport(tester, Viewports.phone);
      final DisplayController d = DisplayController();
      await tester.pumpWidget(_app(d, platform: Brightness.dark));
      await tester.pump();
      expect(colorsOf(tester).isDark, isTrue);
      await tester.pumpWidget(_app(d, platform: Brightness.light));
      await tester.pump();
      expect(colorsOf(tester).isDark, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Transparenz reduzieren (App-Schalter) → opake Variante', (
      WidgetTester tester,
    ) async {
      setViewport(tester, Viewports.phone);
      final DisplayController d = DisplayController();
      await tester.pumpWidget(_app(d));
      await tester.pump();
      expect(colorsOf(tester).highContrast, isFalse);
      expect(_painter(tester).decor, isTrue);
      d.setReduceTransparency(true);
      await tester.pump();
      expect(colorsOf(tester).highContrast, isTrue);
      expect(_painter(tester).decor, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
