// `OnboardingFlow` (Plan 4.1, 4.2, 4.3, 4.5; Brief 6.1): die vier Schritte in
// **einer** Route. Gemeinsames Layout: oben Zurück-Pfeil (ab Schritt 2) und
// `StepProgress`, darunter der scrollende Inhalt mit Manny und Sprechblase,
// unten fest die Mikrofon-Zeile („Noch etwas hinzufügen?“) und der
// Primärbutton. Seitenwechsel als Schiebung 24 dp plus Einblenden in
// `dur-base` (bei Zurück in Gegenrichtung; bei reduzierter Bewegung sofort).
//
// - Jede Eingabe wird sofort über den `AppController` gespeichert; ein Neustart
//   setzt am gespeicherten Schritt fort (UI-16).
// - Zurück (Android, Escape ausgenommen, Browser-Zurück): immer einen Schritt
//   zurück, Eingaben bleiben; Mannys Blase zählt dort nicht als Overlay (N-13).
//   Auf Schritt 1 schließt die App (`SystemNavigator.pop`). Escape schließt die
//   Blase (Brief 8).
// - Vertrag (Review U1): `completeDeletion()` wird sofort nach dem ersten Frame
//   gerufen, vor jeder Eingabe.
// - Hinweise nach Löschen bzw. unlesbaren Daten erscheinen als Snackbar über der
//   Mikrofon-Zeile (4 s, ohne Aktion).
// - Der Manny-Button und die Button-Gruppe gibt es hier nicht (Ergänzung 2, K6).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/strings_de.dart';
import '../../state/app_controller.dart';
import '../../state/app_scope.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../../theme/cura_typography.dart';
import '../../theme/tokens.dart';
import '../components/cura_snackbar.dart';
import '../components/header_icon_button.dart';
import '../components/mic_button.dart';
import '../components/pill_button.dart';
import '../components/probe_keys.dart';
import '../components/screen_frame.dart';
import '../components/size_reporter.dart';
import '../components/step_progress.dart';
import '../routes/app_routes.dart';
import 'onboarding_manny.dart';
import 'step1_name.dart';
import 'step2_consent.dart';
import 'step3_injury.dart';
import 'step4_date.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    this.initialStep,
    this.notice = StartNotice.none,
  });

  /// Schritt 0 … 3; ohne Angabe der gespeicherte.
  final int? initialStep;

  /// Hinweis nach dem Neustart (Snackbar).
  final StartNotice notice;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const int _lastStep = 3;

  final SnackbarController _snackbar = SnackbarController();

  /// Seitenfokus: hält die Tastenkürzel (Escape) am Leben und nimmt beim
  /// Schrittwechsel den Fokus vom Textfeld (Tastatur schließt).
  final FocusNode _pageFocus = FocusNode(
    debugLabel: 'Onboarding',
    skipTraversal: true,
  );
  int _step = 0;
  int _direction = 1;
  bool _bubbleOpen = true;
  bool _micHint = false;
  double _bottomHeight = 0;

  @override
  void initState() {
    super.initState();
    final AppController? c = context
        .getInheritedWidgetOfExactType<AppScope>()
        ?.notifier;
    _step = (widget.initialStep ?? c?.state.onboarding.step ?? 0).clamp(
      0,
      _lastStep,
    );
    _snackbar.addListener(_onSnackbar);
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterFirstFrame());
  }

  @override
  void dispose() {
    _snackbar
      ..removeListener(_onSnackbar)
      ..dispose();
    _pageFocus.dispose();
    super.dispose();
  }

  /// Der Scrollbereich reserviert Platz für die Snackbar (4.5), solange sie
  /// steht.
  void _onSnackbar() {
    if (mounted) setState(() {});
  }

  /// Gemessene Höhe der sichtbaren Snackbar (0 ohne). Gemessen statt
  /// geschätzt, damit auch bei großer Schrift alles unter ihr erreichbar
  /// bleibt (Plan 4.6: Reserven aus gemessenen Höhen).
  double _snackbarHeight = 0;

  void _measureSnackbar() {
    if (!mounted) return;
    double height = 0;
    if (_snackbar.current != null) {
      void visit(Element element) {
        if (height > 0) return;
        if (element.widget is CuraSnackbar) {
          final RenderObject? box = element.renderObject;
          if (box is RenderBox && box.hasSize) height = box.size.height;
          return;
        }
        element.visitChildren(visit);
      }

      context.visitChildElements(visit);
    }
    if (height != _snackbarHeight) setState(() => _snackbarHeight = height);
  }

  double get _snackbarReserve =>
      _snackbarHeight > 0 ? _snackbarHeight + CuraSpace.snackbarGap : 0;

  void _afterFirstFrame() {
    if (!mounted) return;
    final AppController? c = context
        .getInheritedWidgetOfExactType<AppScope>()
        ?.notifier;
    // Vertrag: nach dem Neuaufbau des Onboardings, vor jeder Eingabe.
    c?.completeDeletion();
    final String? text = switch (widget.notice) {
      StartNotice.none => null,
      StartNotice.deleted => S.dataDeleted,
      StartNotice.unreadable => S.dataUnreadable,
    };
    if (text != null) {
      _snackbar.show(
        CuraSnackbarMessage(text: text, duration: SnackbarTokens.short),
      );
      c?.clearStartNotice();
    }
  }

  AppController get _controller => AppScope.of(context);

  bool _canContinue(AppController c) {
    final o = c.state.onboarding;
    return switch (_step) {
      0 => o.firstName.isNotEmpty,
      1 => true,
      2 => o.injuryType != null,
      _ => o.injuryDate != null,
    };
  }

  void _goTo(int step) {
    _pageFocus.requestFocus();
    _controller.setStep(step);
    setState(() {
      _direction = step > _step ? 1 : -1;
      _step = step;
      _bubbleOpen = true;
      _micHint = false;
    });
  }

  void _next() {
    final AppController c = _controller;
    if (!_canContinue(c)) return;
    switch (_step) {
      case 0:
        _goTo(1);
      case 1:
        c.acceptConsent();
        _goTo(2);
      case 2:
        _goTo(3);
      default:
        if (c.completeOnboarding()) {
          Navigator.of(context).pushAndRemoveUntil<void>(
            AppRoutes.home(context),
            (Route<dynamic> route) => false,
          );
        }
    }
  }

  void _back() {
    if (_step == 0) {
      SystemNavigator.pop();
    } else {
      _goTo(_step - 1);
    }
  }

  void _openPrivacy() {
    Navigator.of(context).push<void>(AppRoutes.privacy(context));
  }

  void _onMic() => setState(() {
    _micHint = true;
    _bubbleOpen = true;
  });

  void _closeBubble() {
    if (_bubbleOpen) setState(() => _bubbleOpen = false);
  }

  String _bubbleText(int step, AppController c) {
    final String name = c.state.onboarding.firstName;
    return switch (step) {
      0 => S.onboardingStep1,
      1 => S.onboardingStep2(name),
      2 => S.onboardingStep3(name),
      _ => S.onboardingStep4,
    };
  }

  Widget _stepPage(
    int step,
    bool current,
    double reserve, {
    required bool headerScrolls,
    required bool compactFooter,
  }) {
    final AppController c = _controller;
    final Widget prompt = OnboardingManny(
      height: step == 0
          ? CuraSize.mannyOnboardingStep1Height
          : CuraSize.mannyOnboardingMaxHeight,
      text: current && _micHint ? S.micHint : _bubbleText(step, c),
      bubbleVisible: !current || _bubbleOpen,
      onCloseBubble: _closeBubble,
    );
    final Widget content = switch (step) {
      0 => Step1Name(prompt: prompt, onSubmit: _next),
      1 => Step2Consent(prompt: prompt, onOpenPrivacy: _openPrivacy),
      2 => Step3Injury(prompt: prompt),
      _ => Step4Date(prompt: prompt),
    };
    // Die Scroll-Reserve unten wächst mit der gemessenen Höhe der Snackbar
    // (`reserve`); die Tastatur verkleinert den Scrollbereich selbst (das
    // Gerüst weicht ihr aus), so bleibt jedes Ziel frei scrollbar.
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: CuraSpace.pageMargin + (current ? reserve : 0),
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Immer ein Element an dieser Stelle: der Inhalt darunter behält
          // seinen Zustand (Textfeld, Fokus, Tastatur), wenn der Kopf beim
          // Öffnen der Tastatur in die Scrollfläche wechselt.
          headerScrolls ? _header(step, fixed: false) : const SizedBox.shrink(),
          Padding(
            key: const ValueKey<String>('onboarding-step-content'),
            padding: const EdgeInsets.fromLTRB(
              CuraSpace.pageMargin,
              CuraSpace.s2,
              CuraSpace.pageMargin,
              0,
            ),
            child: content,
          ),
          // Kompakte Weiter-Leiste: der Text „Noch etwas hinzufügen?“ steht am
          // Ende der Scrollfläche, unmittelbar vor der Mikrofon-Taste (auch
          // in der Lesereihenfolge). Immer drei Kinder, der Inhalt trägt einen Schlüssel:
          // wechseln Kopf und Hinweis gleichzeitig, paart Flutter ungeschlüsselte
          // Kinder nicht mehr, und der Inhalt verlöre Zustand und Fokus
          // (Textfeld, Tastatur).
          compactFooter && current ? _moreToAddText() : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _moreToAddText() {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CuraSpace.pageMargin,
        CuraSpace.s4,
        CuraSpace.pageMargin,
        0,
      ),
      child: Semantics(
        container: true,
        child: Text(
          S.moreToAdd,
          style: type.body.copyWith(color: colors.text2),
        ),
      ),
    );
  }

  /// Kopf in der Scrollfläche statt fest oben (A-U3 B1, gewählte Variante):
  /// ab Textskalierung 1,5 oder bei einer Resthöhe unter 400 dp (Route ohne
  /// Systemleisten und ohne Tastatur). Nichts geht verloren (Fortschrittstext,
  /// Zurück-Pfeil, Manny und Blase bleiben als Inhalt erreichbar), und die
  /// Scrollfläche behält mindestens die Höhe, die Tastatur und Weiter-Leiste
  /// übrig lassen.
  bool _headerScrolls(BuildContext context) {
    final MediaQueryData m = MediaQuery.of(context);
    final double rest =
        m.size.height - m.padding.vertical - m.viewInsets.bottom;
    return m.textScaler.scale(1) >= CuraSize.textScaleScrollAlong ||
        rest < CuraSize.onboardingHeaderScrollMaxHeight;
  }

  Widget _header(int step, {required bool fixed}) {
    return KeyedSubtree(
      key: fixed ? ProbeKeys.header : ProbeKeys.scrollHeader,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CuraSpace.s1,
          CuraSpace.s2,
          CuraSpace.pageMargin,
          0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Platz für den Pfeil bleibt auch auf Schritt 1 reserviert, damit
            // die Fortschrittsanzeige nicht springt.
            SizedBox.square(
              dimension: CuraSize.touchTarget,
              child: step == 0
                  ? null
                  : HeaderIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: S.back,
                      onPressed: _back,
                    ),
            ),
            const SizedBox(width: CuraSpace.s2),
            // Eigener Semantik-Knoten: sonst verschmilzt der Text mit anderen
            // Texten außerhalb des Scrollbereichs.
            Expanded(
              child: Semantics(
                container: true,
                child: StepProgress(step: step + 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottom(BuildContext context, AppController c, bool compact) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    final Widget primary = PillButton(
      key: ProbeKeys.primary,
      label: _step == 1 ? S.consentAccept : S.next,
      onPressed: _canContinue(c) ? _next : null,
    );
    final Widget mic = MicButton(onPressed: _onMic);
    // Mit Tastatur, bei großer Schrift oder geringer Höhe bleibt wenig Platz:
    // Mikrofon und Button teilen sich eine Zeile, der Text der Mikrofon-Zeile
    // wandert ans Ende der Scrollfläche ([_moreToAddText]).
    final Widget block = compact
        ? Row(
            children: <Widget>[
              mic,
              const SizedBox(width: CuraSpace.s2),
              Expanded(child: primary),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Semantics(
                      container: true,
                      child: Text(
                        S.moreToAdd,
                        style: type.body.copyWith(color: colors.text2),
                      ),
                    ),
                  ),
                  const SizedBox(width: CuraSpace.s3),
                  mic,
                ],
              ),
              const SizedBox(height: CuraSpace.s3),
              primary,
            ],
          );
    return SizeReporter(
      onSize: (Size size) {
        if (size.height != _bottomHeight && mounted) {
          setState(() => _bottomHeight = size.height);
        }
      },
      child: KeyedSubtree(
        key: ProbeKeys.primaryRow,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            CuraSpace.pageMargin,
            CuraSpace.s2,
            CuraSpace.pageMargin,
            safeBottom > CuraSpace.pageMargin
                ? safeBottom
                : CuraSpace.pageMargin,
          ),
          child: block,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppController c = AppScope.of(context);
    final bool keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final bool headerScrolls = _headerScrolls(context);
    final bool compactFooter = keyboard || headerScrolls;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureSnackbar());
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _back();
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): _closeBubble,
        },
        child: Focus(
          focusNode: _pageFocus,
          autofocus: true,
          // Ohne eigenen Semantik-Knoten: sonst verschmilzt `Focus` die
          // Texte der ganzen Seite zu einem einzigen Knoten.
          includeSemantics: false,
          child: ScreenFrame(
            overlays: <Widget>[
              Positioned.fill(
                child: SnackbarHost(
                  controller: _snackbar,
                  bottomOffset: _bottomHeight + CuraSpace.snackbarGap,
                ),
              ),
            ],
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  headerScrolls
                      ? const SizedBox.shrink()
                      : _header(_step, fixed: true),
                  Expanded(
                    key: const ValueKey<String>('onboarding-scroll-area'),
                    child: KeyedSubtree(
                      key: ProbeKeys.scroll,
                      child: _StepPager(
                        step: _step,
                        direction: _direction,
                        builder: (int step, bool current) => _stepPage(
                          step,
                          current,
                          _snackbarReserve,
                          headerScrolls: headerScrolls,
                          compactFooter: compactFooter,
                        ),
                      ),
                    ),
                  ),
                  Builder(
                    builder: (BuildContext context) =>
                        _bottom(context, c, compactFooter),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Seitenwechsel (Brief 3.6): neuer Schritt kommt mit 24 dp Schiebung und
/// Einblenden, der alte geht in Gegenrichtung (bei Zurück umgekehrt). Bei
/// reduzierter Bewegung wechselt der Inhalt sofort.
class _StepPager extends StatefulWidget {
  const _StepPager({
    required this.step,
    required this.direction,
    required this.builder,
  });

  final int step;

  /// 1 = vorwärts (neuer Schritt von rechts), -1 = zurück.
  final int direction;
  final Widget Function(int step, bool current) builder;

  @override
  State<_StepPager> createState() => _StepPagerState();
}

class _StepPagerState extends State<_StepPager>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _leaving;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: CuraMotion.baseDuration,
      value: 1,
    )..addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _leaving != null && mounted) {
      setState(() => _leaving = null);
    }
  }

  @override
  void didUpdateWidget(_StepPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step == widget.step) return;
    if (CuraMotion.of(context).reduced) {
      _leaving = null;
      _controller.value = 1;
    } else {
      _leaving = oldWidget.step;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animated({
    required int step,
    required bool entering,
    required Widget child,
  }) {
    final double slide = CuraSize.routeSlide * widget.direction;
    return AnimatedBuilder(
      key: ValueKey<int>(step),
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = CuraMotion.easing.transform(_controller.value);
        return Opacity(
          opacity: entering ? t : 1 - t,
          child: Transform.translate(
            offset: Offset(entering ? slide * (1 - t) : -slide * t, 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int? leaving = _leaving;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (leaving != null)
          _animated(
            step: leaving,
            entering: false,
            child: ExcludeFocus(
              child: ExcludeSemantics(
                child: IgnorePointer(child: widget.builder(leaving, false)),
              ),
            ),
          ),
        _animated(
          step: widget.step,
          entering: true,
          child: widget.builder(widget.step, true),
        ),
      ],
    );
  }
}
