import 'json_support.dart';

/// Verletzungstyp (Onboarding Schritt 3). Gespeichert als `acl`, `ankle`,
/// `muscle`, `other`.
enum InjuryType {
  acl,
  ankle,
  muscle,
  other;

  String get jsonName => name;

  static InjuryType? fromJsonName(String? value) {
    if (value == null) return null;
    for (final InjuryType t in InjuryType.values) {
      if (t.name == value) return t;
    }
    return unreadable('onboarding.injuryType: unbekannter Wert');
  }
}
