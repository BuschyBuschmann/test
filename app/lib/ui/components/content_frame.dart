// `ContentFrame` (Plan B-3, Brief 7): Inhalte volle Breite bis 560 dp, breiter
// mittig begrenzt. Hintergrund und Glow liegen außerhalb und laufen voll durch.
import 'package:flutter/widgets.dart';

import '../../theme/cura_metrics.dart';

class ContentFrame extends StatelessWidget {
  const ContentFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth > CuraSize.lineLengthMax
            ? CuraSize.lineLengthMax
            : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            height: constraints.hasBoundedHeight ? constraints.maxHeight : null,
            child: child,
          ),
        );
      },
    );
  }
}
