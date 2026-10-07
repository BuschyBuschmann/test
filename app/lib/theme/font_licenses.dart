// Lizenzregistrierung der gebündelten Fonts (SIL OFL 1.1, Plan 8.6, A-24).
// Die Lizenztexte liegen unverändert unter `assets/fonts/` und erscheinen in
// der Lizenzseite der App (`showLicensePage`).
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asset-Pfade der Lizenztexte, je Schrift.
const Map<String, String> kFontLicenseAssets = <String, String>{
  'Bricolage Grotesque': 'assets/fonts/OFL-BricolageGrotesque.txt',
  'DM Sans': 'assets/fonts/OFL-DMSans.txt',
};

bool _registered = false;

/// Registriert die OFL-Texte beim `LicenseRegistry`. Mehrfachaufruf ist
/// wirkungslos.
void registerFontLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry<String, String> entry in kFontLicenseAssets.entries) {
      final String text = await rootBundle.loadString(entry.value);
      yield LicenseEntryWithLineBreaks(<String>[entry.key], text);
    }
  });
}
