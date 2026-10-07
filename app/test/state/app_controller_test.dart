import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/day_program.dart';
import 'package:curaone/logic/injury_type.dart';
import 'package:curaone/logic/profile.dart';
import 'package:curaone/logic/streak.dart';
import 'package:curaone/state/app_controller.dart';
import 'package:curaone/state/transient_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';
import '../support/controller_harness.dart';
import '../support/stores.dart';

/// Liest zuerst nicht (Plattformfehler), danach normal.
class FlakyReadStore implements RawDocumentStore {
  FlakyReadStore(this.inner, {this.failReads = 1});

  final InMemoryStore inner;
  int failReads;

  @override
  Future<String?> read() {
    if (failReads > 0) {
      failReads--;
      return Future<String?>.error(StateError('plattform'));
    }
    return inner.read();
  }

  @override
  Future<void> write(String raw) => inner.write(raw);

  @override
  Future<void> deleteAll() => inner.deleteAll();
}

/// Schreiben schlägt die ersten [failWrites] Male fehl.
class FlakyWriteStore implements RawDocumentStore {
  FlakyWriteStore({this.failWrites = 1});

  final InMemoryStore inner = InMemoryStore();
  int failWrites;
  int attempts = 0;

  @override
  Future<String?> read() => inner.read();

  @override
  Future<void> write(String raw) {
    attempts++;
    if (failWrites > 0) {
      failWrites--;
      return Future<void>.error(StateError('voll'));
    }
    return inner.write(raw);
  }

  @override
  Future<void> deleteAll() => inner.deleteAll();
}

LocalDay get tomorrow => kToday.addDays(1);

