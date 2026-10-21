import 'dart:convert';
import 'dart:io';

import 'package:curaone/logic/clock.dart';

/// Gemeinsame Fixtures „Mitternacht/Zeitzone“ (Plan 6.7 Nr. 5): liegen unter
/// `supabase/tests/fixtures/local_day/` und werden hier nur gelesen.
const String kLocalDayFixtureDir = '../supabase/tests/fixtures/local_day';

Map<String, dynamic> readLocalDayFixture(String fileName) {
  final File f = File('$kLocalDayFixtureDir/$fileName');
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}

/// Lokaler Kalendertag eines Zeitpunkts in einer Zeitzone mit festem Versatz
/// (`+0200`, `-0700`, `+1300`).
LocalDay localDayAt(String utcInstant, String utcOffset) {
  final DateTime utc = DateTime.parse(utcInstant).toUtc();
  final int sign = utcOffset.startsWith('-') ? -1 : 1;
  final int hours = int.parse(utcOffset.substring(1, 3));
  final int minutes = int.parse(utcOffset.substring(3, 5));
  final DateTime shifted = utc.add(
    Duration(minutes: sign * (hours * 60 + minutes)),
  );
  return LocalDay(shifted.year, shifted.month, shifted.day);
}
