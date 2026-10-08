// `ScreenFrame`: Gerüst der Screens (Plan 4.5): Grund `bg`, Glow einmal je
// Screen-Root hinter dem Inhalt (volle Breite), Inhalt und Overlays im
// `ContentFrame` (höchstens 560 dp, mittig). Overlays (Nav, Snackbar-Host)
// liegen über dem Inhalt, innerhalb des Rahmens.
import 'package:flutter/material.dart';

import 'content_frame.dart';
import 'glow_background.dart';

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
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: GlowBackground()),
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
    );
  }
}
