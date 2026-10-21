// `GlassCard` (Brief v2, 4 und 3.5, Ebene E1): Pseudo-Glas aus `card` (Weiß
// 92 % im Thema Hell, `#241D18` 92 % im Thema Dunkel), Radius 28, Innenabstand
// 16, Rand `border-hair` 1 dp, Lichtkante oben 1 dp und ein weicher, warm
// getönter Schatten 0/18/30 mit negativem Spread. **Kein Blur** (V2-10: Karten
// enthalten keinen `BackdropFilter`). Hoher Kontrast/Transparenz reduzieren:
// opak (`card` 100 %) mit `border-control-hc`, ohne Lichtkante und Schatten.
// Alle Karten der App (Auswahl, Felder, Blasen) sind `GlassCard`s, damit
// Prüfungen den Untergrund „Karte“ am Vorfahren erkennen (Plan 8.2).
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
    this.borderRadius,
    this.borderColor,
    this.borderWidth = CuraSize.hairline,
    this.overlay,
    this.lightEdge = true,
    this.shadow = true,
  });

  final Widget child;

  /// Innenabstand (16; links 22 bei Kategorie-Streifen, Brief 5.1).
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Einzelne Eckenradien (z. B. Chat-Blase mit 6-dp-Ecke zur Absenderseite);
  /// ersetzt [radius] für die Form.
  final BorderRadius? borderRadius;

  /// Rand; Standard `border-hair` (HC: `border-control-hc`).
  final Color? borderColor;
  final double borderWidth;

  /// Zusätzliche Füllung über dem Glas (z. B. `accent-soft` bei Auswahl).
  final Color? overlay;
  final bool lightEdge;

  /// Schatten der Karte (ohne Blur); aus bei verschachtelten Karten.
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final BorderRadius shape = borderRadius ?? BorderRadius.circular(radius);
    final bool edge = lightEdge && !colors.highContrast;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: colors.cardFill,
        borderRadius: shape,
        boxShadow: shadow && colors.shadowsEnabled
            ? CuraShadow.card(dark: colors.isDark)
            : null,
      ),
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
