// Gemeinsame Fixtures „Mitternacht/Zeitzone“ (Plan 6.7 Nr. 5), nur lesend aus
// `supabase/tests/fixtures/local_day/`: Der lokale Tag des Geräts ist die
// Datumsbasis; die Grenzen für sofortige Aufrufe (±1 Tag) und für
// Warteschlangen-Einträge (Bindungstag − 1 … UTC-Datum + 1) entsprechen dem
// Server. (a) und (b) siehe plan_today_test, (h) siehe outbox_sender_test.
import 'package:curaone/dev/fake_backend.dart';
import 'package:curaone/logic/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/local_day_fixtures.dart';

void main() {
  void checkCase(Map<String, dynamic> c) {
    final LocalDay day = localDayAt(
      c['utc_instant'] as String,
      c['utc_offset'] as String,
    );
    expect(day.toString(), c['local_day'], reason: '${c['device_time']}');
    final DateTime utc = DateTime.parse(c['utc_instant'] as String);
    final LocalDay utcDay = LocalDay(utc.year, utc.month, utc.day);
    expect(utcDay.toString(), c['utc_date']);
    expect(utcDay.daysUntil(day), c['offset_days']);
    // Immer innerhalb ±1 Tag um das UTC-Datum: gültig.
    expect(isImmediateDayAccepted(day, utc), isTrue, reason: '$c');
  }

  test('(c) UTC+13, UTC−7, UTC+14, UTC−12: local_day gültig', () {
    final Map<String, dynamic> f = readLocalDayFixture(
      'c_timezones_midnight.json',
    );
    final List<dynamic> cases = f['cases'] as List<dynamic>;
    expect(cases.length, greaterThanOrEqualTo(6));
    for (final dynamic c in cases) {
      checkCase(c as Map<String, dynamic>);
    }
  });

  test(
    '(e) Umstellung Sommer-/Winterzeit: alle Zeitpunkte am Tag 2026-10-25',
    () {
      final Map<String, dynamic> f = readLocalDayFixture(
        'e_dst_berlin_2026-10-25.json',
      );
      final Map<String, dynamic> expected = f['expect'] as Map<String, dynamic>;
      for (final dynamic c in f['cases'] as List<dynamic>) {
        final Map<String, dynamic> m = c as Map<String, dynamic>;
        expect(
          localDayAt(
            m['utc_instant'] as String,
            m['utc_offset'] as String,
          ).toString(),
          expected['local_day'],
          reason: '${m['device_time']}',
        );
        checkCase(m);
      }
    },
  );

  test(
    '(f) Session über Mitternacht: Ergebnisse tragen den Tag des Starts',
    () {
      final Map<String, dynamic> f = readLocalDayFixture(
        'f_session_over_midnight.json',
      );
      final Map<String, dynamic> start =
          f['session_start'] as Map<String, dynamic>;
      final Map<String, dynamic> end = f['session_end'] as Map<String, dynamic>;
      final LocalDay startDay = localDayAt(
        start['utc_instant'] as String,
        start['utc_offset'] as String,
      );
      final LocalDay endDay = localDayAt(
        end['utc_instant'] as String,
        end['utc_offset'] as String,
      );
      expect(startDay.toString(), start['local_day']);
      expect(endDay.toString(), end['local_day']);
      expect(startDay == endDay, isFalse);
      // Regel (8.5): das Ergebnis trägt den Tag des Session-Starts, nicht den
      // Tag, an dem es protokolliert wird.
      final Map<String, dynamic> expected = f['expect'] as Map<String, dynamic>;
      for (final dynamic r in f['results'] as List<dynamic>) {
        expect((r as Map<String, dynamic>)['local_day'], expected['local_day']);
        expect(startDay.toString(), r['local_day']);
      }
    },
  );

  test('(g) Check-up um 00:10 zählt für den neuen Tag', () {
    final Map<String, dynamic> f = readLocalDayFixture('g_checkup_0010.json');
    final Map<String, dynamic> c = f['case'] as Map<String, dynamic>;
    final LocalDay day = localDayAt(
      c['utc_instant'] as String,
      c['utc_offset'] as String,
    );
    expect(day.toString(), (f['expect'] as Map<String, dynamic>)['local_day']);
    expect(c['offset_days'], 1); // UTC-Datum liegt noch einen Tag davor
  });

  group('(d) Plausibilitätsgrenzen', () {
    final Map<String, dynamic> f = readLocalDayFixture('d_out_of_range.json');
    final DateTime server = DateTime.parse(f['server_utc_instant'] as String);
    final DateTime boundAt = DateTime.parse(f['bound_at'] as String);

    test('sofortige Aufrufe: ±1 Tag um das UTC-Datum', () {
      for (final dynamic c in f['cases'] as List<dynamic>) {
        final Map<String, dynamic> m = c as Map<String, dynamic>;
        expect(
          isImmediateDayAccepted(
            LocalDay.parse(m['local_day'] as String),
            server,
          ),
          m['immediate'] == 'accepted',
          reason: '${m['local_day']}',
        );
      }
    });

    test(
      'Warteschlange: Bindungstag − 1 bis UTC-Datum + 1, kein Höchstalter',
      () {
        for (final dynamic c in f['cases'] as List<dynamic>) {
          final Map<String, dynamic> m = c as Map<String, dynamic>;
          expect(
            isQueueDayAccepted(
              LocalDay.parse(m['local_day'] as String),
              boundAt,
              server,
            ),
            m['queue'] == 'accepted',
            reason: '${m['local_day']}',
          );
        }
      },
    );
  });
}
