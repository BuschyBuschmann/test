// Konto, Einlösen und Löschen aus Sicht der App (Plan 6.4, 8.1, 8.10).
// Reine Dart-Logik.
import 'app_state.dart';
import 'clock.dart';
import 'manny_look.dart';

/// Ergebniscodes von `redeem_invitation(code)` (Plan 6.4).
enum RedeemResult {
  ok,
  okRebound,
  invalid,
  alreadyUsed,
  expired,
  tooManyAttempts,
  notAllowed;

  /// Unbekannte Texte liefern `null` (die App behandelt sie als Fehler, nicht
  /// als Erfolg).
  static RedeemResult? fromWire(String? value) {
    switch (value) {
      case 'ok':
        return RedeemResult.ok;
      case 'ok_rebound':
        return RedeemResult.okRebound;
      case 'invalid':
        return RedeemResult.invalid;
      case 'already_used':
        return RedeemResult.alreadyUsed;
      case 'expired':
        return RedeemResult.expired;
      case 'too_many_attempts':
        return RedeemResult.tooManyAttempts;
      case 'not_allowed':
        return RedeemResult.notAllowed;
    }
    return null;
  }

  bool get isBound => this == ok || this == okRebound;
}

/// Ergebnis von `delete_my_data()`: beide Texte gelten als Erfolg (idempotent).
enum DeleteResult {
  ok,
  alreadyDeleted;

  static DeleteResult? fromWire(String? value) {
    switch (value) {
      case 'ok':
        return DeleteResult.ok;
      case 'already_deleted':
        return DeleteResult.alreadyDeleted;
    }
    return null;
  }
}

/// Ergebnis einer Sitzungserneuerung (Plan 8.11: 401 → erst erneuern).
enum SessionRefresh {
  refreshed,

  /// Erneuerung scheitert, weil das Konto nicht mehr existiert: gelöste
  /// Bindung bzw. „bereits gelöscht“.
  accountGone,

  /// Erneuerung nicht möglich (kein Netz o. Ä.): später erneut.
  unavailable,
}

/// Was die App nach dem Einlösen vom Konto weiß.
class AccountInfo {
  const AccountInfo({required this.patientId, required this.boundAt});

  final String patientId;
  final DateTime boundAt;
}

/// Entscheidung für den Manny-Look nach dem Einlösen (Plan 8.1, O-41, B-36/
/// O-44): **lokal bleibt die Quelle für die Anzeige.**
sealed class LookSyncDecision {
  const LookSyncDecision();
}

/// Lokalen Wert an das Konto senden (`manny_look_set`).
class SendLocalLook extends LookSyncDecision {
  const SendLocalLook(this.look);

  final MannyLook look;
}

/// Wert aus dem Konto lokal übernehmen (Neubindung auf neuem Gerät, O-44).
class AdoptAccountLook extends LookSyncDecision {
  const AdoptAccountLook(this.look);

  final MannyLook look;
}

/// Konto-Wert konnte nicht gelesen werden: nichts senden, später erneut
/// versuchen (sonst würde der Konto-Wert überschrieben).
class LookSyncUndecided extends LookSyncDecision {
  const LookSyncUndecided();
}

/// `ok` (erste Bindung): lokalen Wert senden. `ok_rebound`: hat das Konto
/// einen Wert ([accountLook]), gewinnt er (N-17, O-44); ist er `null`, wird der
/// lokale Wert übertragen.
LookSyncDecision decideLookSync({
  required RedeemResult result,
  required MannyLook localLook,
  required MannyLook? accountLook,
}) {
  if (result == RedeemResult.okRebound && accountLook != null) {
    return AdoptAccountLook(accountLook);
  }
  return SendLocalLook(localLook);
}

/// Zustand nach dem Einlösen (Plan 8.1, B-9): der lokale Fortschritt startet
/// neu, **der lokale Manny-Look bleibt** (bzw. wird bei [adoptedLook] durch den
/// Wert des Kontos ersetzt).
AppState stateAfterBinding({
  required AppState old,
  required AccountState account,
  required LocalDay today,
  MannyLook? adoptedLook,
}) =>
    AppState.initial(today)
        .copyWith(mannyLook: adoptedLook ?? old.mannyLook, account: account);
