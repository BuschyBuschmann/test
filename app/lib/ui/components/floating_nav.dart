// `FloatingNav` (Design-Brief v2, 4.1): Leiste E2 mit **Ruhe** und **Aktiv**.
// 72 dp hoch, 14 dp Seitenabstand, 24 dp unten plus Safe Area, Radius Pille,
// Blur σ 30 über `CuraBlur` (eine der drei zulässigen Blur-Flächen). Glas aus
// der Welt: Ruhe Weiß 35 % (Nacht `#1A1320` 45 %), Aktiv Weiß 78 % (Nacht
// 82 %). Darunter liegt ein Schleier (150 dp hoch, 70 % `world-floor`), damit
// der Untergrund begrenzt bleibt. Label und Symbole in `nav-ink`, Gewicht 700.
//
// Aktiv wird die Leiste durch Tipp oder Fokus in der Leiste, den Beginn eines
// Scrolls des Inhalts ([NavActivity], [NavScrollListener]) und den
// Screenreader-Fokus; nach 2 s ohne Interaktion kehrt sie zur Ruhe zurück
// (nicht, solange der Fokus in der Leiste steht). Der Wechsel dauert
// `dur-base`, bei reduzierter Bewegung ist er sofort. **Größe, Position,
// Hit-Areas und Fokusring sind in Ruhe und Aktiv gleich** (V2-18): nur die
// Glasfarbe ändert sich.
//
// Aktiver Tab: Pille 56 dp hoch, Mandarine-Verlauf, Label und Symbol
// `on-accent`. Alle Tabs zeigen Symbol **und** Label (nie nur Farbe). Chats
// trägt einen Zähler im Badge, Profil einen Avatar mit Initialen. Labels
// skalieren bis 130 %. Hoher Kontrast/Transparenz reduzieren: `card` 100 %,
// Rand `border-control-hc`, kein Blur, kein Schatten.
//
// Die Ziele sind eine Liste (V2-15): ein fünftes Ziel (Feed) lässt sich ohne
// Umbau an Position 3 einfügen.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../state/world_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../../theme/tokens.dart';
import '../../theme/world_tokens.dart';
import 'cura_blur.dart';
import 'cura_pressable.dart';

class NavItem {
  const NavItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    this.avatarInitials,
  });

  final IconData icon;
  final String label;

  /// Ungelesen-Zähler (Chats); 0 = kein Badge.
  final int badgeCount;

  /// Initialen statt Symbol (Profil).
  final String? avatarInitials;
}

/// Meldet der Leiste Aktivität des Inhalts (Beginn eines Scrolls). Der
/// Besitzer legt eine Instanz an, reicht sie an [FloatingNav.activity] und
/// umschließt den scrollenden Inhalt mit [NavScrollListener].
class NavActivity extends ChangeNotifier {
  /// Die Leiste wird aktiv und läuft nach 2 s ohne weitere Aktivität aus.
  void poke() => notifyListeners();
}

/// Ruft [NavActivity.poke] beim Beginn eines Scrolls der Kinder auf (nur das
/// äußerste Scrollen eines Pfads, Tiefe 0).
class NavScrollListener extends StatelessWidget {
  const NavScrollListener({
    super.key,
    required this.activity,
    required this.child,
  });

  final NavActivity activity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollStartNotification>(
      onNotification: (ScrollStartNotification n) {
        if (n.depth == 0) activity.poke();
        return false;
      },
      child: child,
    );
  }
}

class FloatingNav extends StatefulWidget {
  const FloatingNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
    this.activity,
    this.physio = false,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Aktivität des Inhalts (Scroll); `null` = nur Tipp, Fokus, Screenreader.
  final NavActivity? activity;

  /// Physio-Bereich: Tabs 76 × 56 statt 62 × 56.
  final bool physio;

  /// Höhe, die die Leiste samt Abstand zum unteren Rand einnimmt (Safe Area
  /// inklusive): Grundlage der Scroll-Reserven (Brief 7: Leiste + 16 dp).
  static double occupiedHeight(BuildContext context) =>
      CuraSize.navBarHeight +
      CuraSize.navBarBottomMargin +
      MediaQuery.paddingOf(context).bottom;

  @override
  State<FloatingNav> createState() => _FloatingNavState();
}

class _FloatingNavState extends State<FloatingNav> {
  bool _active = false;
  bool _focused = false;
  Timer? _rest;

  @override
  void initState() {
    super.initState();
    widget.activity?.addListener(_wake);
  }

  @override
  void didUpdateWidget(FloatingNav old) {
    super.didUpdateWidget(old);
    if (old.activity != widget.activity) {
      old.activity?.removeListener(_wake);
      widget.activity?.addListener(_wake);
    }
  }

  @override
  void dispose() {
    widget.activity?.removeListener(_wake);
    _rest?.cancel();
    super.dispose();
  }

  /// Aktiv werden und die Rückkehr zur Ruhe (2 s) neu starten.
  void _wake() {
    _rest?.cancel();
    if (!_active && mounted) setState(() => _active = true);
    if (_focused) return;
    _rest = Timer(MotionTokens.navRestDelay, () {
      if (mounted && !_focused) setState(() => _active = false);
    });
  }

  void _onFocus(bool focused) {
    _focused = focused;
    if (focused) {
      _rest?.cancel();
      if (!_active && mounted) setState(() => _active = true);
    } else {
      _wake();
    }
  }

