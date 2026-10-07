// „Alles löschen“ (Plan 6.3, n4, KS-9, UI-51, UI-52, UI-82).
import 'dart:async';

import 'package:curaone/data/data_eraser.dart';
import 'package:curaone/data/state_store.dart';
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/streak.dart';
import 'package:curaone/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';
import '../support/controller_harness.dart';
import '../support/fake_clock.dart';
import '../support/stores.dart';

class RecordingEraser implements DataEraser {
  RecordingEraser(this.name, this.log, {this.fail = false, this.gate});

  final String name;
  final List<String> log;
  final bool fail;
  final Completer<void>? gate;

  @override
  Future<void> eraseAll() async {
    log.add('start $name');
    if (gate != null) await gate!.future;
    if (fail) throw StateError('$name fehlgeschlagen');
    log.add('done $name');
  }
}

AppState rich(AppState s) => s.copyWith(
  streak: StreakState(count: 7, freezes: 0, lastTrainingDay: kToday),
  prefs: const PrefsState(timeChoice: 30),
  day: s.day.copyWith(done: true, removed: <String>['ex-wade']),
);

void main() {
  test(
    'Erfolg: Zustand initial, Store leer, Hinweis „gelöscht“, Transientes weg',
    () async {
      final Harness h = await Harness.onboarded(tweak: rich);
      h.controller.removeExercise('ex-bruecke');
      h.transient.showHint('w5-d1');
      expect(h.transient.undoWindowOpen, isTrue);

      await h.controller.deleteAll();
      // Nach Löschen und Neuaufbau: Streak 0, Freezes 2, keine Einträge, Zeitwahl 20.
      expect(h.state, AppState.initial(kToday));
      expect(h.state.onboarding.step, 0);
      expect(h.state.streak.freezes, 2);
      expect(h.state.prefs.timeChoice, 20);
      expect(h.state.consent, isNull);
      expect((h.raw as InMemoryStore).raw, isNull);
      expect(h.controller.startNotice, StartNotice.deleted);
      expect(h.transient.undoWindowOpen, isFalse);
      expect(h.transient.hintUnitId, isNull);
      h.dispose();
    },
  );

  test(
    'Neustart nach Löschen: Onboarding Schritt 1, Consent erneut nötig',
    () async {
      final Harness h = await Harness.onboarded(tweak: rich);
      await h.controller.deleteAll();
      h.controller.completeDeletion();
      final Harness again = await Harness.boot(raw: h.raw);
      expect(again.state.onboarding.step, 0);
      expect(again.state.consent, isNull);
      expect(again.controller.startNotice, StartNotice.none);
      h.dispose();
      again.dispose();
    },
  );

  test('Löscher laufen der Reihe nach (KS-9)', () async {
    final List<String> log = <String>[];
    final Harness h = await Harness.onboarded();
    final AppController c = AppController(
      clock: FakeClock().call,
      store: h.store,
      mannyText: h.controller.mannyText,
      erasers: <DataEraser>[
        RecordingEraser('a', log),
        RecordingEraser('b', log),
        h.store,
      ],
    );
    await c.load();
    await c.deleteAll();
    expect(log, <String>['start a', 'done a', 'start b', 'done b']);
    expect((h.raw as InMemoryStore).raw, isNull);
    c.dispose();
    h.dispose();
  });

  test('erster Fehler bricht ab, RAM-Zustand unverändert, Schreiben wieder erlaubt', () async {
    final List<String> log = <String>[];
    final Harness h = await Harness.onboarded(tweak: rich);
    final AppController c = AppController(
      clock: FakeClock().call,
      store: h.store,
      mannyText: h.controller.mannyText,
      erasers: <DataEraser>[
        RecordingEraser('a', log, fail: true),
        RecordingEraser('b', log),
      ],
    );
    await c.load();
    final AppState before = c.state;
    await expectLater(c.deleteAll(), throwsStateError);
    expect(log, <String>['start a']); // b wurde nicht aufgerufen
    expect(c.state, before);
    expect(c.isDeleting, isFalse);
    expect(c.startNotice, StartNotice.none);
    // Schreiben wieder erlaubt
    c.setName('Lena');
    await c.idle;
    expect((await h.store.load())!.onboarding.name, 'Lena');
    c.dispose();
    h.dispose();
  });

  test('FailingStore: deleteAll wirft, Zustand bleibt (UI-52)', () async {
    final Harness h = await Harness.onboarded(tweak: rich);
    final AppController c = AppController(
      clock: FakeClock().call,
      store: h.store,
      mannyText: h.controller.mannyText,
      erasers: <DataEraser>[RawBackedStateStore2(FailingStore(), h)],
    );
    await c.load();
    final AppState before = c.state;
    await expectLater(c.deleteAll(), throwsStateError);
    expect(c.state, before);
    expect(c.isDeleting, isFalse);
    c.dispose();
    h.dispose();
  });

  test('SlowStore: während des Löschens busy; Doppelaufruf nur ein Vorgang; Schreiben gesperrt', () async {
    final List<String> log = <String>[];
    final Completer<void> gate = Completer<void>();
    final Harness h = await Harness.onboarded(tweak: rich);
    final AppController c = AppController(
      clock: FakeClock().call,
      store: h.store,
      mannyText: h.controller.mannyText,
      erasers: <DataEraser>[RecordingEraser('slow', log, gate: gate)],
    );
    await c.load();
    final Future<void> first = c.deleteAll();
    final Future<void> second = c.deleteAll(); // Doppeltipp
    await Future<void>.delayed(Duration.zero);
    expect(c.isDeleting, isTrue);
    expect(log, <String>['start slow']); // nur ein Vorgang
    // Während des Löschens verworfene Schreibaufträge.
    final int writes = (h.raw as InMemoryStore).writes;
    c.setName('Neu');
    await Future<void>.delayed(Duration.zero);
    expect((h.raw as InMemoryStore).writes, writes);
    gate.complete();
    await first;
    await second;
    expect(log, <String>['start slow', 'done slow']);
    expect(c.isDeleting, isTrue); // bleibt bis zum Neuaufbau
    c.setName('Spaet');
    await c.idle;
    expect((h.raw as InMemoryStore).writes, writes); // weiter gesperrt
    c.completeDeletion();
    expect(c.isDeleting, isFalse);
    c.setName('Frisch');
    await c.idle;
    expect((await h.store.load())!.onboarding.name, 'Frisch');
    c.dispose();
    h.dispose();
  });

  test('wartet auf das Leerlaufen der Schreibschlange (n4)', () async {
    final SlowStore slow = SlowStore(InMemoryStore());
    final Harness h = await Harness.boot(raw: slow, load: false);
    slow.release();
    await h.controller.load();
    slow.hold();
    h.controller.setName('X'); // Schreibvorgang hängt
    await Future<void>.delayed(Duration.zero);
    bool deleted = false;
    final Future<void> del = h.controller.deleteAll().then(
      (_) => deleted = true,
    );
    await Future<void>.delayed(Duration.zero);
    expect(deleted, isFalse);
    expect((slow).pending, greaterThanOrEqualTo(1));
    slow.release();
    await del;
    expect(deleted, isTrue);
    expect(h.state.onboarding.name, '');
    h.dispose();
  });

  test('Store-Schlüssel: nach Löschen kein Schlüssel aus kAllStorageKeys (UI-51/UI-82)', () {
    expect(kAllStorageKeys, <String>{kStateStorageKey});
  });
}

/// Löscher, der über den Fake-Roh-Speicher geht (hier: wirft).
class RawBackedStateStore2 implements DataEraser {
  RawBackedStateStore2(this.raw, this.h);

  final RawDocumentStore raw;
  final Harness h;

  @override
  Future<void> eraseAll() => raw.deleteAll();
}
