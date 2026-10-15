// `MannyLookPicker` (Design-Brief v2, Ergänzung 1, 6a/6b): die zwei
// Auswahlkarten „Mit Brille“ und „Ohne Brille“ als **Radio-Gruppe** (genau eine
// ist gewählt). Baustein für den Onboarding-Schritt 1 und das Sheet „Manny-Look“
// im Profil; die Einbindung in die Screens folgt in F2-R3/R4.
//
// Karte: Manny `normal` (Leinwand bis 190 dp, auf die Kartenbreite begrenzt),
// Name, darunter der Radio-Kreis 28 dp und „Ausgewählt“ bei der gewählten Karte;
// Mindesthöhe 300 dp. Gewählt: Rand 3 dp Mandarine, Fläche `#FFF1E4`, gefüllter
// Kreis mit Haken und der Text „Ausgewählt“ (nie nur Farbe). Nicht gewählt:
// Rand 3 dp neutral (`border-control`), leerer Kreis. Reihenfolge: Mit Brille
// links bzw. oben. Bei Breite < 360 dp oder Systemschrift über 130 % stehen die
// Karten untereinander (Bild links 120 dp, Text rechts).
//
// Bedienung: die ganze Karte ist ein Radio (≥ 48 dp). Tab hat **einen** Stopp
// in der Gruppe, Pfeiltasten wechseln die Auswahl, Leertaste wählt, der
// Fokusring (3 dp) liegt um die gewählte Karte. Screenreader: Gruppe
// „Manny-Look“, Karte „Manny mit Brille, ausgewählt, 1 von 2“; die Bilder darin
// sind ausgeblendet. Der Wechsel überblendet höchstens `dur-fast` (120 ms).
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/strings_de.dart';
import '../../logic/manny_look.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'focus_ring.dart';
import 'manny.dart';

class MannyLookPicker extends StatefulWidget {
  const MannyLookPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.autofocus = false,
    this.focusNode,
  });

  /// Die gewählte Variante (es gibt immer eine Wahl).
  final MannyLook value;
  final ValueChanged<MannyLook> onChanged;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Darstellungsreihenfolge: Mit Brille zuerst.
  static const List<MannyLook> order = <MannyLook>[
    MannyLook.brille,
    MannyLook.ohne,
  ];

  /// Karten untereinander: Breite < 360 dp oder Systemschrift über 130 %.
  static bool stackedFor(double width, TextScaler scaler) =>
      width < CuraSize.mannyChoiceStackBelowWidth ||
      scaler.scale(CuraSize.hairline) > CuraSize.mannyChoiceStackAboveTextScale;

  @override
  State<MannyLookPicker> createState() => _MannyLookPickerState();
}

class _MannyLookPickerState extends State<MannyLookPicker> {
  bool _focusVisible = false;

