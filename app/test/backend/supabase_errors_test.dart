// Abbildung der Paket-Exceptions auf BackendFailure (Plan 8.11).
import 'dart:async';

import 'package:curaone/backend/supabase_errors.dart';
import 'package:curaone/logic/backend_failure.dart';
import 'package:curaone/logic/json_support.dart';
import 'package:curaone/logic/outbox.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

BackendFailure pg(String? code, [String message = '']) =>
    failureFromPostgrest(PostgrestException(message: message, code: code));

OutboxVerdict verdict(
  BackendFailure f, [
  OutboxKind k = OutboxKind.mannyLookSet,
]) => classifyFailure(k, f);

void main() {
  group('PostgrestException', () {
    test('42501: abgelehnt, SQLSTATE erhalten → verwerfen', () {
      final BackendFailure f = pg('42501', 'not_allowed');
      expect(f.kind, FailureKind.rejected);
      expect(f.sqlState, '42501');
      expect(verdict(f), OutboxVerdict.discard);
    });

    test('23505 → Erfolg (idempotent)', () {
      expect(verdict(pg('23505')), OutboxVerdict.success);
    });

    test('40P01 und 40001 → wiederholbar', () {
      for (final String c in <String>['40P01', '40001']) {
        final BackendFailure f = pg(c, 'deadlock detected');
        expect(f.sqlState, c);
        expect(verdict(f), OutboxVerdict.retryLater, reason: c);
      }
    });

    test('invalid_local_day (22023) → zurückstellen', () {
      final BackendFailure f = pg('22023', 'invalid_local_day');
      expect(f.kind, FailureKind.rejected);
      expect(verdict(f), OutboxVerdict.defer);
    });

    test('already_submitted (P0001) beim Tages-Check-up → Erfolg', () {
      expect(
        verdict(
          pg('P0001', 'already_submitted'),
          OutboxKind.dailyCheckupSubmit,
        ),
        OutboxVerdict.success,
      );
    });

    test('JWT abgelaufen (PGRST301) und 401 → Sitzung erneuern', () {
      expect(pg('PGRST301', 'JWT expired').kind, FailureKind.auth);
      expect(pg('401').kind, FailureKind.auth);
      expect(pg('401').httpStatus, 401);
      expect(verdict(pg('PGRST301')), OutboxVerdict.refreshSession);
    });

    test('HTTP-Status ohne Code im Körper: 5xx später, 4xx dauerhaft', () {
      expect(pg('503').kind, FailureKind.server);
      expect(pg('500').httpStatus, 500);
      expect(pg('400').kind, FailureKind.rejected);
      expect(pg('404').kind, FailureKind.rejected);
    });

    test(
      'Datenbank nicht erreichbar (PGRST000, 08xxx, 53xxx, 57xxx) → später',
      () {
        for (final String c in <String>[
          'PGRST000',
          '08006',
          '53300',
          '57014',
          'XX000',
        ]) {
          expect(pg(c).kind, FailureKind.server, reason: c);
        }
      },
    );

    test('Datenfehler und Integrität → abgelehnt', () {
      for (final String c in <String>[
        '22P02',
        '23503',
        '23514',
        '42703',
        'P0001',
        'PGRST100',
      ]) {
        expect(pg(c).kind, FailureKind.rejected, reason: c);
      }
    });

    test('unbekannter Code oder ohne Code: vorübergehend (nie verwerfen)', () {
      expect(pg('seltsam').kind, FailureKind.server);
      expect(pg(null).kind, FailureKind.server);
      expect(verdict(pg(null)), OutboxVerdict.retryLater);
    });

    test('Meldung und Details bleiben für fachliche Prüfungen erhalten', () {
      final BackendFailure f = failureFromPostgrest(
        const PostgrestException(
          message: 'x',
          code: 'P0001',
          details: 'already_submitted',
        ),
      );
      expect(f.hasMessage('already_submitted'), isTrue);
    });
  });

  group('AuthException', () {
    test('Netzfehler → unreachable', () {
      expect(
        failureFromAuth(AuthRetryableFetchException(message: 'offline')).kind,
        FailureKind.unreachable,
      );
    });

    test('Sitzung fehlt/ungültig/401 → auth', () {
      expect(
        failureFromAuth(AuthSessionMissingException()).kind,
        FailureKind.auth,
      );
      expect(
        failureFromAuth(const AuthException('x', statusCode: '401')).kind,
        FailureKind.auth,
      );
    });

    test('übrige Status', () {
      expect(
        failureFromAuth(const AuthException('x', statusCode: '500')).kind,
        FailureKind.server,
      );
      expect(
        failureFromAuth(const AuthException('x', statusCode: '422')).kind,
        FailureKind.rejected,
      );
      expect(
        failureFromAuth(const AuthException('x')).kind,
        FailureKind.timeout,
      );
    });
  });

  group('guardBackend', () {
    const Duration t = Duration(seconds: 1);

    test('gibt das Ergebnis zurück', () async {
      expect(await guardBackend<int>(() async => 7, timeout: t), 7);
    });

    test(
      'BackendFailure und BindingLostException bleiben unverändert',
      () async {
        await expectLater(
          guardBackend<int>(
            () async => throw const BackendFailure(FailureKind.server),
            timeout: t,
          ),
          throwsA(
            isA<BackendFailure>().having(
              (BackendFailure f) => f.kind,
              'k',
              FailureKind.server,
            ),
          ),
        );
        await expectLater(
          guardBackend<int>(
            () async => throw const BindingLostException('x'),
            timeout: t,
          ),
          throwsA(isA<BindingLostException>()),
        );
      },
    );

    test('Postgrest/Auth werden abgebildet', () async {
      await expectLater(
        guardBackend<int>(
          () async =>
              throw const PostgrestException(message: 'm', code: '42501'),
          timeout: t,
        ),
        throwsA(
          isA<BackendFailure>().having(
            (BackendFailure f) => f.sqlState,
            's',
            '42501',
          ),
        ),
      );
      await expectLater(
        guardBackend<int>(
          () async => throw AuthRetryableFetchException(message: 'offline'),
          timeout: t,
        ),
        throwsA(
          isA<BackendFailure>().having(
            (BackendFailure f) => f.kind,
            'k',
            FailureKind.unreachable,
          ),
        ),
      );
    });

    test('Zeitüberschreitung → timeout (Ergebnis unklar)', () async {
      await expectLater(
        guardBackend<int>(
          () => Completer<int>().future,
          timeout: const Duration(milliseconds: 10),
        ),
        throwsA(
          isA<BackendFailure>().having(
            (BackendFailure f) => f.kind,
            'k',
            FailureKind.timeout,
          ),
        ),
      );
    });

    test(
      'unbekannte Plattformfehler → timeout, nie „sicher nicht passiert“',
      () async {
        await expectLater(
          guardBackend<int>(
            () async => throw const FormatException('x'),
            timeout: t,
          ),
          throwsA(
            isA<BackendFailure>().having(
              (BackendFailure f) => f.requestMayHaveReachedServer,
              'r',
              isTrue,
            ),
          ),
        );
      },
    );

    test(
      'unlesbare Zeile → abgelehnt (Zwischenspeicher statt Absturz)',
      () async {
        await expectLater(
          guardBackend<int>(() async => unreadable('Spalte fehlt'), timeout: t),
          throwsA(
            isA<BackendFailure>().having(
              (BackendFailure f) => f.kind,
              'k',
              FailureKind.rejected,
            ),
          ),
        );
      },
    );

    test('Programmfehler (Error) werden nicht verschluckt', () async {
      await expectLater(
        guardBackend<int>(() async => throw StateError('Bug'), timeout: t),
        throwsA(isA<StateError>()),
      );
    });
  });

  test('requestMayHaveReachedServer', () {
    expect(
      const BackendFailure(FailureKind.unreachable).requestMayHaveReachedServer,
      isFalse,
    );
    for (final FailureKind k in FailureKind.values.where(
      (FailureKind k) => k != FailureKind.unreachable,
    )) {
      expect(BackendFailure(k).requestMayHaveReachedServer, isTrue);
    }
  });
}