void main() {
  group('Laden (6.2, N-12)', () {
    test(
      'nichts gespeichert: Erststart, Onboarding Schritt 1, nichts geschrieben',
      () async {
        final Harness h = await Harness.boot();
        expect(h.controller.loadStatus, LoadStatus.ready);
        expect(h.state, AppState.initial(kToday));
        expect(h.state.onboarding.completed, isFalse);
        expect(h.state.onboarding.step, 0);
        expect(h.controller.startNotice, StartNotice.none);
        expect((h.raw as InMemoryStore).writes, 0);
        h.dispose();
      },
    );

    test('vor load(): Status loading', () async {
      final Harness h = await Harness.boot(load: false);
      expect(h.controller.loadStatus, LoadStatus.loading);
      h.dispose();
    });

    test(
      'gespeicherter Zustand wird geladen (neu pumpen am selben Tag, UI-43)',
      () async {
        final Harness a = await Harness.onboarded(
          tweak: (AppState s) => s.copyWith(
            day: s.day.copyWith(removed: <String>['ex-wade'], done: true),
          ),
        );
        expect(a.state.day.removed, <String>['ex-wade']);
        expect(a.state.day.done, isTrue);
        expect(a.state.onboarding.firstName, 'Jakob');
        a.dispose();
      },
    );

    test(
      'Tageswechsel beim App-Start: still angewendet und gespeichert',
      () async {
        final Harness h = await Harness.onboarded(
          now: DateTime(2026, 10, 8, 8),
          tweak: (AppState s) => s.copyWith(
            day: s.day.copyWith(done: true, removed: <String>['ex-wade']),
          ),
        );
        expect(h.state.day, DayProgramState.fresh(tomorrow));
        expect(h.controller.startNotice, StartNotice.none);
        final AppState? saved = await h.persisted();
        expect(saved!.day, DayProgramState.fresh(tomorrow));
        h.dispose();
      },
    );

    for (final String bad in <String>[
      '{kaputt',
      '{"schema":99,"onboarding":{"completed":true,"step":3}}',
      '{"schema":1}',
      '{"schema":1,"onboarding":{"completed":"x","step":0}}',
    ]) {
      test(
        'unlesbar ($bad): Store geleert, Onboarding Schritt 1, Hinweis',
        () async {
          final CorruptStore raw = CorruptStore(bad);
          final Harness h = await Harness.boot(raw: raw);
          expect(raw.deleted, isTrue);
          expect(h.controller.loadStatus, LoadStatus.ready);
          expect(h.state, AppState.initial(kToday));
          expect(h.state.onboarding.step, 0);
          expect(h.controller.startNotice, StartNotice.unreadable);
          h.controller.clearStartNotice();
          expect(h.controller.startNotice, StartNotice.none);
          h.dispose();
        },
      );
    }

    test(
      'Lese-Exception der Plattform → Fehlerzustand, retryLoad lädt',
      () async {
        final InMemoryStore inner = InMemoryStore();
        final FlakyReadStore raw = FlakyReadStore(inner);
        final Harness h = await Harness.boot(raw: raw);
        expect(h.controller.loadStatus, LoadStatus.error);
        expect(inner.deletes, 0); // Daten nicht angetastet
        await h.controller.retryLoad();
        expect(h.controller.loadStatus, LoadStatus.ready);
        h.dispose();
      },
    );

    test('FailingStore: Fehlerzustand statt Neustart', () async {
      final Harness h = await Harness.boot(raw: FailingStore());
      expect(h.controller.loadStatus, LoadStatus.error);
      expect(h.controller.startNotice, StartNotice.none);
      h.dispose();
    });

    test('unlesbar und Verwerfen schlägt fehl → Fehlerzustand', () async {
      final _CorruptUndeletable raw = _CorruptUndeletable();
      final Harness h = await Harness.boot(raw: raw);
      expect(h.controller.loadStatus, LoadStatus.error);
      h.dispose();
    });
  });

  group('Onboarding speichert sofort (UI-16, UI-43)', () {
    test(
      'Name, Schritt, Consent, Typ, Freitext, Datum; Neustart setzt fort',
      () async {
        final Harness h = await Harness.boot(
          now: DateTime(2026, 10, 7, 8, 12, 30, 123),
        );
        final AppController c = h.controller;
        c.setName('  Jakob ');
        c.setStep(1);
        c.acceptConsent();
        c.setStep(2);
        c.selectInjury(InjuryType.other);
        c.setInjuryOther('Schulter');
        c.setStep(3);
        c.setInjuryDate(const LocalDay(2026, 9, 3));
        await c.idle;

        final Harness restarted = await Harness.boot(
          raw: h.raw,
          now: DateTime(2026, 10, 7, 9),
        );
        final OnboardingState o = restarted.state.onboarding;
        expect(o.name, '  Jakob ');
        expect(o.firstName, 'Jakob');
        expect(o.step, 3);
        expect(o.injuryType, InjuryType.other);
        expect(o.injuryOther, 'Schulter');
        expect(o.injuryDate, const LocalDay(2026, 9, 3));
        expect(o.completed, isFalse);
        // Consent: UTC-Zeitstempel der FakeClock, Version prototype-0 (UI-13).
        expect(
          restarted.state.consent!.acceptedAt,
          DateTime(2026, 10, 7, 8, 12, 30, 123).toUtc(),
        );
        expect(restarted.state.consent!.acceptedAt.isUtc, isTrue);
        expect(restarted.state.consent!.version, 'prototype-0');
        h.dispose();
        restarted.dispose();
      },
    );

    test('erneutes Bestätigen überschreibt den Zeitstempel (A-2)', () async {
      final Harness h = await Harness.boot(now: DateTime(2026, 10, 7, 8));
      h.controller.acceptConsent();
      final DateTime first = h.state.consent!.acceptedAt;
      h.clock.advance(const Duration(minutes: 5));
      h.controller.acceptConsent();
      expect(
        h.state.consent!.acceptedAt,
        first.add(const Duration(minutes: 5)),
      );
      h.dispose();
    });

    test('setStep begrenzt auf 0..3', () async {
      final Harness h = await Harness.boot();
      h.controller.setStep(9);
      expect(h.state.onboarding.step, 3);
      h.controller.setStep(-2);
      expect(h.state.onboarding.step, 0);
      h.dispose();
    });

    test('completeOnboarding: Voraussetzungen, Begrüßung fällig, Freitext-Bereinigung', () async {
      final Harness h = await Harness.boot();
      final AppController c = h.controller;
      expect(c.completeOnboarding(), isFalse);
      c.setName('Jakob');
      c.selectInjury(InjuryType.acl);
      c.setInjuryOther('vergessener Text');
      c.setInjuryDate(const LocalDay(2026, 9, 7));
      expect(c.completeOnboarding(), isFalse); // Consent fehlt
      c.acceptConsent();
      c.setName('   ');
      expect(c.completeOnboarding(), isFalse); // Name leer
      c.setName('Jakob');
      expect(c.completeOnboarding(), isTrue);
      expect(h.state.onboarding.completed, isTrue);
      expect(h.state.manny.greetingPending, isTrue);
      expect(h.state.onboarding.injuryOther, '');
      expect(h.state.streak, const StreakState());
      final PathVisit v = c.onPathVisible();
      expect(v.bubble!.occasion, MannyOccasion.greeting);
      h.dispose();
    });
  });

  group('Tageswechsel zuerst (N-11): jede mutierende Methode', () {
    // Ausgang: Heute-Programm mit Änderungen und `done`, dann +1 Tag.
    Future<Harness> stale() => Harness.onboarded(
      tweak: (AppState s) => s.copyWith(
        day: s.day.copyWith(
          done: true,
          removed: <String>['ex-wade'],
          custom: <CustomExercise>[
            const CustomExercise(
              id: 'custom-1',
              name: 'X',
              reps: 'r',
              minutes: 1,
            ),
          ],
        ),
        manny: s.manny.copyWith(greetingPending: true),
      ),
    );

    final Map<String, Object? Function(AppController c, Harness h)> actions =
        <String, Object? Function(AppController, Harness)>{
          'setName': (c, h) => c.setName('Lena'),
          'setStep': (c, h) => c.setStep(1),
          'acceptConsent': (c, h) => c.acceptConsent(),
          'selectInjury': (c, h) => c.selectInjury(InjuryType.ankle),
          'setInjuryOther': (c, h) => c.setInjuryOther('x'),
          'setInjuryDate': (c, h) => c.setInjuryDate(kToday),
          'completeOnboarding': (c, h) => c.completeOnboarding(),
          'selectTime': (c, h) => c.selectTime(10),
          'swapExercise': (c, h) => c.swapExercise('ex-kniebeuge'),
          'removeExercise': (c, h) => c.removeExercise('ex-bruecke'),
          'undoRemove': (c, h) =>
              c.undoRemove(RemovalToken(day: kToday, exerciseId: 'ex-wade')),
          'addCustomExercise': (c, h) => c.addCustomExercise(name: 'Neu'),
          'logTraining': (c, h) => c.logTraining(forDay: tomorrow),
          'undoTraining': (c, h) =>
              c.undoTraining(TrainingSnapshot.capture(h.state)),
          'markBubbleShown': (c, h) =>
              c.markBubbleShown(MannyOccasion.greeting),
          'consumeCelebration': (c, h) => c.consumeCelebration(),
          'updateProfile': (c, h) => c.updateProfile(
            ProfileDraft.fromState(h.state).copyWith(name: 'Lena'),
          ),
          'checkDayChange': (c, h) => c.checkDayChange(),
          'onPathVisible': (c, h) => c.onPathVisible(),
        };

    for (final MapEntry<String, Object? Function(AppController, Harness)> e
        in actions.entries) {
      test('${e.key}: Wechsel wird vor der Aktion angewendet', () async {
        final Harness h = await stale();
        expect(h.state.day.done, isTrue);
        h.clock.advanceDays(1);
        e.value(h.controller, h);
        expect(h.state.day.dayKey, tomorrow, reason: e.key);
        expect(h.state.day.done, e.key == 'logTraining', reason: e.key);
        // Das alte Programm (entfernte/eigene Übungen) ist verschwunden.
        expect(h.state.day.removed.contains('ex-wade'), isFalse, reason: e.key);
        expect(
          h.state.day.custom.any((CustomExercise c) => c.name == 'X'),
          isFalse,
          reason: e.key,
        );
        final AppState? saved = await h.persisted();
        expect(saved!.day.dayKey, tomorrow, reason: e.key);
        h.dispose();
      });
    }

    test('Ergebnis meldet den Wechsel an die UI', () async {
      final Harness h = await stale();
      expect(h.controller.checkDayChange().changed, isFalse);
      h.clock.advanceDays(1);
      expect(h.controller.checkDayChange().changed, isTrue);
      expect(h.controller.checkDayChange().changed, isFalse);
      h.clock.advanceDays(1);
      expect(h.controller.selectTime(30).changed, isTrue);
      h.clock.advanceDays(1);
      expect(h.controller.swapExercise('ex-kniebeuge').changed, isTrue);
      h.clock.advanceDays(1);
      expect(h.controller.removeExercise('ex-wade').dayChanged, isTrue);
      h.clock.advanceDays(1);
      expect(
        h.controller
            .updateProfile(
              ProfileDraft.fromState(h.state).copyWith(name: 'Lena'),
            )
            .dayChanged,
        isTrue,
      );
      h.clock.advanceDays(1);
      expect(h.controller.onPathVisible().dayChange.changed, isTrue);
      h.dispose();
    });

    test('Wechsel beendet ein laufendes Rückgängig-Fenster', () async {
      final Harness h = await Harness.onboarded();
      h.controller.removeExercise('ex-wade');
      expect(h.transient.undoWindowOpen, isTrue);
      h.clock.advanceDays(1);
      h.controller.checkDayChange();
      expect(h.transient.undoWindowOpen, isFalse);
      h.dispose();
    });

    test('Uhr rückwärts ist ebenfalls ein Wechsel', () async {
      final Harness h = await Harness.onboarded();
      h.clock.advanceDays(-1);
      expect(h.controller.checkDayChange().changed, isTrue);
      expect(h.state.day.dayKey, kToday.addDays(-1));
      h.dispose();
    });
  });

  group('Heute', () {
    test(
      'selectTime: nur 10/20/30; Zeitwahl bleibt nach Tageswechsel (N-8)',
      () async {
        final Harness h = await Harness.onboarded();
        expect(h.state.prefs.timeChoice, 20);
        h.controller.selectTime(30);
        expect(h.state.prefs.timeChoice, 30);
        h.controller.selectTime(15);
        expect(h.state.prefs.timeChoice, 30);
        h.clock.advanceDays(1);
        h.controller.checkDayChange();
        expect(h.state.prefs.timeChoice, 30);
        h.dispose();
      },
    );

    test(
      'Tauschen und Entfernen (mit Token und Fenster), Rückgängig',
      () async {
        final Harness h = await Harness.onboarded();
        final AppController c = h.controller;
        c.swapExercise('ex-kniebeuge');
        expect(h.state.day.swaps['ex-kniebeuge'], 1);
        final RemoveResult r = c.removeExercise('ex-bruecke');
        expect(r.token, isNotNull);
        expect(r.dayChanged, isFalse);
        expect(h.state.day.removed, <String>['ex-bruecke']);
        expect(h.transient.undo, isA<RemovalUndo>());
        final UndoResult u = c.undoRemove(r.token!);
        expect(u.applied, isTrue);
        expect(h.state.day.removed, isEmpty);
        expect(h.transient.undoWindowOpen, isFalse);
        h.dispose();
      },
    );

    test(
      'Entfernen einer unbekannten/entfernten Übung: kein Token, kein Fenster',
      () async {
        final Harness h = await Harness.onboarded();
        expect(h.controller.removeExercise('nix').token, isNull);
        expect(h.transient.undoWindowOpen, isFalse);
        h.controller.removeExercise('ex-wade');
        h.transient.endUndoWindow();
        expect(h.controller.removeExercise('ex-wade').token, isNull);
        expect(h.transient.undoWindowOpen, isFalse);
        h.dispose();
      },
    );

    test('Rückgängig nach Tageswechsel wird abgelehnt', () async {
      final Harness h = await Harness.onboarded();
      final RemovalToken token = h.controller.removeExercise('ex-wade').token!;
      h.clock.advanceDays(1);
      final UndoResult u = h.controller.undoRemove(token);
      expect(u.applied, isFalse);
      expect(u.dayChanged, isTrue);
      expect(h.state.day, DayProgramState.fresh(tomorrow));
      h.dispose();
    });

    test('Eigene Übung: Vorgaben als Rückfall, leerer Name wirkungslos, IDs nie doppelt', () async {
      final Harness h = await Harness.onboarded();
      final AppController c = h.controller;
      c.addCustomExercise(name: '   ');
      expect(h.state.day.custom, isEmpty);
      c.addCustomExercise(name: 'Plank');
      final CustomExercise first = h.state.day.custom.single;
      expect((first.name, first.reps, first.minutes), ('Plank', '3 × 10', 5));
      // entfernen, neu hinzufügen, Rückgängig: keine ID-Kollision
      final RemovalToken t = c.removeExercise(first.id).token!;
      c.addCustomExercise(name: 'Brett', reps: '2 × 30 Sek.', minutes: '8');
      final CustomExercise second = h.state.day.custom.single;
      expect(second.id, isNot(first.id));
      c.undoRemove(t);
      expect(h.state.day.custom.map((e) => e.name), <String>['Plank', 'Brett']);
      expect(h.state.day.custom.map((e) => e.id).toSet(), hasLength(2));
      expect(deriveExercises(h.state.day, 20).last.name, 'Brett');
      h.dispose();
    });

    test(
      'Entfernen einer eigenen Übung wirkt und ist rückgängig machbar',
      () async {
        final Harness h = await Harness.onboarded();
        h.controller.addCustomExercise(name: 'A');
        h.controller.addCustomExercise(name: 'B');
        final String idA = h.state.day.custom.first.id;
        final RemoveResult r = h.controller.removeExercise(idA);
        expect(h.state.day.custom.map((e) => e.name), <String>['B']);
        h.controller.undoRemove(r.token!);
        expect(h.state.day.custom.map((e) => e.name), <String>['A', 'B']);
        h.dispose();
      },
    );
  });

  group('Training eintragen (UI-30, UI-38, N-11)', () {
    test(
      'Eintragen: Streak, Unit, done, Fenster; Rückgängig stellt alles her',
      () async {
        final Harness h = await Harness.onboarded(
          tweak: (AppState s) => s.copyWith(
            streak: StreakState(count: 12, lastTrainingDay: kToday.addDays(-1)),
          ),
        );
        final AppState before = h.state;
        final TrainingResult r = h.controller.logTraining(forDay: kToday);
        expect(r.applied, isTrue);
        expect(r.dayChanged, isFalse);
        expect(r.snapshot, isNotNull);
        expect(h.state.streak.count, 13);
        expect(h.state.day.done, isTrue);
        expect(h.state.path.completedUnitIds, <String>['w5-d1']);
        expect(h.transient.undo, isA<TrainingUndo>());
        expect(h.transient.undoWindowOpen, isTrue);

        final UndoResult u = h.controller.undoTraining(r.snapshot!);
        expect(u.applied, isTrue);
        expect(h.state, before);
        expect(h.transient.undoWindowOpen, isFalse);
        // erneutes Eintragen ist normal möglich
        expect(h.controller.logTraining(forDay: kToday).snapshot, isNotNull);
        h.dispose();
      },
    );

    test(
      'zweites Eintragen am selben Tag: kein Snapshot, kein neues Fenster',
      () async {
        final Harness h = await Harness.onboarded();
        h.controller.logTraining(forDay: kToday);
        h.transient.endUndoWindow();
        final TrainingResult r = h.controller.logTraining(forDay: kToday);
        expect(r.applied, isFalse);
        expect(r.snapshot, isNull);
        expect(h.transient.undoWindowOpen, isFalse);
        expect(h.state.streak.count, 1);
        h.dispose();
      },
    );

    test('Rückgängig nach Tageswechsel wird abgelehnt (Controller)', () async {
      final Harness h = await Harness.onboarded();
      final TrainingSnapshot snap = h.controller
          .logTraining(forDay: kToday)
          .snapshot!;
      h.clock.advanceDays(1);
      final UndoResult u = h.controller.undoTraining(snap);
      expect(u.applied, isFalse);
      expect(u.dayChanged, isTrue);
      expect(h.state.streak.count, 1);
      expect(h.state.day.done, isFalse);
      h.dispose();
    });

    test('Eintrag über Mitternacht: zählt für den Vortag, danach Wechsel, kein Fenster, keine Feier', () async {
      final Harness h = await Harness.onboarded(
        now: DateTime(2026, 10, 7, 23, 59),
        tweak: (AppState s) => s.copyWith(
          streak: StreakState(count: 4, lastTrainingDay: kToday.addDays(-1)),
        ),
      );
      final LocalDay openedDay = h.controller.today; // Sheet öffnen um 23:59
      expect(openedDay, kToday);
      h.clock.set(DateTime(2026, 10, 8, 0, 1));
      final TrainingResult r = h.controller.logTraining(forDay: openedDay);
      expect(r.dayChanged, isTrue);
      expect(r.applied, isTrue); // MINOR-4: eingetragen, aber ohne Undo
      expect(r.snapshot, isNull);
      expect(h.transient.undoWindowOpen, isFalse);
      expect(h.state.day, DayProgramState.fresh(tomorrow));
      expect(h.state.celebration, isNull);
      expect(h.state.path.pulsePending, isNull);
      expect(h.state.streak.count, 5);
      expect(h.state.streak.lastTrainingDay, kToday);
      expect(h.state.streak.freezes, 2);
      expect(StreakEngine.view(h.state.streak).display, StreakDisplay.active);
      expect(h.state.path.completedUnitIds, <String>['w5-d1']);
      expect(
        h.controller.onPathVisible().bubble?.occasion,
        isNot(MannyOccasion.celebration),
      );
      final AppState? saved = await h.persisted();
      expect(saved, h.state);
      h.dispose();
    });

    test(
      'Eintrag für einen Tag, der nicht zum Programm passt, wird abgelehnt',
      () async {
        final Harness h = await Harness.onboarded(
          now: DateTime(2026, 10, 8, 0, 1),
        );
        // Zustand wurde beim Start bereits auf den 8.10. gerollt.
        expect(h.state.day.dayKey, tomorrow);
        final TrainingResult r = h.controller.logTraining(forDay: kToday);
        expect(r.applied, isFalse); // MINOR-4: abgelehnt, nicht nur ohne Undo
        expect(r.snapshot, isNull);
        expect(h.state.day.done, isFalse);
        expect(h.state.streak.count, 0);
        h.dispose();
      },
    );

    test('S25 über den Controller: Uhr zurück + Eintrag: done, Streak unverändert, keine Unit, keine Feier', () async {
      final Harness h = await Harness.onboarded(
        tweak: (AppState s) => s.copyWith(
          streak: StreakState(count: 4, lastTrainingDay: kToday.addDays(-1)),
        ),
      );
      h.controller.logTraining(forDay: kToday);
      h.transient.endUndoWindow();
      h.controller.consumeCelebration();
      final StreakState streakAfter = h.state.streak;
      final List<String> units = h.state.path.completedUnitIds;
      h.clock.advanceDays(-1);
      final TrainingResult r = h.controller.logTraining(
        forDay: h.controller.today,
      );
      expect(r.dayChanged, isTrue);
      expect(r.snapshot, isNotNull);
      expect(h.state.day.done, isTrue);
      expect(h.state.streak, streakAfter);
      expect(h.state.path.completedUnitIds, units);
      expect(h.state.celebration, isNull);
      h.dispose();
    });
  });

  group('Pfad und Manny', () {
    test('Feier erscheint erst nach dem Rückgängig-Fenster (UI-40)', () async {
      final Harness h = await Harness.onboarded();
      h.controller.logTraining(forDay: kToday);
      expect(h.transient.undoWindowOpen, isTrue);
      expect(h.controller.onPathVisible().bubble, isNull);
      h.transient.endUndoWindow(); // Tabwechsel o. Ä.
      final PathVisit v = h.controller.onPathVisible();
      expect(v.bubble!.occasion, MannyOccasion.celebration);
      expect(v.bubble!.pulseUnitId, 'w5-d1');
      expect(
        h.controller.bubbleText(v.bubble!),
        'Stark, Jakob. Das war Tag 1.',
      );
      h.controller.markBubbleShown(MannyOccasion.celebration);
      h.controller.consumeCelebration();
      expect(h.state.celebration, isNull);
      expect(h.state.path.pulsePending, isNull);
      expect(h.controller.onPathVisible().bubble, isNull);
      h.dispose();
    });

    test('Text kommt aus der injizierten Quelle (KS-1)', () async {
      final Harness h = await Harness.onboarded(text: FakeMannyTextSource());
      final BubbleDecision d = h.controller.onPathVisible().bubble!;
      expect(h.controller.bubbleText(d), 'FAKE fact Jakob');
      expect(h.controller.mannyContext.firstName, 'Jakob');
      h.dispose();
    });

    test(
      'markBubbleShown: einmal pro Tag, am Folgetag wieder (UI-45)',
      () async {
        final Harness h = await Harness.onboarded();
        expect(
          h.controller.onPathVisible().bubble!.occasion,
          MannyOccasion.fact,
        );
        h.controller.markBubbleShown(MannyOccasion.fact);
        expect(h.controller.onPathVisible().bubble, isNull);
        h.clock.advanceDays(1);
        expect(
          h.controller.onPathVisible().bubble!.occasion,
          MannyOccasion.fact,
        );
        h.dispose();
      },
    );

    test('Streak-Gefahr ab 18:00 mit Plural', () async {
      final Harness h = await Harness.onboarded(
        now: DateTime(2026, 10, 7, 18),
        tweak: (AppState s) => s.copyWith(
          streak: StreakState(count: 1, lastTrainingDay: kToday.addDays(-1)),
        ),
      );
      final BubbleDecision d = h.controller.onPathVisible().bubble!;
      expect(d.occasion, MannyOccasion.streakDanger);
      expect(
        h.controller.bubbleText(d),
        'Dein Streak von 1 Tag wartet auf dich. Heute noch eine Runde?',
      );
      h.dispose();
    });

    test('Neustart-Nachricht nach Reset beim Tageswechsel', () async {
      final Harness h = await Harness.onboarded(
        tweak: (AppState s) => s.copyWith(
          streak: StreakState(
            count: 5,
            freezes: 0,
            lastTrainingDay: kToday.addDays(-1),
          ),
        ),
      );
      h.clock.advanceDays(3);
      final PathVisit v = h.controller.onPathVisible();
      expect(v.dayChange.changed, isTrue);
      expect(v.bubble!.occasion, MannyOccasion.restart);
      expect(
        h.controller.bubbleText(v.bubble!),
        'Neuer Anlauf, Jakob. Dein Pfad bleibt, der Streak startet heute neu.',
      );
      h.dispose();
    });
  });

  group('Profil (7.8)', () {
    test('Speichern: Name sofort, Pfad neu bei Typ/Datum, Flags', () async {
      final Harness h = await Harness.onboarded();
      h.controller.logTraining(forDay: kToday);
      h.transient.endUndoWindow();
      final ProfileDraft d = ProfileDraft.fromState(h.state);

      final ProfileUpdateResult nameOnly = h.controller.updateProfile(
        d.copyWith(name: 'Lena'),
      );
      expect(nameOnly.saved, isTrue);
      expect(nameOnly.nameChanged, isTrue);
      expect(nameOnly.pathRecomputed, isFalse);
      expect(h.state.path.completedUnitIds, <String>['w5-d1']);

      final ProfileUpdateResult both = h.controller.updateProfile(
        ProfileDraft.fromState(h.state).copyWith(
          injuryType: InjuryType.muscle,
          injuryDate: kToday.addDays(-60),
        ),
      );
      expect(both.pathRecomputed, isTrue);
      expect(h.state.path.completedUnitIds, isEmpty);
      expect(h.state.streak.count, 1);
      expect(h.state.day.done, isTrue);
      h.dispose();
    });

    test('nicht speicherbarer Entwurf: nichts passiert', () async {
      final Harness h = await Harness.onboarded();
      final AppState before = h.state;
      final ProfileUpdateResult r = h.controller.updateProfile(
        ProfileDraft.fromState(h.state).copyWith(name: '   '),
      );
      expect(r.saved, isFalse);
      expect(h.state, before);
      expect(
        h.controller
            .updateProfile(
              ProfileDraft.fromState(h.state)
                  .copyWith(injuryDate: kToday.addDays(2)),
            )
            .saved,
        isFalse,
      );
      h.dispose();
    });
  });

  group('Schreiben (A-4)', () {
    test('Schreibfehler: keine Ausnahme, Zustand bleibt, nächster Versuch speichert', () async {
      final FlakyWriteStore raw = FlakyWriteStore();
      final Harness h = await Harness.boot(raw: raw);
      h.controller.setName('Jakob');
      await h.controller.idle;
      expect(raw.attempts, 1);
      expect(raw.inner.raw, isNull);
      expect(h.state.onboarding.name, 'Jakob');
      h.controller.setStep(1);
      await h.controller.idle;
      expect(raw.attempts, 2);
      expect(
        (await h.persisted())!.onboarding.name,
        'Jakob',
        reason: 'das ganze Dokument wird erneut geschrieben',
      );
      h.dispose();
    });

    test(
      'serielle Schlange: Schreibaufträge laufen nacheinander in Reihenfolge',
      () async {
        final SlowStore slow = SlowStore();
        final Harness h = await Harness.boot(raw: slow, load: false);
        slow.release();
        await h.controller.load();
        slow.hold();
        h.controller.setName('A');
        h.controller.setName('AB');
        h.controller.setName('ABC');
        await Future<void>.delayed(Duration.zero);
        expect(slow.pending, 1); // nur ein Schreibvorgang läuft
        slow.release();
        await h.controller.idle;
        expect((await h.persisted())!.onboarding.name, 'ABC');
        h.dispose();
      },
    );

    test('keine Schreibvorgänge ohne Änderung', () async {
      final Harness h = await Harness.onboarded();
      final InMemoryStore raw = h.raw as InMemoryStore;
      final int writes = raw.writes;
      h.controller.setName('Jakob'); // gleicher Wert
      h.controller.selectTime(20);
      h.controller.checkDayChange();
      await h.controller.idle;
      expect(raw.writes, writes);
      h.dispose();
    });

    test('notifyListeners bei Änderung, nicht ohne', () async {
      final Harness h = await Harness.onboarded();
      int calls = 0;
      h.controller.addListener(() => calls++);
      h.controller.setName('Jakob');
      expect(calls, 0);
      h.controller.setName('Lena');
      expect(calls, 1);
      h.dispose();
    });
  });
}

/// Unlesbarer Inhalt, der sich nicht löschen lässt.
class _CorruptUndeletable implements RawDocumentStore {
  @override
  Future<String?> read() async => '{kaputt';

  @override
  Future<void> write(String raw) async {}

  @override
  Future<void> deleteAll() => Future<void>.error(StateError('nicht löschbar'));
}
