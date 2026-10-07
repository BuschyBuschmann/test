import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/date_format.dart';
import 'package:curaone/logic/plural.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_clock.dart';

void main() {
  group('LocalDay', () {
    test('from, toString, parse (Roundtrip)', () {
      final LocalDay d = LocalDay.from(DateTime(2026, 3, 5, 23, 59));
      expect(d, const LocalDay(2026, 3, 5));
      expect(d.toString(), '2026-03-05');
      expect(LocalDay.parse('2026-03-05'), d);
    });

    test('parse ist streng', () {
      for (final String bad in <String>[
        '',
        '2026-3-5',
        '2026-02-30',
        '2026-13-01',
        '2026-00-10',
        '2026-10-07T00:00',
        ' 2026-10-07',
        'abc',
      ]) {
        expect(LocalDay.tryParse(bad), isNull, reason: bad);
        expect(() => LocalDay.parse(bad), throwsFormatException);
      }
      expect(LocalDay.tryParse('2028-02-29'), const LocalDay(2028, 2, 29));
      expect(LocalDay.tryParse('2027-02-29'), isNull);
    });

    test('Arithmetik: Monats-, Jahres-, Schaltjahrgrenzen', () {
      expect(
        const LocalDay(2026, 12, 31).addDays(1),
        const LocalDay(2027, 1, 1),
      );
      expect(
        const LocalDay(2028, 2, 28).addDays(1),
        const LocalDay(2028, 2, 29),
      );
      expect(
        const LocalDay(2028, 2, 28).addDays(2),
        const LocalDay(2028, 3, 1),
      );
      expect(
        const LocalDay(2026, 3, 1).addDays(-1),
        const LocalDay(2026, 2, 28),
      );
    });

    test('daysUntil über Sommerzeitwechsel exakt', () {
      // Sommerzeitende 2026-10-25, Sommerzeitbeginn 2026-03-29 (Berlin)
      expect(
        const LocalDay(2026, 10, 24).daysUntil(const LocalDay(2026, 10, 26)),
        2,
      );
      expect(
        const LocalDay(2026, 3, 28).daysUntil(const LocalDay(2026, 3, 30)),
        2,
      );
      expect(
        const LocalDay(2026, 10, 7).daysUntil(const LocalDay(2026, 10, 1)),
        -6,
      );
      expect(
        const LocalDay(2026, 10, 7).daysUntil(const LocalDay(2026, 10, 7)),
        0,
      );
    });

    test('weekday, Vergleich, Gleichheit', () {
      expect(kFixtureDay.weekday, DateTime.wednesday);
      expect(kFixtureDay.isBefore(kFixtureDay.addDays(1)), isTrue);
      expect(kFixtureDay.isAfter(kFixtureDay.addDays(-1)), isTrue);
      expect(kFixtureDay.compareTo(kFixtureDay), 0);
      expect(<LocalDay>{kFixtureDay, LocalDay.parse('2026-10-07')}.length, 1);
    });

    test('FakeClock ist als Clock verwendbar', () {
      final FakeClock fake = FakeClock();
      final Clock clock = fake.call;
      expect(LocalDay.from(clock()), kFixtureDay);
      fake.advanceDays(1);
      expect(LocalDay.from(clock()), const LocalDay(2026, 10, 8));
    });
  });

  group('tage (B-5)', () {
    test('n = 0, 1, 2', () {
      expect(tage(0), '0 Tage');
      expect(tage(1), '1 Tag');
      expect(tage(2), '2 Tage');
      expect(tage(13), '13 Tage');
    });

    test('Dativ: tagen(n)', () {
      expect(tagen(0), '0 Tagen');
      expect(tagen(1), '1 Tag');
      expect(tagen(2), '2 Tagen');
    });
  });

  group('Datumsformate', () {
    test('„Mittwoch, 7. Oktober“ und „3. September 2026“', () {
      expect(formatDateLong(kFixtureDay), 'Mittwoch, 7. Oktober');
      expect(
        formatDateLong(const LocalDay(2026, 10, 6)),
        'Dienstag, 6. Oktober',
      );
      expect(formatDateLong(const LocalDay(2026, 3, 1)), 'Sonntag, 1. März');
      expect(formatDateFull(const LocalDay(2026, 9, 3)), '3. September 2026');
    });
  });
}

const LocalDay kFixtureDay = LocalDay(2026, 10, 7);
