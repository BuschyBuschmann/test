// Preview-App der Prüfumgebung (Plan 8.1, 12.5): rendert ein Szenario aus der
// Registry mit den Overrides Skalierung, Hoher Kontrast und „Bewegung
// reduzieren“. Dieselbe App läuft im Browser (`main_preview`) und in der
// Matrix (`test/matrix/`), damit beide denselben Override-Weg prüfen.
//
// Reihenfolge in `MaterialApp.builder` (Plan 8.1): (1) [PreviewOverrides]
// setzt `MediaQuery` (Skalierung, HC, RM) und [PreviewMotionOverride],
// (2) [PreviewThemeSelector] wählt den Token-Satz nach `MediaQuery.highContrast`.
// Ein Override oberhalb von `MaterialApp` würde nicht wirken, weil
// `MaterialApp` seine `MediaQuery` aus der View neu erzeugt.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../theme/cura_metrics.dart';
import '../theme/cura_motion.dart';
import '../theme/cura_theme.dart';
import 'preview_texts.dart';
import 'scenarios.dart';

/// Einstellungen der Preview, aus den URL-Parametern (12.5) oder direkt aus
/// dem Test.
@immutable
class PreviewConfig {
  const PreviewConfig({
    this.scenarioId,
    this.now,
    this.textScale = 1,
    this.highContrast = false,
    this.reduceMotion = false,
    this.semantics = false,
    this.dumpText = false,
  });

  /// Liest die URL-Parameter `scenario`, `now`, `scale`, `hc`, `rm`, `a11y`,
  /// `dumpText` (Plan 12.5). Ungültige Werte fallen auf den Standard zurück.
  factory PreviewConfig.fromQuery(Map<String, String> q) {
    bool flag(String key) => q[key] == '1' || q[key] == 'true';
    return PreviewConfig(
      scenarioId: q['scenario'],
      now: q['now'] == null ? null : DateTime.tryParse(q['now']!),
      textScale: double.tryParse(q['scale'] ?? '') ?? 1,
      highContrast: flag('hc'),
      reduceMotion: flag('rm'),
      semantics: flag('a11y'),
      dumpText: flag('dumpText'),
    );
  }

  final String? scenarioId;
  final DateTime? now;
  final double textScale;
  final bool highContrast;
  final bool reduceMotion;
  final bool semantics;
  final bool dumpText;

  PreviewConfig copyWith({
    String? scenarioId,
    double? textScale,
    bool? highContrast,
    bool? reduceMotion,
  }) {
    return PreviewConfig(
      scenarioId: scenarioId ?? this.scenarioId,
      now: now,
      textScale: textScale ?? this.textScale,
      highContrast: highContrast ?? this.highContrast,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      semantics: semantics,
      dumpText: dumpText,
    );
  }
}

/// Setzt `MediaQuery` und [PreviewMotionOverride] nach [config]. Was die
/// Konfiguration nicht erzwingt, bleibt beim Systemsignal (z. B. Browser).
class PreviewOverrides extends StatelessWidget {
  const PreviewOverrides({
    super.key,
    required this.config,
    required this.child,
  });

  final PreviewConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData base = MediaQuery.of(context);
    Widget content = MediaQuery(
      data: base.copyWith(
        textScaler: TextScaler.linear(config.textScale),
        highContrast: config.highContrast || base.highContrast,
        disableAnimations: config.reduceMotion || base.disableAnimations,
      ),
      child: child,
    );
    if (config.reduceMotion) {
      content = PreviewMotionOverride(reduceMotion: true, child: content);
    }
    return content;
  }
}

/// Wählt den Token-Satz nach `MediaQuery.highContrast` (Normal oder
/// „Hoher Kontrast“). Die App bekommt später ihren eigenen Wähler (U2b); der
/// Aufbau ist derselbe.
class PreviewThemeSelector extends StatelessWidget {
  const PreviewThemeSelector({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: CuraTheme.build(highContrast: MediaQuery.highContrastOf(context)),
      child: child,
    );
  }
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key, required this.config});

  final PreviewConfig config;

  @override
  Widget build(BuildContext context) {
    final Scenario? scenario = config.scenarioId == null
        ? null
        : scenarioById(config.scenarioId!);
    final ScenarioEnv env = ScenarioEnv(
      now: config.now ?? ScenarioEnv.defaultNow,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CuraTheme.build(),
      locale: const Locale('de'),
      supportedLocales: const <Locale>[Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (BuildContext context, Widget? app) {
        return PreviewOverrides(
          config: config,
          child: PreviewThemeSelector(child: app!),
        );
      },
      home: Scaffold(
        body: scenario == null
            ? const _ScenarioIndex()
            : Builder(
                builder: (BuildContext context) =>
                    scenario.builder(context, env),
              ),
      ),
    );
  }
}

/// Liste der Szenario-Kennungen (ohne oder bei unbekanntem `scenario`).
class _ScenarioIndex extends StatelessWidget {
  const _ScenarioIndex();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(CuraSpace.pageMargin),
      children: <Widget>[
        const Text(PreviewTexts.indexTitle),
        for (final Scenario s in kScenarios) Text(s.id),
      ],
    );
  }
}
