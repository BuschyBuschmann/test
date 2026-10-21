// Schema-Sprung 2 → 3 (Plan 8.1, L3): Abschnitt `account {patientId, boundAt}`.
// Bestandsdaten ohne Bindung; `mannyLook` bleibt erhalten.
import 'dart:convert';
import 'dart:io';

import 'package:curaone/logic/account.dart';
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/json_support.dart';
import 'package:curaone/logic/manny_look.dart';
import 'package:curaone/logic/migrations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

String _fixture(String name) => File('test/fixtures/$name').readAsStringSync();

Json _json(String raw) => jsonDecode(raw) as Json;

void main() {
  test('aktuelles Schema ist 3, Kette 1 → 2 → 3', () {
    expect(kCurrentSchema, 3);
    expect(kMigrations.keys, containsAll(<int>[1, 2]));
  });

  group('Fixture state_v2.json → Schema 3', () {
    final String raw = _fixture('state_v2.json');

    test('Dokumentebene: Schema 3, kein account, alles Übrige unverändert', () {
      final Json out = migrateToCurrent(_json(raw));
      expect(out['schema'], 3);
      expect(out.containsKey('account'), isFalse);
      final Json v2 = _json(raw);
      for (final String k in v2.keys.where((String k) => k != 'schema')) {
        expect(out[k], v2[k], reason: k);
      }
    });

    test('lädt ohne Bindung (→ Startbildschirm), mannyLook ohne bleibt', () {
      final AppState s = decodeDocument(raw, kToday);
      expect(s.account, isNull);
      expect(s.mannyLook, MannyLook.ohne);
      expect(s.onboarding.completed, isTrue);
    });
  });

  group('Fixture state_v3.json', () {
    final String raw = _fixture('state_v3.json');

    test('lädt mit Bindung', () {
      final AppState s = decodeDocument(raw, kToday);
      expect(s.account, isNotNull);
      expect(s.account!.patientId, '3f1c2a9e-5b7d-4e86-9a0c-1d2e3f4a5b6c');
      expect(s.account!.boundAt, DateTime.utc(2026, 10, 1, 8));
      expect(s.mannyLook, MannyLook.ohne);
    });

    test('Roundtrip ist verlustfrei', () {
      final AppState s = decodeDocument(raw, kToday);
      expect(decodeDocument(encodeDocument(s), kToday), s);
      expect(s.toJson()['schema'], 3);
    });

    test('v1 → v3 über die ganze Kette', () {
      final AppState s = decodeDocument(_fixture('state_v1_done.json'), kToday);
      expect(s.account, isNull);
      expect(s.mannyLook, MannyLook.brille);
    });
  });

  group('account', () {
    test('Standard: nicht gebunden', () {
      expect(AppState.initial(kToday).account, isNull);
      expect(AppState.initial(kToday).toJson()['account'], isNull);
    });

    test('unlesbar: falsche Typen, leere ID, ungültige Zeit', () {
      for (final Object? bad in <Object?>[
        'x',
        <String, Object?>{'patientId': 1, 'boundAt': '2026-10-01T08:00:00Z'},
        <String, Object?>{'patientId': '', 'boundAt': '2026-10-01T08:00:00Z'},
        <String, Object?>{'patientId': 'p'},
        <String, Object?>{'patientId': 'p', 'boundAt': 'gestern'},
      ]) {
        final Json j = AppState.initial(kToday).toJson()..['account'] = bad;
        expect(
          () => AppState.fromJson(j, kToday),
          throwsA(isA<UnreadableDataException>()),
          reason: '$bad',
        );
      }
    });

    test('copyWith setzt und löscht die Bindung', () {
      final AccountState a = AccountState(
        patientId: 'p',
        boundAt: DateTime.utc(2026, 1, 1),
      );
      final AppState bound = AppState.initial(kToday).copyWith(account: a);
      expect(bound.account, a);
      expect(bound.copyWith(clearAccount: true).account, isNull);
      expect(bound == AppState.initial(kToday), isFalse);
    });
  });

  group('Zustand nach dem Einlösen (B-9)', () {
    final AccountState account = AccountState(
      patientId: 'p',
      boundAt: DateTime.utc(2026, 10, 7, 8),
    );

    test('lokaler Fortschritt startet neu, der lokale Look bleibt', () {
      final AppState old = onboardedState().copyWith(mannyLook: MannyLook.ohne);
      final AppState s = stateAfterBinding(
        old: old,
        account: account,
        today: kToday,
      );
      expect(s.mannyLook, MannyLook.ohne);
      expect(s.account, account);
      expect(s.onboarding.completed, isFalse);
      expect(s.streak, AppState.initial(kToday).streak);
      expect(s.path.completedUnitIds, isEmpty);
    });

    test('übernommener Konto-Look ersetzt den lokalen', () {
      final AppState s = stateAfterBinding(
        old: AppState.initial(kToday),
        account: account,
        today: kToday,
        adoptedLook: MannyLook.ohne,
      );
      expect(s.mannyLook, MannyLook.ohne);
    });
  });

  group('Look-Abgleich bei der Bindung (O-41, N-17)', () {
    test('ok: lokalen Wert senden', () {
      final LookSyncDecision d = decideLookSync(
        result: RedeemResult.ok,
        localLook: MannyLook.ohne,
        accountLook: null,
      );
      expect(d, isA<SendLocalLook>());
      expect((d as SendLocalLook).look, MannyLook.ohne);
    });

    test('ok_rebound mit Konto-Wert: Konto gewinnt (O-44)', () {
      final LookSyncDecision d = decideLookSync(
        result: RedeemResult.okRebound,
        localLook: MannyLook.brille,
        accountLook: MannyLook.ohne,
      );
      expect(d, isA<AdoptAccountLook>());
      expect((d as AdoptAccountLook).look, MannyLook.ohne);
    });

    test('ok_rebound ohne Konto-Wert: lokalen Wert übertragen', () {
      final LookSyncDecision d = decideLookSync(
        result: RedeemResult.okRebound,
        localLook: MannyLook.brille,
        accountLook: null,
      );
      expect(d, isA<SendLocalLook>());
    });

    test('Ergebniscodes aus der Datenbank', () {
      expect(RedeemResult.fromWire('ok'), RedeemResult.ok);
      expect(RedeemResult.fromWire('ok_rebound'), RedeemResult.okRebound);
      expect(RedeemResult.fromWire('invalid'), RedeemResult.invalid);
      expect(RedeemResult.fromWire('already_used'), RedeemResult.alreadyUsed);
      expect(RedeemResult.fromWire('expired'), RedeemResult.expired);
      expect(
        RedeemResult.fromWire('too_many_attempts'),
        RedeemResult.tooManyAttempts,
      );
      expect(RedeemResult.fromWire('not_allowed'), RedeemResult.notAllowed);
      expect(RedeemResult.fromWire('seltsam'), isNull);
      expect(RedeemResult.fromWire(null), isNull);
      expect(RedeemResult.ok.isBound, isTrue);
      expect(RedeemResult.okRebound.isBound, isTrue);
      expect(RedeemResult.expired.isBound, isFalse);
      expect(DeleteResult.fromWire('ok'), DeleteResult.ok);
      expect(
        DeleteResult.fromWire('already_deleted'),
        DeleteResult.alreadyDeleted,
      );
      expect(DeleteResult.fromWire('x'), isNull);
    });
  });
}
