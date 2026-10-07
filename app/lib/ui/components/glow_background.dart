// `GlowBackground` (Plan 8.2, Brief 3.2, Errata E-1): zwei ember-farbige
// Radialverläufe hinter dem Inhalt, statisch, einmal je Screen-Root. Füllt
// den verfügbaren Platz (in einen `Stack` hinter den Inhalt legen) und läuft
// auch außerhalb des `ContentFrame` voll durch. Bei `glowEnabled == false`
// (Hoher Kontrast) wird nichts gebaut. Keine Animation (Regel 9).
import 'package:flutter/widgets.dart';

import '../../theme/cura_colors.dart';
import '../../theme/glow.dart';
import '../../theme/tokens.dart';

class GlowBackground extends StatelessWidget {
  const GlowBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    if (!colors.glowEnabled) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: GlowPainter(colors.glowEmber),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// Malt die beiden Lichtflecke nach der Geometrie aus `glow.dart`
/// (`alpha(d) = Spitze × max(0, 1 − d / (0,7 × r))`, lineare Stops 0 und 0,7).
class GlowPainter extends CustomPainter {
  const GlowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final GlowGeometry geometry = GlowGeometry(size.width, size.height);
    for (final GlowSpot spot in geometry.spots) {
      final Rect rect = Rect.fromCircle(
        center: Offset(spot.centerX, spot.centerY),
        radius: spot.radius,
      );
      final Paint paint = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            color.withValues(alpha: spot.peak),
            color.withValues(alpha: 0),
          ],
          stops: const <double>[0, GlowTokens.zeroStop],
        ).createShader(rect);
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(GlowPainter oldDelegate) => oldDelegate.color != color;
}
