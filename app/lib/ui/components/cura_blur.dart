// `CuraBlur` (Plan 8.3, Brief 3.5): einzige Stelle mit `BackdropFilter`
// (Regel 3). Verwendet nur von `FloatingNav`, `MannyBubble` und
// `CuraSheetRoute`. Bei `blurEnabled == false` (Hoher Kontrast) wird nichts
// weichgezeichnet; die Fläche des Kindes ist dann opak.
import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../../theme/cura_colors.dart';
import '../../theme/tokens.dart';

class CuraBlur extends StatelessWidget {
  const CuraBlur({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
  });

  final Widget child;

  /// Zuschnitt des weichgezeichneten Bereichs (Form der schwebenden Fläche).
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    if (!CuraColors.of(context).blurEnabled) return child;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: BlurTokens.sigma,
          sigmaY: BlurTokens.sigma,
        ),
        child: child,
      ),
    );
  }
}
