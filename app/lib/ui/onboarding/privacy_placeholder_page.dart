// Platzhalterseite „Datenschutzerklärung“ (Brief 6.1 Schritt 3): wird vor dem
// echten Einsatz durch den juristisch geprüften Text ersetzt (Brief 6.0).
//
// Design-Brief v2 (V2-5: kein Text direkt auf der Welt): Zurück-Pfeil und Titel
// stehen wie auf allen Seiten auf der `HeaderCard`, der Text auf einer Karte.
// Der Baum von `CuraBlur` bleibt beim Vergeben von Blur-Plätzen stabil, deshalb
// verlängert die Kopf-Karte den Übergang bei „Bewegung reduzieren“ nicht.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import '../components/glass_card.dart';
import '../components/header_card.dart';
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
                  CuraSize.cardMargin,
                  CuraSpace.s2,
                  CuraSize.cardMargin,
                  CuraSpace.s2,
                ),
                child: HeaderCard(
                  title: S.privacyTitle,
                  compactTitle: true,
                  // Zurück-Pfeil über dem Titel: „Datenschutzerklärung“ bekommt
                  // die volle Breite und bricht nicht mitten im Wort.
                  top: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: HeaderIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: S.back,
                      autofocus: true,
                      onHeaderCard: true,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: ProbeKeys.scroll,
                padding: const EdgeInsets.fromLTRB(
                  CuraSize.cardMargin,
                  CuraSpace.s2,
                  CuraSize.cardMargin,
                  CuraSpace.pageMargin,
                ),
                child: GlassCard(
                  child: Text(
                    S.privacyPlaceholderBody,
                    style: type.body.copyWith(color: colors.text1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
