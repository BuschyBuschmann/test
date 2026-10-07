// `CuraTextField` (Brief 5.9): 56 dp hohes Eingabefeld, Rand `border-control`,
// Fokus `accent-hi` 2 dp, Label oberhalb (`secondary`, `text-2`), Eingabe
// `body`. Füllung wie Glas (Hoher Kontrast: opak, Rand `-hc`). **Eine**
// Implementierung für Onboarding und Sheet (Regel 6). Die Tastatur öffnet
// sich erst beim Antippen (kein Autofokus ohne `autofocus`).
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'glass_card.dart';

class CuraTextField extends StatefulWidget {
  const CuraTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.autofocus = false,
    this.enabled = true,
    this.autofillHints,
  });

  /// Label oberhalb des Feldes (und Screenreader-Label).
  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final bool enabled;
  final Iterable<String>? autofillHints;

  @override
  State<CuraTextField> createState() => _CuraTextFieldState();
}

class _CuraTextFieldState extends State<CuraTextField> {
  FocusNode? _ownNode;
  bool _focused = false;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
    _focused = _node.hasFocus;
  }

  @override
  void didUpdateWidget(CuraTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownNode)?.removeListener(_onFocus);
      _node.addListener(_onFocus);
      _focused = _node.hasFocus;
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _ownNode?.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focused != _node.hasFocus && mounted) {
      setState(() => _focused = _node.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: type.secondary.copyWith(color: colors.text2),
          ),
        ),
        const SizedBox(height: CuraComponent.fieldGap),
        GlassCard(
          padding: EdgeInsets.zero,
          radius: CuraComponent.fieldRadius,
          lightEdge: false,
          borderColor: _focused ? colors.accentHi : colors.controlBorder,
          borderWidth: _focused
              ? CuraSize.selectedBorder
              : CuraSize.controlBorder,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CuraSize.textFieldHeight,
            ),
            child: Semantics(
              label: widget.label,
              textField: true,
              child: TextField(
                controller: widget.controller,
                focusNode: _node,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                textInputAction: widget.textInputAction,
                keyboardType: widget.keyboardType,
                textCapitalization: widget.textCapitalization,
                autofillHints: widget.autofillHints,
                style: type.body.copyWith(color: colors.text1),
                cursorColor: colors.accentHi,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: type.body.copyWith(color: colors.text2),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: CuraSize.cardPadding,
                    vertical: CuraSpace.s4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
