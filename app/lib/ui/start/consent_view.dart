// Einwilligung `physio_sharing-2` (Brief-Ergänzung 2, A3): alle Punkte stehen
// vollständig im Text, kein vorangekreuztes Feld, eine ausdrückliche Handlung
// („Ich bin einverstanden“). „Nicht einverstanden“ öffnet einen Dialog mit
// „Zugang löschen“ und „Zurück“ (Offene Frage 2). Kein Zurück (der Code ist
// schon eingelöst).
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../state/backend_controller.dart';
import '../../state/backend_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../components/cura_label.dart';
import '../components/cura_pressable.dart';
import '../components/glass_card.dart';
import '../components/glass_pill.dart';
import '../components/notice_card.dart';
import '../components/primary_pill.dart';
import '../components/probe_keys.dart';
import '../data_sheet/backend_delete_dialog.dart';
import '../routes/app_routes.dart';
import 'start_step_scaffold.dart';

class ConsentView extends StatefulWidget {
  const ConsentView({super.key});

  @override
  State<ConsentView> createState() => _ConsentViewState();
}

class _ConsentViewState extends State<ConsentView> {
  final FocusNode _declineFocus = FocusNode(debugLabel: 'Nicht einverstanden');
  final GlobalKey _errorKey = GlobalKey();

  @override
  void dispose() {
    _declineFocus.dispose();
    super.dispose();
  }

  Future<void> _decline() => Navigator.of(context).push<void>(
    BackendDeleteDialog.route(context, variant: DeleteVariant.decline),
  );

  void _openPrivacy() =>
      Navigator.of(context).push<void>(AppRoutes.privacy(context));

  Widget _point(
    BuildContext context,
    IconData icon,
    Color circle,
    Color mark,
    String lead,
    String text,
  ) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ExcludeSemantics(
          child: SizedBox.square(
            dimension: CuraComponent.iconSize,
            child: DecoratedBox(
              decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
              child: Icon(icon, size: CuraSize.hintIcon, color: mark),
            ),
          ),
        ),
        const SizedBox(width: CuraSpace.s3),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: lead,
                  style: type.bodyStrong.copyWith(color: colors.text1),
                ),
                TextSpan(
                  text: text,
                  style: type.body.copyWith(color: colors.text1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final BackendController backend = BackendScope.maybeOf(context)!;
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    if (backend.consentFailure != null) {
      // Der Fehler steht oben im Inhalt: in den Blick holen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext? ctx = _errorKey.currentContext;
        if (ctx != null && ctx.mounted) Scrollable.ensureVisible(ctx);
      });
    }
    final String? name = backend.framework?.framework.patient.firstName;
    final bool busy = backend.isConsentBusy;
    final ConsentFailure? failure = backend.consentFailure;
    Widget yes(String lead, String text) => _point(
      context,
      Icons.check_rounded,
      colors.chipSuccessFill,
      colors.chipSuccessText,
      lead,
      text,
    );
    return StartStepScaffold(
      title: S.consentTitle,
      subtitle: (name == null || name.isEmpty) ? null : S.consentGreeting(name),
      step: backend.codeStartTotal,
      total: backend.codeStartTotal,
      primary: PrimaryPill(
        key: ProbeKeys.primary,
        label: busy
            ? S.consentSending
            : (failure != null ? S.retry : S.consentAgree),
        busy: busy,
        busyStatus: S.consentSending,
        onPressed: busy ? null : backend.acceptConsent,
      ),
      secondary: GlassPill(
        label: S.consentDecline,
        focusNode: _declineFocus,
        onPressed: busy ? null : _decline,
      ),
      children: <Widget>[
        if (failure != null)
          KeyedSubtree(
            key: _errorKey,
            child: NoticeCard(
              kind: NoticeKind.error,
              text: failure == ConsentFailure.offline
                  ? S.consentOffline
                  : S.consentError,
              live: true,
            ),
          ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  S.consentSeesTitle,
                  style: type.heading.copyWith(color: colors.text1),
                ),
              ),
              const SizedBox(height: CuraSpace.s3),
              yes(S.consentSees1Lead, S.consentSees1),
              const SizedBox(height: CuraSpace.s3),
              yes(S.consentSees2Lead, S.consentSees2),
              const SizedBox(height: CuraSpace.s3),
              yes(S.consentSees3Lead, S.consentSees3),
              const SizedBox(height: CuraSpace.s3),
              yes(S.consentSees4Lead, S.consentSees4),
              const SizedBox(height: CuraSpace.s3),
              yes(S.consentSees5Lead, S.consentSees5),
            ],
          ),
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  S.consentNeverTitle,
                  style: type.heading.copyWith(color: colors.text1),
                ),
              ),
              const SizedBox(height: CuraSpace.s3),
              _point(
                context,
                Icons.close_rounded,
                colors.chipFill,
                colors.text1,
                '',
                S.consentNever,
              ),
            ],
          ),
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CuraLabel(S.consentDeleteTitle),
              const SizedBox(height: CuraSpace.s1),
              Text(
                S.consentDelete,
                style: type.body.copyWith(color: colors.text1),
              ),
              const SizedBox(height: CuraSpace.s3),
              Text(
                S.consentPlaceholderNote,
                style: type.caption.copyWith(color: colors.text2),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: CuraPressable(
                  onPressed: _openPrivacy,
                  semanticLabel: S.privacyLink,
                  ringRadius: CuraRadius.chipInner,
                  builder: (BuildContext context, bool pressed) {
                    return ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: CuraSize.touchTarget,
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          S.privacyLink,
                          style: type.bodyStrong.copyWith(
                            color: pressed ? colors.text1 : colors.accentText,
                            decoration: TextDecoration.underline,
                            decorationColor: pressed
                                ? colors.text1
                                : colors.accentText,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
