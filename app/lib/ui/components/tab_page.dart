// `TabPage` (Design-Brief v2, 7 „Für alle Screens“): Gerüst eines Ziels der
// Leiste (Chats, Profil): die Kopf-Karte oben, darunter der scrollende Inhalt.
// Der Inhalt läuft unter der Leiste durch; das letzte Element ist über der
// Leiste vollständig erreichbar (Reserve = Leiste + 16 dp).
//
// Ab Textskalierung 1,5 steht die Kopf-Karte nicht mehr fest (bei 200 % und
// 320 × 568 dp bliebe sonst zu wenig Platz): sie läuft als erstes Element mit
// dem Inhalt. Marker: `header` für die feste Kopf-Karte, `scroll-header` für
// die mitlaufende, `scroll` für den Scrollbereich.
//
// Die Scroll-Position bleibt beim Wechsel des Ziels erhalten: die Leiste hält
// alle Ziele im Baum (`IndexedStack`), der `ScrollController` gehört diesem
// Widget.
import 'package:flutter/material.dart';

import '../../theme/cura_metrics.dart';
import 'floating_nav.dart';
import 'probe_keys.dart';

class TabPage extends StatefulWidget {
  const TabPage({
    super.key,
    required this.header,
    required this.children,
    this.scrollController,
  });

  /// Die Kopf-Karte (`HeaderCard`).
  final Widget header;

  /// Inhalt unter der Kopf-Karte (Karten, Listen), gestapelt mit 12 dp Abstand.
  final List<Widget> children;

  /// Eigener Controller (Tests lesen die Position); sonst ein interner.
  final ScrollController? scrollController;

  @override
  State<TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> {
  ScrollController? _own;

  ScrollController get _controller =>
      widget.scrollController ?? (_own ??= ScrollController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool along =
        MediaQuery.textScalerOf(context).scale(CuraSize.hairline) >=
        CuraSize.textScaleScrollAlong;
    final double reserve =
        FloatingNav.occupiedHeight(context) + CuraSpace.pageMargin;
    final Widget header = Padding(
      padding: const EdgeInsets.fromLTRB(
        CuraSize.cardMargin,
        CuraSpace.s2,
        CuraSize.cardMargin,
        CuraSpace.s2,
      ),
      child: widget.header,
    );
    final Widget list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (along) KeyedSubtree(key: ProbeKeys.scrollHeader, child: header),
        Padding(
          padding: EdgeInsets.fromLTRB(
            CuraSize.cardMargin,
            CuraSpace.s2,
            CuraSize.cardMargin,
            reserve,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < widget.children.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: CuraSpace.s3),
                widget.children[i],
              ],
            ],
          ),
        ),
      ],
    );
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (!along) KeyedSubtree(key: ProbeKeys.header, child: header),
          Expanded(
            child: SingleChildScrollView(
              key: ProbeKeys.scroll,
              controller: _controller,
              child: list,
            ),
          ),
        ],
      ),
    );
  }
}
