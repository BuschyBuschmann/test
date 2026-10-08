// `ChatListView`: Verlaufsliste der Chat-Screens. Beginnt oben; ist der Inhalt
// länger als der Bereich, steht beim Öffnen das Ende sichtbar. **Folgt dem
// Ende:** steht der Nutzer am Ende (Offset ≥ Maximum − 1 dp), springt die Liste
// nach jeder Größenänderung an das neue Ende (wachsende letzte Nachricht);
// hat er hochgescrollt, bleibt der Offset unverändert. Die Liste ist eine
// Standard-`ListView` mit den Standard-Semantik-Indizes.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../theme/cura_metrics.dart';
import 'probe_keys.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key, required this.children, this.controller});

  final List<Widget> children;

  /// Optional von außen (Tests); sonst eigener Controller.
  final ScrollController? controller;

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  ScrollController? _own;
  bool _following = true;

  ScrollController get _controller =>
      widget.controller ?? (_own ??= ScrollController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
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
          // Kleine, feste Verläufe werden vollständig gebaut: das Ende ist
          // dann exakt (keine geschätzten Höhen) und jede Nachricht erreichbar.
          scrollCacheExtent: const ScrollCacheExtent.pixels(
            CuraSize.smallListCacheExtent,
          ),
          padding: const EdgeInsets.fromLTRB(
            CuraSpace.pageMargin,
            CuraSpace.messageGap,
            CuraSpace.pageMargin,
            CuraSpace.pageMargin,
          ),
          children: widget.children,
        ),
      ),
    );
  }
}
