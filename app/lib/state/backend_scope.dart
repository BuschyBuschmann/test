// Reicht den [BackendController] durch den Baum. Ohne Scope läuft die App im
// Demo-Modus (Onboarding, lokale Daten) wie bisher.
import 'package:flutter/widgets.dart';

import 'backend_controller.dart';

class BackendScope extends InheritedNotifier<BackendController> {
  const BackendScope({
    super.key,
    required BackendController controller,
    required super.child,
  }) : super(notifier: controller);

  /// `null` im Demo-Modus.
  static BackendController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BackendScope>()?.notifier;

  /// Ohne Abhängigkeit (für Handler).
  static BackendController? readOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<BackendScope>()?.notifier;
}
