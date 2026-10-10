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

import '../app.dart';
import '../data/data_eraser.dart';
import '../data/prefs_state_store.dart';
import '../data/state_store.dart';
import '../logic/clock.dart';
import '../logic/manny_text_source.dart';
import '../ui/path/path_source.dart';
import '../ui/today/today_source.dart';
import '../state/app_controller.dart';
import '../theme/cura_colors.dart';
import '../theme/cura_metrics.dart';
import '../theme/cura_motion.dart';
import '../theme/cura_theme.dart';
import '../ui/components/probe_keys.dart';
import 'preview_script.dart';
import 'preview_stores.dart';
import 'preview_texts.dart';
import 'scenarios.dart';

/// Höhe der eingeblendeten Tastatur in Tastatur-Szenarien (Plan 12.4, B-10).
const double kPreviewKeyboardHeight = 300;

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
    this.live = false,
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
      live: flag('live'),
    );
  }

  final String? scenarioId;
  final DateTime? now;
  final double textScale;
  final bool highContrast;
  final bool reduceMotion;
  final bool semantics;
  final bool dumpText;

  /// Echter Speicher (`shared_preferences`) und Systemuhr statt eines
  /// Szenario-Seeds: für Reload-Prüfungen und Zeitsprünge im Browser
  /// (`page.clock`). Das Szenario liefert dann nur noch die Kennung.
  final bool live;

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
      live: live,
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
    this.viewInsetsBottom = 0,
  });

  final PreviewConfig config;
  final Widget child;

  /// Eingeblendete Tastatur (Tastatur-Szenarien): `viewInsets.bottom` in dp.
  final double viewInsetsBottom;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData base = MediaQuery.of(context);
    Widget content = MediaQuery(
      data: base.copyWith(
        textScaler: TextScaler.linear(config.textScale),
        highContrast: config.highContrast || base.highContrast,
        disableAnimations: config.reduceMotion || base.disableAnimations,
        viewInsets: viewInsetsBottom > 0
            ? EdgeInsets.only(bottom: viewInsetsBottom)
            : base.viewInsets,
      ),
      child: child,
    );
    if (viewInsetsBottom > 0) {
      // Platzhalterfläche für die Tastatur: sichtbar im Screenshot und als
      // Overlay-Marker für die Matrix (Inhalt muss darüber erreichbar sein).
      content = Stack(
        children: <Widget>[
          Positioned.fill(child: content),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: viewInsetsBottom,
            child: KeyedSubtree(
              key: ProbeKeys.keyboard,
              child: ColoredBox(color: CuraColors.of(context).surfaceOpaque),
            ),
          ),
        ],
      );
    }
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

/// Veränderliche Uhr eines App-Szenarios.
class _PreviewClock {
  _PreviewClock(this.now);

  DateTime now;
}

/// Laufzeit eines App-Szenarios: Controller, Speicher und Startfunktion.
class _AppRuntime {
  _AppRuntime._(this.controller, this.seed, this.startup, [this._clock]);

  /// Szenario-Uhr (veränderlich für Zeitsprünge); `null` bei `live`.
  final _PreviewClock? _clock;

  PathSource get pathSource => switch (seed.pathMode) {
    PathSeedMode.ready => const ImmediatePathSource(),
    PathSeedMode.loading => const PendingPathSource(),
    PathSeedMode.error => const FailingPathSource(),
  };

  TodaySource get todaySource => switch (seed.todayMode) {
    TodaySeedMode.ready => const ImmediateTodaySource(),
    TodaySeedMode.loading => const PendingTodaySource(),
    TodaySeedMode.error => const FailingTodaySource(),
  };

  /// Verschiebt die Uhr des Szenarios (nur Szenarien mit Seed): Zeitsprung
  /// nach den Tipps (`today-newday-snackbar`).
  void advanceDays(int days) {
    final _PreviewClock? c = _clock;
    if (c == null) return;
    final DateTime t = c.now;
    c.now = DateTime(t.year, t.month, t.day + days, t.hour, t.minute);
  }

