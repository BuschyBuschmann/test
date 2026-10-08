// Produktions-Einstieg (Plan 3): echter Speicher, Systemuhr, Platzhalter-
// Textquelle. Der Speicher steht zugleich in der Löscher-Liste (KS-9); sonst
// bliebe nach „Alles löschen“ bzw. unlesbaren Daten alles beim Alten und die
// App startete endlos neu. Nichts aus `lib/dev/` gelangt hierher.
//
// Die Verdrahtung steht in [buildProductionController], damit ein Test genau
// diese Verdrahtung prüft (und nicht eine nachgebaute).
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/data_eraser.dart';
import 'data/prefs_state_store.dart';
import 'logic/clock.dart';
import 'logic/manny_text_source.dart';
import 'state/app_controller.dart';
import 'theme/font_licenses.dart';

/// Der Controller des Produktionsstarts: Speicher in `shared_preferences`,
/// derselbe Speicher als [DataEraser]. [clock] und [prefs] gibt es nur für
/// Tests (Standard: Systemuhr, echte Plattform).
AppController buildProductionController({
  Clock? clock,
  SharedPreferencesAsync? prefs,
}) {
  final Clock now = clock ?? DateTime.now;
  final PrefsStateStore store = PrefsStateStore(clock: now, prefs: prefs);
  return AppController(
    clock: now,
    store: store,
    mannyText: const PlaceholderMannyTextSource(),
    erasers: <DataEraser>[store],
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  runApp(CuraApp(controller: buildProductionController()));
}
