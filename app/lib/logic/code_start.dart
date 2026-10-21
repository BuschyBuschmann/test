// Code-Start (Brief-Ergänzung 2, Teil A): Schrittzahl, Fehlerarten beim
// Einlösen und Ausgänge der Einwilligung und des Löschens. Reine Dart-Logik.
import 'account.dart';

/// Kind und Version der Einwilligung (Plan 7.2).
const String kConsentKind = 'physio_sharing';
const String kConsentVersion = 'physio_sharing-2';

/// Anzahl der Schritte im Code-Start: Look (nur wenn noch nicht gewählt),
/// Zugang, Einwilligung (V2-76).
int codeStartTotalSteps({required bool lookStep}) => lookStep ? 3 : 2;

/// Was der Zugang-Schritt als Fehler zeigt.
enum RedeemFailure {
  invalid,
  alreadyUsed,
  expired,
  tooManyAttempts,
  notAllowed,

  /// Netzfehler, Zeitüberschreitung, 5xx: „Nochmal versuchen“.
  network;

  /// `null` bei gebunden.
  static RedeemFailure? of(RedeemResult result) {
    switch (result) {
      case RedeemResult.ok:
      case RedeemResult.okRebound:
        return null;
      case RedeemResult.invalid:
        return RedeemFailure.invalid;
      case RedeemResult.alreadyUsed:
        return RedeemFailure.alreadyUsed;
      case RedeemResult.expired:
        return RedeemFailure.expired;
      case RedeemResult.tooManyAttempts:
        return RedeemFailure.tooManyAttempts;
      case RedeemResult.notAllowed:
        return RedeemFailure.notAllowed;
    }
  }
}

/// Fehler beim Senden der Einwilligung.
enum ConsentFailure { offline, failed }

/// Ausgang von „Alles löschen“ bzw. „Zugang löschen“ (V2-100).
enum DeleteUiResult {
  /// Server und lokal gelöscht.
  done,

  /// Sicher nichts gelöscht, weil keine Verbindung bestand.
  notDeletedOffline,

  /// Sicher nichts gelöscht, der Server hat abgelehnt.
  notDeletedRejected,

  /// Ob der Server gelöscht hat, ist unklar.
  unclear,

  /// Server gelöscht, lokales Aufräumen gescheitert.
  localFailure,
}

/// Warum die Bindung nicht mehr besteht (A4, altes Gerät).
enum BindingLostKind { otherDevice, accessDeleted }

/// Zeitangabe „Stand“ ist Sache von F2-4b; hier nur die Entscheidung, ob ein
/// Hinweis zu zurückgestellten Einträgen gezeigt wird: mindestens ein
/// zurückgestellter Eintrag, den der Nutzer noch nicht ausgeblendet hat.
bool showDeferredNotice({
  required Iterable<String> deferredIds,
  required Set<String> dismissedIds,
}) => deferredIds.any((String id) => !dismissedIds.contains(id));
