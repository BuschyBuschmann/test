// Welt-Tokens (Design-Brief v2, 3.1): Himmelsverlauf, Hügelebenen, Licht,
// Boden und die Glasfarben von Kopf-Karte, Leiste und Label-Chip je Tageszeit,
// dazu die Mischung zweier Phasen für die Überblendung an den Grenzen. Die
// Zeitregel selbst (welche Phase, welcher Anteil) steht in
// `lib/logic/world_time.dart`; hier sind nur die Farbwerte. Außerhalb von
// `lib/theme/` gilt KONVENTIONEN Regel 1.
import 'dart:ui' show Color, lerpDouble;

import 'package:flutter/foundation.dart';

import '../logic/world_time.dart';

/// Ein Halt im Himmelsverlauf: Position 0 (oben) … 1 (unten) und Farbe.
@immutable
class SkyStop {
  const SkyStop(this.position, this.color);

  final double position;
  final Color color;
}

Color _rgba(int rgb, double alpha) =>
    Color(0xFF000000 | rgb).withValues(alpha: alpha);

Color _opaque(int rgb) => Color(0xFF000000 | rgb);

/// Farbsatz einer Welt (oder einer Mischung aus zwei Welten).
@immutable
class WorldPalette {
  const WorldPalette._({
    required this.sky,
    required this.hillFar,
    required this.hillMid,
    required this.hillNear,
    required this.lightX,
    required this.lightY,
    required this.lightColor,
    required this.moonAmount,
    required this.starAmount,
    required this.floor,
    required this.mist,
    required this.headerTint,
    required this.navRest,
    required this.navActive,
    required this.navInk,
    required this.chip,
    required this.chipText,
  });

  /// Himmelsverlauf auf dem gemeinsamen Raster [kSkyGrid] (damit Phasen mit
  /// verschiedenen Halten stufenlos gemischt werden können).
  final List<Color> sky;

  /// `world-hill-far/mid/near`.
  final Color hillFar;
  final Color hillMid;
  final Color hillNear;

  /// `world-light`: Mittelpunkt als Anteil von Breite und Höhe und Farbe.
  final double lightX;
  final double lightY;
  final Color lightColor;

  /// 0 = Sonne, 1 = Mond (Größe und Schein des Lichts).
  final double moonAmount;

  /// 0 … 1: Deckkraft der Sterne (Nacht: 46 Sterne).
  final double starAmount;

  /// `world-floor`: Farbe unter der Leiste.
  final Color floor;

  /// Dunstband (Farbe mit Deckkraft).
  final Color mist;

  /// `header-tint` mit Deckkraft (Kopf-Karte).
  final Color headerTint;

  /// `header-tint` zu 100 % (Hoher Kontrast/Transparenz reduzieren).
  Color get headerTintOpaque => headerTint.withValues(alpha: 1);

  /// `nav-tint`, Ruhe und Aktiv (Farbe mit Deckkraft).
  final Color navRest;
  final Color navActive;

  /// `nav-ink` (Label, Symbole).
  final Color navInk;

  /// `chip-world` (Label-Chip) mit Deckkraft und Textfarbe.
  final Color chip;
  final Color chipText;

  /// Oberste Himmelsfarbe (Stichprobe V2-2).
  Color get skyTop => sky.first;

  /// Unterste Himmelsfarbe: gleich `world-floor`.
  Color get skyBottom => sky.last;

  /// Himmelsfarbe oben ohne Alpha, für Kontrastrechnungen.
  static const Color white = Color(0xFFFFFFFF);

  // -------------------------------------------------------------------------
  // Die vier Welten (Brief 3.1)
  // -------------------------------------------------------------------------

  static WorldPalette _make({
    required List<SkyStop> sky,
    required int far,
    required int mid,
    required int near,
    required double lightX,
    required double lightY,
    required int light,
    required bool moon,
    required int floor,
    required Color mist,
    required Color headerTint,
    required Color navRest,
    required Color navActive,
    required int navInk,
    required Color chip,
    required int chipText,
  }) {
    return WorldPalette._(
      sky: _sampleSky(sky),
      hillFar: _opaque(far),
      hillMid: _opaque(mid),
      hillNear: _opaque(near),
      lightX: lightX,
      lightY: lightY,
      lightColor: _opaque(light),
      moonAmount: moon ? 1 : 0,
      starAmount: moon ? 1 : 0,
      floor: _opaque(floor),
      mist: mist,
      headerTint: headerTint,
      navRest: navRest,
      navActive: navActive,
      navInk: _opaque(navInk),
      chip: chip,
      chipText: _opaque(chipText),
    );
  }

