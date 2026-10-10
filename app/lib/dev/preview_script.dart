// Skript für Szenarien, die einen Tipp brauchen (z. B. `ob-mic-hint`): wartet
// Frame für Frame, bis ein tippbarer Baustein mit dem gesuchten Screenreader-
// Label im Baum steht, und löst dessen Aktion aus. Danach kann es das erste
// Textfeld fokussieren (Tastatur-Szenarien: das Feld ist fokussiert und, wie in
// der echten App, in den Blick gescrollt). Nur Prüfumgebung.
import 'package:flutter/material.dart';

import '../ui/components/cura_pressable.dart';
import '../ui/components/pill_button.dart';
import '../ui/components/probe_keys.dart';
import '../ui/home/home_shell.dart';

/// Höchstens so viele Frames lang wird auf den Baustein gewartet.
const int _maxFrames = 600;

/// Eintrag in [PreviewScript.taps]: scrollt den Hauptscrollbereich des
/// **sichtbaren** Tabs an dieser Stelle der Abfolge ans Ende (z. B. nach dem
/// Wechsel auf Heute, `today-cluster`).
const String kPreviewScrollEnd = 'preview:scroll-end';

/// Eintrag in [PreviewScript.taps]: scrollt den Hauptscrollbereich des
/// sichtbaren Tabs ganz nach oben (Pfad: der Ausblick `PathOutlook` über dem
/// Boss, `path-outlook`).
const String kPreviewScrollStart = 'preview:scroll-start';

class PreviewScript extends StatefulWidget {
  const PreviewScript({
    super.key,
    required this.taps,
    required this.child,
    this.focusField = false,
    this.scrollPathToEnd = false,
    this.afterTaps,
  });

  /// Läuft einmal nach den Tipps (z. B. Zeitsprung der Uhr). Danach prüft das
  /// Skript den Tageswechsel wie ein Fortsetzen der App (`today-newday-snackbar`).
  final VoidCallback? afterTaps;

  /// Screenreader-Labels der Bausteine, die der Reihe nach „getippt“ werden.
  final List<String> taps;

  /// Nach den Tipps das erste sichtbare Textfeld fokussieren.
  final bool focusField;

  /// Vor den Tipps den Pfad bis ans Ende scrollen (unterste Unit über die
  /// Button-Gruppe geschoben, `path-scrolled-bottom`).
  final bool scrollPathToEnd;
  final Widget child;

  @override
  State<PreviewScript> createState() => _PreviewScriptState();
}

