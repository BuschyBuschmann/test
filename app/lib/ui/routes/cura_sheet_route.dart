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
// in höchstens `dur-fast`. Scrim aus dem Token `scrim`. Die Fläche ist das
// `Sheet` des Briefs v2 (4, 3.5): `card` zu 100 % opak, **ohne Blur**, Radius
// 32 oben, Griff, Schließen-Schaltfläche 48 dp (im Kopf des Besitzers); der
// Fokus bleibt im Sheet (modale Route).
import 'dart:math' as math;

import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';

import '../../l10n/strings_de.dart';
import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_motion.dart';
import '../../theme/cura_roles.dart';

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

/// Lage des Sheets für seinen Inhalt: [compact] gilt, wenn über der Tastatur
/// (bzw. im Querformat) wenig Platz bleibt. Das Sheet nimmt dann den ganzen
/// Platz, sein Kopf läuft mit dem Inhalt (wie im Onboarding), nur die Fußleiste
/// mit der Hauptaktion bleibt fest.
class CuraSheetScope extends InheritedWidget {
  const CuraSheetScope({
    super.key,
    required this.compact,
    required this.keyboardVisible,
    required super.child,
  });

  final bool compact;

  /// Die Tastatur ist eingeblendet. Der Inhalt sieht sie selbst nicht mehr: die
  /// Route zieht ihre Höhe vor dem Aufbau des Inhalts ab.
  final bool keyboardVisible;

  /// `false` ohne Scope (Sheet-Rahmen außerhalb der Route, z. B. in Tests).
  static bool compactOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CuraSheetScope>()?.compact ??
      false;

  static bool keyboardVisibleOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CuraSheetScope>()
          ?.keyboardVisible ??
      false;

  @override
  bool updateShouldNotify(CuraSheetScope oldWidget) =>
      compact != oldWidget.compact ||
      keyboardVisible != oldWidget.keyboardVisible;
}

/// Unten ausgerichtet, höchstens so breit wie die Zeilenlänge, über der
/// Tastatur. Ein durchsichtiges `Material` darunter liefert den
/// Standard-Textstil und den Untergrund für Eingabefelder; es malt nichts.
/// (Ohne es fallen Texte ohne eigenen Stil auf die gelb unterstrichene
/// Ersatzschrift zurück.)
class _SheetPlacement extends StatelessWidget {
  const _SheetPlacement({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: CuraSize.lineLengthMax),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints box) {
                  // Wenig Platz (Tastatur, Querformat): das Sheet nimmt alles,
                  // Kopf und Inhalt scrollen zusammen. Sonst höchstens 90 %
                  // und nicht näher als `sheetTopClearance` an der Oberkante.
                  final bool compact =
                      box.maxHeight < CuraSize.sheetCompactAvailHeight;
                  final double maxHeight = compact
                      ? box.maxHeight
                      : math.min(
                          box.maxHeight * CuraSize.sheetMaxHeightFraction,
                          box.maxHeight - CuraSize.sheetTopClearance,
                        );
                  return CuraSheetScope(
                    compact: compact,
                    keyboardVisible: media.viewInsets.bottom > 0,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxHeight),
                      child: child,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fläche des Sheets mit Griff, festem Kopf, scrollendem Mittelteil und fester
/// Fußleiste. Kopf und Fußleiste scrollen nicht mit. Die Ziehgeste liegt nur
/// auf Griff und [header]. Die Fläche ist immer opak (`card` 100 %, kein Blur,
/// V2-11).
///
/// Im kompakten Zustand ([CuraSheetScope.compact]: wenig Platz über der
/// Tastatur) läuft der Kopf als erstes Element mit dem Inhalt (ohne Griff); die
/// Fußleiste bleibt fest, ihr Rand ist enger.
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
  final GlobalKey _contentKey = GlobalKey();
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
    final bool compact = CuraSheetScope.compactOf(context);
    const BorderRadius shape = BorderRadius.vertical(
      top: Radius.circular(CuraRadius.sheet),
    );
    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: colors.shadowsEnabled ? CuraShadow.floating : null,
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceOpaque,
            borderRadius: shape,
            border: Border.all(
              color: colors.cardBorder,
              width: CuraSize.hairline,
            ),
          ),
          // Der Inhalt behält sein Element beim Wechsel zwischen normal und
          // kompakt (Tastatur erscheint): sonst verlöre das gerade fokussierte
          // Feld Fokus und Eingabeverbindung. Dafür der GlobalKey und gleiche
          // Kindpositionen in beiden Zuständen (Platzhalter statt `if`).
          child: KeyedSubtree(
            key: _contentKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (compact)
                  const SizedBox.shrink()
                else
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // Die Wischgeste ist kein Bedienweg für den Screenreader
                    // („Schließen“ ist eine eigene Schaltfläche); ohne
                    // Ausschluss würde der Kopf zu einem scrollenden Knoten.
                    excludeFromSemantics: true,
                    onVerticalDragStart: _onDragStart,
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[const _SheetHandle(), widget.header],
                    ),
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Das kompakte Sheet reicht bis an den oberen Rand: der
                        // Kopf rückt unter die Statusleiste (F-6).
                        if (compact)
                          Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.paddingOf(context).top,
                            ),
                            child: widget.header,
                          )
                        else
                          const SizedBox.shrink(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CuraSpace.pageMargin,
                          ),
                          child: widget.body,
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.footer != null)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.all(
                        compact ? CuraSpace.s2 : CuraSpace.pageMargin,
                      ),
                      child: widget.footer,
                    ),
                  ),
              ],
            ),
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

/// Griff oben am Sheet (Brief 4): 36 × 4 dp, reine Zier (kein Screenreader-
/// Knoten); „Schließen“ ist eine eigene Schaltfläche im Kopf.
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: CuraSpace.s2),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.sheetHandle,
              borderRadius: BorderRadius.circular(CuraRadius.pill),
            ),
            child: const SizedBox(
              width: CuraSize.sheetHandleWidth,
              height: CuraSize.sheetHandleHeight,
            ),
          ),
        ),
      ),
    );
  }
}