  static final WorldPalette morning = _make(
    sky: _skyMorning,
    far: 0xB4AFC6,
    mid: 0xD2C0BC,
    near: 0xF6EDE2,
    lightX: 0.24,
    lightY: 0.28,
    light: 0xFFE9C2,
    moon: false,
    floor: 0xF7F2EB,
    mist: _rgba(0xFFFFFF, 0.50),
    headerTint: _rgba(0x2A211C, 0.66),
    navRest: _rgba(0xFFFFFF, 0.35),
    navActive: _rgba(0xFFFFFF, 0.78),
    navInk: 0x211B16,
    chip: _rgba(0xFFFFFF, 0.72),
    chipText: 0x211B16,
  );

  static final WorldPalette midday = _make(
    sky: _skyMidday,
    far: 0x9DB6C6,
    mid: 0xC4D3D1,
    near: 0xF1F0E8,
    lightX: 0.70,
    lightY: 0.09,
    light: 0xFFFFFF,
    moon: false,
    floor: 0xF7F2EB,
    mist: _rgba(0xFFFFFF, 0.55),
    headerTint: _rgba(0x23303A, 0.66),
    navRest: _rgba(0xFFFFFF, 0.35),
    navActive: _rgba(0xFFFFFF, 0.78),
    navInk: 0x211B16,
    chip: _rgba(0xFFFFFF, 0.74),
    chipText: 0x211B16,
  );

  static final WorldPalette evening = _make(
    sky: _skyEvening,
    far: 0xA99AA6,
    mid: 0x9C8E9B,
    near: 0xF4ECE2,
    lightX: 0.78,
    lightY: 0.20,
    light: 0xFFE9C8,
    moon: false,
    floor: 0xF7F2EB,
    mist: _rgba(0xFFE1C8, 0.50),
    headerTint: _rgba(0x281E18, 0.66),
    navRest: _rgba(0xFFFFFF, 0.35),
    navActive: _rgba(0xFFFFFF, 0.78),
    navInk: 0x211B16,
    chip: _rgba(0xFFFFFF, 0.72),
    chipText: 0x211B16,
  );

  static final WorldPalette night = _make(
    sky: _skyNight,
    far: 0x4A4468,
    mid: 0x3A3354,
    near: 0x2E2634,
    lightX: 0.78,
    lightY: 0.18,
    light: 0xFFF3D6,
    moon: true,
    floor: 0x1C1620,
    mist: _rgba(0x9682BE, 0.28),
    headerTint: _rgba(0x0F0B1A, 0.58),
    navRest: _rgba(0x1A1320, 0.45),
    navActive: _rgba(0x1A1320, 0.82),
    navInk: 0xF5EFE8,
    chip: _rgba(0x1E1626, 0.72),
    chipText: 0xFFFFFF,
  );

  /// Anzahl der Sterne der Nacht (Brief 3.1).
  static const int nightStarCount = 46;

  static WorldPalette of(WorldPhase phase) => switch (phase) {
    WorldPhase.morning => morning,
    WorldPhase.midday => midday,
    WorldPhase.evening => evening,
    WorldPhase.night => night,
  };

  /// Palette einer Mischung (reine Phase oder lineare Überblendung aller
  /// Tokens der Tabelle, Sonne wechselt weich die Position).
  static WorldPalette forMix(WorldMix mix) {
    final WorldPalette a = of(mix.from);
    if (mix.isPure) return a;
    return lerp(a, of(mix.to), mix.t);
  }

