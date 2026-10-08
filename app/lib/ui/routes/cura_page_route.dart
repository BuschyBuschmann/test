// Seitenroute der App (StartGate, Onboarding, Home, Datenschutz-Platzhalter):
// opak, Einblenden in `dur-base`, bei reduzierter Bewegung höchstens
// `dur-fast`, keine Schiebung (Plan 4.1, 8.1). Die Dauer wird beim Anlegen
// aus `CuraMotion.of(context)` gelesen.
import 'package:flutter/widgets.dart';

import '../../theme/cura_motion.dart';

Route<T> curaPageRoute<T>(
  BuildContext context,
  WidgetBuilder builder, {
  String? name,
}) {
  final CuraMotion motion = CuraMotion.of(context);
  final Duration duration = motion.duration(motion.base);
  return PageRouteBuilder<T>(
    settings: RouteSettings(name: name),
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondary,
    ) => builder(context),
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondary,
          Widget child,
        ) {
          return FadeTransition(
            opacity: animation.drive(CurveTween(curve: motion.curve)),
            child: child,
          );
        },
  );
}
