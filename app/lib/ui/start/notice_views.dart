// Vollbild-Hinweise und Zustände des Backend-Einstiegs (Brief-Ergänzung 2,
// A4, A9, A11): Neuanmeldung (neues Gerät), gelöste Bindung (altes Gerät),
// Laden, Ladefehler und „Löschen noch nicht abgeschlossen“.
import 'package:flutter/material.dart';

import '../../l10n/strings_de.dart';
import '../../logic/manny_look.dart';
import '../../state/backend_controller.dart';
import '../../state/backend_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../components/glass_card.dart';
import '../components/manny.dart';
import '../components/notice_card.dart';
import '../components/primary_pill.dart';
import '../components/probe_keys.dart';
import '../components/screen_frame.dart';
import 'start_step_scaffold.dart';

/// Eine Zeile mit Haken in der Hinweiskarte.
class _Line extends StatelessWidget {
  const _Line(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ExcludeSemantics(
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: CuraComponent.iconSize,
            color: colors.text1,
          ),
        ),
        const SizedBox(width: CuraSpace.s3),
        Expanded(
          child: Text(text, style: type.body.copyWith(color: colors.text1)),
        ),
      ],
    );
  }
}

/// „Du bist neu angemeldet“ (neues Gerät nach `ok_rebound`).
class ReboundNoticeView extends StatelessWidget {
  const ReboundNoticeView({super.key});

  @override
  Widget build(BuildContext context) {
    final BackendController backend = BackendScope.maybeOf(context)!;
    final MannyLook? look = backend.reboundLookNote;
    return StartStepScaffold(
      title: S.reboundTitle,
      primary: PrimaryPill(
        key: ProbeKeys.primary,
        label: S.reboundAck,
        autofocus: true,
        onPressed: backend.acknowledgeRebound,
      ),
      children: <Widget>[
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _Line(S.reboundKept),
              const SizedBox(height: CuraSpace.s3),
              const _Line(S.reboundChat),
              if (look != null) ...<Widget>[
                const SizedBox(height: CuraSpace.s3),
                _Line(
                  S.reboundLook(
                    look == MannyLook.brille
                        ? S.mannyLookWith
                        : S.mannyLookWithout,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Altes Gerät: Bindung gelöst bzw. Zugang beendet.
class BindingLostView extends StatelessWidget {
  const BindingLostView({super.key});

  @override
  Widget build(BuildContext context) {
    final BackendController backend = BackendScope.maybeOf(context)!;
    final bool ended = backend.lostKind == BindingLostKind.accessDeleted;
    return StartStepScaffold(
      title: ended ? S.lostAccessTitle : S.lostOtherTitle,
      primary: PrimaryPill(
        key: ProbeKeys.primary,
        label: S.lostContinue,
        autofocus: true,
        onPressed: backend.acknowledgeBindingLost,
      ),
      children: <Widget>[
        GlassCard(
          child: Text(
            ended ? S.lostAccessText : S.lostOtherText,
            style: CuraTypography.of(context).body
                .copyWith(color: CuraColors.of(context).text1),
          ),
        ),
      ],
    );
  }
}

/// Laden ohne Zwischenspeicher: Manny, Text und Fortschrittsring (A9, E-3).
class BackendLoadingView extends StatelessWidget {
  const BackendLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return ScreenFrame(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            key: ProbeKeys.scroll,
            padding: const EdgeInsets.all(CuraSpace.pageMargin),
            child: Semantics(
              liveRegion: true,
              label: S.loading,
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const MannyIllustration(height: CuraSize.mannyLoading),
                    const SizedBox(height: CuraSpace.s3),
                    Text(
                      S.backendLoading,
                      textAlign: TextAlign.center,
                      style: type.heading.copyWith(color: colors.text1),
                    ),
                    const SizedBox(height: CuraSpace.s3),
                    SizedBox.square(
                      dimension: CuraComponent.progressSize,
                      child: CircularProgressIndicator(
                        strokeWidth: CuraComponent.progressStroke,
                        color: colors.text1,
                      ),
                    ),
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

/// Fehler ohne Zwischenspeicher: „Dein Plan konnte nicht geladen werden.“.
class BackendErrorView extends StatelessWidget {
  const BackendErrorView({
    super.key,
    required this.onRetry,
    this.message = S.backendLoadError,
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ScreenFrame(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            key: ProbeKeys.scroll,
            padding: const EdgeInsets.all(CuraSpace.pageMargin),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                NoticeCard(kind: NoticeKind.error, text: message, live: true),
                const SizedBox(height: CuraSpace.s3),
                PrimaryPill(
                  key: ProbeKeys.primary,
                  label: S.retry,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// „Löschen noch nicht abgeschlossen“ (nach unklarem Ausgang, beim Start).
class DeletionPendingView extends StatelessWidget {
  const DeletionPendingView({super.key});

  @override
  Widget build(BuildContext context) {
    final BackendController backend = BackendScope.maybeOf(context)!;
    final bool busy = backend.isPendingBusy;
    return StartStepScaffold(
      title: S.deletePendingTitle,
      primary: PrimaryPill(
        key: ProbeKeys.primary,
        label: S.retry,
        busy: busy,
        busyStatus: S.busyStatusDeleting,
        onPressed: busy ? null : backend.retryPendingDeletion,
      ),
      children: <Widget>[
        GlassCard(
          child: Text(
            S.deletePendingText,
            style: CuraTypography.of(context).body
                .copyWith(color: CuraColors.of(context).text1),
          ),
        ),
        if (backend.pendingOffline)
          const NoticeCard(
            kind: NoticeKind.error,
            text: S.deleteOffline,
            live: true,
          ),
      ],
    );
  }
}
