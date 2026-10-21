// `ExampleNotice` (Ergänzung 2, Abschnitt 2): Hinweiskarte „Beispiel“ auf
// `GlassCard` (E1-Glas, Radius 16, Innenabstand 10/14, kein Blur), Info-Icon
// 20 dp `text-2`, optional `CuraLabel` plus Text `secondary`. Dauerhaft
// sichtbar, nicht ausblendbar. Ein Semantik-Knoten (Label und Text zusammen).
import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import 'cura_label.dart';
import 'glass_card.dart';

class ExampleNotice extends StatelessWidget {
  const ExampleNotice({super.key, required this.text, this.label});

  final String text;

  /// Kleine Überschrift über dem Text („Beispielverlauf“).
  final String? label;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final String? heading = label;
    return MergeSemantics(
      child: GlassCard(
        radius: CuraRadius.notice,
        lightEdge: false,
        padding: const EdgeInsets.symmetric(
          vertical: CuraSize.noticePaddingVertical,
          horizontal: CuraSize.noticePaddingHorizontal,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.info_outline_rounded,
              size: CuraSize.noticeIcon,
              color: colors.text2,
            ),
            const SizedBox(width: CuraSpace.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (heading != null)
                    CuraLabel(heading, color: colors.text1, header: false),
                  Text(
                    text,
                    style: type.secondary.copyWith(color: colors.text1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
