// Schnittstelle der Backends und gemeinsamer Ablauf (Reset, dann Schritte in Reihenfolge).
// Konstanten zum Reset stehen hier einmal; API- und SQL-Backend nutzen dieselbe Reihenfolge.

import 'seed_plan.dart';

/// Tabellen mit Spalte patient_id, in einer Reihenfolge, die alle Fremdschluessel einhaelt
/// (Verlauf vor Plaenen, Plaene vor Verletzungen; phases/plan_items fallen per CASCADE mit den Plaenen).
const List<String> patientScopedTables = [
  'exercise_results',
  'training_sessions',
  'consents',
  'account_events',
  'appointments',
  'history_entries',
  'treaters',
  'invitations',
  'plans',
  'injuries',
];

abstract class SeedBackend {
  /// Loescht ausschliesslich Daten der Praxen mit is_test = true und Konten mit der Testdomain.
  Future<void> resetTestData(String emailDomain);

  Future<void> createPhysioAccount(CreatePhysioAccount step);

  Future<void> upsert(UpsertRows step);

  Future<void> update(UpdateRows step);

  /// Liefert die Antwortzeile des Funktionsaufrufs (bei regenerate_invitation: code, expires_at).
  Future<Row?> physioRpc(PhysioRpc step);

  Future<void> close();
}

typedef SeedLog = void Function(String line);

class SeedReport {
  SeedReport(this.invitations, this.physioEmails, this.rowCounts);
  final List<InvitationInfo> invitations;
  final List<String> physioEmails;
  final Map<String, int> rowCounts;
}

/// Fuehrt den Plan aus: Reset, dann alle Schritte in der Reihenfolge des Plans.
Future<SeedReport> runSeed(
  SeedPlan plan,
  SeedBackend backend, {
  SeedLog? log,
  bool reset = true,
}) async {
  void say(String s) => log?.call(s);
  if (reset) {
    say('Reset der Testdaten ...');
    await backend.resetTestData(plan.emailDomain);
  }
  final invitations = <InvitationInfo>[];
  for (final step in plan.steps) {
    say('  ${step.label}');
    switch (step) {
      case CreatePhysioAccount():
        await backend.createPhysioAccount(step);
      case UpsertRows():
        await backend.upsert(step);
      case UpdateRows():
        await backend.update(step);
      case PhysioRpc():
        final r = await backend.physioRpc(step);
        if (step.fn == 'regenerate_invitation') {
          final code = r?['code'];
          if (code is! String) {
            throw StateError(
              'regenerate_invitation lieferte keinen Code (${step.subject})',
            );
          }
          invitations.add(
            InvitationInfo(step.subject, code, '${r?['expires_at']}'),
          );
        }
    }
  }
  return SeedReport(invitations, [
    for (final p in plan.physios) p.email,
  ], plan.rowCounts);
}
