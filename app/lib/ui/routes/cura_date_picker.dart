// Datumsauswahl der Plattform (Material `DatePickerDialog`, Dark-Theme aus
// `CuraTheme`) auf der `CuraDialogRoute`. `showDatePicker` blendet mit festen
// 150 ms ein; bei „Bewegung reduzieren“ sind höchstens 120 ms erlaubt (UI-8,
// UI-64). Die eigene Route nimmt die Dauer aus `CuraMotion` und stellt den
// Scrim aus dem Token `scrim`. Grenzen und Rückgabe wie bei `showDatePicker`
// (Datum oder `null`, Abbrechen und Scrim liefern `null`).
import 'package:flutter/material.dart';

import 'cura_dialog_route.dart';

Future<DateTime?> showCuraDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return Navigator.of(context, rootNavigator: true).push<DateTime>(
    CuraDialogRoute<DateTime>(
      context: context,
      builder: (BuildContext context) => DatePickerDialog(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    ),
  );
}