  void _select(MannyLook look) {
    if (look != widget.value) widget.onChanged(look);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final int index = MannyLookPicker.order.indexOf(widget.value);
    final int count = MannyLookPicker.order.length;
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown) {
      _select(MannyLookPicker.order[(index + 1) % count]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      _select(MannyLookPicker.order[(index - 1 + count) % count]);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      _select(widget.value);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return Semantics(
      role: SemanticsRole.radioGroup,
      container: true,
      explicitChildNodes: true,
      label: S.mannyLookGroup,
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: _onKey,
        onFocusChange: (bool _) {},
        child: Builder(
          builder: (BuildContext context) {
            final bool focused =
                Focus.of(context).hasFocus &&
                FocusManager.instance.highlightMode ==
                    FocusHighlightMode.traditional;
            _focusVisible = focused;
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints box) {
                // Maßgeblich ist die Breite des Geräts (Brief 6a), nicht die der
                // Spalte: 390 dp Gerät bleiben nebeneinander.
                final bool stacked = MannyLookPicker.stackedFor(
                  MediaQuery.sizeOf(context).width,
                  scaler,
                );
                final List<Widget> cards = <Widget>[
                  for (int i = 0; i < MannyLookPicker.order.length; i++)
                    _LookCard(
                      look: MannyLookPicker.order[i],
                      index: i,
                      total: MannyLookPicker.order.length,
                      selected: MannyLookPicker.order[i] == widget.value,
                      focused:
                          _focusVisible &&
                          MannyLookPicker.order[i] == widget.value,
                      stacked: stacked,
                      onSelect: () {
                        Focus.of(context).requestFocus();
                        _select(MannyLookPicker.order[i]);
                      },
                    ),
                ];
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (int i = 0; i < cards.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(height: CuraSpace.s3),
                        cards[i],
                      ],
                    ],
                  );
                }
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (int i = 0; i < cards.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(width: CuraSpace.s3),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _LookCard extends StatelessWidget {
  const _LookCard({
    required this.look,
    required this.index,
    required this.total,
    required this.selected,
    required this.focused,
    required this.stacked,
    required this.onSelect,
  });

  final MannyLook look;
  final int index;
  final int total;
  final bool selected;
  final bool focused;
  final bool stacked;
  final VoidCallback onSelect;

  String get _name =>
      look == MannyLook.brille ? S.mannyLookWith : S.mannyLookWithout;

  String get _label =>
      look == MannyLook.brille ? S.mannyLookWithLabel : S.mannyLookWithoutLabel;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final CuraMotion motion = CuraMotion.of(context);
    final BorderRadius shape = BorderRadius.circular(CuraRadius.card);
    final Widget radio = _RadioMark(selected: selected);
    final Widget name = Text(
      _name,
      textAlign: stacked ? TextAlign.start : TextAlign.center,
      style: type.heading.copyWith(color: colors.text1),
    );
    final Widget state = SizedBox(
      height: type.secondary.fontSize! * type.secondary.height!,
      child: selected
          ? Text(
              S.mannyLookSelected,
              textAlign: stacked ? TextAlign.start : TextAlign.center,
              style: type.secondary.copyWith(color: colors.accentText),
            )
          : null,
    );
    final Widget picture = ExcludeSemantics(
      child: MannyIllustration(
        height: stacked
            ? CuraSize.mannyChoiceStackedImage
            : CuraSize.mannyChoiceMaxHeight,
        look: look,
        excludeSemantics: true,
      ),
    );
    final Widget content = stacked
        ? Row(
            children: <Widget>[
              picture,
              const SizedBox(width: CuraSpace.s3),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    name,
                    const SizedBox(height: CuraSpace.s1),
                    state,
                  ],
                ),
              ),
              const SizedBox(width: CuraSpace.s2),
              radio,
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: Center(child: FittedBox(child: picture)),
              ),
              const SizedBox(height: CuraSpace.s3),
              // Name über dem Radio-Kreis: nebeneinander bricht „Ohne Brille“ in
              // der halben Kartenbreite (390 dp, auch im Sheet) auf zwei Zeilen.
              name,
              const SizedBox(height: CuraSpace.s2),
              radio,
              const SizedBox(height: CuraSpace.s1),
              state,
            ],
          );

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: false,
      label: S.mannyLookChoiceLabel(_label, selected, index + 1, total),
      excludeSemantics: true,
      onTap: onSelect,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onSelect,
        child: FocusRing(
          focused: focused,
          radius: CuraRadius.card,
          child: AnimatedContainer(
            duration: motion.duration(motion.fast),
            curve: motion.curve,
            constraints: BoxConstraints(
              minHeight: stacked ? 0 : CuraSize.mannyChoiceMinHeight,
              minWidth: CuraSize.touchTarget,
            ),
            padding: const EdgeInsets.all(CuraSize.cardPadding),
            decoration: BoxDecoration(
              color: selected
                  ? colors.mannyChoiceSelectedFill
                  : colors.surfaceOpaque,
              borderRadius: shape,
              border: Border.all(
                color: selected ? colors.accent : colors.controlBorder,
                width: CuraSize.mannyChoiceBorder,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Radio-Kreis 28 dp: leer oder gefüllt mit Haken (Zustand nie nur Farbe).
class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: CuraSize.mannyChoiceRadio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? colors.accent : null,
            border: Border.all(
              color: selected ? colors.accent : colors.controlBorder,
              width: CuraSize.controlBorder,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check_rounded,
                  size: CuraComponent.iconSize,
                  color: colors.onAccent,
                )
              : null,
        ),
      ),
    );
  }
}
