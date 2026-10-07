// `PillButton` (Brief 5.3, Ergänzung 1 Abschnitt 2): Primär, Neutral hell und
// Umriss. 56 dp hoch (wächst bei Textumbruch), volle Pill, `button`-Stil,
// Icon optional links, Pressed (Brief 5, Plan 8.4), Disabled 38 %,
// Fortschrittskreis-Zustand. Hit-Area ≥ 48 dp.
//
// Primär: Füllung `accent`, Text `on-accent`, Schein 0/8/28 (nur ohne Hoher
// Kontrast). Neutral hell: Füllung `text-1`, Text `on-accent`; Pressed reines
// Weiß. Umriss: keine Füllung, 1,5 dp `border-control` (HC `-hc`), Text und
// Icon `text-1`; Pressed Weiß 10 %.
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_pressable.dart';

enum PillButtonVariant { primary, neutral, outline }

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillButtonVariant.primary,
    this.icon,
    this.busy = false,
    this.expand = true,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;

  /// `null` = deaktiviert (Brief 5: Inhalt `text-1` 38 %, Füllung Weiß 10 %).
  final VoidCallback? onPressed;
  final PillButtonVariant variant;
  final IconData? icon;

  /// Fortschrittskreis neben dem Text; der Button ist dann deaktiviert
  /// (Löschen-Dialog, Ergänzung 1, 3.2).
  final bool busy;

  /// Volle Breite des Elternelements (sonst Breite des Inhalts).
  final bool expand;
  final bool autofocus;
  final FocusNode? focusNode;

  bool get _enabled => onPressed != null && !busy;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final TextStyle base = CuraTypography.of(context).button;
    return CuraPressable(
      onPressed: _enabled ? onPressed : null,
      autofocus: autofocus,
      focusNode: focusNode,
      builder: (BuildContext context, bool pressed) {
        // Gesperrt wegen `busy` bleibt lesbar (Fortschritt zeigt den Zustand).
        final bool dimmed = onPressed == null;
        final Color content = dimmed
            ? colors.disabledContent
            : switch (variant) {
                PillButtonVariant.primary ||
                PillButtonVariant.neutral => colors.onAccent,
                PillButtonVariant.outline => colors.text1,
              };
        final Color? fill = dimmed
            ? colors.disabledFill
            : switch (variant) {
                PillButtonVariant.primary =>
                  pressed ? colors.accentPressed : colors.accent,
                PillButtonVariant.neutral =>
                  pressed ? colors.pureWhite : colors.text1,
                PillButtonVariant.outline =>
                  pressed ? colors.pressedOverlay : null,
              };
        final List<BoxShadow>? glow =
            variant == PillButtonVariant.primary &&
                !dimmed &&
                colors.shadowsEnabled
            ? CuraShadow.primaryGlow
            : null;
        final BoxBorder? border = variant == PillButtonVariant.outline
            ? Border.all(
                color: dimmed ? colors.borderHair : colors.controlBorder,
                width: CuraSize.controlBorder,
              )
            : null;
        final Widget text = Text(
          label,
          textAlign: TextAlign.center,
          style: base.copyWith(color: content),
        );
        final List<Widget> row = <Widget>[
          if (busy) ...<Widget>[
            SizedBox.square(
              dimension: CuraComponent.progressSize,
              child: CircularProgressIndicator(
                strokeWidth: CuraComponent.progressStroke,
                color: content,
              ),
            ),
            const SizedBox(width: CuraComponent.pillIconGap),
          ] else if (icon != null) ...<Widget>[
            ExcludeSemantics(
              child: Icon(icon, size: CuraComponent.iconSize, color: content),
            ),
            const SizedBox(width: CuraComponent.pillIconGap),
          ],
          Flexible(child: text),
        ];
        return DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(CuraRadius.pill),
            border: border,
            boxShadow: glow,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: CuraSize.primaryButtonHeight,
              minWidth: expand ? double.infinity : CuraSize.touchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CuraSpace.s6,
                vertical: CuraSpace.s4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: row,
              ),
            ),
          ),
        );
      },
    );
  }
}
