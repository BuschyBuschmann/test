// `StatPill` (Brief 5.9, Plan 9): Pille der Pfad-Kopfzeile, Freeze
// (Schneeflocke plus Zahl) und Streak (Flamme plus Zahl, bei „eingefroren“ mit
// dem Wort daneben); der Screenreader liest ein Label („Streak: 12 Tage“,
// „Streak-Freezes: 2“). Fläche `surface-opaque` mit Rand `border-hair`
// (Hoher Kontrast `border-control-hc`), also deckend und glowfrei.
//
// Ohne [onPressed] reine Information (B-8). Mit [onPressed] (SK-1: Tipp erklärt
// den Chip) eine Schaltfläche: Hit-Area mindestens 48 dp hoch (die sichtbare
// Pille bleibt, wie sie ist), Fokusring, Pressed-Füllung, Semantik als
// Schaltfläche. [onPressed] bekommt das Rechteck der Pille in globalen
// Koordinaten (Anker für den Hinweis): waagerecht die sichtbare Pille,
// senkrecht die Hit-Area (der Hinweis darf kein Ziel überdecken).
//
// Abstand der Ziele (mindestens 8 dp, Brief 3.4): Die Hit-Area ist um
// [hitInset] je Seite **schmaler** als die sichtbare Pille (sie bleibt mit
// ≥ 52 dp breit genug). So rücken die Pillen nicht auseinander, und die Ziele
// liegen trotzdem 8 dp und mehr auseinander. Der Aufrufer legt die Boxen mit
// [boxGap] (zwischen zwei Pillen) bzw. `statPillGap + hitInset` (zu einem
// Nachbarn) auseinander, die sichtbaren Abstände bleiben dann 4 dp.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'cura_pressable.dart';
import 'opaque_surface.dart';

