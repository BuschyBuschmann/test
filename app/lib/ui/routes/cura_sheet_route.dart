// `CuraSheetRoute` (Plan 4.4, A-36): eigene `PopupRoute` statt
// `showModalBottomSheet`. Grund: `showModalBottomSheet` ruft beim Wegwischen
// direkt `Navigator.pop` und umgeht `PopScope`; „Deine Daten“ braucht aber den
// Verwerfen-Dialog auch beim Wischen. Wischen und Scrim-Tipp rufen deshalb
// `maybePop` auf; scheitert das (PopScope), federt das Sheet zurück.
//
// Die Ziehgeste liegt nur auf dem fixen Kopf des Sheets ([CuraSheetFrame.header]),
// nicht auf dem Scrollbereich (kein Gestenkonflikt). Schließen ab 30 % der
// Sheet-Höhe oder bei einem Fling über 700 dp/s nach unten.
//
// Übergang: Schiebung in `dur-base`; bei reduzierter Bewegung nur Einblenden
// in höchstens `dur-fast`. Scrim aus dem Token `scrim`. Die Fläche ist E2
// (`surface-float`, Blur über `CuraBlur`, bei Hoher Kontrast opak).
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../components/cura_blur.dart';

class CuraSheetRoute<T> extends PopupRoute<T> {
  CuraSheetRoute({
    required BuildContext context,
    required this.builder,
    required this.routeLabel,
    super.settings,
  }) : _scrim = CuraColors.of(context).scrim,
       _reduced = CuraMotion.of(context).reduced;

  /// Baut den Inhalt, in der Regel ein [CuraSheetFrame].
  final WidgetBuilder builder;

  /// Routenname für den Screenreader („Deine Daten“, „Wie willst du
  /// trainieren?“).
  final String routeLabel;

  final Color _scrim;
  final bool _reduced;

  @override
  Color? get barrierColor => _scrim;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => S.close;

  @override
  Duration get transitionDuration =>
      _reduced ? CuraMotion.fastDuration : CuraMotion.baseDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: routeLabel,
      child: _SheetPlacement(child: builder(context)),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final Animation<double> curved = animation.drive(
      CurveTween(curve: CuraMotion.easing),
    );
    if (_reduced) return FadeTransition(opacity: curved, child: child);
    return SlideTransition(
      position: curved.drive(
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero),
      ),
      child: child,
    );
  }
}

/// Unten ausgerichtet, höchstens so breit wie die Zeilenlänge, über der
/// Tastatur.
class _SheetPlacement extends StatelessWidget {
  const _SheetPlacement({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: CuraSize.lineLengthMax),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints box) {
                final double maxHeight =
                    box.maxHeight * CuraSize.sheetMaxHeightFraction;
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: child,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Fläche des Sheets (E2) mit festem Kopf, scrollendem Mittelteil und fester
/// Fußleiste. Kopf und Fußleiste scrollen nicht mit. Die Ziehgeste liegt nur
/// auf [header].
class CuraSheetFrame extends StatefulWidget {
  const CuraSheetFrame({
    super.key,
    required this.header,
    required this.body,
    this.footer,
  });

  /// Kopf (Titel, Schließen-Button): hier greift die Wischgeste.
  final Widget header;

  /// Scrollbereich; wird in einen `SingleChildScrollView` gelegt.
  final Widget body;

  /// Fußleiste (z. B. „Speichern“), über Safe Area und Tastatur.
  final Widget? footer;

  @override
  State<CuraSheetFrame> createState() => _CuraSheetFrameState();
}

class _CuraSheetFrameState extends State<CuraSheetFrame>
    with SingleTickerProviderStateMixin {
  final GlobalKey _surfaceKey = GlobalKey();
  late final AnimationController _spring;
  double _drag = 0;
  double _springFrom = 0;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController(vsync: this)
      ..addListener(() {
        setState(() => _drag = _springFrom * (1 - _spring.value));
      });
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  double get _height =>
      math.max(1, _surfaceKey.currentContext?.size?.height ?? 1);

  void _onDragStart(DragStartDetails d) => _spring.stop();

  void _onDragUpdate(DragUpdateDetails d) {
    final double next = _drag + (d.primaryDelta ?? 0);
    setState(() => _drag = next < 0 ? 0 : next);
  }

  Future<void> _onDragEnd(DragEndDetails d) async {
    final bool close =
        d.velocity.pixelsPerSecond.dy > CuraSize.sheetFlingVelocity ||
        _drag >= CuraSize.sheetCloseFraction * _height;
    if (close) {
      final NavigatorState navigator = Navigator.of(context);
      final Route<dynamic>? route = ModalRoute.of(context);
      await navigator.maybePop();
      // Blockiert ein PopScope das Schließen (Verwerfen-Dialog), bleibt die
      // Route aktiv: das Sheet federt zurück.
      if (!mounted || route == null || !route.isActive) return;
    }
    _springBack();
  }

  void _springBack() {
    if (_drag == 0) return;
    final CuraMotion motion = CuraMotion.of(context);
    if (motion.reduced) {
      setState(() => _drag = 0);
      return;
    }
    _springFrom = _drag;
    _spring.duration = CuraMotion.baseDuration;
    _spring.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    const BorderRadius shape = BorderRadius.vertical(
      top: Radius.circular(CuraRadius.sheet),
    );
    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: colors.shadowsEnabled ? CuraShadow.floating : null,
      ),
      child: CuraBlur(
        borderRadius: shape,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.floatFill,
            borderRadius: shape,
            border: Border.all(
              color: colors.cardBorder,
              width: CuraSize.hairline,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: _onDragStart,
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
                child: widget.header,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CuraSpace.pageMargin,
                  ),
                  child: widget.body,
                ),
              ),
              if (widget.footer != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(CuraSpace.pageMargin),
                    child: widget.footer,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return Transform.translate(
      offset: Offset(0, _drag),
      child: KeyedSubtree(key: _surfaceKey, child: surface),
    );
  }
}
