// Einlösen und Manny-Look-Abgleich (Plan 7.2, 8.1, O-41, N-17/O-44).
import 'package:curaone/backend/outbox_sender.dart';
import 'package:curaone/data/account_repository.dart';
import 'package:curaone/data/key_value_store.dart';
import 'package:curaone/data/outbox_store.dart';
import 'package:curaone/dev/fake_backend.dart';
import 'package:curaone/logic/account.dart';
import 'package:curaone/logic/backend_failure.dart';
import 'package:curaone/logic/manny_look.dart';
import 'package:curaone/logic/outbox.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_clock.dart';

class Rig {
  Rig() {
    sender = OutboxSender(
      store: StoreOutboxStore(MemoryKeyValueStore()),
      backend: backend,
    );
    repo = AccountRepository(
      backend: backend,
      sender: sender,
      clock: FakeClock(DateTime.utc(2026, 10, 7, 9)).call,
      newId: () => 'id-${++n}',
    );
  }

  int n = 0;
  final FakePatientBackend backend = FakePatientBackend(
    patientId: 'pat-9',
    boundAt: DateTime.utc(2026, 10, 7, 8, 30),
  );
  late final OutboxSender sender;
  late final AccountRepository repo;
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('Eingabe, die kein Code ist: lokal invalid, keine Anfrage (keine Fehlversuche)', () async {
    final Rig r = Rig();
    for (final String bad in <String>['', 'abc', 'ABCDE-FGHJ', 'ABCDE-FGHJU']) {
      final BindOutcome o = await r.repo.redeem(
        rawCode: bad,
        localLook: MannyLook.brille,
      );
      expect(o.result, RedeemResult.invalid, reason: bad);
      expect(o.isBound, isFalse);
    }
    expect(r.backend.calls, isEmpty);
  });

  test('ok: gebunden, lokaler Look geht in die Warteschlange', () async {
    final Rig r = Rig();
    final BindOutcome o = await r.repo.redeem(
      rawCode: 'abcde-fghjk',
      localLook: MannyLook.ohne,
    );
    expect(o.result, RedeemResult.ok);
    expect(o.isBound, isTrue);
    expect(o.account!.patientId, 'pat-9');
    expect(o.account!.boundAt, DateTime.utc(2026, 10, 7, 8, 30));
    expect(o.look, isA<SendLocalLook>());
    await settle();
    await r.sender.drain();
    expect(r.backend.sent.single.kind, OutboxKind.mannyLookSet);
    expect(r.backend.accountLook, MannyLook.ohne);
    expect(r.backend.calls.first, 'redeem');
    // Konto-Look wird bei der ersten Bindung nicht gelesen.
    expect(r.backend.calls, isNot(contains('fetchMannyLook')));
  });

  test(
    'ok_rebound mit Konto-Wert: Konto gewinnt, nichts wird gesendet',
    () async {
      final Rig r = Rig();
      r.backend.redeemResult = RedeemResult.okRebound;
      r.backend.accountLook = MannyLook.ohne;
      final BindOutcome o = await r.repo.redeem(
        rawCode: 'ABCDEFGHJK',
        localLook: MannyLook.brille,
      );
      expect(o.look, isA<AdoptAccountLook>());
      expect((o.look! as AdoptAccountLook).look, MannyLook.ohne);
      await settle();
      await r.sender.drain();
      expect(r.backend.sent, isEmpty);
      expect(r.backend.accountLook, MannyLook.ohne); // unverändert
      expect(r.sender.outbox.isEmpty, isTrue);
    },
  );

  test('ok_rebound ohne Konto-Wert: lokalen Wert übertragen', () async {
    final Rig r = Rig();
    r.backend.redeemResult = RedeemResult.okRebound;
    r.backend.accountLook = null;
    final BindOutcome o = await r.repo.redeem(
      rawCode: 'ABCDEFGHJK',
      localLook: MannyLook.brille,
    );
    expect(o.look, isA<SendLocalLook>());
    await settle();
    await r.sender.drain();
    expect(r.backend.accountLook, MannyLook.brille);
  });