class _PreviewScriptState extends State<PreviewScript> {
  late final List<String> _pending = List<String>.of(widget.taps);
  int _frames = 0;
  late bool _focusPending = widget.focusField;
  late bool _scrollEndPending = widget.scrollPathToEnd;
  late bool _afterPending = widget.afterTaps != null;
  int _endJumps = 0;
  static const int _endJumpFrames = 4;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    if ((_pending.isEmpty &&
            !_focusPending &&
            !_scrollEndPending &&
            !_afterPending) ||
        _frames >= _maxFrames) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _step());
    WidgetsBinding.instance.scheduleFrame();
  }

  void _step() {
    if (!mounted) return;
    _frames++;
    if (_scrollEndPending) {
      if (_scrollPathToEnd()) _scrollEndPending = false;
    } else if (_pending.isNotEmpty && _pending.first == kPreviewScrollStart) {
      if (_scrollPath(toEnd: false) && ++_endJumps >= _endJumpFrames) {
        _pending.removeAt(0);
        _endJumps = 0;
      }
    } else if (_pending.isNotEmpty && _pending.first == kPreviewScrollEnd) {
      // Mehrere Frames lang: Die Reserve am Listenende wächst nach der Messung
      // der Button-Gruppe, das Ende liegt dann etwas weiter unten.
      if (_scrollPathToEnd() && ++_endJumps >= _endJumpFrames) {
        _pending.removeAt(0);
        _endJumps = 0;
      }
    } else if (_pending.isNotEmpty) {
      final VoidCallback? action = _find(_pending.first);
      if (action != null) {
        _pending.removeAt(0);
        action();
      } else {
        _scrollForward();
      }
    } else if (_afterPending) {
      _afterPending = false;
      widget.afterTaps?.call();
      _checkDayChange();
    } else if (_focusPending) {
      final EditableText? field = _findField();
      if (field != null) {
        _focusPending = false;
        field.focusNode.requestFocus();
      }
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
      // Primärbuttons tragen ihr Label als Text („Training starten“).
      if (w is PillButton && w.label == label && w.onPressed != null) {
        found = w.onPressed;
        return;
      }
      // Nur sichtbare Teilbäume: der inaktive Tab im `IndexedStack` zählt nicht.
      e.debugVisitOnstageChildren(walk);
    }

    context.visitChildElements(walk);
    return found;
  }

  /// Der gesuchte Baustein steht nicht im Baum (lazy Liste, noch nicht
  /// gebaut): die sichtbare vertikale Liste ein halbes Fenster weiter
  /// scrollen, wie es der Nutzer täte.
  void _scrollForward() {
    ScrollableState? found;
    void walk(Element e) {
      if (found != null) return;
      final Widget w = e.widget;
      if (w is Offstage && w.offstage) return;
      if (e is StatefulElement && e.state is ScrollableState) {
        final ScrollableState st = e.state as ScrollableState;
        if (st.position.axis == Axis.vertical &&
            st.position.pixels < st.position.maxScrollExtent - 0.5) {
          found = st;
          return;
        }
      }
      e.debugVisitOnstageChildren(walk);
    }

    context.visitChildElements(walk);
    final ScrollableState? st = found;
    if (st == null) return;
    final ScrollPosition p = st.position;
    p.jumpTo((p.pixels + p.viewportDimension / 2).clamp(0, p.maxScrollExtent));
  }

  /// Scrollt den Pfad (Bereich mit dem Marker `scroll`) ans Ende. `false`,
  /// solange er noch nicht im Baum steht.
  bool _scrollPathToEnd() => _scrollPath(toEnd: true);

  /// Scrollt den Pfad ans Ende bzw. (mit [toEnd] `false`) an den Anfang.
  bool _scrollPath({required bool toEnd}) {
    ScrollableState? found;
    void walk(Element e) {
      if (found != null) return;
      final Widget w = e.widget;
      if (w is Offstage && w.offstage) return;
      if (w.key == ProbeKeys.scroll) {
        void inner(Element c) {
          if (found != null) return;
          if (c is StatefulElement && c.state is ScrollableState) {
            found = c.state as ScrollableState;
            return;
          }
          c.visitChildren(inner);
        }

        e.visitChildren(inner);
        return;
      }
      // Nur sichtbare Teilbäume: der inaktive Tab im `IndexedStack` zählt nicht.
      e.debugVisitOnstageChildren(walk);
    }

    context.visitChildElements(walk);
    final ScrollableState? st = found;
    if (st == null) return false;
    // Erst scrollen, wenn die Fläche gelegt ist und etwas zu scrollen hat.
    if (!st.position.hasContentDimensions || st.position.maxScrollExtent < 1) {
      return false;
    }
    st.position.jumpTo(
      toEnd ? st.position.maxScrollExtent : st.position.minScrollExtent,
    );
    return true;
  }

  /// Prüft den Tageswechsel wie nach einem Fortsetzen der App: ein Tabwechsel
  /// auf den aktiven Tab ruft `checkDayChange` und die Folgen in der Shell.
  void _checkDayChange() {
    HomeShellState? shell;
    void walk(Element e) {
      if (shell != null) return;
      if (e is StatefulElement && e.state is HomeShellState) {
        shell = e.state as HomeShellState;
        return;
      }
      e.visitChildren(walk);
    }

    context.visitChildElements(walk);
    shell?.selectTab(shell!.activeTab);
  }

  /// Erstes sichtbares, bearbeitbares Textfeld.
  EditableText? _findField() {
    EditableText? found;
    void walk(Element e) {
      if (found != null) return;
      final Widget w = e.widget;
      if (w is Offstage && w.offstage) return;
      if (w is EditableText && !w.readOnly) {
        found = w;
        return;
      }
      e.debugVisitOnstageChildren(walk);
    }

    context.visitChildElements(walk);
    return found;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
