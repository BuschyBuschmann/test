// `ChatListView`: Verlaufsliste der Chat-Screens. Beginnt oben; ist der Inhalt
// länger als der Bereich, steht beim Öffnen das Ende sichtbar. **Folgt dem
// Ende:** steht der Nutzer am Ende (Offset ≥ Maximum − 1 dp), springt die Liste
// nach jeder Größenänderung an das neue Ende (wachsende letzte Nachricht);
// hat er hochgescrollt, bleibt der Offset unverändert. Die Liste ist eine
// Standard-`ListView` mit den Standard-Semantik-Indizes und dem
// Standard-Cache-Bereich (kein Sonderweg für die Prüfung).
//
// K6: Steht die Hinweiskarte als [leading] vor dem Verlauf (große Schrift oder
// geringe Höhe), ist beim Öffnen **mindestens die erste Nachricht** sichtbar
// (UI-76, UI-88): die Liste öffnet an der kleinsten Lage, in der die erste
// Nachricht ganz im Sichtfenster liegt (ist sie höher, mit ihrem Anfang oben),
// höchstens am Ende. Danach gilt wieder „folgt dem Ende, solange der Nutzer
// dort steht“. Ohne [leading] steht beim Öffnen das Ende sichtbar.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;

import '../../theme/cura_metrics.dart';
import 'probe_keys.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({
    super.key,
    required this.children,
    this.leading,
    this.firstMessageIndex = 0,
    this.controller,
  });

  final List<Widget> children;

  /// Hinweiskarte vor dem Verlauf (scrollt mit, K6).
  final Widget? leading;

  /// Index der ersten Nachricht in [children] (davor kann z. B. eine
  /// Tagesüberschrift stehen); ihre Sichtbarkeit sichert die Öffnungslage.
  final int firstMessageIndex;

  /// Optional von außen (Tests); sonst eigener Controller.
  final ScrollController? controller;

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  ScrollController? _own;
  late bool _following = widget.leading == null;
  final GlobalKey _firstItem = GlobalKey(debugLabel: 'Erste Nachricht');

  ScrollController get _controller =>
      widget.controller ?? (_own ??= ScrollController());

  @override
  void initState() {
    super.initState();
    if (widget.leading != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openAtFirstItem());
    }
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  /// Öffnungslage mit [ChatListView.leading]: erste Nachricht sichtbar.
  void _openAtFirstItem() {
    if (!mounted) return;
    final ScrollController c = _controller;
    final RenderObject? item = _firstItem.currentContext?.findRenderObject();
    if (!c.hasClients || item is! RenderBox || !item.attached) {
      _following = true;
      return;
    }
    final ScrollPosition p = c.position;
    final RenderAbstractViewport? viewport = RenderAbstractViewport.maybeOf(
      item,
    );
    if (viewport != null) {
      final double top = viewport.getOffsetToReveal(item, 0).offset;
      final double fitsAt = top + item.size.height - p.viewportDimension;
      final double target = fitsAt.clamp(0, top);
      p.jumpTo(target.clamp(p.minScrollExtent, p.maxScrollExtent));
    }
    _following = p.extentAfter <= CuraSize.hairline;
  }

  /// Tritt der Nutzer (oder ein Sprung) an eine andere Stelle, merkt sich die
  /// Liste, ob das Ende noch sichtbar ist.
  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
      _following = n.metrics.extentAfter <= CuraSize.hairline;
    }
    return false;
  }

  /// Inhalt oder Bereich haben ihre Größe geändert (nach dem Frame gemeldet).
  bool _onMetrics(ScrollMetricsNotification n) {
    if (n.depth != 0 || !_following) return false;
    final ScrollController c = _controller;
    if (!c.hasClients) return false;
    final ScrollPosition p = c.position;
    if (p.pixels < p.maxScrollExtent - CuraSize.hairline / 2) {
      p.jumpTo(p.maxScrollExtent);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetrics,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView(
          key: ProbeKeys.scroll,
          controller: _controller,
          padding: const EdgeInsets.fromLTRB(
            CuraSpace.pageMargin,
            CuraSpace.messageGap,
            CuraSpace.pageMargin,
            CuraSpace.pageMargin,
          ),
          children: <Widget>[
            if (widget.leading != null)
              Padding(
                padding: const EdgeInsets.only(bottom: CuraSpace.messageGap),
                child: widget.leading,
              ),
            for (int i = 0; i < widget.children.length; i++)
              // Die erste Nachricht trägt den Anker für die Öffnungslage.
              if (i == widget.firstMessageIndex && widget.leading != null)
                KeyedSubtree(key: _firstItem, child: widget.children[i])
              else
                widget.children[i],
          ],
        ),
      ),
    );
  }
}
