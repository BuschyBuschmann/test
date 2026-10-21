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
import 'backend/patient_backend.dart';
import 'backend/supabase_bootstrap.dart';
import 'backend/supabase_config.dart';
import 'data/key_value_store.dart';
import 'logic/invite_code.dart';
import 'state/backend_controller.dart';
import 'data/data_eraser.dart';
import 'data/display_store.dart';
import 'data/prefs_state_store.dart';
import 'logic/clock.dart';
import 'logic/manny_text_source.dart';
import 'state/app_controller.dart';
import 'state/display_controller.dart';
import 'theme/font_licenses.dart';

/// Der Controller des Produktionsstarts: Speicher in `shared_preferences`,
/// derselbe Speicher als [DataEraser]. [clock] und [prefs] gibt es nur für
/// Tests (Standard: Systemuhr, echte Plattform).
///
/// Die Darstellungs-Einstellungen ([display], Plan 3.4) stehen mit in der
/// Löscher-Liste: „Alles löschen“ setzt sie zurück.
AppController buildProductionController({
  Clock? clock,
  SharedPreferencesAsync? prefs,
  DisplayController? display,
  PrefsStateStore? store,
}) {
  final Clock now = clock ?? DateTime.now;
  final PrefsStateStore stateStore =
      store ?? PrefsStateStore(clock: now, prefs: prefs);
  return AppController(
    clock: now,
    store: stateStore,
    mannyText: const PlaceholderMannyTextSource(),
    erasers: <DataEraser>[stateStore, ?display],
  );
}

/// Verdrahtung des Backend-Modus (F2-4a): Warteschlange, Zwischenspeicher,
/// Merkzeichen und Löscher liegen im Schlüssel-Speicher von
/// `shared_preferences`. Die lokalen Löscher sind der Zustandsspeicher
/// ([store]) und die Darstellung ([display]); Zwischenspeicher und Warteschlange
/// ergänzt der [BackendController].
BackendController buildProductionBackend({
  required PatientBackend backend,
  required AppController controller,
  required PrefsStateStore store,
  DisplayController? display,
  Clock? clock,
  SharedPreferencesAsync? prefs,
}) {
  return BackendController.wire(
    backend: backend,
    app: controller,
    store: PrefsKeyValueStore(prefs: prefs),
    clock: clock ?? DateTime.now,
    localErasers: <DataEraser>[store, ?display],
  );
}

/// Die Darstellungs-Einstellungen des Produktionsstarts: Speicher in
/// `shared_preferences`, Uhr der Welt ist die Systemuhr.
DisplayController buildProductionDisplay({SharedPreferencesAsync? prefs}) {
  return DisplayController(store: PrefsDisplayStore(prefs: prefs));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final DisplayController display = buildProductionDisplay();
  // Einstellungen vor dem ersten Frame laden (Thema und Welt ohne Flackern).
  await display.load();
  final PrefsStateStore store = PrefsStateStore(clock: DateTime.now);
  final AppController controller = buildProductionController(
    display: display,
    store: store,
  );
  // Ohne Konfiguration (`--dart-define-from-file=config/supabase.local.json`)
  // startet die App wie bisher im Demo-Modus ohne Backend.
  final PatientBackend? backend = await createPatientBackend(
    SupabaseConfig.fromEnvironment(),
  );
  runApp(
    CuraApp(
      controller: controller,
      display: display,
      backend: backend == null
          ? null
          : buildProductionBackend(
              backend: backend,
              controller: controller,
              store: store,
              display: display,
            ),
      initialInviteCode: backend == null ? null : inviteCodeFromLink(Uri.base),
    ),
  );
}