  factory _AppRuntime.create(
    PreviewConfig config,
    ScenarioEnv env,
    AppSeed? seed,
  ) {
    if (config.live || seed == null) {
      final Clock clock = DateTime.now;
      final PrefsStateStore store = PrefsStateStore(clock: clock);
      return _AppRuntime._(
        _controller(clock, store, store),
        seed ?? const AppSeed(),
        null,
      );
    }
    final DateTime now = seed.now ?? env.now;
    final MemoryStateStore store = seed.unreadable
        ? UnreadableStateStore()
        : seed.loadError
        ? FailingReadStateStore()
        : MemoryStateStore(seed.state);
    final _PreviewClock clock = _PreviewClock(now);
    return _AppRuntime._(
      _controller(() => clock.now, store, store),
      seed,
      seed.deleteFirst
          ? (AppController c) async {
              await c.load();
              await c.deleteAll();
            }
          : null,
      clock,
    );
  }

  static AppController _controller(
    Clock clock,
    StateStore store,
    DataEraser eraser,
  ) => AppController(
    clock: clock,
    store: store,
    mannyText: const PlaceholderMannyTextSource(),
    erasers: <DataEraser>[eraser],
  );

  final AppController controller;
  final AppSeed seed;
  final Future<void> Function(AppController)? startup;

  void dispose() => controller.dispose();
}

class PreviewApp extends StatefulWidget {
  const PreviewApp({super.key, required this.config});

  final PreviewConfig config;

  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  _AppRuntime? _runtime;

  Scenario? get _scenario => widget.config.scenarioId == null
      ? null
      : scenarioById(widget.config.scenarioId!);

  ScenarioEnv get _env =>
      ScenarioEnv(now: widget.config.now ?? ScenarioEnv.defaultNow);

  bool _needsApp(PreviewConfig c) =>
      c.live || (scenarioById(c.scenarioId ?? '')?.app != null);

  @override
  void initState() {
    super.initState();
    _createRuntime();
  }

  void _createRuntime() {
    if (!_needsApp(widget.config)) return;
    _runtime = _AppRuntime.create(
      widget.config,
      _env,
      _scenario?.app?.call(_env),
    );
  }

  @override
  void didUpdateWidget(PreviewApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    final PreviewConfig a = oldWidget.config;
    final PreviewConfig b = widget.config;
    // Overrides (HC, RM, Skalierung) tauschen nur den Wrapper; ein anderes
    // Szenario, `live` oder `now` bauen die App neu auf.
    if (a.scenarioId != b.scenarioId || a.live != b.live || a.now != b.now) {
      _runtime?.dispose();
      _runtime = null;
      _createRuntime();
    }
  }

  @override
  void dispose() {
    _runtime?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Szenarien mit festem Wert (`chat-manny-scale15`) überstimmen die
    // Skalierung der URL.
    final double? fixedScale = _scenario?.fixedTextScale;
    final PreviewConfig config = fixedScale == null
        ? widget.config
        : widget.config.copyWith(textScale: fixedScale);
    final _AppRuntime? runtime = _runtime;
    if (runtime != null) {
      return CuraApp(
        controller: runtime.controller,
        startup: runtime.startup,
        pathSource: runtime.pathSource,
        todaySource: runtime.todaySource,
        previewWrapper: (BuildContext context, Widget child) {
          return PreviewScript(
            taps: runtime.seed.taps,
            focusField: runtime.seed.focusField,
            scrollPathToEnd: runtime.seed.scrollPathToEnd,
            afterTaps: runtime.seed.daysAfterTaps == 0
                ? null
                : () => runtime.advanceDays(runtime.seed.daysAfterTaps),
            child: PreviewOverrides(
              config: config,
              viewInsetsBottom: _scenario?.keyboard ?? false
                  ? kPreviewKeyboardHeight
                  : 0,
              child: child,
            ),
          );
        },
      );
    }
    final Scenario? scenario = _scenario;
    final ScenarioEnv env = _env;
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
        body: scenario?.builder == null
            ? const _ScenarioIndex()
            : Builder(
                builder: (BuildContext context) =>
                    scenario!.builder!(context, env),
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
