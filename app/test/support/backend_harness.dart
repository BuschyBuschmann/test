import 'package:curaone/data/key_value_store.dart';
import 'package:curaone/dev/fake_backend.dart';
import 'package:curaone/dev/preview_stores.dart';
import 'package:curaone/logic/manny_text_source.dart';
import 'package:curaone/state/app_controller.dart';
import 'package:curaone/state/backend_controller.dart';

import 'framework_builders.dart';

/// Backend-Modus ohne Netzwerk: `FakePatientBackend`, Speicher im Arbeitsspeicher.
class BackendHarness {
  BackendHarness({
    FakePatientBackend? fake,
    DateTime? now,
    MemoryStateStore? state,
  }) : fake = fake ?? (FakePatientBackend(framework: sampleFramework())),
       kv = MemoryKeyValueStore(),
       now = now ?? DateTime(2026, 10, 7, 12),
       stateStore = state ?? MemoryStateStore() {
    app = AppController(
      clock: () => this.now,
      store: stateStore,
      mannyText: const PlaceholderMannyTextSource(),
      erasers: [stateStore],
    );
    backend = BackendController.wire(
      backend: this.fake,
      app: app,
      store: kv,
      clock: () => this.now,
      localErasers: [stateStore],
    );
  }

  final FakePatientBackend fake;
  final MemoryKeyValueStore kv;
  final MemoryStateStore stateStore;
  DateTime now;
  late final AppController app;
  late final BackendController backend;

  void dispose() {
    backend.dispose();
    app.dispose();
  }
}
