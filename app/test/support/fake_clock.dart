/// Steuerbare Uhr für Tests. Passt als `Clock` (`DateTime Function()`), sobald
/// `lib/logic/clock.dart` existiert: `FakeClock().call` bzw. die Instanz selbst
/// (Dart erlaubt `call`-Tear-off über die Instanz).
class FakeClock {
  FakeClock([DateTime? initial]) : _now = initial ?? defaultNow;

  /// Standard-Fixture (Plan 6.4): 2026-10-07 = **Mittwoch**, 12:00 Ortszeit.
  static final DateTime defaultNow = DateTime(2026, 10, 7, 12);

  DateTime _now;

  DateTime call() => _now;

  DateTime get now => _now;

  /// Setzt die Uhr auf einen festen Zeitpunkt (auch rückwärts).
  void set(DateTime value) => _now = value;

  void advance(Duration duration) => _now = _now.add(duration);

  /// Springt um ganze Kalendertage (gleiche Uhrzeit, Sommerzeit-sicher).
  void advanceDays(int days) {
    _now = DateTime(
      _now.year,
      _now.month,
      _now.day + days,
      _now.hour,
      _now.minute,
      _now.second,
      _now.millisecond,
    );
  }
}
