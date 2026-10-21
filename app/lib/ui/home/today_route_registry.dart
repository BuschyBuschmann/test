// Register der Heute-Routen (Plan 4.4, 4.6): Trainings-Sheet „Wie willst du
// trainieren?“ und Dialog „Eigene Übung“ melden sich hier an, damit ein
// Tageswechsel genau diese Routen schließen kann (`removeRoute`, ohne
// Animation). „Deine Daten“ meldet sich nicht an und bleibt offen
// (Ergänzung 1, 3.4).
import 'package:flutter/widgets.dart';

class TodayRouteRegistry {
  final List<Route<dynamic>> _routes = <Route<dynamic>>[];

  int get length => _routes.length;

  /// Merkt sich [route] bis zu ihrem Ende.
  void register(Route<dynamic> route) {
    _routes.removeWhere((Route<dynamic> r) => !r.isActive);
    _routes.add(route);
    route.popped.whenComplete(() => _routes.remove(route));
  }

  /// Schließt alle angemeldeten Routen, die noch im Navigator stehen.
  void closeAll() {
    for (final Route<dynamic> route in List<Route<dynamic>>.of(_routes)) {
      final NavigatorState? navigator = route.navigator;
      if (route.isActive && navigator != null) navigator.removeRoute(route);
    }
    _routes.clear();
  }
}
