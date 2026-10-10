// Einstieg der Prüfumgebung (Plan 12.5). NUR mit `-t lib/main_preview.dart`
// bauen; `main.dart` importiert nichts aus `lib/dev/`. Liest URL-Parameter:
//
//   scenario  Kennung aus `lib/dev/scenarios.dart` (ohne: Liste)
//   now       ISO-Ortszeit für die Fake-Uhr (ab U2b wirksam, sobald Szenarien
//             Daten seeden)
//   scale     Textskalierung (linear), z. B. 2.0
//   hc=1      Hoher Kontrast (Override im MaterialApp.builder)
//   rm=1      Bewegung reduzieren (Override)
//   a11y=1    Semantik-Baum aktivieren (ARIA im Web)
//   dumpText=1 JSON-Liste aller Texte nach dem Einschwingen ausgeben
//   live      reserviert: echter Speicher, folgt mit dem StartGate (U2b)
//
// Konsole (Playwright liest sie): `CURA_ENV {json}` direkt nach dem Start,
// `CURA_READY {"settled":bool}` sobald keine Animation und kein Frame mehr
// läuft (`settled:false` = Zeitlimit erreicht, nur bei Szenarien mit
// Dauer-Animation erwartet),
// `CURA_DUMP {json}` bei `dumpText=1`.
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

import 'dev/preview_app.dart';
import 'dev/scenarios.dart';
import 'dev/text_probe.dart';
import 'theme/cura_motion.dart';
import 'theme/font_licenses.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final PreviewConfig config = PreviewConfig.fromQuery(
    Uri.base.queryParameters,
  );
  if (config.semantics) SemanticsBinding.instance.ensureSemantics();
  runApp(PreviewApp(config: config));
  _announce('CURA_ENV', jsonEncode(_environment(config)));
  _afterSettle(config);
}

// Die Konsole ist der Kanal zu Playwright.
// ignore: avoid_print
void _announce(String marker, String payload) => print('$marker $payload');

ui.FlutterView get _view =>
    WidgetsBinding.instance.platformDispatcher.views.first;

Map<String, Object?> _environment(PreviewConfig config) {
  final ui.PlatformDispatcher d = WidgetsBinding.instance.platformDispatcher;
  final ui.AccessibilityFeatures f = d.accessibilityFeatures;
  return <String, Object?>{
    'scenario': config.scenarioId,
    'loops': scenarioById(config.scenarioId ?? '')?.loops ?? false,
    'now': (config.now ?? ScenarioEnv.defaultNow).toIso8601String(),
    'dartNow': DateTime.now().toIso8601String(),
    'override': <String, Object?>{
      'scale': config.textScale,
      'hc': config.highContrast,
      'rm': config.reduceMotion,
    },
    // Systemsignale des Browsers, ohne Override (Plan 12.5 b).
    'system': <String, Object?>{
      'highContrast': f.highContrast,
      'disableAnimations': f.disableAnimations,
      'reduceMotion': f.reduceMotion,
      'textScaleFactor': d.textScaleFactor,
    },
  };
}

/// Einschwingen: Szenarien mit Dauer-Animation (`loops`, z. B. Fortschrittskreis)
/// werden nie ruhig und rendern in Software langsam, darum höchstens 2 s
/// Wanduhrzeit. Alle anderen warten bis zu 10 s: sie enden, sobald es ruhig
/// ist (3 Abfragen in Folge); die längere Frist fängt nur einen langsamen
/// Start unter Last ab (R3), sie verdeckt keine Dauer-Animation (die würde
/// auch nach 10 s als „nicht zur Ruhe gekommen“ gemeldet).
const Duration _maxSettleLoops = Duration(seconds: 2);
const Duration _maxSettleRest = Duration(seconds: 10);
const int _idlePolls = 3;

Future<void> _afterSettle(PreviewConfig config) async {
  await WidgetsBinding.instance.endOfFrame;
  int idle = 0;
  final Stopwatch watch = Stopwatch()..start();
  final Duration limit = (scenarioById(config.scenarioId ?? '')?.loops ?? false)
      ? _maxSettleLoops
      : _maxSettleRest;
  while (watch.elapsed < limit && idle < _idlePolls) {
    await Future<void>.delayed(CuraMotion.fastDuration);
    final SchedulerBinding b = SchedulerBinding.instance;
    idle = (b.transientCallbackCount == 0 && !b.hasScheduledFrame)
        ? idle + 1
        : 0;
  }
  try {
    if (config.dumpText) _dump(config);
  } catch (e, st) {
    _announce('CURA_ERROR', '$e $st');
  }
  _announce(
    'CURA_READY',
    jsonEncode(<String, Object?>{
      'settled': idle >= _idlePolls,
      'waitedMs': watch.elapsedMilliseconds,
      'transientCallbacks': SchedulerBinding.instance.transientCallbackCount,
      'frameScheduled': SchedulerBinding.instance.hasScheduledFrame,
    }),
  );
}

void _dump(PreviewConfig config) {
  final ui.FlutterView view = _view;
  final Size size = view.physicalSize / view.devicePixelRatio;
  final TextProbe probe = probeTexts(view: size);
  final Map<String, Rect> keyed = probeKeyedRects(prefix: 'probe:');
  final Map<String, Rect> overlays = probeKeyedRects(
    prefix: 'overlay:',
    skipBuried: true,
  );
  _announce(
    'CURA_DUMP',
    jsonEncode(<String, Object?>{
      'scenario': config.scenarioId,
      'view': <String, Object?>{
        'w': size.width,
        'h': size.height,
        'dpr': view.devicePixelRatio,
      },
      'hasGlow': probe.hasGlow,
      'texts': <Map<String, Object?>>[
        for (final ProbedText t in probe.texts) t.toJson(),
      ],
      'overlays': <String, Object?>{
        for (final MapEntry<String, Rect> e in overlays.entries)
          e.key: <String, double>{
            'x': e.value.left,
            'y': e.value.top,
            'w': e.value.width,
            'h': e.value.height,
          },
      },
      'probes': <String, Object?>{
        for (final MapEntry<String, Rect> e in keyed.entries)
          e.key: <String, double>{
            'x': e.value.left,
            'y': e.value.top,
            'w': e.value.width,
            'h': e.value.height,
          },
      },
    }),
  );
}
