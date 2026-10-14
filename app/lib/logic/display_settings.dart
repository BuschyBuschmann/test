// Darstellungs-Einstellungen (Design-Brief v2 7.6 „Darstellung“, Plan 3.4):
// Welt, Thema, „Transparenz reduzieren“, Ton, Vibration. Eigenes kleines
// Dokument unter `curaone.display.v1`, getrennt vom Zustandsdokument; es
// bleibt über den Neustart erhalten (V2-7) und wird von „Alles löschen“
// mitgelöscht (B-21). Reine Dart-Logik, kein Flutter-Import.
import 'dart:convert';

import 'world_time.dart';

/// Thema der Inhaltsflächen (Brief 3.2): folgt dem System oder ist
/// überschrieben. Unabhängig von der Welt.
enum ThemeChoice {
  system,
  light,
  dark;

  static ThemeChoice fromJsonName(Object? value) {
    for (final ThemeChoice c in ThemeChoice.values) {
      if (c.name == value) return c;
    }
    return ThemeChoice.system;
  }
}

class DisplaySettings {
  const DisplaySettings({
    this.world = WorldChoice.automatic,
    this.theme = ThemeChoice.system,
    this.reduceTransparency = false,
    this.sound = true,
    this.vibration = true,
  });

  /// Liest das gespeicherte Dokument **tolerant**: Die Einstellungen sind
  /// keine kritischen Daten. Kein JSON, falsche Struktur oder unbekannte
  /// Werte ergeben je Feld den Standard (nie eine Ausnahme).
  factory DisplaySettings.fromJsonString(String? raw) {
    if (raw == null) return const DisplaySettings();
    Object? parsed;
    try {
      parsed = jsonDecode(raw);
    } on FormatException {
      return const DisplaySettings();
    }
    if (parsed is! Map<String, Object?>) return const DisplaySettings();
    final Map<String, Object?> doc = parsed;
    bool flag(String key, bool fallback) {
      final Object? v = doc[key];
      return v is bool ? v : fallback;
    }

    return DisplaySettings(
      world: WorldChoice.fromJsonName(doc['world']),
      theme: ThemeChoice.fromJsonName(doc['theme']),
      reduceTransparency: flag('reduceTransparency', false),
      sound: flag('sound', true),
      vibration: flag('vibration', true),
    );
  }

  /// Fester Look oder Automatisch.
  final WorldChoice world;
  final ThemeChoice theme;

  /// App-Schalter „Transparenz reduzieren“ (Brief 3.5, Entscheidung 5).
  final bool reduceTransparency;

  /// Ton und Vibration (Standard an, B-17); wirken ab L4.
  final bool sound;
  final bool vibration;

  DisplaySettings copyWith({
    WorldChoice? world,
    ThemeChoice? theme,
    bool? reduceTransparency,
    bool? sound,
    bool? vibration,
  }) {
    return DisplaySettings(
      world: world ?? this.world,
      theme: theme ?? this.theme,
      reduceTransparency: reduceTransparency ?? this.reduceTransparency,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'world': world.jsonName,
    'theme': theme.name,
    'reduceTransparency': reduceTransparency,
    'sound': sound,
    'vibration': vibration,
  };

  String toJsonString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      other is DisplaySettings &&
      other.world == world &&
      other.theme == theme &&
      other.reduceTransparency == reduceTransparency &&
      other.sound == sound &&
      other.vibration == vibration;

  @override
  int get hashCode =>
      Object.hash(world, theme, reduceTransparency, sound, vibration);
}
