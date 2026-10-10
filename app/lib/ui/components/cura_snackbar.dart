// `CuraSnackbar` + `SnackbarHost` (Ergänzung 1, Abschnitt 2, 3.3; Plan 9):
// Fläche `surface-opaque`, Rand `border-hair` (Hoher Kontrast `-hc`), Radius
// 20, Innenabstand 16, Text `body` `text-1`, optionale Aktion rechts als
// Text-Button in `accent-hi` (Hit-Area 48 dp); ab Textskalierung 1,3 oder wenn
// sie nicht daneben passt, steht die Aktion rechtsbündig unter dem Text.
// Immer nur eine Snackbar: eine neue ersetzt die alte, die alte Aktion
// verfällt. Live-Region („Eingetragen. Rückgängig, Schaltfläche“), nie Blur.
// Erscheinen: Einblenden plus 8 dp Schiebung (`dur-base`); bei reduzierter
// Bewegung höchstens `dur-fast` ohne Schiebung. Dauer 4/5/8 s (B-8); der
// Timer pausiert bei Fokus/Hover und läuft nicht bei `accessibleNavigation`.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import '../../theme/tokens.dart';
import 'cura_pressable.dart';
import 'size_reporter.dart';

/// Warum eine Snackbar endete (für das Rückgängig-Fenster, Ergänzung 1, 3.3).
enum SnackbarCloseReason {
  /// Zeit abgelaufen.
  timeout,

  /// Aktion ausgelöst.
  action,

  /// Nutzer hat sie weggewischt oder mit Escape geschlossen.
  dismissed,

  /// Eine neue Snackbar hat sie ersetzt.
  replaced,

  /// Vom Besitzer geschlossen (Tab-Wechsel, Tageswechsel, Routenwechsel).
  hidden,
}

class CuraSnackbarMessage {
  const CuraSnackbarMessage({
    required this.text,
    this.duration = SnackbarTokens.long,
    this.actionLabel,
    this.actionSemanticsLabel,
    this.onAction,
    this.onClosed,
  }) : assert(actionLabel == null || onAction != null);

  final String text;

  /// 4 s (`short`), 5 s (`medium`) oder 8 s (`long`), Brief B-8.
  final Duration duration;

  /// Sichtbare Aktion („Rückgängig“).
  final String? actionLabel;

  /// Screenreader-Label der Aktion („Eintrag rückgängig machen“).
  final String? actionSemanticsLabel;
  final VoidCallback? onAction;

  /// Wird genau einmal aufgerufen, wenn die Snackbar endet.
  final void Function(SnackbarCloseReason reason)? onClosed;
}

/// Hält die aktuelle Snackbar; eine neue ersetzt die alte.
class SnackbarController extends ChangeNotifier {
  CuraSnackbarMessage? _current;
  int _serial = 0;

  CuraSnackbarMessage? get current => _current;

  /// Zählt jede neue Snackbar (Schlüssel für Animation und Timer).
  int get serial => _serial;

  void show(CuraSnackbarMessage message) {
    final CuraSnackbarMessage? old = _current;
    _current = message;
    _serial++;
    notifyListeners();
    old?.onClosed?.call(SnackbarCloseReason.replaced);
  }

  /// Schließt die aktuelle Snackbar (ohne Wirkung, wenn keine sichtbar ist).
  void close([SnackbarCloseReason reason = SnackbarCloseReason.hidden]) {
    final CuraSnackbarMessage? message = _current;
    if (message == null) return;
    _current = null;
    notifyListeners();
    message.onClosed?.call(reason);
  }

  /// Löst die Aktion aus: erst schließen, dann ausführen (die Aktion darf
  /// selbst eine neue Snackbar zeigen).
  void trigger() {
    final CuraSnackbarMessage? message = _current;
    if (message == null) return;
    close(SnackbarCloseReason.action);
    message.onAction?.call();
  }
}

/// Die sichtbare Fläche (ohne Timer und Positionierung).
class CuraSnackbar extends StatelessWidget {
  const CuraSnackbar({
    super.key,
    required this.text,
    this.actionLabel,
    this.actionSemanticsLabel,
    this.onAction,
  });

  final String text;
  final String? actionLabel;
  final String? actionSemanticsLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final String? action = actionLabel;
    final TextStyle textStyle = type.body.copyWith(color: colors.text1);

