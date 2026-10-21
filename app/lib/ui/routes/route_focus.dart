// Fokusrückgabe nach dem Schließen einer Route (Plan 4.4, n5): erst nach dem
// Ende der Route und nur, wenn der Auslöser noch existiert (er kann durch
// Tageswechsel oder Löschen weg sein).
import 'package:flutter/widgets.dart';

/// Schiebt [route] und gibt den Fokus an [trigger] zurück, sobald sie
/// geschlossen ist und der Auslöser noch gebaut ist.
Future<T?> pushReturningFocus<T extends Object?>(
  NavigatorState navigator,
  Route<T> route, {
  FocusNode? trigger,
}) async {
  final T? result = await navigator.push<T>(route);
  if (trigger != null && (trigger.context?.mounted ?? false)) {
    trigger.requestFocus();
  }
  return result;
}
