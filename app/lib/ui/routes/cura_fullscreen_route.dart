// `CuraFullscreenRoute` (Plan 4.4, Ergänzung 2, 2.1, 4): Vollbild-Route für
// Manny-Chat, Nachrichten und Beispiel-Chat. Opake `PageRoute` ohne Scrim und
// ohne Blur. Übergang: Einblenden plus 24 dp Schiebung von rechts in
// `dur-base` mit `curve`; bei reduzierter Bewegung nur Einblenden in höchstens
// `dur-fast`, keine Schiebung. Zurück, Android-Zurück und Escape schließen
// (die Route ist immer poppbar; Escape hängt am `ChatScreenScaffold`).
// Routenname für den Screenreader über [routeLabel] („Manny, Chat“,
// „Nachrichten“, „Beispiel-Chat [Name]“). Den Anfangsfokus setzt der
// Zurück-Pfeil des `ChatHeader` (`autofocus`).
import 'package:flutter/widgets.dart';

import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';

class CuraFullscreenRoute<T> extends PageRoute<T> {
  CuraFullscreenRoute({
    required BuildContext context,
    required this.builder,
    required this.routeLabel,
    super.settings,
  }) : _reduced = CuraMotion.of(context).reduced;

  final WidgetBuilder builder;

  /// Name der Route für den Screenreader.
  final String routeLabel;

  final bool _reduced;

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration =>
      _reduced ? CuraMotion.fastDuration : CuraMotion.baseDuration;

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: routeLabel,
      child: builder(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Animation<double> curved = animation.drive(
      CurveTween(curve: CuraMotion.easing),
    );
    final Widget faded = FadeTransition(opacity: curved, child: child);
    if (_reduced) return faded;
    return AnimatedBuilder(
      animation: curved,
      child: faded,
      builder: (BuildContext context, Widget? child) {
        return Transform.translate(
          offset: Offset((1 - curved.value) * CuraSize.routeSlide, 0),
          child: child,
        );
      },
    );
  }
}
