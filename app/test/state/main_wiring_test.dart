// Verdrahtung des Produktions-Einstiegs (`lib/main.dart`, R-U3 MINOR-3): der
// Speicher steht in der Löscher-Liste. Beweis über die echte Verdrahtung
// (`buildProductionController`) und eine In-Memory-Plattform für
// `shared_preferences`: kaputtes Dokument → Hinweis, nach dem nächsten Start
// kein Hinweis mehr (das Dokument ist wirklich gelöscht).
import 'package:curaone/data/data_eraser.dart';
import 'package:curaone/data/prefs_state_store.dart';
import 'package:curaone/data/state_store.dart';
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/manny_text_source.dart';
import 'package:curaone/logic/display_settings.dart';
import 'package:curaone/logic/world_time.dart';
import 'package:curaone/main.dart';
import 'package:curaone/state/app_controller.dart';
import 'package:curaone/state/display_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../support/app_harness.dart';

void main() {
  late InMemorySharedPreferencesAsync platform;

  setUp(() {
    platform = InMemorySharedPreferencesAsync.withData(<String, Object>{
      kStateStorageKey: '{das ist kein Dokument',
    });
    SharedPreferencesAsyncPlatform.instance = platform;
  });

  Future<String?> stored() =>
      SharedPreferencesAsync().getString(kStateStorageKey);

  testWidgets('kaputtes Dokument: Hinweis beim Start, danach gelöscht, beim '
      'nächsten Start kein Hinweis mehr', (WidgetTester tester) async {
    final AppController first = buildProductionController();
    addTearDown(first.dispose);
    await pumpCura(tester, first);
    expect(find.text(S.dataUnreadable), findsOneWidget);
    expect(find.text('Schritt 1 von 5'), findsOneWidget);
    await disposeApp(tester);
    expect(
      await tester.runAsync(stored),
      isNull,
      reason: 'das kaputte Dokument ist über den Löscher entfernt',
    );

    final AppController second = buildProductionController();
    addTearDown(second.dispose);
    await pumpCura(tester, second);
    expect(find.text(S.dataUnreadable), findsNothing);
    expect(find.text('Schritt 1 von 5'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('Gegenprobe: ohne Löscher bliebe das Dokument und der Hinweis '
      'käme bei jedem Start wieder', (WidgetTester tester) async {
    AppController withoutEraser() => AppController(
      clock: DateTime.now,
      store: PrefsStateStore(clock: DateTime.now),
      mannyText: const PlaceholderMannyTextSource(),
      erasers: const <DataEraser>[],
    );
    final AppController first = withoutEraser();
    addTearDown(first.dispose);
    await pumpCura(tester, first);
    expect(find.text(S.dataUnreadable), findsOneWidget);
    await disposeApp(tester);
    expect(await tester.runAsync(stored), isNotNull);
    final AppController second = withoutEraser();
    addTearDown(second.dispose);
    await pumpCura(tester, second);
    expect(find.text(S.dataUnreadable), findsOneWidget);
    await disposeApp(tester);
  });

  group('Darstellungs-Einstellungen im Produktionsstart (B-21)', () {
    test('„Alles löschen“ setzt die Einstellungen zurück und entfernt den '
        'Schlüssel', () async {
      final DisplayController display = buildProductionDisplay();
      display
        ..setWorld(WorldChoice.night)
        ..setReduceTransparency(true);
      await display.flush();
      expect(
        await SharedPreferencesAsync().getString(kDisplayStorageKey),
        isNotNull,
      );
      final AppController controller = buildProductionController(
        display: display,
      );
      addTearDown(controller.dispose);
      await controller.deleteAll();
      expect(display.settings, const DisplaySettings());
      expect(
        await SharedPreferencesAsync().getString(kDisplayStorageKey),
        isNull,
      );
    });

    test('Neustart: gespeicherte Einstellungen werden geladen', () async {
      final DisplayController first = buildProductionDisplay()
        ..setWorld(WorldChoice.evening)
        ..setTheme(ThemeChoice.dark);
      await first.flush();
      final DisplayController second = buildProductionDisplay();
      await second.load();
      expect(second.settings.world, WorldChoice.evening);
      expect(second.settings.theme, ThemeChoice.dark);
    });
  });
}
