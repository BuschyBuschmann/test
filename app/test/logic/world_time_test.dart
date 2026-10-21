// V2-6: Zeitregel der Welt (Design-Brief v2, 3.1): Morgen 5–10, Mittag 10–17,
// Abend 17–21, Nacht 21–5 Uhr; an jeder Grenze T wird linear über 30 Minuten
// von T − 15 min bis T + 15 min überblendet. Reine Funktion, feste Uhr.
import 'package:curaone/logic/world_time.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_clock.dart';

DateTime _at(int h, int m, [int s = 0]) => DateTime(2026, 10, 14, h, m, s);

WorldMix _mix(int h, int m) => worldMixAt(_at(h, m));

void _pure(int h, int m, WorldPhase phase) {
  final WorldMix mix = _mix(h, m);
  expect(mix.isPure, isTrue, reason: '$h:$m $mix');
  expect(mix.from, phase, reason: '$h:$m');
  expect(mix.dominant, phase);
}

void main() {
  group('V2-6: Testzeiten', () {
    test('04:59: Nacht → Morgen, kurz vor der Mitte (14/30)', () {
      final WorldMix mix = _mix(4, 59);
      expect(mix.from, WorldPhase.night);
      expect(mix.to, WorldPhase.morning);
      expect(mix.t, closeTo(14 / 30, 1e-9));
      expect(mix.isPure, isFalse);
    });

    test('05:00: Mitte der Überblendung Nacht → Morgen (50:50)', () {
      final WorldMix mix = _mix(5, 0);
      expect(mix.from, WorldPhase.night);
      expect(mix.to, WorldPhase.morning);
      expect(mix.t, closeTo(0.5, 1e-12));
    });

    test(
      '05:15: reiner Morgen (Fensterende)',
      () => _pure(5, 15, WorldPhase.morning),
    );
    test('09:44: reiner Morgen', () => _pure(9, 44, WorldPhase.morning));
    test('09:45: reiner Morgen (Fensteranfang, Anteil 0)', () {
      final WorldMix mix = _mix(9, 45);
      expect(mix, const WorldMix.pure(WorldPhase.morning));
      expect(mix.t, 0);
    });

    test('10:00: 50:50 Morgen → Mittag', () {
      final WorldMix mix = _mix(10, 0);
      expect(mix.from, WorldPhase.morning);
      expect(mix.to, WorldPhase.midday);
      expect(mix.t, closeTo(0.5, 1e-12));
    });

    test(
      '10:15: reiner Mittag (Fensterende)',
      () => _pure(10, 15, WorldPhase.midday),
    );
    test('16:44: reiner Mittag', () => _pure(16, 44, WorldPhase.midday));

    test('17:00: 50:50 Mittag → Abend', () {
      final WorldMix mix = _mix(17, 0);
      expect(mix.from, WorldPhase.midday);
      expect(mix.to, WorldPhase.evening);
      expect(mix.t, closeTo(0.5, 1e-12));
    });

    test(
      '20:45: reiner Abend (Fensteranfang)',
      () => _pure(20, 45, WorldPhase.evening),
    );

    test('21:00: 50:50 Abend → Nacht', () {
      final WorldMix mix = _mix(21, 0);
      expect(mix.from, WorldPhase.evening);
      expect(mix.to, WorldPhase.night);
      expect(mix.t, closeTo(0.5, 1e-12));
    });

    test(
      '21:15: reine Nacht (Fensterende)',
      () => _pure(21, 15, WorldPhase.night),
    );
  });

  group('Reine Phasen außerhalb der Fenster', () {
    test('Tagesverlauf: Mitte jeder Phase', () {
      _pure(0, 0, WorldPhase.night);
      _pure(3, 30, WorldPhase.night);
      _pure(7, 30, WorldPhase.morning);
      _pure(13, 0, WorldPhase.midday);
      _pure(19, 0, WorldPhase.evening);
      _pure(23, 59, WorldPhase.night);
    });

    test('Mitternacht ist keine Grenze: kein Fenster um 0 Uhr', () {
      for (final (int, int) hm in <(int, int)>[
        (23, 45),
        (23, 59),
        (0, 0),
        (0, 15),
        (1, 0),
      ]) {
        _pure(hm.$1, hm.$2, WorldPhase.night);
      }
    });
  });

  group('Überblendung ist linear und stetig', () {
    test(
      'Anteil wächst über das ganze Tagesraster nie rückwärts je Grenze',
      () {
        for (final int hour in kWorldPhaseStartHour.values) {
          double previous = -1;
          final DateTime start = DateTime(
            2026,
            10,
            14,
            hour,
          ).subtract(const Duration(minutes: 20));
          for (int i = 0; i <= 40; i++) {
            final WorldMix mix = worldMixAt(start.add(Duration(minutes: i)));
            // Außerhalb des Fensters: vor T−15 reine frühere Phase (t = 0),
            // nach T+15 reine spätere (Anteil 1 entspricht reiner Phase `to`).
            final double share = mix.isPure ? (i < 20 ? 0 : 1) : mix.t;
            expect(
              share,
              greaterThanOrEqualTo(previous),
              reason: '$hour Uhr +$i',
            );
            previous = share;
          }
        }
      },
    );

    test('Minute für Minute: t = (Minute − (T − 15)) / 30', () {
      for (int i = 0; i < 30; i++) {
        final DateTime time = DateTime(
          2026,
          10,
          14,
          9,
          45,
        ).add(Duration(minutes: i));
        final WorldMix mix = worldMixAt(time);
        if (i == 0) {
          expect(mix.isPure, isTrue);
        } else {
          expect(mix.from, WorldPhase.morning);
          expect(mix.to, WorldPhase.midday);
          expect(mix.t, closeTo(i / 30, 1e-9), reason: '$time');
        }
      }
    });

    test('Sekunden zählen mit (stetiger Verlauf)', () {
      final WorldMix a = worldMixAt(_at(10, 0, 0));
      final WorldMix b = worldMixAt(_at(10, 0, 30));
      expect(b.t, greaterThan(a.t));
      expect(b.t - a.t, closeTo(0.5 / 30, 1e-9));
    });
  });

  group('Auswahl „Welt“ und Uhr', () {
    test('fester Look wird nie überblendet (auch mitten im Fenster)', () {
      for (final WorldChoice choice in WorldChoice.values) {
        final WorldMix mix = resolveWorld(choice, _at(10, 0));
        if (choice == WorldChoice.automatic) {
          expect(mix.isPure, isFalse);
        } else {
          expect(mix.isPure, isTrue);
          expect(mix.from, choice.fixedPhase);
        }
      }
    });

    test('Namen für den Speicher und Rückfall auf Automatisch', () {
      for (final WorldChoice c in WorldChoice.values) {
        expect(WorldChoice.fromJsonName(c.jsonName), c);
      }
      expect(WorldChoice.fromJsonName('nachmittag'), WorldChoice.automatic);
      expect(WorldChoice.fromJsonName(null), WorldChoice.automatic);
      expect(WorldChoice.fromJsonName(3), WorldChoice.automatic);
    });

    test('WorldClock liest nur die übergebene (feste) Uhr', () {
      final FakeClock clock = FakeClock(_at(16, 44));
      final WorldClock world = WorldClock(clock.call);
      expect(
        world.mixFor(WorldChoice.automatic),
        const WorldMix.pure(WorldPhase.midday),
      );
      clock.set(_at(17, 0));
      expect(world.mixFor(WorldChoice.automatic).t, closeTo(0.5, 1e-12));
      expect(
        world.mixFor(WorldChoice.night),
        const WorldMix.pure(WorldPhase.night),
      );
    });

    test('Phasenreihenfolge und Startstunden (Brief 3.1)', () {
      expect(kWorldPhaseOrder, <WorldPhase>[
        WorldPhase.morning,
        WorldPhase.midday,
        WorldPhase.evening,
        WorldPhase.night,
      ]);
      expect(kWorldPhaseStartHour.values.toList(), <int>[5, 10, 17, 21]);
      expect(kWorldBlendWindow, const Duration(minutes: 30));
    });

    test('Mischung hat Gleichheit und Beschreibung', () {
      expect(
        const WorldMix(WorldPhase.night, WorldPhase.morning, 0.5),
        const WorldMix(WorldPhase.night, WorldPhase.morning, 0.5),
      );
      expect(
        const WorldMix.pure(WorldPhase.night).toString(),
        contains('night'),
      );
    });
  });
}
