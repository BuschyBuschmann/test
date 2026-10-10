// Fehleransicht im Pfad-Layout (Brief 6.2, Plan 6.2 „Fehler der Plattform beim
// Lesen“): `status-error`-Icon, Text und „Nochmal versuchen“. Der StartGate
// zeigt sie, solange unklar ist, ob das Onboarding abgeschlossen war (A-6);
// der Pfad-Screen (U3a) verwendet sie für `path-error` mit eigenem Text
// (Erratum E-4: zwei getrennte Texte), der Tab Heute (U3b) für `today-error`
// mit „Dein Programm konnte nicht geladen werden.“. `status-error` ist hier
// Status, nie Handlungsfarbe: der Button ist ein gewöhnlicher Primärbutton.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../components/pill_button.dart';
import '../components/probe_keys.dart';

class PathErrorView extends StatelessWidget {
  const PathErrorView({
    super.key,
    required this.onRetry,
    required this.message,
  });

  final VoidCallback onRetry;

  /// Text je Ort: `S.startLoadError` im StartGate, `S.pathLoadError` im
  /// Pfad-Tab (Erratum E-4), `S.todayLoadError` im Tab Heute.
  final String message;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          key: ProbeKeys.scroll,
          padding: const EdgeInsets.all(CuraSpace.pageMargin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: CuraComponent.dialogIconSize,
                    color: colors.statusError,
                  ),
                ),
              ),
              const SizedBox(height: CuraSpace.s3),
              Semantics(
                liveRegion: true,
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: type.body.copyWith(color: colors.text1),
                ),
              ),
              const SizedBox(height: CuraSpace.s6),
              PillButton(
                key: ProbeKeys.primary,
                label: S.retry,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
