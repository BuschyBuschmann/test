// `OrbNode` (Design-Brief v2, 4 und 3.5; ersetzt `PathNode`): Pfad-Kugel als
// Glas-Objekt der Ebene E3. Radialverlauf mit Glanzpunkt oben links, Innen-
// schatten unten, 1 dp helle Kante und ein Bodenschatten (Ellipse, getönt);
// keine harten Unterkanten, **kein Blur**.
//
// Größen (dp): Trainingstag 56, Wochenziel 62, Phasen-Abschluss 80, aktuell
// 92, Boss 104. Zustände (jeder mit Symbol und Label, nie nur Farbe):
// - Erledigt: Perlglas, Haken `#8A3A0C`
// - Aktuell: Mandarine-Kugel mit Halo (weicher Schein, Ring), dunkle Flagge;
//   Tipp öffnet Heute
// - Gesperrt: Grauglas, Schloss `ink-2` (Phasen-Abschluss: Stern); Tipp zeigt
//   einen Hinweis
// - Ziel/Boss: Gold, Stern im Ton `#B8470F`, gesperrt oder aktiv
// Screenreader: „Tag 12, erledigt“, „Heute, aktuell“, „gesperrt“, „Ziel Return
// to Sport, gesperrt“ (das Label liefert der Besitzer).
//
// Optional ein einmaliger Ring-Puls (`dur-slow`, nach der Feier); bei
// reduzierter Bewegung entfällt er. Fokus, Enter und Leertaste über
// `CuraPressable`. Hoher Kontrast/Transparenz reduzieren: kein Schein, kein
// Bodenschatten, Kante `border-control-hc`.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../../theme/cura_roles.dart';
import 'cura_pressable.dart';

/// Art der Kugel (bestimmt die Größe und das Symbol im gesperrten Zustand).
enum OrbKind { day, weekGoal, phaseEnd, boss }

enum OrbState { done, current, locked }

class OrbNode extends StatefulWidget {
  const OrbNode({
    super.key,
    required this.kind,
    required this.state,
    required this.semanticLabel,
    required this.onPressed,
    this.pulse = false,
    this.onPulseDone,
  });

  final OrbKind kind;
  final OrbState state;

  /// „Tag 12, erledigt“ / „Heute, aktuell“ / „gesperrt“.
  final String semanticLabel;
  final VoidCallback onPressed;

  /// Löst den einmaligen Ring-Puls aus (Wechsel von `false` zu `true`).
  final bool pulse;
  final VoidCallback? onPulseDone;

  /// Durchmesser: Boss 104, sonst aktuell 92, sonst nach Art 56 / 62 / 80.
  static double diameterFor(OrbKind kind, OrbState state) {
    if (kind == OrbKind.boss) return CuraSize.orbBoss;
    if (state == OrbState.current) return CuraSize.orbCurrent;
    return switch (kind) {
      OrbKind.day => CuraSize.orbDay,
      OrbKind.weekGoal => CuraSize.orbWeekGoal,
      OrbKind.phaseEnd => CuraSize.orbPhaseEnd,
      OrbKind.boss => CuraSize.orbBoss,
    };
  }

  @override
  State<OrbNode> createState() => _OrbNodeState();
}

