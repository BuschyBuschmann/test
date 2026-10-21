// Darstellungs-Einstellungen (Plan 3.4, V2-7): Standardwerte, JSON, tolerantes
// Lesen.
import 'dart:convert';

import 'package:curaone/logic/display_settings.dart';
import 'package:curaone/logic/world_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Standard: Welt Automatisch, Thema System, Transparenz an, Ton/Vibration an', () {
    const DisplaySettings s = DisplaySettings();
    expect(s.world, WorldChoice.automatic);
    expect(s.theme, ThemeChoice.system);
    expect(s.reduceTransparency, isFalse);
    expect(s.sound, isTrue);
    expect(s.vibration, isTrue);
  });

  test('Roundtrip aller Felder', () {
    const DisplaySettings s = DisplaySettings(
      world: WorldChoice.night,
      theme: ThemeChoice.light,
      reduceTransparency: true,
      sound: false,
      vibration: false,
    );
    expect(DisplaySettings.fromJsonString(s.toJsonString()), s);
    expect(s.toJson().keys.toSet(), <String>{
      'world',
      'theme',
      'reduceTransparency',
      'sound',
      'vibration',
    });
  });

  test('alle Welt- und Themawerte überleben das Speichern', () {
    for (final WorldChoice w in WorldChoice.values) {
      for (final ThemeChoice t in ThemeChoice.values) {
        final DisplaySettings s = DisplaySettings(world: w, theme: t);
        expect(DisplaySettings.fromJsonString(s.toJsonString()), s);
      }
    }
  });

  test('tolerant: Unbrauchbares ergibt den Standard, nie eine Ausnahme', () {
    const DisplaySettings d = DisplaySettings();
    expect(DisplaySettings.fromJsonString(null), d);
    expect(DisplaySettings.fromJsonString(''), d);
    expect(DisplaySettings.fromJsonString('{kaputt'), d);
    expect(DisplaySettings.fromJsonString('[1,2]'), d);
    expect(DisplaySettings.fromJsonString('42'), d);
    expect(DisplaySettings.fromJsonString('{}'), d);
    expect(
      DisplaySettings.fromJsonString(
        jsonEncode(<String, Object?>{
          'world': 'mondschein',
          'theme': 7,
          'reduceTransparency': 'ja',
          'sound': null,
          'vibration': 1,
        }),
      ),
      d,
    );
  });

  test('einzelne gültige Felder bleiben trotz kaputter Nachbarn', () {
    final DisplaySettings s = DisplaySettings.fromJsonString(
      jsonEncode(<String, Object?>{
        'world': 'evening',
        'theme': 'unbekannt',
        'sound': false,
      }),
    );
    expect(s.world, WorldChoice.evening);
    expect(s.theme, ThemeChoice.system);
    expect(s.sound, isFalse);
    expect(s.vibration, isTrue);
  });

  test('copyWith, Gleichheit', () {
    const DisplaySettings a = DisplaySettings();
    final DisplaySettings b = a.copyWith(world: WorldChoice.midday);
    expect(b.world, WorldChoice.midday);
    expect(b.theme, a.theme);
    expect(b, isNot(a));
    expect(b.copyWith(world: WorldChoice.automatic), a);
    expect(a.hashCode, const DisplaySettings().hashCode);
  });
}
