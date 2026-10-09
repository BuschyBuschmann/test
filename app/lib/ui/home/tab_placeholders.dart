// Einfacher Platzhalter-Inhalt des Tabs Heute, bis U3b ihn ersetzt. Er trägt
// keine Funktion; nur Überschrift und Hinweis. (Der Pfad-Tab ist seit U3a der
// `PathScreen`.)
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_typography.dart';
import '../components/floating_nav.dart';

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          CuraSpace.pageMargin,
          CuraSpace.s6,
          CuraSpace.pageMargin,
          FloatingNav.occupiedHeight(context) + CuraSpace.pageMargin,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(
                title,
                style: type.display.copyWith(color: colors.text1),
              ),
            ),
            const SizedBox(height: CuraSpace.s3),
            Text(text, style: type.body.copyWith(color: colors.text2)),
          ],
        ),
      ),
    );
  }
}

class TodayTabPlaceholder extends StatelessWidget {
  const TodayTabPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final String name = AppScope.of(context).state.onboarding.firstName;
    return _TabPlaceholder(
      title: S.todayTitle(name),
      text: S.todayTabPlaceholder,
    );
  }
}
