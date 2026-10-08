// Tag und Uhr (Plan 6.4). Reine Dart-Logik, kein Flutter-Import.

/// Quelle der aktuellen Zeit. Produktion: `DateTime.now`; Tests: `FakeClock`.
typedef Clock = DateTime Function();

/// Lokaler Kalendertag (Jahr, Monat, Tag) ohne Uhrzeit und Zeitzone.
///
/// Rechnen geht über `DateTime.utc`, damit Sommerzeitwechsel keinen Tag
/// verschieben (Plan 6.4, Streak S15/S20).
class LocalDay implements Comparable<LocalDay> {
  const LocalDay(this.year, this.month, this.day);

  /// Kalendertag eines Zeitpunkts in dessen eigener Zeitzone (bei einer
  /// lokalen Uhr: Ortszeit).
  factory LocalDay.from(DateTime t) => LocalDay(t.year, t.month, t.day);

  /// Streng `YYYY-MM-DD`; wirft [FormatException] bei jedem anderen Text und
  /// bei Daten, die es im Kalender nicht gibt (z. B. 2026-02-30).
  factory LocalDay.parse(String text) {
    final LocalDay? parsed = tryParse(text);
    if (parsed == null) {
      throw FormatException('Kein gültiger Kalendertag', text);
    }
    return parsed;
  }

  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static LocalDay? tryParse(String text) {
    final RegExpMatch? m = _pattern.firstMatch(text);
    if (m == null) return null;
    final int y = int.parse(m.group(1)!);
    final int mo = int.parse(m.group(2)!);
    final int d = int.parse(m.group(3)!);
    final DateTime utc = DateTime.utc(y, mo, d);
    if (utc.year != y || utc.month != mo || utc.day != d) return null;
    return LocalDay(y, mo, d);
  }

  final int year;
  final int month;
  final int day;

  DateTime get _utc => DateTime.utc(year, month, day);

  /// 1 = Montag … 7 = Sonntag (wie `DateTime.weekday`).
  int get weekday => _utc.weekday;

  LocalDay addDays(int n) => LocalDay.from(_utc.add(Duration(days: n)));

  /// Anzahl Kalendertage von diesem Tag bis [other] (negativ, wenn [other]
  /// früher liegt).
  int daysUntil(LocalDay other) => other._utc.difference(_utc).inDays;

  bool isBefore(LocalDay other) => compareTo(other) < 0;
  bool isAfter(LocalDay other) => compareTo(other) > 0;

  @override
  int compareTo(LocalDay other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDay &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// `YYYY-MM-DD`, so auch im Dokument gespeichert.
  @override
  String toString() {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${year.toString().padLeft(4, '0')}-${two(month)}-${two(day)}';
  }
}
