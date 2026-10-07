// Deutsche Datumsformate (Plan 6.4), ohne `intl`.
import '../l10n/strings_de.dart';
import 'clock.dart';

/// „Mittwoch, 7. Oktober“
String formatDateLong(LocalDay d) =>
    '${S.weekdays[d.weekday - 1]}, ${d.day}. ${S.months[d.month - 1]}';

/// „3. September 2026“
String formatDateFull(LocalDay d) =>
    '${d.day}. ${S.months[d.month - 1]} ${d.year}';
