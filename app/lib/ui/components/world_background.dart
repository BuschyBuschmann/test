// `WorldBackground` (Design-Brief v2, 4 und 3.1; ersetzt `GlowBackground`):
// die Welt der aktuellen Tageszeit als **eine** gecachte Ebene hinter dem
// Inhalt (`RepaintBoundary`, `ExcludeSemantics`), einmal je Screen-Root, nicht
// pro Karte. Sie füllt den verfügbaren Platz (in einen `Stack` hinter den
// Inhalt legen) und läuft auch außerhalb des `ContentFrame` voll durch. Keine
// Animation (Regel 9): Palette und Größe bestimmen das Bild, eine neue Palette
// (Minuten-Timer des `WorldHost`) ersetzt es in einem Schritt.
//
// Bei „Transparenz reduzieren“/Hoher Kontrast fehlen Körnung, Dunst, Sterne
// und Sonne/Mond (ruhiger Verlauf, `worldDecorEnabled == false`). [calm] ist
// die ruhigere Welt des Physio-Bereichs.
import 'package:flutter/widgets.dart';

import '../../state/world_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/world_painter.dart';
import '../../theme/world_tokens.dart';

class WorldBackground extends StatefulWidget {
  const WorldBackground({super.key, this.calm = false});

  /// Ruhige Welt (Physio): Ebenen 50 %, ohne Sonne/Mond/Sterne/Körnung.
  final bool calm;

  @override
  State<WorldBackground> createState() => _WorldBackgroundState();
}

class _WorldBackgroundState extends State<WorldBackground> {
  @override
  void initState() {
    super.initState();
    // Beim Öffnen eines Screens neu rechnen (Brief 3.1).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) WorldScope.maybeOf(context)?.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final WorldPalette palette = WorldScope.paletteOf(context);
    return ExcludeSemantics(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            painter: WorldPainter(
              palette: palette,
              decor: colors.worldDecorEnabled,
              calm: widget.calm,
            ),
            isComplex: true,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
