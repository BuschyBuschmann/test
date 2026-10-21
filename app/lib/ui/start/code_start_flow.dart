// Code-Start (Brief-Ergänzung 2, A1/A2): Schritt „Wie soll Manny aussehen?“
// (nur wenn noch kein Look gewählt wurde, O-43) und „Zugang über deinen
// Physio“ mit dem Code-Feld. Den Rest (Hinweise, Einwilligung, Laden) zeigt
// `BackendRoot` nach der Phase des [BackendController].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/strings_de.dart';
import '../../logic/code_start.dart';
import '../../logic/invite_code.dart';
import '../../logic/manny_occasions.dart' show MannyPose;
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../state/backend_controller.dart';
import '../../state/backend_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../../theme/tokens.dart';
import '../components/cura_snackbar.dart';
import '../components/code_field.dart';
import '../components/glass_card.dart';
import '../components/glass_pill.dart';
import '../components/notice_card.dart';
import '../components/primary_pill.dart';
import '../components/probe_keys.dart';
import '../onboarding/onboarding_manny.dart';
import '../onboarding/step_look.dart';
import 'start_step_scaffold.dart';

class CodeStartFlow extends StatefulWidget {
  const CodeStartFlow({super.key, this.initialCode});

  /// Code aus einem Einladungslink (normalisiert); wird nur ins Feld gesetzt,
  /// eingelöst wird erst nach „Weiter“ (V2-80).
  final String? initialCode;

  @override
  State<CodeStartFlow> createState() => _CodeStartFlowState();
}

class _CodeStartFlowState extends State<CodeStartFlow> {
  final TextEditingController _code = TextEditingController();
  final FocusNode _codeFocus = FocusNode(debugLabel: 'Code');
  final SnackbarController _snackbar = SnackbarController();
  late bool _lookStep;
  bool _onLook = false;
  bool _fromLink = false;
  bool _bubbleOpen = true;

  @override
  void initState() {
    super.initState();
    final AppController? app = context
        .getInheritedWidgetOfExactType<AppScope>()
        ?.notifier;
    _lookStep = !(app?.state.lookAlreadyChosen ?? true);
    _onLook = _lookStep;
    final String? link = widget.initialCode;
    if (link != null) {
      _code.text = formatInviteCodeInput(link);
      _fromLink = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterFirstFrame());
  }

  /// Nach „Alles löschen“ bzw. „Zugang löschen“: Sperre aufheben (Vertrag wie
  /// beim Onboarding) und die Snackbar zeigen.
  void _afterFirstFrame() {
    if (!mounted) return;
    final AppController? app = context
        .getInheritedWidgetOfExactType<AppScope>()
        ?.notifier;
    app?.completeDeletion();
    if (app?.startNotice == StartNotice.deleted) {
      _snackbar.show(
        CuraSnackbarMessage(
          text: S.dataDeleted,
          duration: SnackbarTokens.short,
        ),
      );
      app?.clearStartNotice();
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _codeFocus.dispose();
    _snackbar.dispose();
    super.dispose();
  }

  BackendController get _backend => BackendScope.readOf(context)!;

  bool get _valid => parseInviteCode(_code.text) != null;

  Future<void> _submit() async {
    if (!_valid || _backend.isRedeeming) return;
    await _backend.redeem(
      _code.text,
      totalSteps: codeStartTotalSteps(lookStep: _lookStep),
    );
    if (!mounted) return;
    if (_backend.redeemFailure != null) {
      _codeFocus.requestFocus();
    }
  }

  void _back() {
    if (!_onLook && _lookStep) {
      setState(() => _onLook = true);
    } else {
      SystemNavigator.pop();
    }
  }

  String? _failureText(RedeemFailure? f) => switch (f) {
    null => null,
    RedeemFailure.invalid => S.codeInvalid,
    RedeemFailure.alreadyUsed => S.codeAlreadyUsed,
    RedeemFailure.expired => S.codeExpired,
    RedeemFailure.tooManyAttempts => S.codeTooManyAttempts,
    RedeemFailure.notAllowed => S.codeNotAllowed,
    RedeemFailure.network => S.codeNetwork,
  };

  @override
  Widget build(BuildContext context) {
    // Hört auf den Look (Wahl) und das Backend (Prüfung, Fehler).
    final AppController app = AppScope.of(context);
    final BackendController backend = BackendScope.maybeOf(context)!;
    final int total = codeStartTotalSteps(lookStep: _lookStep);
    final Widget overlay = Positioned.fill(
      child: SnackbarHost(controller: _snackbar, bottomOffset: 0),
    );
    if (_onLook) {
      return StartStepScaffold(
        title: S.onboardingTitleLook,
        step: 1,
        total: total,
        onBack: _back,
        overlays: <Widget>[overlay],
        primary: PrimaryPill(
          key: ProbeKeys.primary,
          label: S.next,
          onPressed: () {
            app.confirmLookChosen();
            setState(() => _onLook = false);
          },
        ),
        children: const <Widget>[StepLook()],
      );
    }
    final bool busy = backend.isRedeeming;
    final RedeemFailure? failure = backend.redeemFailure;
    final String? failureText = _failureText(failure);
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return StartStepScaffold(
      title: S.accessTitle,
      secondaryBeside: true,
      secondary: _lookStep
          ? GlassPill(
              label: S.back,
              expand:
                  MediaQuery.textScalerOf(context)
                      .scale(CuraSize.textScaleUnit) >
                  CuraComponent.codeMaxTextScale,
              onPressed: busy ? null : _back,
            )
          : null,
      primary: Semantics(
        hint: _valid ? null : S.codeEmptyHint,
        child: PrimaryPill(
          key: ProbeKeys.primary,
          label: busy ? S.codeChecking : S.next,
          busy: busy,
          busyStatus: S.codeChecking,
          onPressed: _valid && !busy ? _submit : null,
        ),
      ),
      step: _lookStep ? 2 : 1,
      total: total,
      onBack: _back,
      overlays: <Widget>[overlay],
      children: <Widget>[
        OnboardingManny(
          height: CuraSize.mannyOnboardingStep1Height,
          text: S.accessMannyBubble,
          bubbleVisible: _bubbleOpen,
          onCloseBubble: () => setState(() => _bubbleOpen = false),
          pose: MannyPose.neutral,
        ),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CodeField(
                label: S.codeLabel,
                controller: _code,
                focusNode: _codeFocus,
                enabled: !busy,
                hasError: failure != null,
                onChanged: (_) => setState(() => _fromLink = false),
                onSubmitted: (_) => _submit(),
              ),
              if (_fromLink && failure == null) ...<Widget>[
                const SizedBox(height: CuraSpace.s3),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    children: <Widget>[
                      ExcludeSemantics(
                        child: Icon(
                          Icons.link_rounded,
                          size: CuraSize.hintIcon,
                          color: colors.text2,
                        ),
                      ),
                      const SizedBox(width: CuraSpace.s2),
                      Expanded(
                        child: Text(
                          S.codeFromLink,
                          style: type.secondary.copyWith(color: colors.text2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (failureText != null) ...<Widget>[
                const SizedBox(height: CuraSpace.s3),
                NoticeCard(
                  kind: NoticeKind.error,
                  text: failureText,
                  live: true,
                  actionLabel: failure == RedeemFailure.network
                      ? S.retry
                      : null,
                  onAction: failure == RedeemFailure.network && !busy
                      ? _submit
                      : null,
                ),
              ],
            ],
          ),
        ),
        GlassCard(
          child: Text(
            S.accessExplain,
            style: type.body.copyWith(color: colors.text1),
          ),
        ),
      ],
    );
  }
}
