// Gerüst der Schritte des Code-Starts und der Vollbild-Hinweise (Brief-
// Ergänzung 2, A1): Kopf-Karte mit Titel (und „Schritt N von M“), darunter der
// scrollende Inhalt, unten fest die Knöpfe. Bei großer Schrift (über 130 %)
// stehen die Knöpfe am Ende des Inhalts, damit der Scrollbereich Platz behält
// (V2-87, V2-118). Keine Leiste (V2-19). Alle Texte stehen auf Karten oder der
// Kopf-Karte (V2-5).
import 'package:flutter/material.dart';

import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../components/header_card.dart';
import '../components/probe_keys.dart';
import '../components/screen_frame.dart';
import '../components/step_progress.dart';

class StartStepScaffold extends StatelessWidget {
  const StartStepScaffold({
    super.key,
    required this.title,
    required this.children,
    this.primary,
    this.secondary,
    this.secondaryBeside = false,
    this.step,
    this.total,
    this.subtitle,
    this.onBack,
    this.overlays = const <Widget>[],
    this.scrollController,
  });

  final String title;
  final String? subtitle;

  /// „Schritt [step] von [total]“; ohne Angabe kein Fortschritt (Hinweise).
  final int? step;
  final int? total;
  final List<Widget> children;

  /// Hauptknopf: immer fest unten (auch bei großer Schrift erreichbar).
  final Widget? primary;

  /// Zweiter Knopf („Zurück“, „Nicht einverstanden“): neben bzw. unter dem
  /// Hauptknopf; bei Schrift über 130 % am Ende des Inhalts, damit der
  /// Scrollbereich Platz behält (V2-87, V2-118).
  final Widget? secondary;

  /// `true`: links neben dem Hauptknopf (Zurück), sonst darunter.
  final bool secondaryBeside;

  /// System-Zurück; `null` = nichts (die App bleibt stehen).
  final VoidCallback? onBack;
  final List<Widget> overlays;
  final ScrollController? scrollController;

  Widget _bar(bool largeText) {
    final Widget main = primary!;
    final Widget? other = largeText ? null : secondary;
    if (other == null) return main;
    if (secondaryBeside) {
      return Row(
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: CuraSize.onboardingBackWidth,
            ),
            child: other,
          ),
          const SizedBox(width: CuraSize.onboardingButtonGap),
          Expanded(child: main),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        main,
        const SizedBox(height: CuraSpace.s3),
        other,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData m = MediaQuery.of(context);
    final bool largeText =
        m.textScaler.scale(CuraSize.textScaleUnit) >
        CuraComponent.codeMaxTextScale;
    final double rest =
        m.size.height - m.padding.vertical - m.viewInsets.bottom;
    final bool headerScrolls =
        m.textScaler.scale(CuraSize.textScaleUnit) >=
            CuraSize.textScaleScrollAlong ||
        rest < CuraSize.onboardingHeaderScrollMaxHeight;
    final Widget header = Padding(
      key: headerScrolls ? ProbeKeys.scrollHeader : ProbeKeys.header,
      padding: const EdgeInsets.fromLTRB(
        CuraSize.cardMargin,
        CuraSpace.s2,
        CuraSize.cardMargin,
        CuraSpace.s2,
      ),
      child: HeaderCard(
        top: step == null
            ? null
            : Semantics(
                container: true,
                child: StepProgress(
                  step: step!,
                  total: total!,
                  onHeaderCard: true,
                ),
              ),
        title: title,
        subtitle: subtitle,
      ),
    );
    final double safeBottom = m.padding.bottom;
    final Widget scroll = SingleChildScrollView(
      key: ProbeKeys.scroll,
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: CuraSpace.pageMargin),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (headerScrolls) header,
          Padding(
            padding: const EdgeInsets.fromLTRB(
              CuraSize.cardMargin,
              CuraSpace.s2,
              CuraSize.cardMargin,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < children.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: CuraSpace.s3),
                  children[i],
                ],
                if (largeText && secondary != null) ...<Widget>[
                  const SizedBox(height: CuraSpace.s4),
                  secondary!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
    Widget body = ScreenFrame(
      overlays: overlays,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!headerScrolls) header,
            Expanded(child: scroll),
            if (primary != null)
              KeyedSubtree(
                key: ProbeKeys.primaryRow,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    CuraSize.cardMargin,
                    CuraSpace.s2,
                    CuraSize.cardMargin,
                    safeBottom > CuraSpace.pageMargin
                        ? safeBottom
                        : CuraSpace.pageMargin,
                  ),
                  child: _bar(largeText),
                ),
              ),
          ],
        ),
      ),
    );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) onBack?.call();
      },
      child: body,
    );
  }
}