  /// Ruhe oder Aktiv (für Tests und den Screenreader-Zustand).
  @visibleForTesting
  bool get isActive => _active;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraMotion motion = CuraMotion.of(context);
    final WorldPalette world = WorldScope.paletteOf(context);
    final double bottom = MediaQuery.paddingOf(context).bottom;
    final BorderRadius shape = BorderRadius.circular(CuraRadius.pill);
    final bool hc = colors.highContrast;
    final Color glass = hc
        ? colors.surfaceOpaque
        : (_active ? world.navActive : world.navRest);
    final Color ink = hc ? colors.text1 : world.navInk;
    final double tabWidth = widget.physio
        ? CuraSize.navTabWidthPhysio
        : CuraSize.navTabWidth;

    final Widget bar = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: colors.shadowsEnabled ? CuraShadow.floating : null,
      ),
      child: CuraBlur(
        borderRadius: shape,
        sigma: BlurTokens.navSigma,
        child: AnimatedContainer(
          duration: motion.reduced ? Duration.zero : motion.base,
          curve: motion.curve,
          decoration: BoxDecoration(color: glass, borderRadius: shape),
          // Der Rand liegt über der Fläche und verändert die Maße nicht.
          foregroundDecoration: BoxDecoration(
            borderRadius: shape,
            border: Border.all(
              color: hc ? colors.controlBorder : colors.lightEdge,
              width: hc ? CuraSize.controlBorder : CuraSize.hairline,
            ),
          ),
          child: SizedBox(
            height: CuraSize.navBarHeight,
            child: Row(
              children: <Widget>[
                for (int i = 0; i < widget.items.length; i++)
                  Expanded(
                    child: _NavEntry(
                      item: widget.items[i],
                      active: i == widget.currentIndex,
                      ink: ink,
                      tabWidth: tabWidth,
                      onAccessibilityFocus: _wake,
                      onPressed: () {
                        _wake();
                        widget.onSelected(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // Tipp irgendwo auf der Leiste, Fokus in der Leiste und Screenreader-Fokus
    // machen sie aktiv (Brief 4.1).
    final Widget interactive = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent _) => _wake(),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: _onFocus,
        child: bar,
      ),
    );

    // Die Fläche der Leiste selbst misst Leiste + Rand unten (+ Safe Area); der
    // Schleier ragt nach oben darüber hinaus (rein gemalt, nie Treffer), damit
    // Kollisionsprüfungen und Scroll-Reserven die Leiste meinen, nicht den
    // Schleier.
    return SizedBox(
      height: FloatingNav.occupiedHeight(context),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: <Widget>[
          // Schleier: 70 % `world-floor`, 150 dp hoch, läuft nach oben aus.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: CuraSize.navVeilHeight + bottom,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        world.floor.withValues(alpha: 0),
                        world.floor.withValues(
                          alpha: WorldGeometry.navVeilAlpha,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: CuraSize.navBarSideMargin,
              right: CuraSize.navBarSideMargin,
              bottom: CuraSize.navBarBottomMargin + bottom,
            ),
            child: interactive,
          ),
        ],
      ),
    );
  }
}

class _NavEntry extends StatelessWidget {
  const _NavEntry({
    required this.item,
    required this.active,
    required this.ink,
    required this.tabWidth,
    required this.onPressed,
    required this.onAccessibilityFocus,
  });

  final NavItem item;
  final bool active;
  final Color ink;
  final double tabWidth;
  final VoidCallback onPressed;
  final VoidCallback onAccessibilityFocus;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final Color content = active ? colors.onAccent : ink;
    final String label = item.badgeCount > 0
        ? S.navUnread(item.label, item.badgeCount)
        : item.label;
    // Die Semantik (und der Fokusring) liegt an der Pille; die ganze Zelle
    // (72 dp hoch) reagiert zusätzlich auf Tipps.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onPressed,
      child: Center(
        child: CuraPressable(
          onPressed: onPressed,
          onAccessibilityFocus: onAccessibilityFocus,
          semanticLabel: label,
          selected: active,
          excludeChildSemantics: true,
          builder: (BuildContext context, bool pressed) {
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: active ? colors.accentFill : null,
                color: !active && pressed ? colors.pressedOverlay : null,
                borderRadius: BorderRadius.circular(CuraRadius.pill),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: tabWidth,
                  minHeight: CuraSize.navTabHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CuraSpace.s2),
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: CuraSize.navLabelMaxTextScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        _Glyph(item: item, color: content, active: active),
                        Text(
                          item.label,
                          textAlign: TextAlign.center,
                          style: type.chip.copyWith(color: content),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Symbol, Avatar (Profil) und Badge (Chats) eines Tabs.
class _Glyph extends StatelessWidget {
  const _Glyph({required this.item, required this.color, required this.active});

  final NavItem item;
  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final Widget base = item.avatarInitials != null
        ? SizedBox.square(
            dimension: CuraComponent.iconSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: CuraSize.controlBorder),
              ),
              child: Center(
                child: MediaQuery.withNoTextScaling(
                  child: Text(
                    item.avatarInitials!,
                    style: type.chip.copyWith(color: color),
                  ),
                ),
              ),
            ),
          )
        : Icon(item.icon, size: CuraComponent.iconSize, color: color);
    if (item.badgeCount <= 0) return base;
    final String text = item.badgeCount > 99 ? '99+' : '${item.badgeCount}';
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        base,
        Positioned(
          left: CuraComponent.iconSize - CuraSpace.s2,
          top: -CuraSpace.s2,
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: CuraSize.navBadgeMin,
                minHeight: CuraSize.navBadgeMin,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.navBadgeFill,
                  borderRadius: BorderRadius.circular(CuraRadius.pill),
                  border: Border.all(
                    color: colors.navBadgeInk,
                    width: CuraSize.hairline,
                  ),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CuraSpace.s1,
                    ),
                    child: MediaQuery.withNoTextScaling(
                      child: Text(
                        text,
                        style: type.chip.copyWith(color: colors.navBadgeInk),
                      ),
                    ),
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
