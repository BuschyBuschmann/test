// `PathOutlook` (Ergänzung 3, 2.1): Abschnittsmarke am oberen Ende des Pfads,
// hinter dem Boss: „Prävention & Gesundheitssport“, „Danach geht es weiter“.
// Bewusst **keine Unit** (kein Kreis, keine Woche, kein Ring, kein Manny) und
// immer gesperrt: Glas-Füllung ohne Blur, gestrichelter Rand `lockedBorder`
// (Hoher Kontrast: opak mit `border-control-hc`), Schloss-Kreis 36 dp, Titel
// `heading`/`text-1`, Untertitel `secondary`/`text-2`. Statisch (keine
// Animation, kein Schein). Pressed: Füllung 10 % heller wie bei Units.
//
// PLATZHALTER: Die volle Phase „Prävention & Gesundheitssport“ folgt später
// mit eigener Spec; die Marke ersetzt sich dann durch deren Units (A-4). Das
// Schloss bleibt auch bei späterer Freischaltung (A-5, dann neuer Brief).
//
// Breite und Lage bestimmt der Besitzer (`PathView`, Layout); die Höhe wächst
// mit dem Text, mindestens `unitLarge`. Hit-Area ist die ganze Marke.
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_pressable.dart';

class PathOutlook extends StatelessWidget {
  const PathOutlook({super.key, required this.onPressed});

  /// Tipp, Enter, Leertaste: zeigt den `NodeHint` (Besitzer).
  final VoidCallback onPressed;

  /// Breite des Textblocks bei der Markenbreite [width].
  static double textWidthFor(double width) =>
      width -
      2 * CuraSize.outlookPaddingHorizontal -
      CuraSize.outlookLock -
      CuraSize.outlookLockGap;

  /// Höhe der Marke bei gemessener Texthöhe [textHeight] (Titel plus
  /// Untertitel): Innenabstand oben und unten, mindestens `unitLarge`.
  static double heightFor(double textHeight) {
    final double content = textHeight > CuraSize.outlookLock
        ? textHeight
        : CuraSize.outlookLock;
    final double h = content + 2 * CuraSize.outlookPaddingVertical;
    return h > CuraSize.unitLarge ? h : CuraSize.unitLarge;
  }

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final BorderRadius shape = BorderRadius.circular(CuraRadius.card);
    return CuraPressable(
      onPressed: onPressed,
      semanticLabel: S.outlookLabel,
      ringRadius: CuraRadius.card,
      builder: (BuildContext context, bool pressed) {
        return CustomPaint(
          foregroundPainter: DashedRRectPainter(
            color: colors.lockedBorder,
            width: CuraSize.controlBorder,
            radius: CuraRadius.card,
            dash: CuraSize.outlookDash,
            gap: CuraSize.outlookDashGap,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: colors.cardFill,
              borderRadius: shape,
            ),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                color: pressed ? colors.pressedOverlay : null,
                borderRadius: shape,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: CuraSize.unitLarge,
                  minWidth: double.infinity,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CuraSize.outlookPaddingHorizontal,
                    vertical: CuraSize.outlookPaddingVertical,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.lockedBorder,
                            width: CuraSize.controlBorder,
                          ),
                        ),
                        child: SizedBox.square(
                          dimension: CuraSize.outlookLock,
                          child: Icon(
                            Icons.lock_rounded,
                            size:
                                CuraSize.outlookLock * CuraSize.unitIconFactor,
                            color: colors.lockedIcon,
                          ),
                        ),
                      ),
                      const SizedBox(width: CuraSize.outlookLockGap),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              S.outlookTitle,
                              style: type.heading.copyWith(color: colors.text1),
                            ),
                            Text(
                              S.outlookSubtitle,
                              style: type.secondary.copyWith(
                                color: colors.text2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Gestrichelter Rand um ein Rechteck mit gerundeten Ecken (Strich [dash],
/// Lücke [gap], Linie [width], innen bündig).
class DashedRRectPainter extends CustomPainter {
  const DashedRRectPainter({
    required this.color,
    required this.width,
    required this.radius,
    required this.dash,
    required this.gap,
  });

  final Color color;
  final double width;
  final double radius;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final double inset = width / 2;
    final RRect shape = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(inset),
      Radius.circular(radius - inset),
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
        final double end = (distance + dash).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedRRectPainter old) =>
      old.color != color ||
      old.width != width ||
      old.radius != radius ||
      old.dash != dash ||
      old.gap != gap;
}
