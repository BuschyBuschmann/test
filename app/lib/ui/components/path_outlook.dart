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

/// Messung eines Textes: Größe bei der Höchstbreite (die Besitzerin der Marke
/// misst gecacht, der Baustein selbst mit [PathOutlook.paint]).
typedef OutlookTextMeasure = Size Function(
  String text,
  TextStyle style,
  double maxWidth,
  TextScaler s,
);

/// Aufbau der Marke bei einer Breite: Schloss **neben** dem Text oder, wenn der
/// schmale Block ein Wort des Titels sonst mitten im Wort bräche, **über** dem
/// Text (F-3); dazu Breite des Textblocks und Höhe der ganzen Marke.
class OutlookLayout {
  const OutlookLayout({
    required this.stacked,
    required this.textWidth,
    required this.height,
  });

  final bool stacked;
  final double textWidth;
  final double height;
}

class PathOutlook extends StatelessWidget {
  const PathOutlook({super.key, required this.onPressed});

  /// Tipp, Enter, Leertaste: zeigt den `NodeHint` (Besitzer).
  final VoidCallback onPressed;

  /// Der Titel skaliert bis 150 % mit (wie die Titel der Köpfe): bei 200 % auf
  /// 320 dp bräche „Gesundheitssport“ sonst mitten im Wort (F-3, B3).
  static TextScaler titleScaler(TextScaler scaler) => scaler.clamp(
    minScaleFactor: 1,
    maxScaleFactor: CuraSize.headerTitleMaxTextScale,
  );

  /// Breite des Textblocks bei der Markenbreite [width], Schloss daneben.
  static double textWidthFor(double width) =>
      width -
      2 * CuraSize.outlookPaddingHorizontal -
      CuraSize.outlookLock -
      CuraSize.outlookLockGap;

  /// Breite des Textblocks, Schloss darüber.
  static double stackedTextWidthFor(double width) =>
      width - 2 * CuraSize.outlookPaddingHorizontal;

  /// Höhe der Marke bei gemessener Texthöhe [textHeight] (Titel plus
  /// Untertitel): Innenabstand oben und unten, mindestens `unitLarge`.
  static double heightFor(double textHeight) {
    final double content = textHeight > CuraSize.outlookLock
        ? textHeight
        : CuraSize.outlookLock;
    final double h = content + 2 * CuraSize.outlookPaddingVertical;
    return h > CuraSize.unitLarge ? h : CuraSize.unitLarge;
  }

  /// Aufbau und Höhe bei der Markenbreite [width] (ohne Außenrand). Schloss
  /// daneben, solange jedes Wort von Titel und Untertitel in den Textblock
  /// passt; sonst das Schloss über den Text, der Textblock wird breiter.
  static OutlookLayout layoutFor({
    required double width,
    required CuraTypography type,
    required TextScaler scaler,
    required OutlookTextMeasure measure,
  }) {
    final TextScaler titleS = titleScaler(scaler);
    double longestWord(String text, TextStyle style, TextScaler s) {
      double w = 0;
      for (final String word in text.split(' ')) {
        if (word.isEmpty) continue;
        final double ww = measure(word, style, double.infinity, s).width;
        if (ww > w) w = ww;
      }
      return w;
    }

    final double need = <double>[
      longestWord(S.outlookTitle, type.heading, titleS),
      longestWord(S.outlookSubtitle, type.secondary, scaler),
    ].reduce((double a, double b) => a > b ? a : b);
    final bool stacked = need > textWidthFor(width);
    final double textWidth = stacked
        ? stackedTextWidthFor(width)
        : textWidthFor(width);
    final double text =
        measure(S.outlookTitle, type.heading, textWidth, titleS).height +
        measure(S.outlookSubtitle, type.secondary, textWidth, scaler).height;
    if (!stacked) {
      return OutlookLayout(
        stacked: false,
        textWidth: textWidth,
        height: heightFor(text),
      );
    }
    return OutlookLayout(
      stacked: true,
      textWidth: textWidth,
      height: heightFor(CuraSize.outlookLock + CuraSize.outlookLockGap + text),
    );
  }

  /// Messung des Bausteins selbst: wie `Text` (geerbter `DefaultTextStyle`
  /// gehört zur Breite) mit etwas Luft gegen Rundung der Textbreite.
  static OutlookTextMeasure paint(BuildContext context) {
    final TextStyle base = DefaultTextStyle.of(context).style;
    return (String text, TextStyle style, double maxWidth, TextScaler s) {
      final TextPainter tp = TextPainter(
        text: TextSpan(text: text, style: base.merge(style)),
        textDirection: TextDirection.ltr,
        textScaler: s,
      )..layout(maxWidth: maxWidth < 0 ? 0 : maxWidth);
      final Size size = Size(
        tp.width.ceilToDouble() + CuraSize.measureSlack,
        tp.height,
      );
      tp.dispose();
      return size;
    };
  }

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final BorderRadius shape = BorderRadius.circular(CuraRadius.card);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final OutlookTextMeasure measure = paint(context);
    return CuraPressable(
      onPressed: onPressed,
      semanticLabel: S.outlookLabel,
      ringRadius: CuraRadius.card,
      builder: (BuildContext context, bool pressed) {
        final Widget lock = DecoratedBox(
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
              size: CuraSize.outlookLock * CuraSize.unitIconFactor,
              color: colors.lockedIcon,
            ),
          ),
        );
        final Widget texts = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Titel höchstens bei 150 %, nie mitten im Wort (F-3).
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: CuraSize.headerTitleMaxTextScale,
              child: Text(
                S.outlookTitle,
                style: type.heading.copyWith(color: colors.text1),
              ),
            ),
            Text(
              S.outlookSubtitle,
              style: type.secondary.copyWith(color: colors.text2),
            ),
          ],
        );
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
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints box) {
                      final OutlookLayout layout = layoutFor(
                        width:
                            box.maxWidth +
                            2 * CuraSize.outlookPaddingHorizontal,
                        type: type,
                        scaler: scaler,
                        measure: measure,
                      );
                      if (layout.stacked) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            lock,
                            const SizedBox(height: CuraSize.outlookLockGap),
                            texts,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          lock,
                          const SizedBox(width: CuraSize.outlookLockGap),
                          Expanded(child: texts),
                        ],
                      );
                    },
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
