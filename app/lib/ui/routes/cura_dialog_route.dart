// `CuraDialogRoute` (Plan 4.1, 4.4): Route für Bestätigungsdialoge („Eigene
// Übung“, „Alles löschen?“, „Änderungen verwerfen?“). Scrim aus dem Token
// `scrim` (HC 72 %), Einblenden `dur-base` (bei reduzierter Bewegung höchstens
// `dur-fast`), kein Skalieren, kein Blur. Tipp auf den Scrim und Escape rufen
// `maybePop` auf (so greift ein `PopScope` des Dialogs, etwa während des
// Löschens). Den Inhalt (`CuraDialog`) liefert der Aufrufer; Routenname und
// `alertdialog`-Semantik stecken im `CuraDialog`.
import 'package:flutter/widgets.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';

class CuraDialogRoute<T> extends RawDialogRoute<T> {
  CuraDialogRoute({
    required BuildContext context,
    required WidgetBuilder builder,
    super.settings,
  }) : super(
         pageBuilder: (
           BuildContext context,
           Animation<double> animation,
           Animation<double> secondary,
         ) => _DialogPage(child: builder(context)),
         barrierDismissible: true,
         barrierColor: CuraColors.of(context).scrim,
         barrierLabel: S.close,
         transitionDuration: CuraMotion.of(context)
             .duration(CuraMotion.baseDuration),
         transitionBuilder:
             (
               BuildContext context,
               Animation<double> animation,
               Animation<double> secondary,
               Widget child,
             ) {
               return FadeTransition(
                 opacity: animation.drive(CurveTween(curve: CuraMotion.easing)),
                 child: child,
               );
             },
       );
}

/// Stellt dem Dialog eine begrenzte Höhe (Bildschirm abzüglich Rand, Safe
/// Area und Tastatur) und zentriert ihn.
class _DialogPage extends StatelessWidget {
  const _DialogPage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: CuraSpace.pageMargin,
            bottom: CuraSpace.pageMargin + media.viewInsets.bottom,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
