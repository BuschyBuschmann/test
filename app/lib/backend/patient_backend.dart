// Die eine Schnittstelle zum Backend (Supabase) für die Patienten-App. Alles
// oberhalb (Repositories, Warteschlange, Löschen) kennt nur diese Schnittstelle;
// alle Tests laufen mit `FakePatientBackend` (lib/dev) ohne Netzwerk.
//
// Fehler: [BackendFailure] (Netz, Server, abgelehnt) und
// [BindingLostException] (Bindung besteht nicht mehr).
import '../logic/account.dart';
import '../logic/framework.dart';
import '../logic/manny_look.dart';
import '../logic/outbox.dart';

abstract class PatientBackend {
  /// `redeem_invitation(code)` mit dem **normalisierten** Code. Meldet bei
  /// Bedarf zuerst anonym an (Plan 7.2). Unbekannte Antworttexte werfen
  /// [BackendFailure] (`rejected`), sie gelten nie als Erfolg.
  Future<RedeemResult> redeemInvitation(String normalizedCode);

  /// Patienten-ID und Bindungszeitpunkt der aktuellen Sitzung. Wirft
  /// [BindingLostException], wenn es keine aktive Bindung gibt.
  Future<AccountInfo> fetchAccount();

  /// Liest das Framework (nur Lesen, Spalten einzeln, Plan 8.2). Wirft
  /// [BindingLostException] bei `access_deleted` bzw. fehlender Zeile.
  Future<Framework> fetchFramework();

  /// `accept_consent(kind, version)`.
  Future<void> acceptConsent(String kind, String version);

  /// Eigener Manny-Look im Konto über `get_my_manny_look()`; `null` = noch
  /// nicht übertragen.
  Future<MannyLook?> fetchMannyLook();

  /// Führt einen Eintrag der Warteschlange aus (Plan 8.11). Wirft
  /// [BackendFailure]; idempotent durch Geräte-IDs.
  Future<void> send(OutboxEntry entry);

  /// `delete_my_data()`; `ok` und `already_deleted` sind beide Erfolg.
  Future<DeleteResult> deleteMyData();

  /// Erneuert die Sitzung (nach 401).
  Future<SessionRefresh> refreshSession();

  /// Meldet lokal ab und verwirft die Sitzung. Fehler (z. B. weil das Konto
  /// schon gelöscht ist) wirft die Implementierung nicht.
  Future<void> signOut();
}
