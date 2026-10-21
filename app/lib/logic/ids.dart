// Geräte-IDs (Plan 6.2: Schreibvorgänge der Warteschlange tragen IDs, die das
// Gerät erzeugt; `on conflict (id) do nothing` macht Wiederholungen
// unschädlich). Reine Dart-Logik.
import 'dart:math';

final Random _secure = Random.secure();

/// UUID Version 4 (zufällig). [random] nur für Tests.
String newUuid([Random? random]) {
  final Random r = random ?? _secure;
  final List<int> b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int from, int to) => <String>[
    for (int i = from; i < to; i++) b[i].toRadixString(16).padLeft(2, '0'),
  ].join();
  return '${h(0, 4)}-${h(4, 6)}-${h(6, 8)}-${h(8, 10)}-${h(10, 16)}';
}

final RegExp _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

bool isUuid(String value) => _uuid.hasMatch(value);

const int _mask32 = 4294967295;

int _imul(int a, int b) {
  // 32-Bit-Multiplikation, die auch im Web (53-Bit-Zahlen) exakt bleibt.
  final int ah = (a >> 16) & 0xffff;
  final int al = a & 0xffff;
  final int bh = (b >> 16) & 0xffff;
  final int bl = b & 0xffff;
  return (al * bl + (((ah * bl + al * bh) & 0xffff) << 16)) & _mask32;
}

int _fnv32(List<int> bytes, int seed) {
  int h = seed;
  for (final int b in bytes) {
    h = _imul(h ^ b, 16777619);
  }
  return h & _mask32;
}

/// Eine aus [seed] abgeleitete, gleichbleibende ID in UUID-Form (Version 8,
/// „custom“). Für Zeilen, deren ID sich ohne gespeicherten Zustand
/// wiederfinden lassen muss (z. B. das Ergebnis „Übung X am Tag D“, damit
/// „Rückgängig“ es löschen kann). Kein kryptografisches Verfahren; nur
/// Eindeutigkeit im Sinne einer Namens-ID (vier 32-Bit-Hashes über denselben
/// Text, 128 Bit Zustand).
String uuidFromSeed(String seed) {
  final List<int> bytes = seed.codeUnits;
  const List<int> seeds = <int>[2166136261, 2538058380, 461845907, 3432918353];
  final List<int> b = <int>[];
  for (final int s in seeds) {
    final int h = _fnv32(bytes, s);
    b.addAll(<int>[
      (h >> 24) & 0xff,
      (h >> 16) & 0xff,
      (h >> 8) & 0xff,
      h & 0xff,
    ]);
  }
  b[6] = (b[6] & 0x0f) | 0x80;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int from, int to) => <String>[
    for (int i = from; i < to; i++) b[i].toRadixString(16).padLeft(2, '0'),
  ].join();
  return '${h(0, 4)}-${h(4, 6)}-${h(6, 8)}-${h(8, 10)}-${h(10, 16)}';
}
