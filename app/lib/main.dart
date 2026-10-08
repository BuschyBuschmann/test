// Vorläufiger Einstieg (U1a Fundament): registriert die Font-Lizenzen und
// zeigt eine leere Fläche im Theme. App, Navigation und Speicher folgen
// in den späteren Paketen (Plan 14).
import 'package:flutter/material.dart';

import 'theme/cura_theme.dart';
import 'theme/font_licenses.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CuraTheme.build(),
      home: const Scaffold(body: SizedBox.expand()),
    ),
  );
}
