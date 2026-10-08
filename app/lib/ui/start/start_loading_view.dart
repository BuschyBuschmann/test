// Ladeansicht des Starts (Brief 6.2, A-33): statische Glas-Kreise als
// Platzhalter des Pfads, kein Shimmer, keine künstliche Verzögerung.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_metrics.dart';
import '../components/glass_card.dart';

class StartLoadingView extends StatelessWidget {
  const StartLoadingView({super.key});

  static const double _padding = CuraSpace.s8;

  Widget _circle(double size, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: SizedBox.square(
        dimension: size,
        child: const GlassCard(
          padding: EdgeInsets.zero,
          radius: CuraRadius.pill,
          lightEdge: false,
          child: SizedBox.shrink(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: S.loading,
      child: ExcludeSemantics(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) {
              // Nur ein Platzhalterbild: bei wenig Höhe (Tastatur, Querformat)
              // wird abgeschnitten statt zu überlaufen.
              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(_padding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: box.maxHeight - (_padding + _padding),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _circle(CuraSize.unitSmall, Alignment.centerRight),
                      const SizedBox(height: CuraSpace.s8),
                      _circle(CuraSize.unitMedium, Alignment.center),
                      const SizedBox(height: CuraSpace.s8),
                      _circle(CuraSize.unitSmall, Alignment.centerLeft),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
