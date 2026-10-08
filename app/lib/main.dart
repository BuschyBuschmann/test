// Produktions-Einstieg (Plan 3): echter Speicher, Systemuhr, Platzhalter-
// Textquelle. Der Speicher steht zugleich in der Löscher-Liste (KS-9); sonst
// bliebe nach „Alles löschen“ bzw. unlesbaren Daten alles beim Alten und die
// App startete endlos neu. Nichts aus `lib/dev/` gelangt hierher.
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/data_eraser.dart';
import 'data/prefs_state_store.dart';
import 'logic/clock.dart';
import 'logic/manny_text_source.dart';
import 'state/app_controller.dart';
import 'theme/font_licenses.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final Clock clock = DateTime.now;
  final PrefsStateStore store = PrefsStateStore(clock: clock);
  final AppController controller = AppController(
    clock: clock,
    store: store,
    mannyText: const PlaceholderMannyTextSource(),
    erasers: <DataEraser>[store],
  );
  runApp(CuraApp(controller: controller));
}
