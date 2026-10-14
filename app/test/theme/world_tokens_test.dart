// V2-2: Jede der 4 Welten rendert mit den Tokens aus 3.1; Stichprobe der
// Himmelsfarbe oben und der Bodenfarbe unten entspricht der Tabelle.
import 'dart:ui';

import 'package:curaone/logic/world_time.dart';
import 'package:curaone/theme/world_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

int _c(int rgb) => 0xFF000000 | rgb;

void _rgb(Color c, int rgb, [String? reason]) =>
    expect(c.withValues(alpha: 1).toARGB32(), _c(rgb), reason: reason);

void _alpha(Color c, int rgb, double a, [String? reason]) {
  _rgb(c, rgb, reason);
  expect(c.a, closeTo(a, 1e-9), reason: reason);
}

void main() {
  group('Token-Dump je Welt (Brief 3.1)', () {
    test('Morgen', () {
      final WorldPalette p = WorldPalette.morning;
      final List<SkyStop> sky = worldSkySources[WorldPhase.morning]!;
      expect(sky.map((SkyStop s) => s.position), <double>[
        0,
        0.34,
        0.58,
        0.80,
        1,
      ]);
      expect(
        sky.map((SkyStop s) => s.color.toARGB32()),
        <int>[0xBCD2EA, 0xF3C6B6, 0xF7DFCB, 0xF6EDE0, 0xF7F2EB].map(_c),
      );
      _rgb(p.hillFar, 0xB4AFC6);
      _rgb(p.hillMid, 0xD2C0BC);
      _rgb(p.hillNear, 0xF6EDE2);
      expect((p.lightX, p.lightY), (0.24, 0.28));
      _rgb(p.lightColor, 0xFFE9C2);
      expect(p.starAmount, 0);
      _rgb(p.floor, 0xF7F2EB);
      _alpha(p.headerTint, 0x2A211C, 0.66);
      _alpha(p.navRest, 0xFFFFFF, 0.35);
      _alpha(p.navActive, 0xFFFFFF, 0.78);
      _rgb(p.navInk, 0x211B16);
      _alpha(p.chip, 0xFFFFFF, 0.72);
      _rgb(p.chipText, 0x211B16);
    });

    test('Mittag', () {
      final WorldPalette p = WorldPalette.midday;
      final List<SkyStop> sky = worldSkySources[WorldPhase.midday]!;
      expect(sky.map((SkyStop s) => s.position), <double>[
        0,
        0.36,
        0.60,
        0.82,
        1,
      ]);
      expect(
        sky.map((SkyStop s) => s.color.toARGB32()),
        <int>[0x8EC3EC, 0xCDE5F4, 0xE9F2EE, 0xF6F3EA, 0xF7F2EB].map(_c),
      );
      _rgb(p.hillFar, 0x9DB6C6);
      _rgb(p.hillMid, 0xC4D3D1);
      _rgb(p.hillNear, 0xF1F0E8);
      expect((p.lightX, p.lightY), (0.70, 0.09));
      _rgb(p.lightColor, 0xFFFFFF);
      _rgb(p.floor, 0xF7F2EB);
      _alpha(p.headerTint, 0x23303A, 0.66);
      _alpha(p.chip, 0xFFFFFF, 0.74);
    });

    test('Abend', () {
      final WorldPalette p = WorldPalette.evening;
      final List<SkyStop> sky = worldSkySources[WorldPhase.evening]!;
      expect(sky.map((SkyStop s) => s.position), <double>[
        0,
        0.16,
        0.36,
        0.58,
        0.80,
        1,
      ]);
      expect(
        sky.map((SkyStop s) => s.color.toARGB32()),
        <int>[
          0xF2B58C,
          0xE8A68A,
          0xC8B1A8,
          0xDCCFC4,
          0xF1E8DD,
          0xF7F2EB,
        ].map(_c),
      );
      _rgb(p.hillFar, 0xA99AA6);
      _rgb(p.hillMid, 0x9C8E9B);
      _rgb(p.hillNear, 0xF4ECE2);
      expect((p.lightX, p.lightY), (0.78, 0.20));
      _rgb(p.lightColor, 0xFFE9C8);
      _rgb(p.floor, 0xF7F2EB);
      _alpha(p.headerTint, 0x281E18, 0.66);
      _alpha(p.chip, 0xFFFFFF, 0.72);
    });

    test('Nacht', () {
      final WorldPalette p = WorldPalette.night;
      final List<SkyStop> sky = worldSkySources[WorldPhase.night]!;
      expect(sky.map((SkyStop s) => s.position), <double>[
        0,
        0.30,
        0.55,
        0.78,
        1,
      ]);
      expect(
        sky.map((SkyStop s) => s.color.toARGB32()),
        <int>[0x141A33, 0x2B2547, 0x4A3548, 0x2B2230, 0x1C1620].map(_c),
      );
      _rgb(p.hillFar, 0x4A4468);
      _rgb(p.hillMid, 0x3A3354);
      _rgb(p.hillNear, 0x2E2634);
      expect((p.lightX, p.lightY), (0.78, 0.18));
      _rgb(p.lightColor, 0xFFF3D6);
      expect(p.moonAmount, 1);
      expect(p.starAmount, 1);
      expect(WorldPalette.nightStarCount, 46);
      _rgb(p.floor, 0x1C1620);
      _alpha(p.headerTint, 0x0F0B1A, 0.58);
      _alpha(p.navRest, 0x1A1320, 0.45);
      _alpha(p.navActive, 0x1A1320, 0.82);
      _rgb(p.navInk, 0xF5EFE8);
      _alpha(p.chip, 0x1E1626, 0.72);
      _rgb(p.chipText, 0xFFFFFF);
    });
  });

  test('V2-2 Stichprobe: Himmel oben und Boden unten je Welt', () {
    final Map<WorldPhase, (int, int)> expected = <WorldPhase, (int, int)>{
      WorldPhase.morning: (0xBCD2EA, 0xF7F2EB),
      WorldPhase.midday: (0x8EC3EC, 0xF7F2EB),
      WorldPhase.evening: (0xF2B58C, 0xF7F2EB),
      WorldPhase.night: (0x141A33, 0x1C1620),
    };
    for (final WorldPhase phase in WorldPhase.values) {
      final WorldPalette p = WorldPalette.of(phase);
      final (int top, int bottom) = expected[phase]!;
      _rgb(p.skyTop, top, '${phase.name} oben');
      _rgb(p.skyBottom, bottom, '${phase.name} unten');
      expect(p.skyBottom, p.floor, reason: 'unten = world-floor');
    }
  });

  group('Himmelsraster', () {
    test('Raster enthält alle Halte; reine Phasen werden exakt abgebildet', () {
      for (final MapEntry<WorldPhase, List<SkyStop>> e
          in worldSkySources.entries) {
        final WorldPalette p = WorldPalette.of(e.key);
        expect(p.sky.length, kSkyGrid.length);
        for (final SkyStop s in e.value) {
          final int i = kSkyGrid.indexOf(s.position);
          expect(i, isNonNegative, reason: '${e.key} ${s.position}');
          expect(p.sky[i], s.color, reason: '${e.key} ${s.position}');
        }
      }
      expect(kSkyGrid.first, 0);
      expect(kSkyGrid.last, 1);
      expect(kSkyGrid, <double>[...kSkyGrid]..sort(), reason: 'aufsteigend');
    });

    test('Zwischen zwei Halten linear interpoliert (wie CSS)', () {
      final List<SkyStop> s = worldSkySources[WorldPhase.midday]!;
      final Color mid = skyColorAt(s, 0.18);
      expect(mid, Color.lerp(s[0].color, s[1].color, 0.5));
    });
  });

  group('Mischung', () {
    test('reine Mischung liefert die Palette selbst', () {
      expect(
        WorldPalette.forMix(const WorldMix.pure(WorldPhase.evening)),
        same(WorldPalette.evening),
      );
      expect(
        WorldPalette.forMix(
          const WorldMix(WorldPhase.night, WorldPhase.morning, 0),
        ),
        same(WorldPalette.night),
      );
      expect(
        WorldPalette.forMix(
          const WorldMix(WorldPhase.night, WorldPhase.morning, 1),
        ),
        same(WorldPalette.morning),
      );
    });

    test('50:50 liegt in der Mitte aller Tokens, Sonne wechselt weich', () {
      final WorldPalette a = WorldPalette.morning;
      final WorldPalette b = WorldPalette.midday;
      final WorldPalette m = WorldPalette.forMix(
        const WorldMix(WorldPhase.morning, WorldPhase.midday, 0.5),
      );
      expect(m.skyTop, Color.lerp(a.skyTop, b.skyTop, 0.5));
      expect(m.hillMid, Color.lerp(a.hillMid, b.hillMid, 0.5));
      expect(m.floor, Color.lerp(a.floor, b.floor, 0.5));
      expect(m.headerTint, Color.lerp(a.headerTint, b.headerTint, 0.5));
      expect(m.mist, Color.lerp(a.mist, b.mist, 0.5));
      expect(m.lightX, closeTo((0.24 + 0.70) / 2, 1e-9));
      expect(m.lightY, closeTo((0.28 + 0.09) / 2, 1e-9));
    });

    test('Nacht → Morgen: Sterne blenden aus, Mond wird Sonne', () {
      final WorldPalette m = WorldPalette.forMix(
        const WorldMix(WorldPhase.night, WorldPhase.morning, 0.5),
      );
      expect(m.starAmount, closeTo(0.5, 1e-9));
      expect(m.moonAmount, closeTo(0.5, 1e-9));
    });

    test('Beschriftungs-Sätze (Chip, Leiste) springen in der Mitte', () {
      final WorldPalette a = WorldPalette.evening;
      final WorldPalette b = WorldPalette.night;
      WorldPalette at(double t) => WorldPalette.forMix(
        WorldMix(WorldPhase.evening, WorldPhase.night, t),
      );
      for (final double t in <double>[0.01, 0.25, 0.4999]) {
        final WorldPalette p = at(t);
        expect(p.chip, a.chip, reason: 't=$t');
        expect(p.chipText, a.chipText);
        expect(p.navRest, a.navRest);
        expect(p.navActive, a.navActive);
        expect(p.navInk, a.navInk);
      }
      for (final double t in <double>[0.5, 0.75, 0.99]) {
        final WorldPalette p = at(t);
        expect(p.chip, b.chip, reason: 't=$t');
        expect(p.chipText, b.chipText);
        expect(p.navRest, b.navRest);
        expect(p.navActive, b.navActive);
        expect(p.navInk, b.navInk);
      }
      // Alles andere mischt stetig, auch die Kopf-Karte.
      expect(at(0.25).headerTint, Color.lerp(a.headerTint, b.headerTint, 0.25));
      expect(at(0.25).skyTop, Color.lerp(a.skyTop, b.skyTop, 0.25));
    });

    test('Palette hat Gleichheit nach Werten', () {
      final WorldPalette a = WorldPalette.forMix(
        const WorldMix(WorldPhase.night, WorldPhase.morning, 0.3),
      );
      final WorldPalette b = WorldPalette.forMix(
        const WorldMix(WorldPhase.night, WorldPhase.morning, 0.3),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(WorldPalette.night));
    });
  });
}
