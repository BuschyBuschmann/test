// `ScreenFrame`: Gerüst der Screens (Plan 4.5): Grund `bg`, Welt einmal je
// Screen-Root hinter dem Inhalt (volle Breite), Inhalt und Overlays im
// `ContentFrame` (höchstens 560 dp, mittig). Overlays (Nav, Snackbar-Host)
// liegen über dem Inhalt, innerhalb des Rahmens.
import 'package:flutter/material.dart';

import 'content_frame.dart';
import 'world_background.dart';

/// Fester Textstil für das Scaffold-Material (siehe [ScreenFrame.build]).
const TextStyle _steadyBody = TextStyle(
  inherit: false,
  color: Colors.transparent,
);

class ScreenFrame extends StatelessWidget {
  const ScreenFrame({
    super.key,
    required this.child,
    this.overlays = const <Widget>[],
    this.resizeToAvoidBottomInset = true,
  });

  final Widget child;
  final List<Widget> overlays;

  /// Standard: der Inhalt weicht der Tastatur aus (fester Primärbutton über
  /// der Tastatur, Brief 7).
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final ThemeData real = Theme.of(context);
    // Das Material des Scaffold blendet Textstil und Schatten bei einem
    // Themenwechsel 200 ms über (V2-26: bei reduzierter Bewegung nichts über
    // 120 ms). Es sieht deshalb ein Theme, das sich zwischen Hell und Dunkel
    // nicht unterscheidet; der Inhalt bekommt das echte Theme und den echten
    // Standard-Textstil zurück.
    final TextStyle realBody = real.textTheme.bodyMedium ?? const TextStyle();
    final ThemeData steady = real.copyWith(
      textTheme: real.textTheme.copyWith(bodyMedium: _steadyBody),
      shadowColor: Colors.transparent,
      colorScheme: real.colorScheme.copyWith(
        shadow: Colors.transparent,
        surfaceTint: Colors.transparent,
      ),
    );
    return Theme(
      data: steady,
      child: Scaffold(
        // Die Welt füllt den Screen; ein eigener Scaffold-Grund würde beim
        // Themenwechsel 200 ms überblenden (V2-26: bei reduzierter Bewegung nichts
        // über 120 ms).
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: Theme(
          data: real,
          child: DefaultTextStyle(
            style: realBody,
            child: Stack(
              children: <Widget>[
                const Positioned.fill(child: WorldBackground()),
                Positioned.fill(
                  child: ContentFrame(
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(child: child),
                        ...overlays,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
