import 'package:curaone/backend/patient_backend.dart';
import 'package:curaone/dev/fake_backend.dart';
import 'package:curaone/logic/account.dart';
import 'package:curaone/logic/framework.dart';
import 'package:curaone/logic/manny_look.dart';
import 'package:curaone/logic/outbox.dart';

/// Reicht alles an ein [FakePatientBackend] weiter; Tests überschreiben einzelne
/// Aufrufe.
class FakePatientBackendDelegate implements PatientBackend {
  FakePatientBackendDelegate(this.inner);

  final FakePatientBackend inner;

  @override
  Future<RedeemResult> redeemInvitation(String normalizedCode) =>
      inner.redeemInvitation(normalizedCode);

  @override
  Future<AccountInfo> fetchAccount() => inner.fetchAccount();

  @override
  Future<Framework> fetchFramework() => inner.fetchFramework();

  @override
  Future<void> acceptConsent(String kind, String version) =>
      inner.acceptConsent(kind, version);

  @override
  Future<MannyLook?> fetchMannyLook() => inner.fetchMannyLook();

  @override
  Future<void> send(OutboxEntry entry) => inner.send(entry);

  @override
  Future<DeleteResult> deleteMyData() => inner.deleteMyData();

  @override
  Future<SessionRefresh> refreshSession() => inner.refreshSession();

  @override
  Future<void> signOut() => inner.signOut();
}
