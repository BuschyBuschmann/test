// Ladeansicht des Tabs Heute (Brief 6.3: „statische Glas-Platzhalterkarten“):
// keine Animation, kein Shimmer, keine künstliche Verzögerung (A-33). Der
// Screenreader hört „Wird geladen“ als Live-Region; die Platzhalter selbst
// sind ausgeblendet.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_metrics.dart';
import '../components/glass_card.dart';

class TodayLoadingView extends StatelessWidget {
  const TodayLoadingView({super.key});

  Widget _card(double height) {
    return GlassCard(
      lightEdge: false,
      padding: EdgeInsets.zero,
      child: SizedBox(width: double.infinity, height: height),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: S.loading,
      child: ExcludeSemantics(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              CuraSpace.pageMargin,
              CuraSpace.s10,
              CuraSpace.pageMargin,
              CuraSpace.pageMargin,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _card(CuraSize.chipHeight),
                const SizedBox(height: CuraSpace.s6),
                _card(CuraSize.placeholderCardHeight),
                const SizedBox(height: CuraSpace.s3),
                _card(CuraSize.placeholderCardHeight),
                const SizedBox(height: CuraSpace.s3),
                _card(CuraSize.placeholderCardHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
