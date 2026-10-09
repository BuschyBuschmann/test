// Quelle der Pfaddaten und Ladezustand des Pfad-Tabs (Brief 6.2, Plan 4.6).
//
// Der Beispielpfad wird im ersten Ausschnitt synchron aus dem `AppState`
// abgeleitet; es gibt keine echte Ladequelle. Damit die Zustände „Laden“ und
// „Fehler“ des Pfad-Tabs (`path-loading`, `path-error`) trotzdem über den
// echten Weg erreichbar und prüfbar sind, läuft ihre Auslösung über diese
// Naht: [PathSource.prepare] liefert `null` (Standard, sofort bereit, kein
// Ladebild), ein `Future` (Laden, bis es endet) oder wirft (Fehler mit „Nochmal versuchen“).
// Das spätere Physio-Framework tritt hier an.
import 'package:flutter/widgets.dart';

enum PathLoadState { loading, ready, error }

abstract class PathSource {
  /// Bereitet den Pfad vor. `null` = sofort bereit; ein `Future` = Laden, bis
  /// es endet; eine Ausnahme (auch im `Future`) = Fehler.
  Future<void>? prepare();
}

/// Standard: der Pfad ist sofort da.
class ImmediatePathSource implements PathSource {
  const ImmediatePathSource();

  @override
  Future<void>? prepare() => null;
}

/// Stellt die [PathSource] bereit (Standard: [ImmediatePathSource]).
class PathSourceScope extends InheritedWidget {
  const PathSourceScope({
    super.key,
    required this.source,
    required super.child,
  });

  final PathSource source;

  /// Liest ohne Abhängigkeit (die Quelle wechselt nicht zur Laufzeit).
  static PathSource read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PathSourceScope>()?.source ??
      const ImmediatePathSource();

  @override
  bool updateShouldNotify(PathSourceScope oldWidget) =>
      source != oldWidget.source;
}
