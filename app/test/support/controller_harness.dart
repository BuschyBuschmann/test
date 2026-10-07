import 'package:curaone/data/data_eraser.dart';
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/manny_context.dart';
import 'package:curaone/logic/manny_text_source.dart';
import 'package:curaone/logic/migrations.dart' show encodeDocument;
import 'package:curaone/logic/placeholder_pools.dart';
import 'package:curaone/state/app_controller.dart';
import 'package:curaone/state/transient_ui.dart';

import 'builders.dart';
import 'fake_clock.dart';
import 'raw_state_store.dart';
import 'stores.dart';

/// Eine Text-Quelle, die jeden Anlass erkennbar markiert.
class FakeMannyTextSource implements MannyTextSource {
  @override
  String bubbleText(MannyOccasion occasion, MannyContext ctx) =>
      'FAKE ${occasion.name} ${ctx.firstName}';

  @override
  FactRef fact(MannyContext ctx) => const FactRef(id: 'fake', text: 'FAKE');
}

/// Verdrahtet Controller, Fake-Uhr und Roh-Speicher für Tests.
class Harness {
  Harness._(this.clock, this.raw, this.store, this.controller, this.transient);

  final FakeClock clock;
  final RawDocumentStore raw;
  final RawBackedStateStore store;
  final AppController controller;
  final TransientUi transient;

  AppState get state => controller.state;

  static Future<Harness> boot({
    RawDocumentStore? raw,
    DateTime? now,
    MannyTextSource? text,
    List<DataEraser>? erasers,
    bool load = true,
  }) async {
    final FakeClock clock = FakeClock(now);
    final RawDocumentStore r = raw ?? InMemoryStore();
    final RawBackedStateStore store = RawBackedStateStore(r, clock: clock.call);
    final TransientUi transient = TransientUi();
    final AppController c = AppController(
      clock: clock.call,
      store: store,
      mannyText: text ?? const PlaceholderMannyTextSource(),
      erasers: erasers ?? <DataEraser>[store],
      transient: transient,
    );
    if (load) await c.load();
    return Harness._(clock, r, store, c, transient);
  }

  /// Startet mit einem abgeschlossenen Onboarding (Name Jakob, ACL, Woche 5).
  static Future<Harness> onboarded({
    DateTime? now,
    MannyTextSource? text,
    AppState Function(AppState)? tweak,
  }) async {
    AppState s = onboardedState();
    if (tweak != null) s = tweak(s);
    final InMemoryStore raw = InMemoryStore(
      // Dokument direkt schreiben (wie ein früherer Lauf).
      encodeDocument(s),
    );
    return boot(raw: raw, now: now, text: text);
  }

  /// Liest den gespeicherten Zustand zurück (nach Leerlauf der Schlange).
  Future<AppState?> persisted() async {
    await controller.idle;
    return store.load();
  }

  void dispose() => controller.dispose();
}
