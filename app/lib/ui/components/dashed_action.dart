// `DashedAction` (Brief 5.3): gestrichelte Aktion „+ Eigene Übung“. 48 dp
// hoch, volle Breite, Rand gestrichelt in `border-control` (HC `-hc`), Text
// und Icon `text-1`. Pressed: Überlagerung Weiß 10 %.
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_pressable.dart';

class DashedAction extends StatelessWidget {
  const DashedAction({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.focusNode,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final IconData icon;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return CuraPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      ringRadius: CuraRadius.pill,
      builder: (BuildContext context, bool pressed) {
        return CustomPaint(
          foregroundPainter: _DashedBorderPainter(
            color: colors.controlBorder,
            width: CuraSize.controlBorder,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: pressed ? colors.pressedOverlay : null,
              borderRadius: BorderRadius.circular(CuraRadius.pill),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: CuraSize.chipHeight,
                minWidth: double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CuraSpace.s4,
                  vertical: CuraSpace.s2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      icon,
                      size: CuraComponent.iconSize,
                      color: colors.text1,
                    ),
                    const SizedBox(width: CuraComponent.pillIconGap),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: type.body.copyWith(color: colors.text1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.width});

  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect shape = RRect.fromRectAndRadius(
      rect.deflate(width / 2),
      // Ein Radius über der halben Höhe wird auf die Pille zurückgenommen.
      Radius.circular(size.shortestSide),
    );
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    final Path path = Path()..addRRect(shape);
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double end = (distance + CuraSize.dashLength).clamp(
          0,
          metric.length,
        );
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += CuraSize.dashLength + CuraSize.dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.width != width;
}
