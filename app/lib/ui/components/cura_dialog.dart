// `CuraDialog` (Ergänzung 1, Abschnitt 2): Bestätigungsdialog. Fläche
// `surface-opaque`, Rand `border-hair` (Hoher Kontrast `-hc`), Radius 24,
// Breite Bildschirm minus 32 dp (höchstens 400 dp), Icon 28 dp `text-1`,
// Titel `title`, Text `body`, Buttons gestapelt in voller Breite (56 dp,
// Abstand 8 dp). Der Inhalt scrollt, wenn er nicht passt; die Buttons bleiben
// unten sichtbar. Kein Blur, kein Skalieren, kein Glow. Scrim, Einblenden und
// Routennamen liefert die `CuraDialogRoute` (U2b); hier steht die Semantik
// `alertdialog` und der Titel benennt die Route.
//
// Braucht eine begrenzte Höhe vom Elternelement (die Route stellt sie).
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';

class CuraDialog extends StatelessWidget {
  const CuraDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actions,
    this.icon,
    this.extra,
  });

  final String title;
  final String message;

  /// Buttons (`PillButton`s), von oben nach unten: die sichere Aktion zuerst.
  final List<Widget> actions;
  final IconData? icon;

  /// Zusatzinhalt unter dem Text (z. B. Fehlerhinweis), scrollt mit.
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CuraSpace.pageMargin),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: CuraSize.dialogMaxWidth),
        child: Semantics(
          role: SemanticsRole.alertDialog,
          scopesRoute: true,
          explicitChildNodes: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceOpaque,
              borderRadius: BorderRadius.circular(CuraRadius.dialog),
              border: Border.all(
                color: colors.cardBorder,
                width: CuraSize.hairline,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(CuraComponent.dialogPadding),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (icon != null) ...<Widget>[
                              ExcludeSemantics(
                                child: Icon(
                                  icon,
                                  size: CuraComponent.dialogIconSize,
                                  color: colors.text1,
                                ),
                              ),
                              const SizedBox(height: CuraComponent.dialogGap),
                            ],
                            Semantics(
                              namesRoute: true,
                              header: true,
                              child: Text(
                                title,
                                style: type.title.copyWith(color: colors.text1),
                              ),
                            ),
                            const SizedBox(height: CuraComponent.dialogGap),
                            Text(
                              message,
                              style: type.body.copyWith(color: colors.text1),
                            ),
                            if (extra != null) ...<Widget>[
                              const SizedBox(height: CuraComponent.dialogGap),
                              extra!,
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: CuraComponent.dialogPadding),
                    for (int i = 0; i < actions.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: CuraSpace.s2),
                      actions[i],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
