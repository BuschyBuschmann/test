// `StatusChip` (Design-Brief v2, 4 und 3.2): Statusanzeige im Stil `chip`
// (13 sp/700, Radius Pille). **Status immer mit Symbol und Text**, nie nur
// Farbe: Erfolg mit ✓, Warnung mit ⚠, neutral mit einem Info-Symbol. Farben
// `chip-success` (`#DDF3E6` mit `#14532D`, 7,8:1), `chip-warn` (`#FFE3DD` mit
// `#7A1A12`, 8,7:1) und `chip-neutral` im Thema Hell, getönte dunkle Chips im
// Thema Dunkel (Text ≥ 4,5:1, per Test). Mandarine ist nie Statusfarbe.
//
// Mit [onPressed] ist der Chip wählbar: Hit-Area ≥ 48 dp, gewählt mit Rand
// 2 dp `text-1` zusätzlich zu Symbol und Text (V2-23, V2-29).
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_pressable.dart';

enum StatusKind { neutral, success, warn }

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.kind = StatusKind.neutral,
    this.icon,
    this.onPressed,
    this.selected = false,
    this.semanticLabel,
  });

  final String label;
  final StatusKind kind;

  /// Symbol; ohne Angabe ✓ (Erfolg), ⚠ (Warnung) bzw. ein Info-Symbol.
  final IconData? icon;

  /// Gesetzt = wählbar (Hit-Area 48 dp).
  final VoidCallback? onPressed;
  final bool selected;
  final String? semanticLabel;

  IconData get _icon =>
      icon ??
      switch (kind) {
        StatusKind.success => Icons.check_rounded,
        StatusKind.warn => Icons.warning_amber_rounded,
        StatusKind.neutral => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final (Color fill, Color ink) = switch (kind) {
      StatusKind.success => (colors.chipSuccessFill, colors.chipSuccessText),
      StatusKind.warn => (colors.chipWarnFill, colors.chipWarnText),
      StatusKind.neutral => (colors.chipFill, colors.text1),
    };
    Widget chip(bool pressed) => DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(CuraRadius.pill),
        border: selected
            ? Border.all(color: colors.text1, width: CuraSize.selectedBorder)
            : (colors.highContrast
                  ? Border.all(
                      color: colors.controlBorder,
                      width: CuraSize.hairline,
                    )
                  : null),
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          color: pressed ? colors.pressedOverlay : null,
          borderRadius: BorderRadius.circular(CuraRadius.pill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CuraSize.statPillPaddingH,
            vertical: CuraSize.statPillPaddingV,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ExcludeSemantics(
                child: Icon(_icon, size: CuraSize.hintIcon, color: ink),
              ),
              const SizedBox(width: CuraSize.statPillGap),
              Flexible(
                child: Text(label, style: type.chip.copyWith(color: ink)),
              ),
            ],
          ),
        ),
      ),
    );

    if (onPressed == null) {
      return Semantics(
        container: true,
        label: semanticLabel ?? label,
        excludeSemantics: true,
        child: chip(false),
      );
    }
    return CuraPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel ?? label,
      selected: selected,
      ringRadius: CuraRadius.pill,
      builder: (BuildContext context, bool pressed) {
        return ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: CuraSize.touchTarget,
            minHeight: CuraSize.touchTarget,
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: chip(pressed)),
        );
      },
    );
  }
}
