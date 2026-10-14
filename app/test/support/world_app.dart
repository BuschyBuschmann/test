// Bausteine in einer festen Welt, einem Thema und optional Hohem Kontrast
// pumpen (Design-Brief v2, 3.1/3.2): die Grundlage der Komponententests und
// der Komponenten-Goldens (Welten × Thema × Hoher Kontrast). Die Welt kommt
// über `WorldScope` (reine Phase, feste Palette), der Blur über einen
// `BlurBudgetScope` je Screen (V2-10).
import 'package:curaone/logic/world_time.dart';
import 'package:curaone/state/app_controller.dart';
import 'package:curaone/state/app_scope.dart';
import 'package:curaone/state/world_scope.dart';
import 'package:curaone/theme/cura_theme.dart';
import 'package:curaone/theme/world_tokens.dart';
import 'package:curaone/ui/components/cura_blur.dart';
import 'package:curaone/ui/components/world_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Die vier Welten in der Reihenfolge des Briefs.
const List<WorldPhase> kWorlds = <WorldPhase>[
  WorldPhase.morning,
  WorldPhase.midday,
  WorldPhase.evening,
  WorldPhase.night,
];

/// Eine Darstellung: Welt, Thema, Hoher Kontrast.
class WorldLook {
  const WorldLook(this.phase, this.brightness, {this.highContrast = false});

  final WorldPhase phase;
  final Brightness brightness;
  final bool highContrast;

  String get name =>
      '${phase.name}_${brightness == Brightness.dark ? 'dark' : 'light'}'
      '${highContrast ? '_hc' : ''}';
}

/// Alle Darstellungen: 4 Welten × Hell/Dunkel, dazu Hoher Kontrast in Hell und
/// Dunkel (die Welt ist dort ohne Dekor).
List<WorldLook> allWorldLooks() => <WorldLook>[
  for (final WorldPhase w in kWorlds)
    for (final Brightness b in Brightness.values) WorldLook(w, b),
  for (final Brightness b in Brightness.values)
    WorldLook(WorldPhase.night, b, highContrast: true),
];

/// Baut die App-Hülle um [child]: Theme, Welt, Blur-Budget, optional die
/// Welt als Hintergrund und einen [AppController] (Manny-Look).
Widget worldApp(
  Widget child, {
  WorldPhase phase = WorldPhase.midday,
  Brightness brightness = Brightness.light,
  bool highContrast = false,
  bool background = true,
  double textScale = 1,
  AppController? controller,
  EdgeInsets padding = EdgeInsets.zero,
  Key? boundaryKey,
}) {
  Widget content = background
      ? Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const WorldBackground(),
            Padding(padding: padding, child: child),
          ],
        )
      : Padding(padding: padding, child: child);
  if (boundaryKey != null) {
    content = RepaintBoundary(key: boundaryKey, child: content);
  }
  if (controller != null) {
    content = AppScope(controller: controller, child: content);
  }
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: CuraTheme.build(brightness: brightness, highContrast: highContrast),
    locale: const Locale('de'),
    supportedLocales: const <Locale>[Locale('de')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (BuildContext context, Widget? app) {
      return MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: WorldScope(
          mix: WorldMix.pure(phase),
          palette: WorldPalette.of(phase),
          refresh: () {},
          child: BlurBudgetScope(child: app!),
        ),
      );
    },
    home: Scaffold(body: content),
  );
}

/// Pumpt [child] in Welt/Thema/Kontrast; Pixelverhältnis [dpr].
Future<void> pumpWorld(
  WidgetTester tester,
  Widget child, {
  WorldPhase phase = WorldPhase.midday,
  Brightness brightness = Brightness.light,
  bool highContrast = false,
  bool background = true,
  Size size = const Size(390, 844),
  double dpr = 1,
  double textScale = 1,
  AppController? controller,
  EdgeInsets padding = EdgeInsets.zero,
  Key? boundaryKey,
}) async {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    worldApp(
      child,
      phase: phase,
      brightness: brightness,
      highContrast: highContrast,
      background: background,
      textScale: textScale,
      controller: controller,
      padding: padding,
      boundaryKey: boundaryKey,
    ),
  );
}

/// Lädt alle Bilder der Tafel vor, damit Pixel und Goldens sie zeigen.
Future<void> precacheImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final Element e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pumpAndSettle();
}
