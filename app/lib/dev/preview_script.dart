// Skript für Szenarien, die einen Tipp brauchen (z. B. `ob-mic-hint`): wartet
// Frame für Frame, bis ein tippbarer Baustein mit dem gesuchten Screenreader-
// Label im Baum steht, und löst dessen Aktion aus. Nur Prüfumgebung.
import 'package:flutter/material.dart';

import '../ui/components/cura_pressable.dart';

/// Höchstens so viele Frames lang wird auf den Baustein gewartet.
const int _maxFrames = 600;

class PreviewScript extends StatefulWidget {
  const PreviewScript({super.key, required this.taps, required this.child});

  /// Screenreader-Labels der Bausteine, die der Reihe nach „getippt“ werden.
  final List<String> taps;
  final Widget child;

  @override
  State<PreviewScript> createState() => _PreviewScriptState();
}

class _PreviewScriptState extends State<PreviewScript> {
  late final List<String> _pending = List<String>.of(widget.taps);
  int _frames = 0;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    if (_pending.isEmpty || _frames >= _maxFrames) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _step());
    WidgetsBinding.instance.scheduleFrame();
  }

  void _step() {
    if (!mounted) return;
    _frames++;
    final VoidCallback? action = _find(_pending.first);
    if (action != null) {
      _pending.removeAt(0);
      action();
    }
    _schedule();
  }

  /// Sichtbarer (nicht ausgeblendeter) Baustein mit dem Label.
  VoidCallback? _find(String label) {
    VoidCallback? found;
    void walk(Element e) {
      if (found != null) return;
      final Widget w = e.widget;
      if (w is Offstage && w.offstage) return;
      if (w is CuraPressable && w.semanticLabel == label) {
        found = w.onPressed;
        return;
      }
      e.visitChildren(walk);
    }

    context.visitChildElements(walk);
    return found;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
