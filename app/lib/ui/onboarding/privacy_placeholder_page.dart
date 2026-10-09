// Platzhalterseite „Datenschutzerklärung“ (Brief 6.1 Schritt 2): wird vor dem
// echten Einsatz durch den juristisch geprüften Text ersetzt (Brief 6.0).
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import '../components/header_icon_button.dart';
import '../components/probe_keys.dart';
import '../components/screen_frame.dart';

class PrivacyPlaceholderPage extends StatelessWidget {
  const PrivacyPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return ScreenFrame(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            KeyedSubtree(
              key: ProbeKeys.header,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  CuraSpace.s2,
                  CuraSpace.s2,
                  CuraSpace.pageMargin,
                  CuraSpace.s2,
                ),
                child: Row(
                  children: <Widget>[
                    HeaderIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: S.back,
                      autofocus: true,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: CuraSpace.s2),
                    Expanded(
                      child: Semantics(
                        header: true,
                        namesRoute: true,
                        child: Text(
                          S.privacyTitle,
                          style: type.title.copyWith(color: colors.text1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: ProbeKeys.scroll,
                padding: const EdgeInsets.all(CuraSpace.pageMargin),
                child: Text(
                  S.privacyPlaceholderBody,
                  style: type.body.copyWith(color: colors.text1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
