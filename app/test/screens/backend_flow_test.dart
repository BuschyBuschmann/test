// Backend-Modus der Patienten-App (F2-4a): Code-Start, Einwilligung,
// Neuanmeldung, gelöste Bindung, Löschen, zurückgestellte Einträge. Alles
// gegen `FakePatientBackend`, kein Netzwerk.
import 'package:curaone/data/data_eraser.dart';
import 'package:curaone/dev/fake_backend.dart';
import 'package:curaone/dev/preview_stores.dart';
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/account.dart';
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/backend_failure.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/manny_look.dart';
import 'package:curaone/logic/outbox.dart';
import 'package:curaone/state/backend_controller.dart';
import 'package:curaone/ui/home/home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/backend_harness.dart';
import '../support/framework_builders.dart';

const String _code = 'ABCDE-FGHJK';

AppState _lookChosen() =>
    AppState.initial(const LocalDay(2026, 10, 7))
        .copyWith(mannyLookChosen: true);

Future<void> _enterCode(WidgetTester tester, [String code = _code]) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  late BackendHarness h;

  tearDown(() => h.dispose());

  Future<void> boot(
    WidgetTester tester, {
    BackendHarness? harness,
    String? link,
  }) async {
    h = harness ?? BackendHarness(state: MemoryStateStore(_lookChosen()));
    await pumpCura(tester, h.app, backend: h.backend, initialInviteCode: link);
  }

  group('Code-Start', () {
    testWidgets('Look-Schritt zuerst, drei Schritte (V2-76)', (tester) async {
      await boot(tester, harness: BackendHarness());
      expect(find.text(S.onboardingTitleLook), findsOneWidget);
      expect(find.text('Schritt 1 von 3'), findsOneWidget);
      await _tap(tester, S.next);
      expect(find.text(S.accessTitle), findsOneWidget);
      expect(find.text('Schritt 2 von 3'), findsOneWidget);
      expect(find.text(S.codeLabel), findsOneWidget);
      expect(h.app.state.mannyLookChosen, isTrue);
      await disposeApp(tester);
    });

    testWidgets(
      'Look schon gewählt: zwei Schritte, kein Look-Schritt (V2-77)',
      (tester) async {
        await boot(tester);
        expect(find.text(S.onboardingTitleLook), findsNothing);
        expect(find.text(S.accessTitle), findsOneWidget);
        expect(find.text('Schritt 1 von 2'), findsOneWidget);
        await disposeApp(tester);
      },
    );

    testWidgets('Weiter erst bei zehn gültigen Zeichen (V2-79)', (
      tester,
    ) async {
      await boot(tester);
      Finder next() => find.widgetWithText(Semantics, S.next);
      await _enterCode(tester, 'abcde');
      await tester.tap(find.text(S.next));
      await tester.pump();
      expect(h.fake.calls, isNot(contains('redeem')));
      await _enterCode(tester, 'abcde fghjk');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        _code,
      );
      expect(next(), findsWidgets);
      await disposeApp(tester);
    });

    testWidgets('Code aus Link: Hinweis, eingelöst erst nach Weiter (V2-80)', (
      tester,
    ) async {
      await boot(tester, link: 'abcdefghjk');
      expect(find.text(S.codeFromLink), findsOneWidget);
      expect(h.fake.calls, isNot(contains('redeem')));
      await _tap(tester, S.next);
      expect(h.fake.calls, contains('redeem'));
      await disposeApp(tester);
    });

    for (final (RedeemResult, String) c in <(RedeemResult, String)>[
      (RedeemResult.invalid, S.codeInvalid),
      (RedeemResult.alreadyUsed, S.codeAlreadyUsed),
      (RedeemResult.expired, S.codeExpired),
      (RedeemResult.tooManyAttempts, S.codeTooManyAttempts),
      (RedeemResult.notAllowed, S.codeNotAllowed),
    ]) {
      testWidgets('Fehlertext ${c.$1.name} (V2-81)', (tester) async {
        await boot(tester);
        h.fake.redeemResult = c.$1;
        // `notAllowed` mit bestehender Bindung gälte als gebunden.
        h.fake.bound = c.$1 != RedeemResult.notAllowed;
        await _enterCode(tester);
        await _tap(tester, S.next);
        expect(find.text(c.$2), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          _code,
          reason: 'der Code bleibt im Feld',
        );
        await disposeApp(tester);
      });
    }

    testWidgets('Netzfehler: Text und „Nochmal versuchen“, danach Erfolg', (
      tester,
    ) async {
      await boot(tester);
      h.fake.redeemError = const BackendFailure(FailureKind.unreachable);
      await _enterCode(tester);
      await _tap(tester, S.next);
      expect(find.text(S.codeNetwork), findsOneWidget);
      h.fake.redeemError = null;
      await _tap(tester, S.retry);
      expect(find.text(S.consentTitle), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('Einwilligung', () {
    testWidgets('ok: Einwilligung, Zustimmen sendet, Look geht ins Konto', (
      tester,
    ) async {
      await boot(tester);
      h.app.setMannyLook(MannyLook.ohne);
      await _enterCode(tester);
      await _tap(tester, S.next);
      expect(find.text(S.consentTitle), findsOneWidget);
      expect(find.text('Schritt 2 von 2'), findsOneWidget);
      expect(h.app.state.account, isNotNull);
      expect(h.fake.consents, isEmpty, reason: 'nichts ohne Handlung');
      await _tap(tester, S.consentAgree);
      expect(h.fake.consents, <String>['physio_sharing:physio_sharing-2']);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(h.fake.accountLook, MannyLook.ohne);
      expect(h.app.state.consent?.version, 'physio_sharing-2');
      await disposeApp(tester);
    });

    testWidgets('alle Pflichtpunkte stehen im Text (V2-86)', (tester) async {
      await boot(tester);
      await _enterCode(tester);
      await _tap(tester, S.next);
      for (final String part in <String>[
        'Schwellung',
        'Stimmung',
        'Fragen',
        'Chat mit Manny',
        'Krise',
        '5 Tagen',
        S.consentNever,
      ]) {
        expect(find.textContaining(part, findRichText: true), findsWidgets);
      }
      await disposeApp(tester);
    });

    testWidgets('Fehler beim Senden: Hinweis und erneuter Versuch', (
      tester,
    ) async {
      final BackendHarness x = BackendHarness(
        fake: _FailingConsent(sampleFake()),
        state: MemoryStateStore(_lookChosen()),
      );
      await boot(tester, harness: x);
      await _enterCode(tester);
      await _tap(tester, S.next);
      await _tap(tester, S.consentAgree);
      expect(find.text(S.consentOffline), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('Nicht einverstanden: Dialog, Zurück oder Zugang löschen', (
      tester,
    ) async {
      await boot(tester);
      await _enterCode(tester);
      await _tap(tester, S.next);
      await _tap(tester, S.consentDecline);
      expect(find.text(S.declineTitle), findsOneWidget);
      await _tap(tester, S.back);
      expect(find.text(S.consentTitle), findsOneWidget);
      expect(h.fake.calls, isNot(contains('deleteMyData')));
      await _tap(tester, S.consentDecline);
      await _tap(tester, S.declineDelete);
      expect(h.fake.calls, contains('deleteMyData'));
      expect(find.text(S.onboardingTitleLook), findsOneWidget);
      expect(h.app.state.account, isNull);
      await disposeApp(tester);
    });

    testWidgets('Neustart nach dem Einlösen setzt bei der Einwilligung fort', (
      tester,
    ) async {
      await boot(tester);
      await _enterCode(tester);
      await _tap(tester, S.next);
      await h.app.idle;
      final MemoryStateStore saved = MemoryStateStore(h.stateStore.state);
      await disposeApp(tester);
      h.dispose();
      await boot(
        tester,
        harness: BackendHarness(fake: h.fake, state: saved),
      );
      expect(find.text(S.consentTitle), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('Neubindung', () {
    testWidgets('ok_rebound: Konto-Look gewinnt, Hinweis nennt ihn (O-44)', (
      tester,
    ) async {
      final FakePatientBackend fake = sampleFake()
        ..redeemResult = RedeemResult.okRebound
        ..accountLook = MannyLook.ohne
        ..knownConsents.add('physio_sharing:physio_sharing-2');
      await boot(
        tester,
        harness: BackendHarness(
          fake: fake,
          state: MemoryStateStore(_lookChosen()),
        ),
      );
      expect(h.app.state.mannyLook, MannyLook.brille);
      await _enterCode(tester);
      await _tap(tester, S.next);
      expect(find.text(S.reboundTitle), findsOneWidget);
      expect(find.text(S.reboundKept), findsOneWidget);
      expect(find.text(S.reboundChat), findsOneWidget);
      expect(find.text(S.reboundLook(S.mannyLookWithout)), findsOneWidget);
      expect(h.app.state.mannyLook, MannyLook.ohne);
      expect(
        fake.calls.where((String c) => c == 'send:manny_look_set'),
        isEmpty,
        reason: 'der Konto-Wert wird nicht überschrieben',
      );
      await _tap(tester, S.reboundAck);
      expect(
        find.byType(HomeShell),
        findsOneWidget,
        reason: 'Einwilligung lag vor',
      );
      await disposeApp(tester);
    });

    testWidgets('ok_rebound ohne Einwilligung auf dem Server: sie folgt', (
      tester,
    ) async {
      final FakePatientBackend fake = sampleFake()
        ..redeemResult = RedeemResult.okRebound;
      await boot(
        tester,
        harness: BackendHarness(
          fake: fake,
          state: MemoryStateStore(_lookChosen()),
        ),
      );
      await _enterCode(tester);
      await _tap(tester, S.next);
      expect(find.text(S.reboundLook(S.mannyLookWithout)), findsNothing);
      await _tap(tester, S.reboundAck);
      expect(find.text(S.consentTitle), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('Gelöste Bindung (altes Gerät)', () {
    testWidgets('Hinweis, lokale Daten weg, Weiter führt zum Code-Start', (
      tester,
    ) async {
      final AppState bound = _lookChosen().copyWith(
        account: AccountState(
          patientId: 'patient-1',
          boundAt: DateTime.utc(2026, 7, 1),
        ),
        consent: ConsentState(
          acceptedAt: DateTime.utc(2026, 7, 1),
          version: 'physio_sharing-2',
        ),
        mannyLook: MannyLook.ohne,
      );
      final FakePatientBackend fake = sampleFake()..bound = false;
      await boot(
        tester,
        harness: BackendHarness(fake: fake, state: MemoryStateStore(bound)),
      );
      expect(find.text(S.lostOtherTitle), findsOneWidget);
      expect(find.text(S.lostOtherText), findsOneWidget);
      expect(h.app.state.account, isNull);
      expect(h.app.state.mannyLook, MannyLook.defaultLook);
      await _tap(tester, S.lostContinue);
      expect(find.text(S.onboardingTitleLook), findsOneWidget);
      expect(find.text('Schritt 1 von 3'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('Löschen', () {
    Future<void> toReady(WidgetTester tester) async {
      await boot(tester);
      await _enterCode(tester);
      await _tap(tester, S.next);
      await _tap(tester, S.consentAgree);
      expect(find.byType(HomeShell), findsOneWidget);
    }

    test(
      'sicher gelöscht: Sender läuft nach dem Löschen weiter (F2-3R MINOR-2)',
      () async {
        h = BackendHarness(state: MemoryStateStore(_lookChosen()));
        await h.backend.start();
        await h.backend.redeem(_code);
        await h.backend.acceptConsent();
        expect(h.backend.phase, BackendPhase.ready);
        expect(await h.backend.deleteAccount(), DeleteUiResult.done);
        expect(h.backend.phase, BackendPhase.codeStart);
        expect(h.backend.sender.isPaused, isFalse);
        // Neuer Code-Start: die Look-Änderung geht wieder ins Konto.
        h.fake.deleted = false;
        h.app.completeDeletion();
        await h.backend.redeem(_code);
        await h.backend.sender.drain();
        expect(h.fake.accountLook, isNotNull);
      },
    );

    test('offline: nichts gelöscht, Schreiben wieder frei', () async {
      h = BackendHarness(state: MemoryStateStore(_lookChosen()));
      await h.backend.start();
      await h.backend.redeem(_code);
      await h.backend.acceptConsent();
      h.fake.deleteError = const BackendFailure(FailureKind.unreachable);
      expect(await h.backend.deleteAccount(), DeleteUiResult.notDeletedOffline);
      expect(h.app.isDeleting, isFalse);
      expect(h.backend.phase, BackendPhase.ready);
    });

    test('abgelehnt: nichts gelöscht, andere Meldung', () async {
      h = BackendHarness(state: MemoryStateStore(_lookChosen()));
      await h.backend.start();
      await h.backend.redeem(_code);
      await h.backend.acceptConsent();
      h.fake.deleteError = const BackendFailure(
        FailureKind.rejected,
        sqlState: '42501',
      );
      expect(
        await h.backend.deleteAccount(),
        DeleteUiResult.notDeletedRejected,
      );
    });

    test(
      'unklar: Zeitüberschreitung, Merkzeichen bleibt, Wiederholung klappt',
      () async {
        h = BackendHarness(state: MemoryStateStore(_lookChosen()));
        await h.backend.start();
        await h.backend.redeem(_code);
        await h.backend.acceptConsent();
        h.fake.deleteError = const BackendFailure(FailureKind.timeout);
        expect(await h.backend.deleteAccount(), DeleteUiResult.unclear);
        expect(h.app.isDeleting, isFalse);
        h.fake.deleteError = null;
        expect(await h.backend.deleteAccount(), DeleteUiResult.done);
      },
    );

    test('lokaler Fehler: Server gelöscht, Wiederholung nur lokal', () async {
      final _FailOnce eraser = _FailOnce();
      h = BackendHarness(state: MemoryStateStore(_lookChosen()));
      final BackendController b = BackendController.wire(
        backend: h.fake,
        app: h.app,
        store: h.kv,
        clock: () => h.now,
        localErasers: [eraser],
      );
      await b.start();
      await b.redeem(_code);
      await b.acceptConsent();
      expect(await b.deleteAccount(), DeleteUiResult.localFailure);
      final int deletes = h.fake.calls.where((c) => c == 'deleteMyData').length;
      expect(await b.deleteAccount(), DeleteUiResult.done);
      expect(
        h.fake.calls.where((c) => c == 'deleteMyData').length,
        deletes,
        reason: 'kein zweiter Serveraufruf',
      );
      b.dispose();
    });

    test(
      'Wiederaufnahme beim Start: Merkzeichen requested, Konto besteht noch',
      () async {
        h = BackendHarness(state: MemoryStateStore(_lookChosen()));
        await h.backend.start();
        await h.backend.redeem(_code);
        await h.backend.acceptConsent();
        h.fake.deleteError = const BackendFailure(FailureKind.timeout);
        await h.backend.deleteAccount();
        // Neustart: neue Instanzen auf demselben Speicher.
        final BackendHarness again = BackendHarness(
          fake: h.fake,
          state: h.stateStore,
        );
        final BackendController b = BackendController.wire(
          backend: h.fake,
          app: again.app,
          store: h.kv,
          clock: () => h.now,
        );
        await b.start();
        expect(b.phase, BackendPhase.deletionPending);
        h.fake.deleteError = null;
        await b.retryPendingDeletion();
        expect(b.phase, BackendPhase.codeStart);
        b.dispose();
        again.dispose();
      },
    );

    testWidgets(
      'Dialog in Deine Daten: unklarer Ausgang zeigt Text und Wiederholung',
      (tester) async {
        await toReady(tester);
        h.fake.deleteError = const BackendFailure(FailureKind.timeout);
        await tester.tap(find.text(S.navProfile).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(S.profileRowData));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(S.dataDeleteButton));
        await tester.tap(find.text(S.dataDeleteButton));
        await tester.pumpAndSettle();
        expect(find.text(S.deleteBackendText), findsOneWidget);
        await tester.tap(find.text(S.deleteConfirm));
        await tester.pumpAndSettle();
        expect(find.text(S.deleteUnclear), findsOneWidget);
        expect(find.text(S.retry), findsOneWidget);
        h.fake.deleteError = null;
        await tester.tap(find.text(S.retry));
        await tester.pumpAndSettle();
        expect(find.text(S.onboardingTitleLook), findsOneWidget);
        expect(find.text('Schritt 1 von 3'), findsOneWidget);
        expect(find.text(S.dataDeleted), findsOneWidget);
        await disposeApp(tester);
      },
    );
  });

  group('Zurückgestellte Einträge (NIT-2)', () {
    testWidgets(
      'Hinweis auf Heute, ausblenden, kehrt bei neuem Eintrag zurück',
      (tester) async {
        await boot(tester);
        await _enterCode(tester);
        await _tap(tester, S.next);
        await _tap(tester, S.consentAgree);
        await tester.tap(find.text(S.navToday).last);
        await tester.pumpAndSettle();
        expect(find.text(S.syncNoticeOne), findsNothing);
        Future<void> defer(String id) async {
          await h.backend.sender.enqueue(dailyCheckupEntryFor(id));
          await h.backend.sender.drain(retryDeferred: true);
          await tester.pumpAndSettle();
        }

        await defer('c1');
        expect(h.backend.deferredCount, 1);
        expect(find.text(S.syncNoticeOne), findsOneWidget);
        expect(find.text(S.syncResend), findsOneWidget);
        await tester.tap(find.bySemanticsLabel(S.syncHide));
        await tester.pumpAndSettle();
        expect(find.text(S.syncNoticeOne), findsNothing);
        await defer('c2');
        expect(find.text(S.syncNoticeMany(2)), findsOneWidget);
        await disposeApp(tester);
      },
    );
  });

  group('Manny-Look im Konto (O-41)', () {
    test(
      'Änderung nach der Bindung geht in die Warteschlange, vorher nicht',
      () async {
        h = BackendHarness(state: MemoryStateStore(_lookChosen()));
        await h.backend.start();
        h.app.setMannyLook(MannyLook.ohne);
        await Future<void>.delayed(Duration.zero);
        expect(h.fake.calls, isNot(contains('send:manny_look_set')));
        await h.backend.redeem(_code);
        await h.backend.acceptConsent();
        h.fake.accountLook = null;
        h.app.setMannyLook(MannyLook.brille);
        await h.backend.sender.drain();
        expect(h.fake.accountLook, MannyLook.brille);
      },
    );
  });
}

FakePatientBackend sampleFake() =>
    FakePatientBackend(framework: sampleFramework());

/// Ein Check-up mit einem Tag vor der Bindung: der Server lehnt ihn mit
/// `invalid_local_day` ab, die Warteschlange stellt ihn zurück.
OutboxEntry dailyCheckupEntryFor(String id) => dailyCheckupEntry(
  entryId: 'e-$id',
  now: DateTime.utc(2026, 10, 7, 10),
  checkupId: id,
  localDay: const LocalDay(2026, 6, 1),
  pain: 2,
  wellbeing: 3,
  motivation: 3,
  swelling: 0,
  limitations: 'none',
  mood: 3,
);

class _FailingConsent extends FakePatientBackend {
  _FailingConsent(FakePatientBackend base) : super(framework: base.framework);

  @override
  Future<void> acceptConsent(String kind, String version) async {
    throw const BackendFailure(FailureKind.unreachable);
  }
}

class _FailOnce implements DataEraser {
  bool failed = false;

  @override
  Future<void> eraseAll() async {
    if (!failed) {
      failed = true;
      throw StateError('lokal');
    }
  }
}
