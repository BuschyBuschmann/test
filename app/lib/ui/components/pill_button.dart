// `PillButton`: Engine der beiden Brief-v2-Buttons `PrimaryPill` und
// `GlassPill` (Brief 4) plus Umriss-Variante. Hit-Area ≥ 48 dp, Pressed,
// Disabled, Fortschrittskreis-Zustand.
//
// Primär (`PrimaryPill`): Verlauf Mandarine (`#FFA063` → `#FF7A2E`), Text
// `on-accent`, 56 dp, Lichtkante oben, Schein unten (0/14/24, Mandarine 70 %,
// nur ohne Hoher Kontrast), **kein harter Rand**. Gedrückt: 2 % kleiner,
// Schein halb. Deaktiviert: Weiß 50 % mit `ink-2`-Text und Rand.
// Neutral (`GlassPill`): Weiß 90 % ohne Blur, 52 dp, Rand `border-control`,
// Text `ink-1` (dunkle Tinte in beiden Themen, die Pille bleibt hell).
// Umriss: keine Füllung, 1,5 dp `border-control` (HC `-hc`), Text und Icon
// `text-1`; Pressed Überlagerung `text-1` 10 %.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_pressable.dart';

enum PillButtonVariant { primary, neutral, outline }

/// Wird von `CuraDialog` gesetzt: Ab Textskalierung 1,5 zeigen die Buttons des
/// Dialogs kein Symbol (F-4), damit der Text die Breite bekommt und nicht
/// mitten im Wort bricht.
class PillButtonDialogScope extends InheritedWidget {
  const PillButtonDialogScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PillButtonDialogScope>() !=
      null;

  @override
  bool updateShouldNotify(PillButtonDialogScope old) => false;
}

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillButtonVariant.primary,
    this.icon,
    this.busy = false,
    this.busyStatus = S.busyStatusDefault,
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

  /// Statusansage für den Screenreader, solange [busy] gilt (Erratum E-3,
  /// z. B. „Wird gelöscht“, `S.busyStatusDeleting`). Der Button meldet sie als
  /// Live-Region zusammen mit dem Label.
  final String busyStatus;

  /// Volle Breite des Elternelements (sonst Breite des Inhalts).
  final bool expand;
  final bool autofocus;
  final FocusNode? focusNode;

  bool get _enabled => onPressed != null && !busy;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final TextStyle base = CuraTypography.of(context).button;
    // Ab 1,5 sinkt der Seitenrand auf `s4`; im Dialog entfällt dort das Symbol.
    final bool large =
        MediaQuery.textScalerOf(context).scale(CuraSize.textScaleUnit) >=
        CuraSize.textScaleDialogCompact;
    final IconData? shownIcon = large && PillButtonDialogScope.of(context)
        ? null
        : icon;
    return Semantics(
      liveRegion: busy,
      child: CuraPressable(
        semanticLabel: busy ? S.busyLabel(label, busyStatus) : null,
        onPressed: _enabled ? onPressed : null,
        autofocus: autofocus,
        focusNode: focusNode,
        builder: (BuildContext context, bool pressed) {
          // Gesperrt wegen `busy` bleibt lesbar (Fortschritt zeigt den Zustand).
          final bool dimmed = onPressed == null;
          final bool primary = variant == PillButtonVariant.primary;
          final bool glass = variant == PillButtonVariant.neutral;
          final Color content = switch (variant) {
            PillButtonVariant.primary =>
              dimmed ? colors.primaryDisabledInk : colors.onAccent,
            PillButtonVariant.neutral =>
              dimmed ? colors.disabledContent : colors.glassPillInk,
            PillButtonVariant.outline =>
              dimmed ? colors.disabledContent : colors.text1,
          };
          final Color? fill = switch (variant) {
            PillButtonVariant.primary =>
              dimmed ? colors.primaryDisabledFill : null,
            PillButtonVariant.neutral =>
              dimmed
                  ? colors.disabledFill
                  : (pressed ? colors.glassPillPressed : colors.glassPillFill),
            PillButtonVariant.outline =>
              dimmed ? null : (pressed ? colors.pressedOverlay : null),
          };
          final Gradient? gradient = primary && !dimmed
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    colors.accentTop,
                    pressed ? colors.accentPressed : colors.accent,
                  ],
                )
              : null;
          final List<BoxShadow>? glow =
              primary && !dimmed && colors.shadowsEnabled
              ? (pressed
                    ? CuraShadow.primaryGlowPressed
                    : CuraShadow.primaryGlow)
              : null;
          // Primär hat im Normalzustand keinen Rand (kein harter Rand), nur
          // deaktiviert; Glas und Umriss tragen `border-control`.
          final BoxBorder? border = primary && !dimmed
              ? null
              : Border.all(
                  color: dimmed
                      ? (primary ? colors.controlBorder : colors.borderHair)
                      : (glass ? colors.glassPillBorder : colors.controlBorder),
                  width: CuraSize.controlBorder,
                );
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
            ] else if (shownIcon != null) ...<Widget>[
              ExcludeSemantics(
                child: Icon(
                  shownIcon,
                  size: CuraComponent.iconSize,
                  color: content,
                ),
              ),
              const SizedBox(width: CuraComponent.pillIconGap),
            ],
            Flexible(child: text),
          ];
          final Widget body = ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: glass
                  ? CuraSize.glassButtonHeight
                  : CuraSize.primaryButtonHeight,
              minWidth: expand ? double.infinity : CuraSize.touchTarget,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: large ? CuraSpace.s4 : CuraSpace.s6,
                vertical: glass ? CuraSpace.s3 : CuraSpace.s4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: row,
              ),
            ),
          );
          final bool edge = primary && !dimmed && !colors.highContrast;
          Widget pill = DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              gradient: gradient,
              borderRadius: BorderRadius.circular(CuraRadius.pill),
              border: border,
              boxShadow: glow,
            ),
            child: edge
                ? Stack(
                    fit: StackFit.passthrough,
                    children: <Widget>[
                      body,
                      // Lichtkante oben (1 dp, Weiß), innerhalb der Rundung.
                      Positioned(
                        top: CuraSize.hairline,
                        left: CuraSpace.s5,
                        right: CuraSpace.s5,
                        height: CuraSize.hairline,
                        child: ExcludeSemantics(
                          child: IgnorePointer(
                            child: ColoredBox(color: colors.primaryEdge),
                          ),
                        ),
                      ),
                    ],
                  )
                : body,
          );
          // Gedrückt: 2 % kleiner (Brief 4).
          if (primary && pressed && !dimmed) {
            pill = Transform.scale(
              scale: CuraComponent.primaryPressedScale,
              child: pill,
            );
          }
          return pill;
        },
      ),
    );
  }
}
