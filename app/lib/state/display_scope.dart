import 'package:flutter/widgets.dart';

import 'display_controller.dart';

/// Stellt den [DisplayController] bereit; Theme-Wahl und Welt lesen per
/// `DisplayScope.maybeOf(context)` und bauen bei jeder Änderung neu.
class DisplayScope extends InheritedNotifier<DisplayController> {
  const DisplayScope({
    super.key,
    required DisplayController controller,
    required super.child,
  }) : super(notifier: controller);

  static DisplayController of(BuildContext context) {
    final DisplayController? c = maybeOf(context);
    assert(c != null, 'Kein DisplayScope im Widget-Baum');
    return c!;
  }

  static DisplayController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DisplayScope>()?.notifier;
}
