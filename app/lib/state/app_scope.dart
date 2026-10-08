import 'package:flutter/widgets.dart';

import 'app_controller.dart';

/// Stellt den [AppController] bereit; Screens lesen per `AppScope.of(context)`
/// und werden bei jeder Änderung neu gebaut.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final AppController? c = maybeOf(context);
    assert(c != null, 'Kein AppScope im Widget-Baum');
    return c!;
  }

  static AppController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()?.notifier;
}