    Widget? actionButton;
    if (action != null) {
      actionButton = CuraPressable(
        onPressed: onAction,
        semanticLabel: actionSemanticsLabel ?? action,
        ringRadius: CuraRadius.pill,
        builder: (BuildContext context, bool pressed) {
          return ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: CuraSize.touchTarget,
              minHeight: CuraSize.touchTarget,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: pressed ? colors.pressedOverlay : null,
                borderRadius: BorderRadius.circular(CuraRadius.pill),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CuraComponent.snackbarActionPadding,
                ),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    action,
                    style: type.bodyStrong.copyWith(color: colors.accentHi),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    final Widget message = ExcludeSemantics(
      child: Text(text, style: textStyle),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceOpaque,
        borderRadius: BorderRadius.circular(CuraRadius.snackbar),
        border: Border.all(color: colors.cardBorder, width: CuraSize.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CuraComponent.snackbarPadding),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (actionButton == null) return message;
            // Aktion unter den Text: ab Skalierung 1,3 oder wenn der Text in
            // einer Zeile nicht neben die Aktion passt.
            final TextPainter textPainter = TextPainter(
              text: TextSpan(text: text, style: textStyle),
              textDirection: Directionality.of(context),
              textScaler: scaler,
            )..layout();
            final TextPainter actionPainter = TextPainter(
              text: TextSpan(text: action, style: type.bodyStrong),
              textDirection: Directionality.of(context),
              textScaler: scaler,
            )..layout();
            final double actionWidth =
                actionPainter.width + CuraComponent.snackbarActionPadding * 2;
            final bool below =
                scaler.scale(1) >= SnackbarTokens.actionBelowTextScale ||
                textPainter.width +
                        CuraSpace.s2 +
                        (actionWidth < CuraSize.touchTarget
                            ? CuraSize.touchTarget
                            : actionWidth) >
                    constraints.maxWidth;
            textPainter.dispose();
            actionPainter.dispose();
            if (below) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Align(alignment: Alignment.centerLeft, child: message),
                  actionButton,
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: message),
                const SizedBox(width: CuraSpace.s2),
                actionButton,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Zeigt die Snackbar des [controller]s. Als Ebene über den Inhalt legen
/// (`Positioned.fill`); die Snackbar steht mit 16 dp Seitenrand und
/// [bottomOffset] Abstand zum unteren Rand (Heute: 12 dp über der Oberkante
/// des Nachrichten-Buttons, Onboarding: über der Mikrofon-Zeile).
class SnackbarHost extends StatefulWidget {
  const SnackbarHost({
    super.key,
    required this.controller,
    this.bottomOffset = 0,
    this.onHeightChanged,
  });

  final SnackbarController controller;
  final double bottomOffset;

  /// Meldet die gemessene Höhe der sichtbaren Snackbar (0, wenn keine
  /// sichtbar ist): Heute rechnet die Scroll-Reserve am Listenende damit, damit
  /// die Snackbar den letzten Eintrag nie überdeckt (Plan 4.6).
  final ValueChanged<double>? onHeightChanged;

  @override
  State<SnackbarHost> createState() => _SnackbarHostState();
}

class _SnackbarHostState extends State<SnackbarHost> {
  Timer? _timer;
  int _shownSerial = -1;
  Duration _remaining = Duration.zero;
  bool _hover = false;
  bool _focus = false;
  bool _accessible = false;

  SnackbarController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onController);
  }

  @override
  void didUpdateWidget(SnackbarHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
      _onController();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool accessible = MediaQuery.accessibleNavigationOf(context);
    if (accessible != _accessible) {
      _accessible = accessible;
      _syncTimer();
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onController);
    _timer?.cancel();
    super.dispose();
  }

  void _onController() {
    if (_c.serial != _shownSerial) {
      _shownSerial = _c.serial;
      _remaining = _c.current?.duration ?? Duration.zero;
      _hover = false;
      _focus = false;
    }
    _syncTimer();
    if (!mounted) return;
    if (_c.current == null) widget.onHeightChanged?.call(0);
    // `show` kann mitten im Bauen aufgerufen werden: dann nach dem Frame.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  /// Der Timer läuft nur, solange eine Snackbar da ist, kein Screenreader
  /// aktiv ist und weder Fokus noch Zeiger auf ihr liegen. Er zählt in
  /// Schritten, damit „Pause“ die Restzeit behält.
  void _syncTimer() {
    final bool run = _c.current != null && !_accessible && !_hover && !_focus;
    if (!run) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(CuraComponent.snackbarTick, (Timer t) {
      _remaining -= CuraComponent.snackbarTick;
      if (_remaining <= Duration.zero) {
        t.cancel();
        _timer = null;
        _c.close(SnackbarCloseReason.timeout);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final CuraSnackbarMessage? message = _c.current;
    if (message == null) return const SizedBox.shrink();
    final CuraMotion motion = CuraMotion.of(context);
    final Widget bar = CuraSnackbar(
      text: message.text,
      actionLabel: message.actionLabel,
      actionSemanticsLabel: message.actionSemanticsLabel,
      onAction: message.actionLabel == null ? null : _c.trigger,
    );
    final String? action = message.actionLabel;
    Widget content = Semantics(
      container: true,
      explicitChildNodes: true,
      liveRegion: true,
      label: action == null
          ? message.text
          : S.snackbarWithAction(message.text, action),
      child: bar,
    );
    content = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (bool focused) {
        _focus = focused;
        _syncTimer();
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              _c.close(SnackbarCloseReason.dismissed),
        },
        child: MouseRegion(
          onEnter: (_) {
            _hover = true;
            _syncTimer();
          },
          onExit: (_) {
            _hover = false;
            _syncTimer();
          },
          child: GestureDetector(
            excludeFromSemantics: true,
            onPanEnd: (DragEndDetails d) {
              if (d.velocity.pixelsPerSecond.distance >= kMinFlingVelocity) {
                _c.close(SnackbarCloseReason.dismissed);
              }
            },
            child: content,
          ),
        ),
      ),
    );
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          left: CuraSpace.pageMargin,
          right: CuraSpace.pageMargin,
          bottom: widget.bottomOffset,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: CuraSize.lineLengthMax),
          child: TweenAnimationBuilder<double>(
            key: ValueKey<int>(_c.serial),
            tween: Tween<double>(begin: 0, end: 1),
            duration: motion.duration(MotionTokens.base),
            curve: motion.curve,
            child: SizeReporter(
              onSize: (Size size) => widget.onHeightChanged?.call(size.height),
              child: content,
            ),
            builder: (BuildContext context, double t, Widget? child) {
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    motion.slide(MotionTokens.bubbleSlide) * (1 - t),
                  ),
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