  /// Mischung zweier Paletten (Brief 3.1: alle Tokens der Tabelle werden
  /// linear überblendet, die Sonne wechselt weich die Position).
  ///
  /// **Ausnahme (Annahme, zur Bestätigung durch den `ui-designer`):** Die
  /// Beschriftungs-Sätze von Label-Chip (`chip`, `chipText`) und Leiste
  /// (`navRest`, `navActive`, `navInk`) springen in der Mitte des Fensters
  /// (t = 0,5) von der einen zur anderen Phase, statt linear zu mischen. Bei
  /// einer linearen Mischung von Tinte *und* Fläche liegen beide in der Mitte
  /// des Fensters bei einem mittleren Grau (gemessen 1,0:1 zwischen Abend und
  /// Nacht bzw. Nacht und Morgen); mit dem Sprung gilt in jedem Augenblick
  /// das gemessene Paar einer reinen Phase (Tabelle 3.1, ≥ 4,5:1). Die
  /// Kopf-Karte (immer weißer Text auf dunkler Tönung) bleibt linear.
  static WorldPalette lerp(WorldPalette a, WorldPalette b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    double d(double x, double y) => lerpDouble(x, y, t)!;
    final WorldPalette labels = t < 0.5 ? a : b;
    return WorldPalette._(
      sky: <Color>[
        for (int i = 0; i < a.sky.length; i++) c(a.sky[i], b.sky[i]),
      ],
      hillFar: c(a.hillFar, b.hillFar),
      hillMid: c(a.hillMid, b.hillMid),
      hillNear: c(a.hillNear, b.hillNear),
      lightX: d(a.lightX, b.lightX),
      lightY: d(a.lightY, b.lightY),
      lightColor: c(a.lightColor, b.lightColor),
      moonAmount: d(a.moonAmount, b.moonAmount),
      starAmount: d(a.starAmount, b.starAmount),
      floor: c(a.floor, b.floor),
      mist: c(a.mist, b.mist),
      headerTint: c(a.headerTint, b.headerTint),
      navRest: labels.navRest,
      navActive: labels.navActive,
      navInk: labels.navInk,
      chip: labels.chip,
      chipText: labels.chipText,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WorldPalette &&
      listEquals(other.sky, sky) &&
      other.hillFar == hillFar &&
      other.hillMid == hillMid &&
      other.hillNear == hillNear &&
      other.lightX == lightX &&
      other.lightY == lightY &&
      other.lightColor == lightColor &&
      other.moonAmount == moonAmount &&
      other.starAmount == starAmount &&
      other.floor == floor &&
      other.mist == mist &&
      other.headerTint == headerTint &&
      other.navRest == navRest &&
      other.navActive == navActive &&
      other.navInk == navInk &&
      other.chip == chip &&
      other.chipText == chipText;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(sky),
    hillFar,
    hillMid,
    hillNear,
    lightX,
    lightY,
    lightColor,
    moonAmount,
    starAmount,
    floor,
    mist,
    headerTint,
    navRest,
    navActive,
    navInk,
    chip,
    chipText,
  );
}

// ---------------------------------------------------------------------------
// Himmelsverläufe (Brief 3.1, `world-sky`)
// ---------------------------------------------------------------------------

final List<SkyStop> _skyMorning = <SkyStop>[
  SkyStop(0, _opaque(0xBCD2EA)),
  SkyStop(0.34, _opaque(0xF3C6B6)),
  SkyStop(0.58, _opaque(0xF7DFCB)),
  SkyStop(0.80, _opaque(0xF6EDE0)),
  SkyStop(1, _opaque(0xF7F2EB)),
];

final List<SkyStop> _skyMidday = <SkyStop>[
  SkyStop(0, _opaque(0x8EC3EC)),
  SkyStop(0.36, _opaque(0xCDE5F4)),
  SkyStop(0.60, _opaque(0xE9F2EE)),
  SkyStop(0.82, _opaque(0xF6F3EA)),
  SkyStop(1, _opaque(0xF7F2EB)),
];

final List<SkyStop> _skyEvening = <SkyStop>[
  SkyStop(0, _opaque(0xF2B58C)),
  SkyStop(0.16, _opaque(0xE8A68A)),
  SkyStop(0.36, _opaque(0xC8B1A8)),
  SkyStop(0.58, _opaque(0xDCCFC4)),
  SkyStop(0.80, _opaque(0xF1E8DD)),
  SkyStop(1, _opaque(0xF7F2EB)),
];

final List<SkyStop> _skyNight = <SkyStop>[
  SkyStop(0, _opaque(0x141A33)),
  SkyStop(0.30, _opaque(0x2B2547)),
  SkyStop(0.55, _opaque(0x4A3548)),
  SkyStop(0.78, _opaque(0x2B2230)),
  SkyStop(1, _opaque(0x1C1620)),
];

/// Die Halte der vier Himmelsverläufe (zur Prüfung gegen die Tabelle).
Map<WorldPhase, List<SkyStop>> get worldSkySources =>
    <WorldPhase, List<SkyStop>>{
      WorldPhase.morning: _skyMorning,
      WorldPhase.midday: _skyMidday,
      WorldPhase.evening: _skyEvening,
      WorldPhase.night: _skyNight,
    };

/// Gemeinsames Raster aller Haltepositionen der vier Verläufe.
final List<double> kSkyGrid = () {
  final Set<double> all = <double>{
    for (final List<SkyStop> list in <List<SkyStop>>[
      _skyMorning,
      _skyMidday,
      _skyEvening,
      _skyNight,
    ])
      for (final SkyStop s in list) s.position,
  };
  return all.toList()..sort();
}();

/// Farbe eines Verlaufs an der Stelle [position] (linear zwischen den Halten,
/// wie ein CSS-`linear-gradient`).
Color skyColorAt(List<SkyStop> stops, double position) {
  if (position <= stops.first.position) return stops.first.color;
  for (int i = 1; i < stops.length; i++) {
    final SkyStop b = stops[i];
    if (position <= b.position) {
      final SkyStop a = stops[i - 1];
      final double t = (position - a.position) / (b.position - a.position);
      return Color.lerp(a.color, b.color, t)!;
    }
  }
  return stops.last.color;
}

List<Color> _sampleSky(List<SkyStop> stops) => <Color>[
  for (final double p in kSkyGrid) skyColorAt(stops, p),
];

// ---------------------------------------------------------------------------
// Geometrie und Mengen der Welt (Painter)
// ---------------------------------------------------------------------------

/// Maße der gezeichneten Welt. Alles als Anteil von Breite/Höhe, damit eine
/// Ebene bei jeder Bildschirmgröße gleich wirkt.
abstract final class WorldGeometry {
  // Hügelebenen: Höhe der Kammlinie (Anteil der Höhe), Amplitude der Welle
  // und Wellenlänge (Anteil der Breite), Phase, Weichzeichnung (dp).
  static const double farCrest = 0.50;
  static const double farAmplitude = 0.035;
  static const double farWavelength = 1.30;
  static const double farPhase = 0.35;
  static const double farBlur = 14;

