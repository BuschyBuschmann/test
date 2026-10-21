// Einlösen des Einladungscodes und Abgleich des Manny-Looks (Plan 7.2, 8.1).
import 'dart:async';

import '../backend/backend_errors.dart';
import '../backend/outbox_sender.dart';
import '../backend/patient_backend.dart';
import '../logic/account.dart';
import '../logic/app_state.dart' show AccountState;
import '../logic/backend_failure.dart';
import '../logic/clock.dart';
import '../logic/ids.dart';
import '../logic/invite_code.dart';
import '../logic/manny_look.dart';
import '../logic/outbox.dart';

/// Ergebnis von [AccountRepository.redeem].
class BindOutcome {
  const BindOutcome({required this.result, this.account, this.look});

  /// Ergebniscode; bei einer Eingabe, die nicht wie ein Code aussieht, lokal
  /// `invalid` (ohne Anfrage, damit kein Fehlversuch bei der Bremse zählt).
  final RedeemResult result;

  /// Nur bei gebunden (`ok`, `ok_rebound`).
  final AccountState? account;

  /// Was mit dem Manny-Look geschah (nur bei gebunden).
  final LookSyncDecision? look;

  bool get isBound => account != null;
}

class AccountRepository {
  AccountRepository({
    required this.backend,
    required this.sender,
    required this.clock,
    String Function()? newId,
  }) : _newId = newId ?? newUuid;

  final PatientBackend backend;
  final OutboxSender sender;
  final Clock clock;
  final String Function() _newId;

  /// Löst [rawCode] ein. [localLook] ist der lokal gewählte Look (lokal bleibt
  /// die Quelle für die Anzeige).
  ///
  /// Wirft [BackendFailure] bei Netz-/Serverfehlern (nichts angenommen; die
  /// Wiederholung ist gefahrlos, auch wenn die Antwort verloren ging, siehe
  /// unten).
  Future<BindOutcome> redeem({
    required String rawCode,
    required MannyLook localLook,
  }) async {
    final String? code = parseInviteCode(rawCode);
    if (code == null) return const BindOutcome(result: RedeemResult.invalid);

    RedeemResult result = await backend.redeemInvitation(code);

    // Ging die Antwort auf ein erfolgreiches Einlösen verloren, liefert die
    // Wiederholung `not_allowed` (die Sitzung ist schon gebunden). Besteht eine
    // Bindung, gilt das als gebunden; weil unklar ist, ob es eine Neubindung
    // war, wird wie bei `ok_rebound` verfahren (ein Wert im Konto gewinnt).
    if (result == RedeemResult.notAllowed) {
      try {
        await withSessionRefresh<AccountInfo>(backend, backend.fetchAccount);
        result = RedeemResult.okRebound;
      } on BindingLostException {
        return const BindOutcome(result: RedeemResult.notAllowed);
      }
    }
    if (!result.isBound) return BindOutcome(result: result);

    final AccountInfo info = await withSessionRefresh<AccountInfo>(
      backend,
      backend.fetchAccount,
    );
    final AccountState account = AccountState(
      patientId: info.patientId,
      boundAt: info.boundAt.toUtc(),
    );
    final LookSyncDecision look = await syncLookAfterBinding(
      result: result,
      localLook: localLook,
    );
    return BindOutcome(result: result, account: account, look: look);
  }

  /// Gleicht den Look nach der Bindung ab (Plan 8.1, N-17/O-44):
  /// - `ok`: lokalen Wert in die Warteschlange (`manny_look_set`);
  /// - `ok_rebound`: hat das Konto einen Wert, übernimmt ihn das Gerät
  ///   ([AdoptAccountLook], die aufrufende Stelle setzt ihn lokal); sonst wird
  ///   der lokale Wert gesendet;
  /// - Konto-Wert nicht lesbar: [LookSyncUndecided], nichts gesendet. Später
  ///   erneut aufrufen (idempotent), sonst würde der Konto-Wert überschrieben.
  Future<LookSyncDecision> syncLookAfterBinding({
    required RedeemResult result,
    required MannyLook localLook,
  }) async {
    MannyLook? accountLook;
    if (result == RedeemResult.okRebound) {
      try {
        accountLook = await withSessionRefresh<MannyLook?>(
          backend,
          backend.fetchMannyLook,
        );
      } on BackendFailure {
        return const LookSyncUndecided();
      }
    }
    final LookSyncDecision decision = decideLookSync(
      result: result,
      localLook: localLook,
      accountLook: accountLook,
    );
    if (decision is SendLocalLook) {
      await setMannyLook(decision.look);
    }
    return decision;
  }

  /// Jede Änderung des Looks im Profil: lokal sofort (macht die aufrufende
  /// Stelle), dann `manny_look_set` über die Warteschlange.
  Future<void> setMannyLook(MannyLook look) async {
    await sender.enqueue(
      mannyLookSetEntry(entryId: _newId(), now: clock(), look: look.jsonName),
    );
    unawaited(sender.drain());
  }

  /// `accept_consent(kind, version)` (Einwilligung nach dem Einlösen).
  Future<void> acceptConsent(String kind, String version) =>
      withSessionRefresh<void>(
        backend,
        () => backend.acceptConsent(kind, version),
      );
}
