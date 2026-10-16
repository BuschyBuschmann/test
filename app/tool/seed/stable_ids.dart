// Stabile, reproduzierbare UUIDs fuer den Testdaten-Seed (Plan Ausschnitt 2, Abschnitt 10).
//
// Gleicher Schluessel -> gleiche UUID, in jedem Lauf und auf jeder Plattform. So entsteht nach
// einem Reset derselbe Endzustand (DB-T40). Die UUIDs sind formal gueltig (Version 4, Variante 1)
// und beginnen mit "5eed", damit Seed-Zeilen in der Datenbank sofort erkennbar sind.
// Kein kryptografischer Zweck: die IDs sind weder geheim noch sicherheitsrelevant.

import 'dart:convert';

final BigInt _mask64 = (BigInt.one << 64) - BigInt.one;
final BigInt _fnvPrime = BigInt.parse('100000001b3', radix: 16);
final BigInt _fnvOffsetA = BigInt.parse('cbf29ce484222325', radix: 16);
final BigInt _fnvOffsetB = BigInt.parse('84222325cbf29ce4', radix: 16);
final BigInt _mix = BigInt.parse('ff51afd7ed558ccd', radix: 16);

BigInt _lane(List<int> bytes, BigInt offset) {
  var h = offset;
  for (final b in bytes) {
    h = ((h ^ BigInt.from(b)) * _fnvPrime) & _mask64;
  }
  // Abschlussmischung (verteilt Unterschiede in kurzen Schluesseln auf alle Bits)
  h = (h ^ (h >> 33)) & _mask64;
  h = (h * _mix) & _mask64;
  h = (h ^ (h >> 33)) & _mask64;
  return h;
}

/// Liefert die stabile UUID zu [key], z. B. `stableId('patient:lena')`.
String stableId(String key) {
  final bytes = utf8.encode(key);
  final a = _lane(bytes, _fnvOffsetA);
  final b = _lane(bytes.reversed.toList(), _fnvOffsetB);
  final hex =
      a.toRadixString(16).padLeft(16, '0') +
      b.toRadixString(16).padLeft(16, '0');
  final variant = (int.parse(hex[16], radix: 16) & 0x3 | 0x8).toRadixString(16);
  final d =
      '5eed${hex.substring(4, 12)}4${hex.substring(13, 16)}$variant${hex.substring(17)}';
  return '${d.substring(0, 8)}-${d.substring(8, 12)}-${d.substring(12, 16)}-'
      '${d.substring(16, 20)}-${d.substring(20, 32)}';
}
