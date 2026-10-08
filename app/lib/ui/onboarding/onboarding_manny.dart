// Manny mit Sprechblase im Onboarding (Brief 6.1, 5.6): immer linksbündig zur
// Inhaltsspalte (auch auf breiten Displays, A-U3 B5); Manny links, die Blase
// rechts daneben mit Pfeil nach links; bleiben rechts weniger als 140 dp, steht
// die Blase oberhalb (Pfeil nach unten). Manny ist hier nicht antippbar
// (Ergänzung 2: kein Chat-Einstieg im Onboarding).
import 'package:flutter/material.dart';

import '../../theme/cura_roles.dart';
import '../components/manny.dart';
import '../components/manny_bubble.dart';

class OnboardingManny extends StatelessWidget {
  const OnboardingManny({
    super.key,
    required this.height,
    required this.text,
    required this.bubbleVisible,
    required this.onCloseBubble,
  });

  /// Höhe von Manny (Schritt 1: 120 dp, sonst 64 dp).
  final double height;
  final String text;
  final bool bubbleVisible;
  final VoidCallback onCloseBubble;

  @override
  Widget build(BuildContext context) {
    final Size manny = MannyPlaceholder.sizeFor(MannyCrop.full, height);
    final Widget figure = MannyPlaceholder(height: height);
    if (!bubbleVisible) {
      return Align(alignment: Alignment.topLeft, child: figure);
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final BubbleArrow arrow = MannyBubble.arrowFor(
          box.maxWidth - manny.width,
        );
        if (arrow == BubbleArrow.left) {
          final Widget row = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              figure,
              Flexible(
                child: MannyBubble(text: text, onClose: onCloseBubble),
              ),
            ],
          );
          return Align(alignment: Alignment.topLeft, child: row);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MannyBubble(
              text: text,
              onClose: onCloseBubble,
              arrow: BubbleArrow.down,
              arrowOffset: (manny.width - CuraComponent.bubbleArrowBase) / 2,
            ),
            figure,
          ],
        );
      },
    );
  }
}
