// `PathNode` (Brief 5.5, Ergänzung 1, 3.5, Plan 9): eine Unit des Pfads als
// Kreis. Durchmesser 48 (Trainingstag), 60 (Wochenziel), 72 (Phasen-Abschluss)
// oder 92 (Boss); die Hit-Area ist der Kreis (mindestens 48 dp).
//
// Zustände (Zustand nie nur in der Farbe: Symbol und Screenreader-Label):
// - erledigt: Füllung `text-1`, dunkler Haken (`on-accent`)
// - aktuell: Füllung `accent`, Flagge in `on-accent`, Ring 1,5 dp `accent`
//   40 % im Abstand 9 dp, weicher Schein (Radialverlauf `accent` 50 %, bei
//   Hohem Kontrast aus)
// - gesperrt: `bg` plus Glas-Füllung, Rand Weiß 20 %, Schloss Weiß 50 %; Boss:
//   Rand `accent` 55 % und Stern `accent-hi`; Phasen-Abschluss: Stern Weiß 50 %
// Pressed: Füllung 10 % heller. Fokus, Enter und Leertaste über
// `CuraPressable`. Optional ein einmaliger Ring-Puls (`dur-slow`, nach der
// Feier); bei reduzierter Bewegung entfällt er.
import 'package:flutter/material.dart';

import '../../logic/path_model.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../../theme/cura_roles.dart';
import 'cura_pressable.dart';

class PathNode extends StatefulWidget {
  const PathNode({
    super.key,
    required this.unit,
    required this.status,
    required this.diameter,
    required this.semanticLabel,
    required this.onPressed,
    this.pulse = false,
    this.onPulseDone,
  });

  final PathUnit unit;
  final UnitStatus status;
  final double diameter;

  /// „Woche 5, Trainingstag 3, aktuell. Öffnet Heute.“
  final String semanticLabel;
  final VoidCallback onPressed;

  /// Löst den einmaligen Ring-Puls aus (Wechsel von `false` zu `true`).
  final bool pulse;
  final VoidCallback? onPulseDone;

  @override
  State<PathNode> createState() => _PathNodeState();
}

class _PathNodeState extends State<PathNode>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void didUpdateWidget(PathNode old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !old.pulse) _startPulseAfterBuild();
  }

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _startPulseAfterBuild();
  }

  /// Der Puls beginnt nie mitten im Bauen: `setState` und der Rückruf des
  /// Besitzers kommen nach dem Frame.
  void _startPulseAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startPulse();
    });
  }

  void _startPulse() {
    final CuraMotion motion = CuraMotion.of(context);
    if (motion.reduced) {
      // Bewegung reduzieren: kein Puls (Brief 3.6).
      widget.onPulseDone?.call();
      return;
    }
    final AnimationController c = _pulse ??= AnimationController(
      vsync: this,
      duration: motion.slow,
    );
    c.forward(from: 0).whenComplete(() {
      if (mounted) widget.onPulseDone?.call();
    });
    setState(() {});
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.status) {
      case UnitStatus.done:
        return Icons.check_rounded;
      case UnitStatus.current:
        return Icons.flag_rounded;
      case UnitStatus.locked:
        return widget.unit.kind == UnitKind.boss ||
                widget.unit.kind == UnitKind.phaseEnd
            ? Icons.star_rounded
            : Icons.lock_rounded;
    }
  }

  Color _iconColor(CuraColors c) {
    switch (widget.status) {
      case UnitStatus.done:
      case UnitStatus.current:
        return c.onAccent;
      case UnitStatus.locked:
        return widget.unit.kind == UnitKind.boss ? c.accentHi : c.lockedIcon;
    }
  }

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final double d = widget.diameter;
    final bool current = widget.status == UnitStatus.current;
    final AnimationController? pulse = _pulse;
    return CuraPressable(
      onPressed: widget.onPressed,
      semanticLabel: widget.semanticLabel,
      ringRadius: d / 2,
      builder: (BuildContext context, bool pressed) {
        final Widget disc = _disc(colors, d, pressed);
        return SizedBox.square(
          dimension: d,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              if (current || (pulse != null && pulse.isAnimating))
                Positioned(
                  left: -_outer,
                  top: -_outer,
                  right: -_outer,
                  bottom: -_outer,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation:
                            pulse ?? const AlwaysStoppedAnimation<double>(0),
                        builder: (BuildContext context, Widget? _) {
                          return CustomPaint(
                            painter: _NodeAuraPainter(
                              colors: colors,
                              diameter: d,
                              current: current,
                              pulse: pulse != null && pulse.isAnimating
                                  ? pulse.value
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              Positioned.fill(child: disc),
            ],
          ),
        );
      },
    );
  }

  /// So weit reicht Ring, Schein bzw. Puls über den Kreis hinaus.
  static const double _outer =
      CuraSize.unitRingGap + CuraSize.unitRingWidth + CuraSize.unitGlowExtent;

  Widget _disc(CuraColors colors, double d, bool pressed) {
    final UnitStatus status = widget.status;
    final Widget icon = Center(
      child: Icon(
        _icon,
        size: d * CuraSize.unitIconFactor,
        color: _iconColor(colors),
      ),
    );
    switch (status) {
      case UnitStatus.done:
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pressed ? colors.pureWhite : colors.text1,
          ),
          child: icon,
        );
      case UnitStatus.current:
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: pressed ? colors.accentPressed : colors.accent,
          ),
          child: icon,
        );
      case UnitStatus.locked:
        final bool boss = widget.unit.kind == UnitKind.boss;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: colors.cardFill,
            border: Border.all(
              color: boss && !colors.highContrast
                  ? colors.bossBorder
                  : colors.lockedBorder,
              width: CuraSize.controlBorder,
            ),
          ),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pressed ? colors.pressedOverlay : null,
            ),
            child: icon,
          ),
        );
    }
  }
}

/// Ring, weicher Schein der aktuellen Unit und Ring-Puls. Die Fläche ist um
/// [_PathNodeState._outer] größer als der Kreis; der Kreis liegt in der Mitte.
class _NodeAuraPainter extends CustomPainter {
  _NodeAuraPainter({
    required this.colors,
    required this.diameter,
    required this.current,
    required this.pulse,
  });

  final CuraColors colors;
  final double diameter;
  final bool current;

  /// 0 … 1 während des Puls, sonst `null`.
  final double? pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = diameter / 2;
    if (current) {
      final double ring = r + CuraSize.unitRingGap + CuraSize.unitRingWidth / 2;
      if (colors.shadowsEnabled) {
        final double glow = ring + CuraSize.unitGlowExtent;
        canvas.drawCircle(
          c,
          glow,
          Paint()
            ..shader = RadialGradient(
              colors: <Color>[
                colors.accentUnitGlow,
                colors.accentUnitGlowClear,
              ],
              stops: <double>[r / glow, 1],
            ).createShader(Rect.fromCircle(center: c, radius: glow)),
        );
      }
      canvas.drawCircle(
        c,
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = CuraSize.unitRingWidth
          ..color = colors.accentRing,
      );
    }
    final double? t = pulse;
    if (t != null) {
      // Ring wächst vom Rand der Unit nach außen und blendet aus.
      final double radius = r + CuraSize.unitPulseExtent * t;
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = CuraSize.unitPulseWidth
          ..color = colors.unitPulse(t),
      );
    }
  }

  @override
  bool shouldRepaint(_NodeAuraPainter old) =>
      old.colors != colors ||
      old.diameter != diameter ||
      old.current != current ||
      old.pulse != pulse;
}