  test(
    'ok_rebound, Konto-Wert nicht lesbar: nichts senden, später erneut',
    () async {
      final Rig r = Rig();
      r.backend.redeemResult = RedeemResult.okRebound;
      r.backend.accountLook = MannyLook.ohne;
      r.backend.fetchLookError = const BackendFailure(FailureKind.unreachable);
      final BindOutcome o = await r.repo.redeem(
        rawCode: 'ABCDEFGHJK',
        localLook: MannyLook.brille,
      );
      expect(o.isBound, isTrue);
      expect(o.look, isA<LookSyncUndecided>());
      expect(r.sender.outbox.isEmpty, isTrue);
      // Später: idempotent erneut abgleichen.
      r.backend.fetchLookError = null;
      final LookSyncDecision d = await r.repo.syncLookAfterBinding(
        result: RedeemResult.okRebound,
        localLook: MannyLook.brille,
      );
      expect(d, isA<AdoptAccountLook>());
    },
  );

  test('Fehlercodes: keine Bindung, keine Warteschlange', () async {
    for (final RedeemResult res in <RedeemResult>[
      RedeemResult.invalid,
      RedeemResult.alreadyUsed,
      RedeemResult.expired,
      RedeemResult.tooManyAttempts,
    ]) {
      final Rig r = Rig();
      r.backend.redeemResult = res;
      final BindOutcome o = await r.repo.redeem(
        rawCode: 'ABCDEFGHJK',
        localLook: MannyLook.brille,
      );
      expect(o.result, res);
      expect(o.account, isNull);
      expect(o.look, isNull);
      expect(r.sender.outbox.isEmpty, isTrue);
      expect(r.backend.calls, <String>['redeem']);
    }
  });

  test('Netzfehler beim Einlösen wird durchgereicht', () async {
    final Rig r = Rig();
    r.backend.redeemError = const BackendFailure(FailureKind.unreachable);
    await expectLater(
      r.repo.redeem(rawCode: 'ABCDEFGHJK', localLook: MannyLook.brille),
      throwsA(isA<BackendFailure>()),
    );
  });

  test('not_allowed nach verlorener Antwort: besteht die Bindung, gilt sie wie ok_rebound', () async {
    final Rig r = Rig();
    r.backend.redeemResult = RedeemResult.notAllowed;
    r.backend.accountLook = MannyLook.ohne;
    final BindOutcome o = await r.repo.redeem(
      rawCode: 'ABCDEFGHJK',
      localLook: MannyLook.brille,
    );
    expect(o.isBound, isTrue);
    expect(o.look, isA<AdoptAccountLook>());
  });

  test('not_allowed ohne Bindung bleibt not_allowed', () async {
    final Rig r = Rig();
    r.backend.redeemResult = RedeemResult.notAllowed;
    r.backend.bound = false;
    final BindOutcome o = await r.repo.redeem(
      rawCode: 'ABCDEFGHJK',
      localLook: MannyLook.brille,
    );
    expect(o.result, RedeemResult.notAllowed);
    expect(o.isBound, isFalse);
  });

  test('Änderung im Profil: manny_look_set über die Warteschlange', () async {
    final Rig r = Rig();
    await r.repo.setMannyLook(MannyLook.ohne);
    await settle();
    await r.sender.drain();
    expect(r.backend.accountLook, MannyLook.ohne);
    await r.repo.setMannyLook(MannyLook.brille);
    await settle();
    await r.sender.drain();
    expect(r.backend.accountLook, MannyLook.brille);
    expect(r.backend.sent.length, 2);
  });

  test('Einwilligung', () async {
    final Rig r = Rig();
    await r.repo.acceptConsent('physio_sharing', 'physio_sharing-2');
    expect(r.backend.consents, <String>['physio_sharing:physio_sharing-2']);
  });
}
