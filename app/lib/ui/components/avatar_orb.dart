// `AvatarOrb` (Design-Brief v2, 7.6): Avatar-Kugel in der Kopf-Karte des
// Profils. Eine Glas-Kugel in Mandarine (wie die aktuelle Pfad-Kugel, aber
// ohne Bedienung) mit der Initiale des Namens in `on-accent`. Ohne Namen steht
// ein Personen-Symbol. Die Kugel ist Zier: Name und Rolle stehen daneben als
// Text, das Bild ist für den Screenreader ausgeblendet.
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'orb_node.dart';

class AvatarOrb extends StatelessWidget {
  const AvatarOrb({
    super.key,
    required this.initial,
    this.size = CuraSize.avatarOrb,
  });

  /// Anfangsbuchstabe des Namens; leer = Symbol.
  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return ExcludeSemantics(
      child: OrbSphere(
        diameter: size,
        shades: colors.orbMandarin,
        child: initial.isEmpty
            ? Icon(
                Icons.person_rounded,
                size: size * CuraSize.unitIconFactor,
                color: colors.onAccent,
              )
            : MediaQuery.withClampedTextScaling(
                maxScaleFactor: CuraSize.avatarInitialsMaxTextScale,
                child: Text(
                  initial,
                  style: type.heading.copyWith(color: colors.onAccent),
                ),
              ),
      ),
    );
  }
}