  static const double midCrest = 0.62;
  static const double midAmplitude = 0.04;
  static const double midWavelength = 1.05;
  static const double midPhase = 1.9;
  static const double midBlur = 9;

  static const double nearCrest = 0.76;
  static const double nearAmplitude = 0.045;
  static const double nearWavelength = 0.85;
  static const double nearPhase = 3.6;
  static const double nearBlur = 4;

  // Jede Ebene läuft nach unten in Transparenz aus: Anteil der Höhe, bei dem
  // sie vollständig durchsichtig ist (die vorderste genau am unteren Rand,
  // damit unten die Bodenfarbe `world-floor` steht).
  static const double farFadeEnd = 0.80;
  static const double midFadeEnd = 0.92;
  static const double nearFadeEnd = 1.0;

  // Dunstbänder zwischen den Ebenen: Mitte (Anteil der Höhe), Höhe.
  static const List<double> mistCenters = <double>[0.52, 0.64, 0.78];
  static const double mistHeight = 0.12;

  // Licht: Radius des Scheins und der Scheibe (Anteil der Breite).
  static const double sunGlowRadius = 0.42;
  static const double sunDiscRadius = 0.07;
  static const double moonGlowRadius = 0.26;
  static const double moonDiscRadius = 0.045;
  static const double lightGlowAlpha = 0.85;
  // Die Scheibe läuft auf das 1,5-Fache ihres Radius weich aus.
  static const double lightDiscSoftness = 1.5;

  // Sterne: Anzahl in `WorldPalette.nightStarCount`; feste Zufallsfolge.
  static const int starSeed = 7;
  static const double starRegionHeight = 0.5;
  static const double starMinRadius = 0.6;
  static const double starMaxRadius = 1.6;
  static const double starMinAlpha = 0.45;

  // Körnung: Zahl der Punkte je 10 000 dp² und Deckkraft.
  static const int grainSeed = 11;
  static const double grainPerTenThousand = 9;
  static const double grainAlpha = 0.10;

  // Ruhige Welt (Physio, Brief 3.1): Ebenen auf 50 % Deckkraft.
  static const double calmHillAlpha = 0.5;

  // Schleier unter der Leiste: 70 % `world-floor`, 150 dp hoch (Brief 4.1,
  // Höhe in `CuraSize.navVeilHeight`).
  static const double navVeilAlpha = 0.70;

  // Pfad-Linie auf der Welt (Brief 7.1): erreichte Strecke in `nav-ink`,
  // künftige gepunktet mit dieser Deckkraft.
  static const double pathLineFutureAlpha = 0.55;
}
