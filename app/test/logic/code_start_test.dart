// Code-Start (F2-4a): Schrittzahl, Fehlerarten, Look-Merkung im Dokument.
import 'dart:convert';

import 'package:curaone/logic/account.dart';
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/code_start.dart';
import 'package:curaone/logic/manny_look.dart';
import 'package:curaone/logic/migrations.dart';
import 'package:flutter_test/flutter_test.dart';

const LocalDay _today = LocalDay(2026, 10, 7);

void main() {
  test('Schrittzahl: drei mit Look-Schritt, sonst zwei (V2-76)', () {
    expect(codeStartTotalSteps(lookStep: true), 3);
    expect(codeStartTotalSteps(lookStep: false), 2);
  });

  test('jeder Ergebniscode ohne Bindung hat genau eine Fehlerart', () {
    expect(RedeemFailure.of(RedeemResult.ok), isNull);
    expect(RedeemFailure.of(RedeemResult.okRebound), isNull);
    expect(RedeemFailure.of(RedeemResult.invalid), RedeemFailure.invalid);
    expect(
      RedeemFailure.of(RedeemResult.alreadyUsed),
      RedeemFailure.alreadyUsed,
    );
    expect(RedeemFailure.of(RedeemResult.expired), RedeemFailure.expired);
    expect(
      RedeemFailure.of(RedeemResult.tooManyAttempts),
      RedeemFailure.tooManyAttempts,
    );
    expect(RedeemFailure.of(RedeemResult.notAllowed), RedeemFailure.notAllowed);
  });

  test(
    'zurückgestellter Eintrag: ausgeblendete kommen nur mit neuem zurück',
    () {
      expect(
        showDeferredNotice(
          deferredIds: <String>['a'],
          dismissedIds: <String>{},
        ),
        isTrue,
      );
      expect(
        showDeferredNotice(
          deferredIds: <String>['a'],
          dismissedIds: <String>{'a'},
        ),
        isFalse,
      );
      expect(
        showDeferredNotice(
          deferredIds: <String>['a', 'b'],
          dismissedIds: <String>{'a'},
        ),
        isTrue,
      );
      expect(
        showDeferredNotice(deferredIds: <String>[], dismissedIds: <String>{}),
        isFalse,
      );
    },
  );

  group('mannyLookChosen im Dokument', () {
    test('Ausgangszustand: nicht gewählt, Dokument ohne das Feld', () {
      final AppState s = AppState.initial(_today);
      expect(s.mannyLookChosen, isFalse);
      expect(s.lookAlreadyChosen, isFalse);
      expect(s.toJson().containsKey('mannyLookChosen'), isFalse);
    });

    test('gewählt: wird gespeichert und gelesen', () {
      final AppState s = AppState.initial(_today)
          .copyWith(mannyLookChosen: true);
      final AppState back = decodeDocument(encodeDocument(s), _today);
      expect(back.mannyLookChosen, isTrue);
      expect(back, s);
    });

    test('Bestandsdaten mit abgeschlossenem Onboarding gelten als gewählt', () {
      final AppState s = AppState.initial(_today)
          .copyWith(onboarding: const OnboardingState(completed: true));
      expect(s.lookAlreadyChosen, isTrue);
    });

    test('nach der Bindung bleibt der Look und gilt als gewählt', () {
      final AppState after = stateAfterBinding(
        old: AppState.initial(_today).copyWith(mannyLook: MannyLook.ohne),
        account: AccountState(patientId: 'p', boundAt: DateTime.utc(2026)),
        today: _today,
      );
      expect(after.mannyLook, MannyLook.ohne);
      expect(after.lookAlreadyChosen, isTrue);
      expect(
        jsonDecode(encodeDocument(after)),
        containsPair('mannyLookChosen', true),
      );
    });
  });
}
