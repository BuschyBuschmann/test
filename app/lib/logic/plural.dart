import '../l10n/strings_de.dart';

/// „1 Tag“, sonst „n Tage“ (auch bei 0). Plan 7.4, B-5.
String tage(int n) => n == 1 ? S.dayOne : S.dayMany(n);

/// Dativ: „1 Tag“, sonst „n Tagen“ („Dein Streak von 12 Tagen …“). Der Brief
/// (6.2) verlangt in der Streak-Gefahr-Blase „Tagen“; [tage] wäre dort
/// grammatisch falsch.
String tagen(int n) => n == 1 ? S.dayOne : S.dayManyDative(n);
