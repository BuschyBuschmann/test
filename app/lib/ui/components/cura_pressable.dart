// Gemeinsame Bedienbasis der antippbaren Bausteine: Tipp, Pressed-Zustand,
// Tastaturfokus mit `FocusRing`, Enter/Leertaste (`ActivateIntent`),
// Semantik als Schaltfläche. Keine Material-Überlagerungen (Pressed ist eine
// Füllung des Bausteins, Brief 5).
import 'package:flutter/material.dart';

import '../../theme/cura_metrics.dart';
import 'focus_ring.dart';

class CuraPressable extends StatefulWidget {
  const CuraPressable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.semanticLabel,
    this.excludeChildSemantics,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
    this.ringRadius = CuraRadius.pill,
    this.enabled = true,
    this.selected,
  });

  /// `null` = nicht bedienbar (kein Fokus, kein Tipp).
  final VoidCallback? onPressed;

  /// Baut die sichtbare Fläche; `pressed` ist während des Tippens gesetzt.
  final Widget Function(BuildContext context, bool pressed) builder;

  /// Screenreader-Label. Ohne Angabe liefert der Inhalt (Text) das Label.
  final String? semanticLabel;

  /// Standard: Inhalt wird ausgeblendet, sobald [semanticLabel] gesetzt ist.
  final bool? excludeChildSemantics;

  /// Tooltip bei Langdruck/Hover; liest der Screenreader nicht zusätzlich vor.
  final String? tooltip;

  final FocusNode? focusNode;
  final bool autofocus;
  final double ringRadius;

  /// `false` = sichtbar, aber ohne Aktion (z. B. disabled).
  final bool enabled;

  /// Zustand „ausgewählt“ für den Screenreader (Tabs); `null` = nicht relevant.
  final bool? selected;

  @override
  State<CuraPressable> createState() => _CuraPressableState();
}

class _CuraPressableState extends State<CuraPressable> {
  bool _pressed = false;
  bool _focusVisible = false;

  bool get _active => widget.enabled && widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(CuraPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_active && (_pressed || _focusVisible)) {
      _pressed = false;
      _focusVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? label = widget.semanticLabel;
    // Semantik innen: Fokus und Tipp (außen) verschmelzen mit diesem Knoten.
    Widget core = FocusRing(
      focused: _focusVisible && _active,
      radius: widget.ringRadius,
      child: Semantics(
        button: true,
        enabled: _active,
        selected: widget.selected,
        label: label,
        excludeSemantics: widget.excludeChildSemantics ?? label != null,
        child: widget.builder(context, _pressed && _active),
      ),
    );
    core = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _active ? (TapDownDetails _) => _setPressed(true) : null,
      onTapUp: _active ? (TapUpDetails _) => _setPressed(false) : null,
      onTapCancel: _active ? () => _setPressed(false) : null,
      onTap: _active ? widget.onPressed : null,
      child: core,
    );
    core = FocusableActionDetector(
      enabled: _active,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: _active ? SystemMouseCursors.click : MouseCursor.defer,
      onShowFocusHighlight: (bool v) {
        if (_focusVisible != v && mounted) setState(() => _focusVisible = v);
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent _) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: core,
    );
    final String? tooltip = widget.tooltip;
    if (tooltip != null) {
      core = Tooltip(message: tooltip, excludeFromSemantics: true, child: core);
    }
    return core;
  }
}
