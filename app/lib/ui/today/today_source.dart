// Quelle der Heute-Daten und Ladezustand des Tabs Heute (Brief 6.3, Plan 4.6).
//
// Wie beim Pfad (`PathSource`) wird das Tagesprogramm im ersten Ausschnitt
// synchron aus dem `AppState` abgeleitet; es gibt keine echte Ladequelle. Damit
// die Zustände „Laden“ und „Fehler“ (`today-loading`, `today-error`) über den
// echten Weg erreichbar und prüfbar sind, läuft ihre Auslösung über diese
// Naht: [TodaySource.prepare] liefert `null` (Standard, sofort bereit), ein
// `Future` (Laden, bis es endet) oder wirft (Fehler mit „Nochmal versuchen“).
// Das spätere Physio-Framework tritt hier an.
import 'package:flutter/widgets.dart';

enum TodayLoadState { loading, ready, error }

abstract class TodaySource {
  /// Bereitet das Tagesprogramm vor. `null` = sofort bereit; ein `Future` =
  /// Laden, bis es endet; eine Ausnahme (auch im `Future`) = Fehler.
  Future<void>? prepare();
}

/// Standard: das Programm ist sofort da.
class ImmediateTodaySource implements TodaySource {
  const ImmediateTodaySource();

  @override
  Future<void>? prepare() => null;
}

/// Stellt die [TodaySource] bereit (Standard: [ImmediateTodaySource]).
class TodaySourceScope extends InheritedWidget {
  const TodaySourceScope({
    super.key,
    required this.source,
    required super.child,
  });

  final TodaySource source;

  /// Liest ohne Abhängigkeit (die Quelle wechselt nicht zur Laufzeit).
  static TodaySource read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<TodaySourceScope>()?.source ??
      const ImmediateTodaySource();

  @override
  bool updateShouldNotify(TodaySourceScope oldWidget) =>
      source != oldWidget.source;
}
