// `CuraDialog` (Brief v2, 4; Ergänzung 1, Abschnitt 2): Bestätigungsdialog.
// Fläche `card` zu 100 % opak (`surface-opaque`), Rand `border-hair` (Hoher
// Kontrast `-hc`), Radius 28, Scrim `ink-1` 45 % (Route), Abbrechen immer
// vorhanden, Warn-Dialoge neutral (kein Mandarine als Statusfarbe),
// Breite Bildschirm minus 32 dp (höchstens 400 dp), Icon 28 dp `text-1`,
// Titel `title`, Text `body`, Buttons gestapelt in voller Breite (56 dp,
// Abstand 8 dp). Der Inhalt scrollt, wenn er nicht passt; die Buttons bleiben
// unten sichtbar. Kein Blur, kein Skalieren, kein Glow. Scrim, Einblenden und
// Routennamen liefert die `CuraDialogRoute` (U2b); hier steht die Semantik
// `alertdialog` und der Titel benennt die Route.
//
// Braucht eine begrenzte Höhe vom Elternelement (die Route stellt sie). Ist sie
// kleiner als `CuraSize.dialogCompactMaxHeight` (kleines Gerät mit Tastatur,
// Querformat) **oder** die Textskalierung mindestens 1,5, scrollt der ganze
// Dialog samt Buttons: bei fest unten stehenden Buttons bliebe sonst für
// Eingabefelder bzw. den Text kein sichtbarer Platz (F-4). Ab 1,5 skaliert der
// Titel höchstens mit 1,5, die Buttons zeigen kein Symbol, und ein Zusatz
// (Fehlerhinweis) steht gleich unter dem Titel, damit er ohne Scrollen zu
// sehen ist.
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';

import '../../theme/cura_colors.dart';
import '../../theme/cura_metrics.dart';
import '../../theme/cura_roles.dart';
import '../../theme/cura_typography.dart';
import 'pill_button.dart';

class CuraDialog extends StatefulWidget {
  const CuraDialog({
    super.key,
    required this.title,
    required this.actions,
    this.message,
    this.icon,
    this.extra,
  });

  final String title;

  /// Erklärender Text unter dem Titel; entfällt bei Dialogen, die nur Felder
  /// zeigen (Eigene Übung).
  final String? message;

  /// Buttons (`PillButton`s), von oben nach unten: die sichere Aktion zuerst.
  final List<Widget> actions;
  final IconData? icon;

  /// Zusatzinhalt unter dem Text (z. B. Fehlerhinweis), scrollt mit.
  final Widget? extra;

  @override
  State<CuraDialog> createState() => _CuraDialogState();
}

class _CuraDialogState extends State<CuraDialog> {
  final ScrollController _scroll = ScrollController();
  final FocusNode _extraFocus = FocusNode(
    debugLabel: 'Dialog-Hinweis',
    skipTraversal: true,
  );

  /// Der Dialog scrollt als Ganzes (kompakt): Buttons liegen dann nicht
  /// zwingend im Bild.
  bool _compact = false;

  String get title => widget.title;
  String? get message => widget.message;
  List<Widget> get actions => widget.actions;
  IconData? get icon => widget.icon;
  Widget? get extra => widget.extra;

  @override
  void dispose() {
    _scroll.dispose();
    _extraFocus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CuraDialog old) {
    super.didUpdateWidget(old);
    // Erscheint ein Zusatz (Fehlerhinweis) und steht der gescrollte Dialog
    // weiter unten (der Nutzer tippte einen Button am Ende), springt er an den
    // Anfang, damit der Hinweis ohne Scrollen zu sehen ist (F-4). Der Fokus
    // zog dabei mit dem Button aus dem Bild: Bei einem scrollenden Dialog geht
    // er auf den Hinweis (Live-Region sagt ihn an); der Button bleibt per Tab
    // erreichbar (N-3). Passt alles ins Bild, bleibt der Fokus am Button.
    if (old.extra == null && widget.extra != null && _compact) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scroll.hasClients) _scroll.jumpTo(0);
        _extraFocus.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final CuraColors colors = CuraColors.of(context);
    final CuraTypography type = CuraTypography.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: CuraSpace.pageMargin),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: CuraSize.dialogMaxWidth),
        child: Semantics(
          role: SemanticsRole.alertDialog,
          scopesRoute: true,
          explicitChildNodes: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceOpaque,
              borderRadius: BorderRadius.circular(CuraRadius.dialog),
              border: Border.all(
                color: colors.cardBorder,
                width: CuraSize.hairline,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(CuraComponent.dialogPadding),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints box) {
                  final bool largeText =
                      MediaQuery.textScalerOf(context)
                          .scale(CuraSize.hairline) >=
                      CuraSize.textScaleDialogCompact;
                  final bool compact =
                      largeText ||
                      (box.hasBoundedHeight &&
                          box.maxHeight + CuraComponent.dialogPadding * 2 <
                              CuraSize.dialogCompactMaxHeight);
                  _compact = compact;
                  final Widget content = _content(
                    context,
                    colors,
                    type,
                    extraFirst: compact,
                  );
                  final Widget buttons = PillButtonDialogScope(
                    child: _buttons(),
                  );
                  return SizedBox(
                    width: double.infinity,
                    child: compact
                        ? SingleChildScrollView(
                            controller: _scroll,
                            // Etwas Rand im Scrollbereich: Fokusring und
                            // Doppelrand der Buttons werden sonst seitlich
                            // abgeschnitten (R-1).
                            padding: const EdgeInsets.all(CuraSpace.s1),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                content,
                                const SizedBox(
                                  height: CuraComponent.dialogPadding,
                                ),
                                buttons,
                              ],
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Flexible(
                                child: SingleChildScrollView(
                                  controller: _scroll,
                                  child: content,
                                ),
                              ),
                              const SizedBox(
                                height: CuraComponent.dialogPadding,
                              ),
                              buttons,
                            ],
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

  Widget _content(
    BuildContext context,
    CuraColors colors,
    CuraTypography type, {
    required bool extraFirst,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          ExcludeSemantics(
            child: Icon(
              icon,
              size: CuraComponent.dialogIconSize,
              color: colors.text1,
            ),
          ),
          const SizedBox(height: CuraComponent.dialogGap),
        ],
        Semantics(
          namesRoute: true,
          header: true,
          // Der Titel skaliert höchstens mit 150 % (F-4, B3).
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: CuraSize.headerTitleMaxTextScale,
            child: Text(title, style: type.title.copyWith(color: colors.text1)),
          ),
        ),
        if (extra != null && extraFirst) ...<Widget>[
          const SizedBox(height: CuraComponent.dialogGap),
          Focus(focusNode: _extraFocus, child: extra!),
        ],
        if (message != null) ...<Widget>[
          const SizedBox(height: CuraComponent.dialogGap),
          Text(message!, style: type.body.copyWith(color: colors.text1)),
        ],
        if (extra != null && !extraFirst) ...<Widget>[
          const SizedBox(height: CuraComponent.dialogGap),
          Focus(focusNode: _extraFocus, child: extra!),
        ],
      ],
    );
  }

  Widget _buttons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < actions.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: CuraSpace.s2),
          actions[i],
        ],
      ],
    );
  }
}
