// Fonts als Assets (Plan 8.6): Dateien, OFL-Texte, pubspec-Eintrag,
// Lizenzregistrierung (A-24) und tatsächliches Rendern mit Variationen.
import 'dart:io';

import 'package:curaone/theme/cura_theme.dart';
import 'package:curaone/theme/cura_typography.dart';
import 'package:curaone/theme/font_licenses.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  test('Font-Dateien und OFL-Texte liegen im Projekt', () {
    for (final String name in <String>[
      'BricolageGrotesque[opsz,wdth,wght].ttf',
      'DMSans[opsz,wght].ttf',
    ]) {
      expect(
        File('assets/fonts/$name').lengthSync(),
        greaterThan(100000),
        reason: name,
      );
    }
    final String ofl1 = File('assets/fonts/OFL-BricolageGrotesque.txt')
        .readAsStringSync();
    final String ofl2 = File('assets/fonts/OFL-DMSans.txt').readAsStringSync();
    expect(ofl1, contains('SIL OPEN FONT LICENSE Version 1.1'));
    expect(ofl2, contains('SIL OPEN FONT LICENSE Version 1.1'));
    expect(ofl1, contains('Bricolage Grotesque'));
    expect(ofl2, contains('DM Sans'));
  });

  test('pubspec deklariert beide Familien und beide Lizenztexte', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: BricolageGrotesque'));
    expect(pubspec, contains('family: DMSans'));
    expect(pubspec, contains('assets/fonts/OFL-BricolageGrotesque.txt'));
    expect(pubspec, contains('assets/fonts/OFL-DMSans.txt'));
    // kein google_fonts, keine Laufzeit-Downloads
    expect(pubspec.contains('google_fonts'), isFalse);
  });

  testWidgets('Lizenzregistrierung: beide OFL-Texte erscheinen im Registry', (
    WidgetTester tester,
  ) async {
    registerFontLicenses();
    registerFontLicenses(); // idempotent
    final List<LicenseEntry> entries = await tester.runAsync(
      () => LicenseRegistry.licenses.toList(),
    ) as List<LicenseEntry>;
    LicenseEntry? forPackage(String name) {
      for (final LicenseEntry e in entries) {
        if (e.packages.contains(name)) return e;
      }
      return null;
    }

    for (final String name in kFontLicenseAssets.keys) {
      final LicenseEntry? entry = forPackage(name);
      expect(entry, isNotNull, reason: name);
      final String text = entry!.paragraphs
          .map((LicenseParagraph p) => p.text)
          .join('\n');
      expect(text, contains('SIL OPEN FONT LICENSE'), reason: name);
    }
    // nicht doppelt registriert
    expect(
      entries.where((LicenseEntry e) => e.packages.contains('DM Sans')).length,
      1,
    );
  });

  testWidgets('Variable Fonts rendern: Gewicht ändert die Textbreite', (
    WidgetTester tester,
  ) async {
    final CuraTypography t = CuraTypography.dark;
    final GlobalKey light = GlobalKey();
    final GlobalKey heavy = GlobalKey();
    final GlobalKey ahem = GlobalKey();
    await pumpApp(
      tester,
      Column(
        children: <Widget>[
          Text(
            'Hamburgefonstiv',
            key: light,
            style: t.body.copyWith(
              fontVariations: <FontVariation>[
                const FontVariation('wght', 400),
                const FontVariation('opsz', 16),
              ],
            ),
          ),
          Text(
            'Hamburgefonstiv',
            key: heavy,
            style: t.body.copyWith(
              fontVariations: <FontVariation>[
                const FontVariation('wght', 800),
                const FontVariation('opsz', 16),
              ],
            ),
          ),
          Text(
            'Hamburgefonstiv',
            key: ahem,
            style: t.body.copyWith(fontFamily: 'GibtEsNicht'),
          ),
        ],
      ),
    );
    double widthOf(GlobalKey k) => tester.getSize(find.byKey(k)).width;
    expect(widthOf(heavy), greaterThan(widthOf(light)));
    // Die echte Schrift ist geladen (Ersatzschrift hätte andere Breite).
    expect(widthOf(light), isNot(closeTo(widthOf(ahem), 0.01)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('alle Stile rendern ohne Fehler im Theme', (
    WidgetTester tester,
  ) async {
    final CuraTypography t = CuraTypography.dark;
    await pumpApp(
      tester,
      SingleChildScrollView(
        child: Column(
          children: <Widget>[
            for (final MapEntry<String, TextStyle> e in t.all.entries)
              Text(e.key, style: e.value),
          ],
        ),
      ),
    );
    expect(find.byType(Text), findsNWidgets(t.all.length));
    expect(tester.takeException(), isNull);
    // Theme liefert die Erweiterungen.
    final ThemeData theme = CuraTheme.build();
    expect(theme.extension<CuraTypography>(), isNotNull);
  });
}