class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.semanticLabel,
    this.valueColor,
    this.extra,
    this.extraColor,
    this.onPressed,
  });

  final IconData icon;
  final Color iconColor;

  /// Die Zahl.
  final String value;
  final Color? valueColor;

  /// Zusatzwort rechts der Zahl („eingefroren“): Text, nicht nur Farbe.
  final String? extra;
  final Color? extraColor;

  /// Label für den Screenreader (ersetzt den sichtbaren Inhalt).
  final String semanticLabel;

  /// `null` = reine Information; sonst Tipp auf die Pille (Erklärung).
  final ValueChanged<Rect>? onPressed;

  /// Um so viel ist die Hit-Area je Seite schmaler als die sichtbare Pille
  /// (nur mit `onPressed`).
  static const double hitInset = CuraSpace.s1;

  /// Abstand zweier Pillen-Boxen für sichtbar `statPillGap`.
  static const double boxGap = CuraSize.statPillGap + 2 * hitInset;

  /// Breite, die die Pille bei der aktuellen Textskalierung einnimmt (für die
  /// Entscheidung zwischen Zeilen- und Umbruch-Layout der Kopfzeile).
  static double measureWidth(
    BuildContext context, {
    required String value,
    String? extra,
  }) {
    final CuraTypography type = CuraTypography.of(context);
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    double text(String s, TextStyle style) {
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: s,
          style: DefaultTextStyle.of(context).style.merge(style),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      final double w = tp.width;
      tp.dispose();
      return w;
    }

    double w =
        2 * CuraSize.statPillPaddingH +
        CuraSize.statPillIcon +
        CuraSize.statPillGap +
        text(value, type.numeral);
    if (extra != null) {
      w += CuraSize.statPillGap + text(extra, type.secondary);
    }
    return w;
  }

  @override
  Widget build(BuildContext context) {
    final ValueChanged<Rect>? onPressed = this.onPressed;
    if (onPressed == null) {
      return Semantics(
        container: true,
        label: semanticLabel,
        excludeSemantics: true,
        child: _pill(context, pressed: false),
      );
    }
    final GlobalKey pillKey = GlobalKey();
    final GlobalKey targetKey = GlobalKey();
    return CuraPressable(
      semanticLabel: semanticLabel,
      onPressed: () {
        final RenderObject? pill = pillKey.currentContext?.findRenderObject();
        final RenderObject? target = targetKey.currentContext
            ?.findRenderObject();
        if (pill is! RenderBox || !pill.attached) return;
        if (target is! RenderBox || !target.attached) return;
        final Rect p = pill.localToGlobal(Offset.zero) & pill.size;
        final Rect t = target.localToGlobal(Offset.zero) & target.size;
        onPressed(Rect.fromLTRB(p.left, t.top, p.right, t.bottom));
      },
      builder: (BuildContext context, bool pressed) => KeyedSubtree(
        key: targetKey,
        child: _TargetBox(
          inset: hitInset,
          minWidth: CuraSize.touchTarget,
          minHeight: CuraSize.touchTarget,
          child: KeyedSubtree(
            key: pillKey,
            child: _pill(context, pressed: pressed),
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, {required bool pressed}) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    final BorderRadius radius = BorderRadius.circular(CuraRadius.pill);
    final Widget pill = OpaqueSurface(
      borderRadius: radius,
      padding: const EdgeInsets.symmetric(
        horizontal: CuraSize.statPillPaddingH,
        vertical: CuraSize.statPillPaddingV,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: CuraSize.statPillIcon, color: iconColor),
          const SizedBox(width: CuraSize.statPillGap),
          Text(
            value,
            style: type.numeral.copyWith(color: valueColor ?? colors.text1),
          ),
          if (extra != null) ...<Widget>[
            const SizedBox(width: CuraSize.statPillGap),
            Flexible(
              child: Text(
                extra!,
                style: type.secondary.copyWith(
                  color: extraColor ?? colors.text2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    if (!pressed) return pill;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        color: colors.pressedOverlay,
        borderRadius: radius,
      ),
      child: pill,
    );
  }
}

/// Trefferfläche um die Pille: mindestens [minWidth] breit und [minHeight]
/// hoch, sonst je Seite um [inset] schmaler als das Kind. Das Kind steht mittig und ragt seitlich
/// heraus (gemalt, nicht treffbar).
class _TargetBox extends SingleChildRenderObjectWidget {
  const _TargetBox({
    required this.inset,
    required this.minWidth,
    required this.minHeight,
    required Widget super.child,
  });

  final double inset;
  final double minWidth;
  final double minHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTargetBox(inset, minWidth, minHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderTargetBox render) {
    render
      ..inset = inset
      ..minWidth = minWidth
      ..minHeight = minHeight;
  }
}

class _RenderTargetBox extends RenderShiftedBox {
  _RenderTargetBox(this._inset, this._minWidth, this._minHeight) : super(null);

  double _inset;
  double _minWidth;
  double _minHeight;

  set inset(double v) {
    if (v == _inset) return;
    _inset = v;
    markNeedsLayout();
  }

  set minWidth(double v) {
    if (v == _minWidth) return;
    _minWidth = v;
    markNeedsLayout();
  }

  set minHeight(double v) {
    if (v == _minHeight) return;
    _minHeight = v;
    markNeedsLayout();
  }

  Size _sizeFor(Size child, BoxConstraints constraints) {
    final double narrower = _inset + _inset;
    return constraints.constrain(
      Size(
        math.max(_minWidth, child.width - narrower),
        math.max(child.height, _minHeight),
      ),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final RenderBox? c = child;
    if (c == null) return constraints.constrain(Size(_minWidth, _minHeight));
    return _sizeFor(c.getDryLayout(constraints.loosen()), constraints);
  }

  @override
  void performLayout() {
    final RenderBox? c = child;
    if (c == null) {
      size = constraints.constrain(Size(_minWidth, _minHeight));
      return;
    }
    c.layout(constraints.loosen(), parentUsesSize: true);
    size = _sizeFor(c.size, constraints);
    (c.parentData! as BoxParentData).offset = Offset(
      (size.width - c.size.width) / 2,
      (size.height - c.size.height) / 2,
    );
  }
}
