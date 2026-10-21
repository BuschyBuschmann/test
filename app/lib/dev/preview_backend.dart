// Backend-Szenarien der Prüfumgebung (F2-4a): ein `FakePatientBackend`, das
// Aufrufe anhalten kann (Prüfung läuft, Senden läuft, Laden läuft, Löschen
// läuft), und ein Beispiel-Framework mit erfundenen Testdaten.
import 'dart:async';

import '../dev/fake_backend.dart';
import '../logic/account.dart';
import '../logic/clock.dart';
import '../logic/framework.dart';

class PreviewBackend extends FakePatientBackend {
  PreviewBackend({
    super.framework,
    super.patientId,
    this.hangRedeem = false,
    this.hangConsent = false,
    this.hangFramework = false,
    this.hangDelete = false,
  });

  final bool hangRedeem;
  final bool hangConsent;
  final bool hangFramework;
  final bool hangDelete;

  @override
  Future<RedeemResult> redeemInvitation(String normalizedCode) {
    if (hangRedeem) return Completer<RedeemResult>().future;
    return super.redeemInvitation(normalizedCode);
  }

  @override
  Future<void> acceptConsent(String kind, String version) {
    if (hangConsent) return Completer<void>().future;
    return super.acceptConsent(kind, version);
  }

  @override
  Future<Framework> fetchFramework() {
    if (hangFramework) return Completer<Framework>().future;
    return super.fetchFramework();
  }

  @override
  Future<DeleteResult> deleteMyData() {
    if (hangDelete) return Completer<DeleteResult>().future;
    return super.deleteMyData();
  }
}

/// Beispiel-Framework mit erfundenen Daten (Vorname, Verletzung, ein Plan).
Framework previewFramework(LocalDay today, {String name = 'Jakob'}) {
  const String phaseId = 'ph1';
  return Framework(
    patient: PatientInfo(
      id: kPreviewPatientId,
      firstName: name,
      boundAt: DateTime.utc(2026, 7, 1, 8),
    ),
    injury: Injury(
      id: 'inj-1',
      label: 'Kreuzbandriss',
      referenceDate: today.addDays(-30),
      startedOn: today.addDays(-30),
    ),
    plan: Plan(
      id: 'plan-1',
      injuryId: 'inj-1',
      version: 1,
      currentPhaseId: phaseId,
      closed: false,
      phases: <Phase>[
        Phase(
          id: phaseId,
          position: 0,
          title: 'Beweglichkeit',
          plannedWeeks: 4,
        ),
      ],
      items: <PlanItem>[],
    ),
    exercises: const <Exercise>[],
    treaters: const <Treater>[],
    appointments: const <Appointment>[],
    history: const <HistoryEntry>[],
  );
}

const String kPreviewPatientId = 'preview-patient-1';
