// `FloatingNav` (Brief 5.4): Pill-Leiste E2, 64 dp hoch, Einträge mit Icon
// **und** Label (immer beide sichtbar). Aktiv: Pill 48 dp mit `accent-soft` und
// 1 dp Rand `accent` 60 %, Icon `accent-hi`, Label `text-1`; inaktiv `text-2`.
// 16 dp zu den Seiten, 22 dp zum unteren Rand (plus Safe Area). Der Inhalt
// blendet unter der Leiste mit einem Verlauf in `bg` aus. Labels sind ab
// Textskalierung 1,3 begrenzt (`withClampedTextScaling`). Schatten 0/10/30
// nur ohne Hoher Kontrast; Blur über `CuraBlur` (HC: opak).
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_blur.dart';
import 'cura_pressable.dart';

class NavItem {
  const NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class FloatingNav extends StatelessWidget {
  const FloatingNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Höhe, die die Leiste samt Abstand zum unteren Rand einnimmt (Safe Area
  /// inklusive): Grundlage der Scroll-Reserven (Plan 4.6).
  static double occupiedHeight(BuildContext context) =>
      CuraSize.navHeight +
      CuraSize.navBottomMargin +
      MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final double bottom = MediaQuery.paddingOf(context).bottom;
    final double fadeHeight =
        CuraComponent.navFadeExtra + occupiedHeight(context);
    final BorderRadius shape = BorderRadius.circular(CuraRadius.pill);

    final Widget bar = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: colors.shadowsEnabled ? CuraShadow.floating : null,
      ),
      child: CuraBlur(
        borderRadius: shape,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.floatFill,
            borderRadius: shape,
            border: Border.all(
              color: colors.cardBorder,
              width: CuraSize.hairline,
            ),
          ),
          child: SizedBox(
            height: CuraSize.navHeight,
            child: Row(
              children: <Widget>[
                for (int i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavEntry(
                      item: items[i],
                      active: i == currentIndex,
                      onPressed: () => onSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      height: fadeHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          // Ausblend-Verlauf: Inhalt läuft nach unten in `bg` aus.
          Positioned.fill(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        colors.bg.withValues(alpha: 0),
                        colors.bg,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: CuraSize.navSideMargin,
              right: CuraSize.navSideMargin,
              bottom: CuraSize.navBottomMargin + bottom,
            ),
            child: bar,
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
    required this.onPressed,
  });

  final NavItem item;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final Color iconColor = active ? colors.accentHi : colors.text2;
    final Color labelColor = active ? colors.text1 : colors.text2;
    // Die Semantik (und der Fokusring) liegt an der Pill; die ganze Zelle
    // (64 dp hoch) reagiert zusätzlich auf Tipps.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onPressed,
      child: Center(
        child: CuraPressable(
          onPressed: onPressed,
          semanticLabel: item.label,
          selected: active,
          excludeChildSemantics: true,
          builder: (BuildContext context, bool pressed) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: active
                    ? colors.accentSoft
                    : (pressed ? colors.pressedOverlay : null),
                borderRadius: BorderRadius.circular(CuraRadius.pill),
                border: active
                    ? Border.all(
                        color: colors.navActiveBorder,
                        width: CuraSize.hairline,
                      )
                    : null,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: CuraSize.navActivePill,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: CuraSpace.s4),
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: CuraSize.navLabelMaxTextScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          item.icon,
                          size: CuraComponent.iconSize,
                          color: iconColor,
                        ),
                        Text(
                          item.label,
                          textAlign: TextAlign.center,
                          style: type.caption.copyWith(color: labelColor),
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