class _OrbNodeState extends State<OrbNode> with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _startPulseAfterBuild();
  }

  @override
  void didUpdateWidget(OrbNode old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !old.pulse) _startPulseAfterBuild();
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

  bool get _boss => widget.kind == OrbKind.boss;

  IconData get _icon {
    if (widget.state == OrbState.done) return Icons.check_rounded;
    if (_boss) return Icons.star_rounded;
    if (widget.state == OrbState.current) return Icons.flag_rounded;
    return widget.kind == OrbKind.phaseEnd
        ? Icons.star_rounded
        : Icons.lock_rounded;
  }

  Color _iconColor(CuraColors c) {
    if (widget.state == OrbState.done) return c.orbCheck;
    if (_boss) return c.orbStar;
    if (widget.state == OrbState.current) return c.onAccent;
    return c.text2;
  }

  OrbShades _shades(CuraColors c) {
    if (_boss) return c.orbGold;
    return switch (widget.state) {
      OrbState.done => c.orbPearl,
      OrbState.current => c.orbMandarin,
      OrbState.locked => c.orbGlass,
    };
  }

  /// So weit reichen Ring, Schein und Puls über den Kreis hinaus.
  static const double _outer =
      CuraSize.unitRingGap + CuraSize.unitRingWidth + CuraSize.unitGlowExtent;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final double d = OrbNode.diameterFor(widget.kind, widget.state);
    final bool current = widget.state == OrbState.current;
    final AnimationController? pulse = _pulse;
    final OrbShades shades = _shades(colors);
    return CuraPressable(
      onPressed: widget.onPressed,
      semanticLabel: widget.semanticLabel,
      ringRadius: d / 2,
      builder: (BuildContext context, bool pressed) {
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
                            painter: _OrbAuraPainter(
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
              Positioned.fill(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    painter: _OrbPainter(
                      colors: colors,
                      shades: shades,
                      pressed: pressed,
                    ),
                    child: Center(
                      child: Icon(
                        _icon,
                        size: d * CuraSize.unitIconFactor,
                        color: _iconColor(colors),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Die Kugel: Bodenschatten, Radialverlauf, Innenschatten, Glanz, Kante.
class _OrbPainter extends CustomPainter {
  _OrbPainter({
    required this.colors,
    required this.shades,
    required this.pressed,
  });

  final CuraColors colors;
  final OrbShades shades;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final double d = size.width;
    final Rect rect = Offset.zero & size;
    final Offset center = rect.center;

    // Bodenschatten (Ellipse unter der Kugel, weich); bei Hohem Kontrast aus.
    if (colors.shadowsEnabled) {
      final Rect ground = Rect.fromCenter(
        center: Offset(
          center.dx,
          d + d * OrbGeometry.groundOffset + d * OrbGeometry.groundHeight / 2,
        ),
        width: d * OrbGeometry.groundWidth,
        height: d * OrbGeometry.groundHeight,
      );
      canvas.drawOval(
        ground,
        Paint()
          ..color = colors.orbGroundShadow
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            OrbGeometry.groundBlur,
          ),
      );
    }

    // Körper: Radialverlauf mit Lichtpunkt oben links.
    canvas.drawCircle(
      center,
      d / 2,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(OrbGeometry.highX, OrbGeometry.highY),
          radius: OrbGeometry.gradientRadius,
          colors: <Color>[shades.high, shades.body, shades.edge],
          stops: OrbGeometry.gradientStops,
        ).createShader(rect),
    );

    // Innenschatten unten.
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            colors.orbInnerShadow.withValues(alpha: 0),
            colors.orbInnerShadow,
          ],
          stops: const <double>[OrbGeometry.innerShadowFrom, 1],
        ).createShader(rect),
    );

    // Glanzfleck oben links.
    canvas.save();
    final Rect gloss = Rect.fromLTWH(
      d * OrbGeometry.glossLeft,
      d * OrbGeometry.glossTop,
      d * OrbGeometry.glossWidth,
      d * OrbGeometry.glossHeight,
    );
    canvas.translate(gloss.center.dx, gloss.center.dy);
    canvas.rotate(OrbGeometry.glossTiltDegrees * math.pi / 180);
    final Rect local = Rect.fromCenter(
      center: Offset.zero,
      width: gloss.width,
      height: gloss.height,
    );
    canvas.drawOval(
      local,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            colors.orbGloss,
            colors.orbGloss.withValues(alpha: 0),
          ],
        ).createShader(local),
    );
    canvas.restore();

    // Gedrückt: 10 % Überlagerung.
    if (pressed) {
      canvas.drawRect(rect, Paint()..color = colors.pressedOverlay);
    }
    canvas.restore();

    // Kante 1 dp (Hoher Kontrast: `border-control-hc`).
    canvas.drawCircle(
      center,
      d / 2 - CuraSize.hairline / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = colors.highContrast
            ? CuraSize.controlBorder
            : CuraSize.hairline
        ..color = colors.highContrast ? colors.controlBorder : colors.orbEdge,
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      old.colors != colors || old.shades != shades || old.pressed != pressed;
}

/// Ring, weicher Schein (Halo) der aktuellen Kugel und Ring-Puls. Die Fläche
/// ist um [_OrbNodeState._outer] größer als die Kugel; sie liegt in der Mitte.
class _OrbAuraPainter extends CustomPainter {
  _OrbAuraPainter({
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
                colors.orbHalo,
                colors.orbHalo.withValues(alpha: 0),
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
      // Ring wächst vom Rand der Kugel nach außen und blendet aus.
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
  bool shouldRepaint(_OrbAuraPainter old) =>
      old.colors != colors ||
      old.diameter != diameter ||
      old.current != current ||
      old.pulse != pulse;
}
