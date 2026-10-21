// DisplayController (Plan 3.4, V2-7): wirkt sofort, speichert jede Änderung,
// bleibt nach Neustart erhalten, „Alles löschen“ setzt zurück (B-21).
import 'package:curaone/data/display_store.dart';
import 'package:curaone/data/state_store.dart';
import 'package:curaone/logic/display_settings.dart';
import 'package:curaone/logic/world_time.dart';
import 'package:curaone/state/display_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/fake_clock.dart';

class _FailingDisplayStore implements DisplayStore {
  @override
  Future<DisplaySettings> load() async => throw Exception('Lesen kaputt');

  @override
  Future<void> save(DisplaySettings settings) async =>
      throw Exception('Schreiben kaputt');

  @override
  Future<void> erase() async => throw Exception('Löschen kaputt');
}

void main() {
  test('Änderungen wirken sofort und benachrichtigen', () {
    final DisplayController c = DisplayController();
    int notified = 0;
    c.addListener(() => notified++);
    c.setWorld(WorldChoice.night);
    c.setTheme(ThemeChoice.dark);
    c.setReduceTransparency(true);
    c.setSound(false);
    c.setVibration(false);
    expect(c.settings.world, WorldChoice.night);
    expect(c.settings.theme, ThemeChoice.dark);
    expect(c.settings.reduceTransparency, isTrue);
    expect(c.settings.sound, isFalse);
    expect(c.settings.vibration, isFalse);
    expect(notified, 5);
    c.setWorld(WorldChoice.night); // unverändert
    expect(notified, 5);
  });

  test('worldNow: fester Look ohne Überblendung, Automatisch nach Uhr', () {
    final FakeClock clock = FakeClock(DateTime(2026, 10, 14, 10, 0));
    final DisplayController c = DisplayController(
      worldClock: WorldClock(clock.call),
    );
    expect(c.worldNow().isPure, isFalse);
    expect(c.worldNow().t, closeTo(0.5, 1e-12));
    c.setWorld(WorldChoice.evening);
    expect(c.worldNow(), const WorldMix.pure(WorldPhase.evening));
    c.setWorld(WorldChoice.automatic);
    clock.set(DateTime(2026, 10, 14, 13));
    expect(c.worldNow(), const WorldMix.pure(WorldPhase.midday));
  });

  test('Speichern und Neustart: Einstellungen bleiben erhalten', () async {
    final MemoryDisplayStore store = MemoryDisplayStore();
    final DisplayController first = DisplayController(store: store);
    first
      ..setWorld(WorldChoice.morning)
      ..setTheme(ThemeChoice.light)
      ..setReduceTransparency(true);
    await first.flush();
    final DisplayController second = DisplayController(store: store);
    expect(second.settings, const DisplaySettings());
    await second.load();
    expect(second.settings.world, WorldChoice.morning);
    expect(second.settings.theme, ThemeChoice.light);
    expect(second.settings.reduceTransparency, isTrue);
  });

  test('Schreiben läuft der Reihe nach, der letzte Stand gewinnt', () async {
    final MemoryDisplayStore store = MemoryDisplayStore();
    final DisplayController c = DisplayController(store: store);
    c
      ..setWorld(WorldChoice.night)
      ..setWorld(WorldChoice.morning)
      ..setWorld(WorldChoice.midday);
    await c.flush();
    expect(store.settings.world, WorldChoice.midday);
  });

  test('Fehler beim Lesen oder Schreiben: Einstellung gilt weiter', () async {
    final DisplayController c = DisplayController(
      store: _FailingDisplayStore(),
    );
    await c.load();
    expect(c.settings, const DisplaySettings());
    c.setTheme(ThemeChoice.dark);
    await c.flush();
    expect(c.settings.theme, ThemeChoice.dark);
  });

  test('load benachrichtigt nur bei Abweichung', () async {
    final DisplayController c = DisplayController(store: MemoryDisplayStore());
    int notified = 0;
    c.addListener(() => notified++);
    await c.load();
    expect(notified, 0);
    final DisplayController d = DisplayController(
      store: MemoryDisplayStore(
        const DisplaySettings(world: WorldChoice.night),
      ),
    )..addListener(() => notified++);
    await d.load();
    expect(notified, 1);
  });

  test(
    'eraseAll („Alles löschen“): zurück auf den Standard, Dokument weg',
    () async {
      final MemoryDisplayStore store = MemoryDisplayStore();
      final DisplayController c = DisplayController(store: store)
        ..setWorld(WorldChoice.night)
        ..setReduceTransparency(true);
      await c.flush();
      await c.eraseAll();
      expect(c.settings, const DisplaySettings());
      expect(store.settings, const DisplaySettings());
    },
  );

  group('PrefsDisplayStore (SharedPreferencesAsync, In-Memory-Plattform)', () {
    late SharedPreferencesAsync prefs;

    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      prefs = SharedPreferencesAsync();
    });

    test('Schlüssel curaone.display.v1; Roundtrip', () async {
      final PrefsDisplayStore store = PrefsDisplayStore(prefs: prefs);
      expect(kDisplayStorageKey, 'curaone.display.v1');
      expect(await store.load(), const DisplaySettings());
      const DisplaySettings s = DisplaySettings(
        world: WorldChoice.evening,
        theme: ThemeChoice.dark,
        reduceTransparency: true,
      );
      await store.save(s);
      expect(await prefs.getString(kDisplayStorageKey), isNotNull);
      expect(await store.load(), s);
    });

    test('kaputter Inhalt: Standard', () async {
      await prefs.setString(kDisplayStorageKey, '{kaputt');
      expect(
        await PrefsDisplayStore(prefs: prefs).load(),
        const DisplaySettings(),
      );
    });

    test('erase entfernt genau den Schlüssel', () async {
      final PrefsDisplayStore store = PrefsDisplayStore(prefs: prefs);
      await store.save(const DisplaySettings(sound: false));
      await prefs.setString('fremd', 'bleibt');
      await store.erase();
      expect(await prefs.getKeys(), <String>{'fremd'});
    });

    test('Controller und Speicher zusammen über Neustart', () async {
      final DisplayController a = DisplayController(
        store: PrefsDisplayStore(prefs: prefs),
      )..setWorld(WorldChoice.night);
      await a.flush();
      final DisplayController b = DisplayController(
        store: PrefsDisplayStore(prefs: prefs),
      );
      await b.load();
      expect(b.settings.world, WorldChoice.night);
    });
  });
}
