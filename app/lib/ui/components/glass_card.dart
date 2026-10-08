// `GlassCard` (Brief 5.1, E1 aus 3.5): Verlauf `surface-glass-top` zu
// `-bottom`, Rand `border-hair` 1 dp, innere Lichtkante oben (Weiß 10 %),
// **kein Blur, kein Schatten**. Hoher Kontrast: opak (`surface-opaque`) mit
// `border-control-hc`, ohne Lichtkante. Alle Glas-Flächen der App (Karten,
// Auswahl, Felder) sind `GlassCard`s, damit Prüfungen den Untergrund „Glas“
// am Vorfahren erkennen (Plan 8.2).
import 'package:flutter/widgets.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(CuraSize.cardPadding),
    this.radius = CuraRadius.card,
    this.borderColor,
    this.borderWidth = CuraSize.hairline,
    this.overlay,
    this.lightEdge = true,
  });

  final Widget child;

  /// Innenabstand (16; links 22 bei Kategorie-Streifen, Brief 5.1).
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Rand; Standard `border-hair` (HC: `border-control-hc`).
  final Color? borderColor;
  final double borderWidth;

  /// Zusätzliche Füllung über dem Glas (z. B. `accent-soft` bei Auswahl).
  final Color? overlay;
  final bool lightEdge;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final BorderRadius shape = BorderRadius.circular(radius);
    final bool edge = lightEdge && !colors.highContrast;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: colors.cardFill, borderRadius: shape),
      child: DecoratedBox(
        decoration: BoxDecoration(color: overlay, borderRadius: shape),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(
              color: borderColor ?? colors.cardBorder,
              width: borderWidth,
            ),
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              Padding(padding: padding, child: child),
              if (edge)
                Positioned(
                  top: CuraSize.hairline,
                  left: radius,
                  right: radius,
                  height: CuraSize.hairline,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: ColoredBox(color: colors.lightEdge),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
