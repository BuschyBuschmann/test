// `OpaqueSurface` (Ergänzung 2, Abschnitt 2): deckende Fläche `surface-opaque`
// mit Rand 1 dp `border-hair` (Hoher Kontrast: `border-control-hc`), ohne Blur,
// ohne Glow, ohne Schatten. Gemeinsame Basis der Eingabeleiste und der
// eigenen Blasen. Die Text-Sonde der Prüfumgebung erkennt sie als deckenden
// Untergrund (glowfrei).
import 'package:flutter/widgets.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';

class OpaqueSurface extends StatelessWidget {
  const OpaqueSurface({
    super.key,
    required this.child,
    required this.borderRadius,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  /// Radien einer Chat-Blase: alle Ecken 20 dp, die Ecke zur Absenderseite
  /// 6 dp (rechts unten bei eigenen, links unten beim Gegenüber).
  static BorderRadius bubbleRadius({required bool ownSide}) =>
      BorderRadius.only(
        topLeft: const Radius.circular(CuraRadius.bubble),
        topRight: const Radius.circular(CuraRadius.bubble),
        bottomLeft: Radius.circular(
          ownSide ? CuraRadius.bubble : CuraRadius.bubbleCorner,
        ),
        bottomRight: Radius.circular(
          ownSide ? CuraRadius.bubbleCorner : CuraRadius.bubble,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceOpaque,
        borderRadius: borderRadius,
        border: Border.all(color: colors.cardBorder, width: CuraSize.hairline),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
