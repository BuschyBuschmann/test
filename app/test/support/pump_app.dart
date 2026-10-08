import 'package:curaone/theme/cura_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Viewports aus Plan 12.2 (logische Größen in dp).
abstract final class Viewports {
  static const Size small = Size(320, 568);
  static const Size phone = Size(390, 844);
  static const Size large = Size(430, 932);
  static const Size tablet = Size(768, 1024);

  static const List<Size> matrix = <Size>[small, phone, large];
}

/// Stellt die Ansichtsgröße ein (Pixelverhältnis 1) und räumt am Testende auf.
void setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Baut [child] in einer `MaterialApp` mit dem Cura-Theme, Locale `de` und
/// den Material-Lokalisierungen. Die echte `CuraApp` entsteht erst in U2b;
/// dieser Helfer genügt für Bausteintests.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Size size = Viewports.phone,
  bool highContrast = false,
  double textScale = 1.0,
}) async {
  setViewport(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CuraTheme.build(highContrast: highContrast),
      locale: const Locale('de'),
      supportedLocales: const <Locale>[Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext context, Widget? app) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        );
      },
      home: Scaffold(body: child),
    ),
  );
}
