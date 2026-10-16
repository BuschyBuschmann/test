// Szenario-Registry der Prüfumgebung (Plan 3, 12.4, 12.5). Ein Szenario ist
// ein benannter Bildschirminhalt (hier: Baustein-Tafeln aus U2a; die
// Zustandsliste 12.4 füllen die Pakete U2b bis U4 nach). Dieselbe Registry
// dient der Matrix (`test/matrix/`), den Goldens und `main_preview` im
// Browser (`?scenario=<id>`).
//
// Marker-Schlüssel (`PreviewKeys`) bezeichnen Elemente, die die Prüfungen
// brauchen: Overlays (Nav, Button-Gruppe, Snackbar, Primärbutton-Reihe),
// Kopf, den Hauptscrollbereich, den Primärbutton und Messpunkte für die
// Pipette. Fehlt ein Marker, entfällt die jeweilige Prüfung.
import 'package:flutter/material.dart';

import '../l10n/strings_de.dart';
import '../logic/app_state.dart';
import '../logic/clock.dart';
import '../logic/day_program.dart';
import '../logic/manny_look.dart';
import '../logic/manny_state.dart';
import '../logic/path_generator.dart';
import '../logic/path_model.dart';
import '../logic/placeholder_pools.dart';
import '../logic/plural.dart';
import '../logic/streak.dart';
import '../logic/injury_type.dart';
import '../theme/cura_colors.dart';
import '../theme/cura_metrics.dart';
import '../theme/cura_typography.dart';
import '../theme/tokens.dart' show BlurTokens;
import '../ui/components/choice_card.dart';
import '../ui/components/content_frame.dart';
import '../ui/components/cura_dialog.dart';
import '../ui/components/cura_label.dart';
import '../ui/components/cura_snackbar.dart';
import '../ui/components/cura_text_field.dart';
import '../ui/components/date_card.dart';
import '../ui/components/floating_nav.dart';
import '../ui/components/glass_card.dart';
import '../ui/components/header_icon_button.dart';
import '../ui/components/manny.dart';
import '../ui/components/manny_bubble.dart';
import '../ui/components/manny_chat_button.dart';
import '../ui/components/manny_look_picker.dart';
import '../ui/components/mic_button.dart';
import '../ui/components/pill_button.dart';
import '../ui/components/probe_keys.dart';
import '../ui/components/step_progress.dart';
import '../ui/components/world_background.dart';
import '../ui/messages/example_contacts.dart';
import 'preview_script.dart'
    show
        kPreviewScrollDialogEnd,
        kPreviewScrollEnd,
        kPreviewScrollSheetEnd,
        kPreviewScrollStart;
import 'preview_texts.dart';

/// Marker für die Prüfungen. Namen mit Präfix `overlay:` zählen als Overlay
/// (schwebt über dem Inhalt), `probe:` als Messpunkt für die Pipette.
abstract final class PreviewKeys {
  static const ValueKey<String> nav = ProbeKeys.nav;
  static const ValueKey<String> mannyButton = ProbeKeys.mannyButton;
  static const ValueKey<String> primaryRow = ProbeKeys.primaryRow;
  static const ValueKey<String> bubble = ProbeKeys.bubble;
  static const ValueKey<String> hint = ProbeKeys.hint;
  static const ValueKey<String> keyboard = ProbeKeys.keyboard;
  static const ValueKey<String> chatFooter = ProbeKeys.chatFooter;
  static const ValueKey<String> header = ProbeKeys.header;
  static const ValueKey<String> scroll = ProbeKeys.scroll;
  static const ValueKey<String> primary = ProbeKeys.primary;
  static const ValueKey<String> probeBackground = ProbeKeys.probeBackground;
  static const ValueKey<String> probePrimary = ProbeKeys.probePrimary;
  static const ValueKey<String> probeTitle = ProbeKeys.probeTitle;
}

/// Umgebung, die `main_preview` bzw. die Matrix dem Szenario mitgibt.
class ScenarioEnv {
  const ScenarioEnv({required this.now});

  /// Ortszeit der Fake-Uhr (URL-Parameter `now`).
  final DateTime now;

  /// Standard-Fixture (Plan 6.4): Mittwoch, 2026-10-07, 12:00.
  static final DateTime defaultNow = DateTime(2026, 10, 7, 12);
}

typedef ScenarioBuilder = Widget Function(
  BuildContext context,
  ScenarioEnv env,
);

/// Wie sich der Pfad-Tab eines App-Szenarios lädt (`path-loading`,
/// `path-error`); sonst sofort bereit.
enum PathSeedMode { ready, loading, error }

/// Wie sich der Tab Heute eines App-Szenarios lädt (`today-loading`,
/// `today-error`); sonst sofort bereit.
enum TodaySeedMode { ready, loading, error }

/// Wie sich „Alles löschen“ eines App-Szenarios verhält: gewöhnlich, langsam
/// (der Vorgang endet nie: `data-delete-busy`) oder mit Fehler
/// (`data-delete-error`).
enum DeleteSeedMode { normal, slow, failing }

/// Zustand einer **App-Szenarios** (Plan 12.4: `ob*`, `shell-*`): die echte
/// App (`CuraApp` mit StartGate, Routen und Speicher) startet mit diesem
/// Speicher. So laufen Matrix und Screenshots durch denselben Code wie die
/// Produktion.
class AppSeed {
  const AppSeed({
    this.state,
    this.unreadable = false,
    this.deleteFirst = false,
    this.loadError = false,
    this.focusField = false,
    this.taps = const <String>[],
    this.now,
    this.pathMode = PathSeedMode.ready,
    this.todayMode = TodaySeedMode.ready,
    this.scrollPathToEnd = false,
    this.daysAfterTaps = 0,
    this.deleteMode = DeleteSeedMode.normal,
  });

  /// Verhalten des Löschens (Löschdialog-Szenarien).
  final DeleteSeedMode deleteMode;

  /// Ladezustand des Tabs Heute.
  final TodaySeedMode todayMode;

  /// Nach den Tipps springt die Szenario-Uhr um so viele Kalendertage weiter
  /// und die Shell prüft den Tageswechsel wie nach einem Fortsetzen der App
  /// (`today-newday-snackbar`).
  final int daysAfterTaps;

  /// Uhrzeit der Fake-Uhr dieses Szenarios; `null` = die der Umgebung
  /// (`ScenarioEnv.now`). Z. B. 19:00 Uhr für die Streak-Gefahr-Blase.
  final DateTime? now;

  /// Ladezustand des Pfad-Tabs.
  final PathSeedMode pathMode;

  /// Der Hauptscrollbereich (Marker `scroll`: Pfad bzw. Liste von Heute) wird
  /// nach dem Start bis ans Ende gescrollt (unterste Unit bzw. letzter Eintrag
  /// über die Button-Gruppe geschoben).
  final bool scrollPathToEnd;

  /// Gespeicherter Zustand; `null` = Erststart (nichts gespeichert).
  final AppState? state;

  /// Der Speicher liefert unlesbaren Inhalt (N-12): Neustart mit Hinweis.
  final bool unreadable;

  /// Nach dem Laden läuft „Alles löschen“ (echter Löschweg): Onboarding
  /// Schritt 1 mit dem Hinweis „Alle Daten sind gelöscht.“.
  final bool deleteFirst;

  /// Der Speicher wirft beim Lesen einen Plattformfehler: StartGate-Fehler.
  final bool loadError;

  /// Nach den Tipps wird das erste Textfeld fokussiert (Tastatur-Szenarien):
  /// das Feld hat den Fokus und ist, wie in der echten App, in den Blick
  /// gescrollt.
  final bool focusField;

  /// Screenreader-Labels von Bausteinen, die nach dem Start „getippt“ werden;
  /// [kPreviewScrollEnd] scrollt an dieser Stelle den sichtbaren Hauptbereich
  /// ans Ende.
  final List<String> taps;
}

typedef AppSeedBuilder = AppSeed Function(ScenarioEnv env);

class Scenario {
  const Scenario({
    required this.id,
    this.builder,
    this.app,
    this.maxBackdrops = BlurTokens.maxPerScreen,
    this.expectsPrimary = false,
    this.expectsNav = false,
    this.expectsMannyButton = false,
    this.expectsHeader = false,
    this.expectsChatFooter = false,
    this.tablet = false,
    this.keyboard = false,
    this.loops = false,
    this.fixedTextScale,
  }) : assert(
         (builder == null) != (app == null),
         'Genau eines von builder und app',
       );

  /// Kennung für URL (`?scenario=`), Tests und Screenshot-Dateien.
  final String id;

  /// Baustein-Szenario: ein Widget im Gerüst der Prüfumgebung.
  final ScenarioBuilder? builder;

  /// App-Szenario: die echte App mit diesem Speicher (siehe [AppSeed]).
  final AppSeedBuilder? app;

  /// Obergrenze `BackdropFilter` (Pfad/Heute 2, Chat/Nachrichten 0, UI-6).
  final int maxBackdrops;

  /// Das Szenario enthält den Primärbutton ([PreviewKeys.primary]); die
  /// Matrix prüft ihn dann auf Sichtbarkeit und Treffbarkeit.
  final bool expectsPrimary;

  /// Das Szenario enthält eine dauerhaft laufende Animation (Fortschrittskreis):
  /// kein `pumpAndSettle`, und bei „Bewegung reduzieren“ sind genau diese
  /// Fortschrittsanzeigen als laufende Animation erlaubt.
  final bool loops;

  /// Das Szenario enthält Nav, Manny-Knopf, Kopf bzw. Chat-Fuß mit dem
  /// jeweiligen Marker (`overlay:nav`, `overlay:manny-button`, `header`,
  /// `overlay:chat-footer`). Fehlt der Marker, ist das ein harter Befund der
  /// Matrix; ohne Flag würde die jeweilige Prüfung still entfallen.
  final bool expectsNav;
  final bool expectsMannyButton;
  final bool expectsHeader;
  final bool expectsChatFooter;

  /// Fester Wert der Textskalierung (1,5 für `chat-manny-scale15` und
  /// `messages-scale15`, Fuß-Regel ab 1,5): überstimmt `scale` aus der URL.
  /// Die Matrix prüft solche Szenarien nur mit diesem Wert.
  final double? fixedTextScale;

  /// Zusätzlich bei 768 × 1024 prüfen (ContentFrame, Plan 12.2).
  final bool tablet;

  /// Tastatur-Szenario (Plan 12.4, B-10): die Prüfumgebung blendet eine
  /// Tastatur von 300 dp ein (`viewInsets.bottom` plus Platzhalterfläche mit
  /// dem Marker `overlay:keyboard`) und das Szenario fokussiert sein Textfeld.
  /// Die Matrix prüft es bei **allen** Viewports und Skalierungen ohne
  /// Ausnahme: das fokussierte Feld muss sichtbar, der Inhalt erreichbar sein.
  final bool keyboard;
}

// ---------------------------------------------------------------------------
// Gerüst
// ---------------------------------------------------------------------------

/// Welt hinter dem Inhalt, Inhalt im `ContentFrame`, Overlays darüber.
Widget _screen({required Widget body, List<Widget> overlays = const []}) {
  return Stack(
    children: <Widget>[
      const Positioned.fill(child: WorldBackground()),
      Positioned.fill(child: ContentFrame(child: body)),
      ...overlays,
    ],
  );
}

Widget _gap() => const SizedBox(height: CuraSpace.s3);

/// Platz über den Inhalten der Szenarien (stammt aus der Zeit des Glow, der
/// Wert bleibt, damit die Szenario-Layouts stabil sind).
const double _topClearance = CuraSpace.s10 * 5;

Widget _scrollBody(List<Widget> children, {double bottom = CuraSpace.s6}) {
  return SingleChildScrollView(
    key: PreviewKeys.scroll,
    padding: EdgeInsets.fromLTRB(
      CuraSpace.pageMargin,
      _topClearance,
      CuraSpace.pageMargin,
      bottom,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

void _noop() {}

String _sampleFor(String styleName) => styleName == _labelStyleName
    ? PreviewTexts.typoLabelSample.toUpperCase()
    : PreviewTexts.typoSample;

const String _labelStyleName = 'label';

String _styleCaption(MapEntry<String, TextStyle> e) =>
    '${e.key} · ${e.value.fontFamily} ${e.value.fontSize} '
    '${e.value.fontWeight?.value}';

// ---------------------------------------------------------------------------
// Szenarien
// ---------------------------------------------------------------------------

Widget _typo(BuildContext context, ScenarioEnv env) {
  final CuraColors c = CuraColors.of(context);
  final CuraTypography t = CuraTypography.of(context);
  // Die Schriftmuster stehen auf einer Karte (V2-5: kein Text direkt auf der
  // Welt).
  return _screen(
    body: SingleChildScrollView(
      key: PreviewKeys.scroll,
      padding: const EdgeInsets.all(CuraSpace.pageMargin),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final MapEntry<String, TextStyle> e
                in t.all.entries) ...<Widget>[
              Text(_styleCaption(e), style: t.caption.copyWith(color: c.text2)),
              Text(
                _sampleFor(e.key),
                style: e.value.copyWith(color: e.value.color ?? c.text1),
              ),
              const SizedBox(height: CuraSpace.s3),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _buttons(BuildContext context, ScenarioEnv env) {
  return _screen(
    body: _scrollBody(<Widget>[
      PillButton(
        key: PreviewKeys.primary,
        label: PreviewTexts.startTraining,
        icon: Icons.play_arrow_rounded,
        onPressed: _noop,
      ),
      _gap(),
      PillButton(
        label: PreviewTexts.cancel,
        variant: PillButtonVariant.neutral,
        onPressed: _noop,
      ),
      _gap(),
      PillButton(
        label: PreviewTexts.deleteAll,
        variant: PillButtonVariant.outline,
        icon: Icons.delete_outline_rounded,
        onPressed: _noop,
      ),
      _gap(),
      const PillButton(
        label: PreviewTexts.doneToday,
        icon: Icons.check_rounded,
        onPressed: null,
      ),
    ]),
  );
}

/// Button mit Fortschrittskreis (Löschen läuft): der Kreis dreht sich
/// dauerhaft, das Szenario schwingt nie ein (`loops`).
Widget _busy(BuildContext context, ScenarioEnv env) {
  return _screen(
    body: _scrollBody(<Widget>[
      const PillButton(
        label: PreviewTexts.deleteAll,
        variant: PillButtonVariant.outline,
        busy: true,
        onPressed: _noop,
      ),
    ]),
  );
}

Widget _forms(BuildContext context, ScenarioEnv env) {
  return _screen(
    body: _scrollBody(<Widget>[
      const StepProgress(step: 2),
      _gap(),
      const CuraLabel(PreviewTexts.injuryLabel),
      _gap(),
      ChoiceCard(
        title: PreviewTexts.choiceAcl,
        selected: true,
        onPressed: _noop,
      ),
      _gap(),
      ChoiceCard(
        title: PreviewTexts.choiceAnkle,
        selected: false,
        onPressed: _noop,
      ),
      _gap(),
      ChoiceCard(
        title: PreviewTexts.choiceOther,
        selected: false,
        leadingIcon: Icons.edit_rounded,
        onPressed: _noop,
      ),
      _gap(),
      CuraTextField(
        label: PreviewTexts.nameLabel,
        hintText: PreviewTexts.nameHint,
        controller: TextEditingController(text: PreviewTexts.nameValue),
      ),
      _gap(),
      DateCard(valueText: PreviewTexts.dateValue, onPressed: _noop),
      _gap(),
      DateCard(onPressed: _noop),
    ]),
    // Tafel für 768 × 1024 und 2,0: durchgehend scrollbar, kein Primärbutton.
  );
}

Widget _controls(BuildContext context, ScenarioEnv env) {
  const double gap = CuraSpace.s4;
  return _screen(
    body: _scrollBody(<Widget>[
      Wrap(
        spacing: gap,
        runSpacing: gap,
        children: <Widget>[
          MicButton(onPressed: _noop),
          HeaderIconButton(
            icon: Icons.person_outline_rounded,
            tooltip: PreviewTexts.yourData,
            onPressed: _noop,
          ),
          MannyButton(onPressed: _noop),
        ],
      ),
    ]),
  );
}

Widget _surfaces(BuildContext context, ScenarioEnv env) {
  return _screen(
    body: _scrollBody(<Widget>[
      const GlassCard(child: Text(PreviewTexts.glassCardText)),
      _gap(),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const MannyIllustration(height: CuraSize.mannyPathHeight),
          const SizedBox(width: CuraSpace.s1),
          Expanded(
            child: MannyBubble(
              text: S.bubbleGreeting(PreviewTexts.sampleName),
              onClose: _noop,
            ),
          ),
        ],
      ),
      _gap(),
      CuraSnackbar(
        text: PreviewTexts.snackbarAdded,
        actionLabel: PreviewTexts.snackbarUndo,
        onAction: _noop,
      ),
      _gap(),
      const CuraSnackbar(text: PreviewTexts.snackbarDeleted),
      _gap(),
      CuraDialog(
        icon: Icons.delete_outline_rounded,
        title: PreviewTexts.dialogTitle,
        message: PreviewTexts.dialogMessage,
        actions: <Widget>[
          PillButton(
            label: PreviewTexts.cancel,
            variant: PillButtonVariant.neutral,
            onPressed: _noop,
          ),
          PillButton(
            label: PreviewTexts.deleteAll,
            variant: PillButtonVariant.outline,
            icon: Icons.delete_outline_rounded,
            onPressed: _noop,
          ),
        ],
      ),
    ]),
  );
}

Widget _manny(BuildContext context, ScenarioEnv env) {
  return _screen(
    body: _scrollBody(<Widget>[
      for (final MannyLook look in MannyLookPicker.order) ...<Widget>[
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: CuraSpace.s4,
          runSpacing: CuraSpace.s4,
          children: <Widget>[
            // Die drei gelieferten Posen (Ergänzung 1, 6.3): normal, freudig,
            // traurig; Kopf auf heller Scheibe in 48 und 56 dp.
            for (final MannyPose p in const <MannyPose>[
              MannyPose.neutral,
              MannyPose.feiernd,
              MannyPose.troestend,
            ])
              MannyIllustration(
                height: CuraSize.mannyPathHeight,
                pose: p,
                look: look,
              ),
            MannyAvatar(size: CuraSize.avatar, look: look),
            MannyAvatar(size: CuraSize.emblemHeader, look: look),
          ],
        ),
        _gap(),
      ],
      MannyLookPicker(value: MannyLook.brille, onChanged: (_) {}),
    ]),
  );
}

/// Leiste (vier Ziele) und Manny-Knopf über scrollenden Auswahlkarten: Reserve
/// am Listenende wie auf dem Pfad (Leiste + 16 + 56 + 16).
Widget _navManny(BuildContext context, ScenarioEnv env) {
  final double nav = FloatingNav.occupiedHeight(context);
  const double reserve =
      CuraSize.mannyButtonNavGap +
      CuraSize.mannyChatButton +
      CuraSpace.pageMargin;
  return _screen(
    body: _scrollBody(<Widget>[
      for (int i = 1; i <= 8; i++) ...<Widget>[
        ChoiceCard(
          title: '${PreviewTexts.cardPrefix} $i',
          selected: i == 2,
          onPressed: _noop,
        ),
        _gap(),
      ],
    ], bottom: nav + reserve),
    overlays: <Widget>[
      Align(
        alignment: Alignment.bottomCenter,
        child: KeyedSubtree(key: PreviewKeys.nav, child: _NavDemo()),
      ),
      Positioned(
        right: CuraSize.mannyButtonSideMargin,
        bottom: nav + CuraSize.mannyButtonNavGap,
        child: KeyedSubtree(
          key: PreviewKeys.mannyButton,
          child: MannyButton(onPressed: _noop),
        ),
      ),
    ],
  );
}

class _NavDemo extends StatefulWidget {
  @override
  State<_NavDemo> createState() => _NavDemoState();
}

class _NavDemoState extends State<_NavDemo> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return FloatingNav(
      currentIndex: _index,
      onSelected: (int i) => setState(() => _index = i),
      items: const <NavItem>[
        NavItem(icon: Icons.route_rounded, label: PreviewTexts.pathTab),
        NavItem(
          icon: Icons.event_available_rounded,
          label: PreviewTexts.todayTab,
        ),
        NavItem(
          icon: Icons.chat_bubble_outline_rounded,
          label: PreviewTexts.chatsTab,
          badgeCount: 2,
        ),
        NavItem(
          icon: Icons.person_outline_rounded,
          label: PreviewTexts.profileTab,
          avatarInitials: PreviewTexts.profileInitial,
        ),
      ],
    );
  }
}

/// Snackbar mit Aktion über der Nav (Einblenden prüft „Bewegung reduzieren“).
Widget _snackbar(BuildContext context, ScenarioEnv env) {
  return _screen(
    body: const SizedBox.expand(),
    overlays: <Widget>[
      const _SnackbarDemo(),
      Align(
        alignment: Alignment.bottomCenter,
        child: KeyedSubtree(key: PreviewKeys.nav, child: _NavDemo()),
      ),
    ],
  );
}

class _SnackbarDemo extends StatefulWidget {
  const _SnackbarDemo();

  @override
  State<_SnackbarDemo> createState() => _SnackbarDemoState();
}

class _SnackbarDemoState extends State<_SnackbarDemo> {
  final SnackbarController _controller = SnackbarController();

  @override
  void initState() {
    super.initState();
    // Nach dem ersten Frame, damit der Host schon am Controller hängt.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.show(
        CuraSnackbarMessage(
          text: PreviewTexts.snackbarAdded,
          actionLabel: PreviewTexts.snackbarUndo,
          onAction: _noop,
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      // Kein Marker: der Host füllt den Bildschirm; die Matrix erkennt die
      // sichtbare Leiste (`CuraSnackbar`) selbst.
      child: SnackbarHost(
        controller: _controller,
        bottomOffset:
            FloatingNav.occupiedHeight(context) + CuraSpace.snackbarGap,
      ),
    );
  }
}

/// Messpunkte für die Pipette (UI-2): glowfreie Fläche (oben mittig, dort ist
/// der Glow-Alpha 0 bei allen Viewports ab 320 dp), Primärbutton, Titel.
Widget _pipette(BuildContext context, ScenarioEnv env) {
  final CuraTypography t = CuraTypography.of(context);
  return _screen(
    body: Stack(
      children: <Widget>[
        const Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            key: PreviewKeys.probeBackground,
            width: CuraSize.touchTarget,
            height: CuraSize.touchTarget,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CuraSpace.pageMargin,
            _topClearance,
            CuraSpace.pageMargin,
            CuraSpace.pageMargin,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                PreviewTexts.pipetteTitle,
                key: PreviewKeys.probeTitle,
                style: t.display,
              ),
              _gap(),
              PillButton(
                key: PreviewKeys.probePrimary,
                label: PreviewTexts.startTraining,
                onPressed: _noop,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// App-Szenarien (U2b): Onboarding und Home-Gerüst
// ---------------------------------------------------------------------------

LocalDay _today(ScenarioEnv env) => LocalDay.from(env.now);

/// Verletzungsdatum der Beispiel-Szenarien: 3. September 2026.
const LocalDay _exampleInjuryDay = LocalDay(2026, 9, 3);

/// Zustand des Onboardings; [step] ist der Zustandsschritt 0 … 4 (0 = Look,
/// 1 Name, 2 Datenschutz, 3 Verletzungstyp, 4 Datum). Die Kennungen `ob1-*` bis
/// `ob4-*` der Szenarien stammen aus den vier Schritten von Ausschnitt 1 und
/// bleiben stabil: `ob1-*` = Name (jetzt Schritt 2), `ob2` = Datenschutz (3),
/// `ob3-*` = Verletzungstyp (4), `ob4-*` = Datum (5); `ob0-*` ist der neue
/// Look-Schritt.
AppState _onboardingState(
  ScenarioEnv env, {
  int step = 1,
  String name = '',
  InjuryType? type,
  String other = '',
  LocalDay? date,
  bool consent = false,
  bool completed = false,
  MannyLook look = MannyLook.defaultLook,
}) {
  return AppState.initial(_today(env)).copyWith(
    mannyLook: look,
    onboarding: OnboardingState(
      completed: completed,
      step: step,
      name: name,
      injuryType: type,
      injuryOther: other,
      injuryDate: date,
    ),
    consent: consent
        ? ConsentState(
            acceptedAt: env.now.toUtc(),
            version: ConsentState.kVersion,
          )
        : null,
  );
}

AppState _completedState(ScenarioEnv env) => _onboardingState(
  env,
  step: kLastOnboardingStep,
  name: PreviewTexts.nameValue,
  type: InjuryType.acl,
  date: _today(env).addDays(-30),
  consent: true,
  completed: true,
);

AppSeed _obEmpty(ScenarioEnv env) => const AppSeed();

/// Look-Schritt (Schritt 1 von 5) mit der Vorbelegung „Mit Brille“.
AppSeed _obLook(ScenarioEnv env) =>
    AppSeed(state: _onboardingState(env, step: 0));

/// Look-Schritt mit gewähltem „Ohne Brille“.
AppSeed _obLookWithout(ScenarioEnv env) =>
    AppSeed(state: _onboardingState(env, step: 0, look: MannyLook.ohne));

/// Name-Schritt in der Variante „Ohne Brille“ (V2-67).
AppSeed _obNameWithout(ScenarioEnv env) => AppSeed(
  state: _onboardingState(
    env,
    name: PreviewTexts.nameValue,
    look: MannyLook.ohne,
  ),
);

AppSeed _obName(ScenarioEnv env) =>
    AppSeed(state: _onboardingState(env, name: PreviewTexts.nameValue));

AppSeed _obNameKeyboard(ScenarioEnv env) => AppSeed(
  state: _onboardingState(env, name: PreviewTexts.nameValue),
  focusField: true,
);

AppSeed _obConsent(ScenarioEnv env) => AppSeed(
  state: _onboardingState(env, step: 2, name: PreviewTexts.nameValue),
);

AppSeed _obInjuryNone(ScenarioEnv env) => AppSeed(
  state: _onboardingState(
    env,
    step: 3,
    name: PreviewTexts.nameValue,
    consent: true,
  ),
);

AppSeed _obInjuryAcl(ScenarioEnv env) => AppSeed(
  state: _onboardingState(
    env,
    step: 3,
    name: PreviewTexts.nameValue,
    type: InjuryType.acl,
    consent: true,
  ),
);

/// Muskelfaserriss gewählt: der Hinweis „noch keinen eigenen Pfad“ (SK-1).
AppSeed _obInjuryMuscle(ScenarioEnv env) => AppSeed(
  state: _onboardingState(
    env,
    step: 3,
    name: PreviewTexts.nameValue,
    type: InjuryType.muscle,
    consent: true,
  ),
);

AppState _otherInjury(ScenarioEnv env) => _onboardingState(
  env,
  step: 3,
  name: PreviewTexts.nameValue,
  type: InjuryType.other,
  other: PreviewTexts.injuryOtherValue,
  consent: true,
);

AppSeed _obInjuryOther(ScenarioEnv env) => AppSeed(state: _otherInjury(env));

AppSeed _obInjuryOtherKeyboard(ScenarioEnv env) =>
    AppSeed(state: _otherInjury(env), focusField: true);

AppSeed _obDateEmpty(ScenarioEnv env) => AppSeed(
  state: _onboardingState(
    env,
    step: 4,
    name: PreviewTexts.nameValue,
    type: InjuryType.acl,
    consent: true,
  ),
);

AppSeed _obDate(ScenarioEnv env) => AppSeed(
  state: _onboardingState(
    env,
    step: 4,
    name: PreviewTexts.nameValue,
    type: InjuryType.acl,
    date: _exampleInjuryDay,
    consent: true,
  ),
);

/// Echter Löschweg: gespeicherter Zustand, dann `deleteAll()`.
AppSeed _obDeleted(ScenarioEnv env) =>
    AppSeed(state: _completedState(env), deleteFirst: true);

/// Echter Neustart-Weg: der Speicher liefert unlesbaren Inhalt.
AppSeed _obCorrupt(ScenarioEnv env) => const AppSeed(unreadable: true);

/// Datenschutz-Platzhalterseite: Tipp auf den Link in Schritt 2.
AppSeed _obPrivacy(ScenarioEnv env) => AppSeed(
  state: _onboardingState(env, step: 2, name: PreviewTexts.nameValue),
  taps: const <String>[S.privacyLink],
);

/// StartGate-Fehler: der Speicher wirft beim Lesen einen Plattformfehler.
AppSeed _startError(ScenarioEnv env) => const AppSeed(loadError: true);

/// Mikrofon-Hinweis: Tipp auf den Mikrofon-Button.
AppSeed _obMicHint(ScenarioEnv env) => AppSeed(
  state: _onboardingState(env, name: PreviewTexts.nameValue),
  taps: const <String>[S.micUnavailable],
);

AppSeed _shellPath(ScenarioEnv env) => AppSeed(state: _completedState(env));

AppSeed _shellToday(ScenarioEnv env) =>
    AppSeed(state: _completedState(env), taps: const <String>[S.navToday]);

// ---------------------------------------------------------------------------
// App-Szenarien (U2c, F2-R3): Manny-Chat, Chats, Beispiel-Chats, Profil
// ---------------------------------------------------------------------------
// Sie öffnen die Ansichten über die echten Wege (Manny-Knopf auf dem Pfad,
// Ziele der Leiste, Zeilen der Listen), nicht über eine Abkürzung.

AppSeed _chatManny(ScenarioEnv env) =>
    AppSeed(state: _completedState(env), taps: const <String>[S.mannyChatOpen]);

AppSeed _chats(ScenarioEnv env) =>
    AppSeed(state: _completedState(env), taps: const <String>[S.navChats]);

AppSeed _exampleChat(ScenarioEnv env, String contactId) {
  final ExampleContact contact = kExampleContacts.firstWhere(
    (ExampleContact c) => c.id == contactId,
  );
  return AppSeed(
    state: _completedState(env),
    taps: <String>[
      S.navChats,
      exampleContactLabel(contact, PreviewTexts.nameValue),
    ],
  );
}

AppSeed _exampleChatPhysio(ScenarioEnv env) =>
    _exampleChat(env, 'physio-mueller');

AppSeed _exampleChatFamily(ScenarioEnv env) =>
    _exampleChat(env, 'familie-mama');

AppSeed _exampleChatDoctor(ScenarioEnv env) =>
    _exampleChat(env, 'aerzte-weber');

/// Profil mit Streak 12 und erledigten Trainingstagen (Kacheln mit Werten).
AppState _profileState(ScenarioEnv env) {
  final LocalDay today = _today(env);
  return _completedState(env).copyWith(
    onboarding: OnboardingState(
      completed: true,
      step: kLastOnboardingStep,
      name: PreviewTexts.nameValue,
      injuryType: InjuryType.acl,
      injuryDate: today.addDays(-30),
    ),
    streak: StreakState(
      count: 12,
      freezes: 1,
      lastTrainingDay: today.addDays(-1),
      evaluatedThrough: today.addDays(-1),
    ),
    manny: MannyState(
      lastShown: <MannyOccasion, LocalDay>{MannyOccasion.fact: today},
    ),
    day: DayProgramState(dayKey: today),
  );
}

AppSeed _profile(ScenarioEnv env) =>
    AppSeed(state: _profileState(env), taps: const <String>[S.navProfile]);

/// Sheet „Manny-Look“ über dem Profil (Mit Brille gewählt).
AppSeed _profileLook(ScenarioEnv env) => AppSeed(
  state: _profileState(env),
  taps: <String>[
    S.navProfile,
    S.profileRowLabel(S.profileRowLook, S.mannyLookWith),
  ],
);

/// Sheet „Darstellung“ über dem Profil.
AppSeed _profileDisplay(ScenarioEnv env) => AppSeed(
  state: _profileState(env),
  taps: <String>[S.navProfile, S.profileRowLabel(S.profileRowDisplay, null)],
);

// ---------------------------------------------------------------------------
// App-Szenarien (U3a): Pfad (Plan 12.4)
// ---------------------------------------------------------------------------
// Alle laufen durch die echte App (StartGate, HomeShell, PathScreen). Ohne
// Anlass der Manny-Blase markiert [_pathState] den Beispielfakt des Tages als
// gezeigt, damit die Ruhelage ohne Blase geprüft wird; die Szenarien
// `path-bubble-*` und `path-cluster-bubble` zeigen eine.

DateTime _at(ScenarioEnv env, int hour) =>
    DateTime(env.now.year, env.now.month, env.now.day, hour);

/// Alle Unit-IDs der Woche 12 samt Phasen-Abschluss 3 (Endfall: nur der Boss
/// ist offen).
List<String> _endCompleted() => <String>[
  for (final PathUnit u in kSamplePath)
    if (u.week == kPathWeeks && u.kind != UnitKind.boss) u.id,
];

AppState _pathState(
  ScenarioEnv env, {
  int daysSinceInjury = 30,
  StreakState streak = const StreakState(),
  MannyState? manny,
  List<String> completed = const <String>[],
  String? pulse,
  CelebrationState? celebration,
  bool dayDone = false,
}) {
  final LocalDay today = _today(env);
  return _completedState(env).copyWith(
    onboarding: OnboardingState(
      completed: true,
      step: kLastOnboardingStep,
      name: PreviewTexts.nameValue,
      injuryType: InjuryType.acl,
      injuryDate: today.addDays(-daysSinceInjury),
    ),
    streak: streak,
    manny:
        manny ??
        MannyState(
          lastShown: <MannyOccasion, LocalDay>{MannyOccasion.fact: today},
        ),
    path: PathState(completedUnitIds: completed, pulsePending: pulse),
    celebration: celebration,
    day: DayProgramState(dayKey: today, done: dayDone),
  );
}

/// Streak 12, gestern trainiert (aktiv).
StreakState _streakActive(ScenarioEnv env) {
  final LocalDay today = _today(env);
  return StreakState(
    count: 12,
    lastTrainingDay: today.addDays(-1),
    evaluatedThrough: today.addDays(-1),
  );
}

/// Streak 12, vorgestern trainiert, gestern per Freeze gedeckt (eingefroren).
StreakState _streakFrozen(ScenarioEnv env) {
  final LocalDay today = _today(env);
  return StreakState(
    count: 12,
    freezes: 1,
    lastTrainingDay: today.addDays(-2),
    evaluatedThrough: today.addDays(-1),
    coveredInGap: 1,
  );
}

AppSeed _pathLoading(ScenarioEnv env) =>
    AppSeed(state: _pathState(env), pathMode: PathSeedMode.loading);

AppSeed _pathError(ScenarioEnv env) =>
    AppSeed(state: _pathState(env), pathMode: PathSeedMode.error);

AppSeed _pathActive(ScenarioEnv env) =>
    AppSeed(state: _pathState(env, streak: _streakActive(env)));

AppSeed _pathFrozen(ScenarioEnv env) =>
    AppSeed(state: _pathState(env, streak: _streakFrozen(env)));

AppSeed _pathReset(ScenarioEnv env) => AppSeed(
  state: _pathState(
    env,
    streak: const StreakState(freezes: 0, uncoveredInGap: 2),
  ),
);

AppSeed _pathBubbleGreeting(ScenarioEnv env) => AppSeed(
  state: _pathState(
    env,
    daysSinceInjury: 0,
    manny: const MannyState(greetingPending: true),
  ),
);

/// Abends (19:00): Streak-Gefahr.
AppSeed _pathBubbleDanger(ScenarioEnv env) => AppSeed(
  now: _at(env, 19),
  state: _pathState(env, streak: _streakActive(env), manny: const MannyState()),
);

AppSeed _pathBubbleRestart(ScenarioEnv env) => AppSeed(
  state: _pathState(
    env,
    streak: const StreakState(
      freezes: 0,
      uncoveredInGap: 2,
      resetNoticePending: true,
    ),
    manny: const MannyState(),
  ),
);

/// Feier mit Ring-Puls: heute Unit `w5-d1` erledigt (Streak 13).
AppSeed _pathCelebration(ScenarioEnv env) {
  final LocalDay today = _today(env);
  return AppSeed(
    state: _pathState(
      env,
      streak: StreakState(
        count: 13,
        lastTrainingDay: today,
        evaluatedThrough: today.addDays(-1),
      ),
      manny: const MannyState(),
      completed: const <String>['w5-d1'],
      pulse: 'w5-d1',
      celebration: CelebrationState(day: today, unitId: 'w5-d1'),
      dayDone: true,
    ),
  );
}

String _unitLabel(String id, UnitStatus status) {
  final PathUnit unit = kSamplePath.firstWhere((PathUnit u) => u.id == id);
  return unitSemanticsLabel(unit, status);
}

/// Tipp auf eine gesperrte Unit der laufenden Woche: „Kommt noch diese Woche“.
AppSeed _pathHintLocked(ScenarioEnv env) => AppSeed(
  state: _pathState(env, streak: _streakActive(env)),
  taps: <String>[_unitLabel('w5-d2', UnitStatus.locked)],
);

/// Tipp auf eine erledigte Unit: „Erledigt. Das hast du geschafft.“
AppSeed _pathHintDone(ScenarioEnv env) => AppSeed(
  state: _pathState(env, streak: _streakActive(env)),
  taps: <String>[_unitLabel('w4-d3', UnitStatus.done)],
);

/// Tipp auf den Chip „Freeze“: „Ein Freeze rettet deinen Streak an einem
/// verpassten Tag.“ (SK-1). Ab Skalierung 1,5 steht der Chip in der mitlaufenden
/// Kopfzeile ganz oben im Pfad: der Pfad scrollt zuerst ganz nach oben (bei
/// kleiner Schrift ändert das am Chip nichts).
AppSeed _pathStatHintFreeze(ScenarioEnv env) => AppSeed(
  state: _pathState(env, streak: _streakActive(env)),
  taps: <String>[
    kPreviewScrollStart,
    S.freezesLabel(const StreakState().freezes),
  ],
);

/// Tipp auf den Chip „Streak“: „Dein Streak zählt die Tage in Folge mit
/// Training.“ (SK-1).
AppSeed _pathStatHintStreak(ScenarioEnv env) => AppSeed(
  state: _pathState(env, streak: _streakActive(env)),
  taps: <String>[
    kPreviewScrollStart,
    S.streakLabel(tage(_streakActive(env).count)),
  ],
);

AppSeed _pathWeek1(ScenarioEnv env) =>
    AppSeed(state: _pathState(env, daysSinceInjury: 0));

AppSeed _pathEnd(ScenarioEnv env) => AppSeed(
  state: _pathState(
    env,
    daysSinceInjury: 200,
    streak: _streakActive(env),
    completed: _endCompleted(),
  ),
);

/// Endfall (alles bis vor Boss erledigt), Pfad ganz nach oben gescrollt: der
/// gesperrte Ausblick „Prävention & Gesundheitssport“ über dem Boss
/// (Ergänzung 3, UI-90 bis UI-98).
AppSeed _pathOutlook(ScenarioEnv env) => AppSeed(
  state: _pathState(
    env,
    daysSinceInjury: 200,
    streak: _streakActive(env),
    completed: _endCompleted(),
  ),
  taps: const <String>[kPreviewScrollStart],
);

/// Wie `path-outlook`, dazu Tipp auf die Marke: `NodeHint` über ihr (UI-92).
AppSeed _pathOutlookHint(ScenarioEnv env) => AppSeed(
  state: _pathState(
    env,
    daysSinceInjury: 200,
    streak: _streakActive(env),
    completed: _endCompleted(),
  ),
  taps: const <String>[kPreviewScrollStart, S.outlookLabel],
);

/// Pfad ganz nach unten gescrollt, Manny auf der untersten Unit nahe der
/// Button-Gruppe, Begrüßungsblase: sie wechselt über Manny.
AppSeed _pathClusterBubble(ScenarioEnv env) => AppSeed(
  state: _pathState(
    env,
    daysSinceInjury: 0,
    manny: const MannyState(greetingPending: true),
  ),
  scrollPathToEnd: true,
);

/// Pfad ganz nach unten gescrollt, Hinweis an einer erledigten Unit nahe der
/// Gruppe (Woche 5: die unteren Units sind erledigt).
AppSeed _pathClusterHint(ScenarioEnv env) => AppSeed(
  state: _pathState(env, streak: _streakActive(env)),
  scrollPathToEnd: true,
  taps: <String>[_unitLabel('w1-d2', UnitStatus.done)],
);

/// Unterste Unit über die Button-Gruppe geschoben (Woche 5, Pfad ganz unten).
AppSeed _pathScrolledBottom(ScenarioEnv env) => AppSeed(
  state: _pathState(env, streak: _streakActive(env)),
  scrollPathToEnd: true,
);

// ---------------------------------------------------------------------------
// App-Szenarien (U3b): Heute (Plan 12.4)
// ---------------------------------------------------------------------------
// Alle laufen durch die echte App (StartGate, HomeShell, TodayScreen): sie
// starten auf dem Pfad und wechseln über die Nav auf Heute. Aktionen (Entfernen,
// Training eintragen, Sheet, Dialog) laufen über die echten Bausteine.

/// Zustand für Heute: [day] (Standard: Tag der Umgebung), Zeitwahl, Tagesprogramm.
AppState _todayState(
  ScenarioEnv env, {
  LocalDay? day,
  int timeChoice = kDefaultTimeChoice,
  List<String> removed = const <String>[],
  List<CustomExercise> custom = const <CustomExercise>[],
  bool done = false,
}) {
  final LocalDay d = day ?? _today(env);
  return _completedState(env).copyWith(
    onboarding: OnboardingState(
      completed: true,
      step: kLastOnboardingStep,
      name: PreviewTexts.nameValue,
      injuryType: InjuryType.acl,
      injuryDate: d.addDays(-30),
    ),
    manny: MannyState(
      lastShown: <MannyOccasion, LocalDay>{MannyOccasion.fact: d},
    ),
    prefs: PrefsState(timeChoice: timeChoice),
    day: DayProgramState(
      dayKey: d,
      removed: removed,
      custom: custom,
      done: done,
    ),
  );
}

/// Alle Basis-IDs der Zeitwahl 20 (leere Übungsliste).
List<String> _allBaseIds() => <String>[
  for (final ExerciseFamily f in kBaseExercises[kDefaultTimeChoice]!) f.base.id,
];

const List<String> _toToday = <String>[S.navToday];

/// Erste und letzte Basisübung der Zeitwahl 20 (Entfernen-Labels).
String _firstRemoveLabel() =>
    S.exerciseRemoveLabel(kBaseExercises[kDefaultTimeChoice]!.first.base.name);
String _lastRemoveLabel() =>
    S.exerciseRemoveLabel(kBaseExercises[kDefaultTimeChoice]!.last.base.name);

AppSeed _todayLoading(ScenarioEnv env) => AppSeed(
  state: _todayState(env),
  todayMode: TodaySeedMode.loading,
  taps: _toToday,
);

AppSeed _todayError(ScenarioEnv env) => AppSeed(
  state: _todayState(env),
  todayMode: TodaySeedMode.error,
  taps: _toToday,
);

AppSeed _todayStandard(ScenarioEnv env) =>
    AppSeed(state: _todayState(env), taps: _toToday);

/// Freitag: Arzttermin 09:30 und Physio 17:00.
AppSeed _todayFriday(ScenarioEnv env) {
  final DateTime now = DateTime(2026, 10, 9, 12);
  return AppSeed(
    now: now,
    state: _todayState(env, day: LocalDay.from(now)),
    taps: _toToday,
  );
}

/// Samstag: keine Termine („Heute keine Termine.“).
AppSeed _todayWeekend(ScenarioEnv env) {
  final DateTime now = DateTime(2026, 10, 10, 12);
  return AppSeed(
    now: now,
    state: _todayState(env, day: LocalDay.from(now)),
    taps: _toToday,
  );
}

AppSeed _today10(ScenarioEnv env) =>
    AppSeed(state: _todayState(env, timeChoice: 10), taps: _toToday);

AppSeed _today30(ScenarioEnv env) =>
    AppSeed(state: _todayState(env, timeChoice: 30), taps: _toToday);

/// Eine eigene Übung am Ende der Liste (Karte ohne „Tauschen“).
AppSeed _todayCustom(ScenarioEnv env) => AppSeed(
  state: _todayState(
    env,
    custom: const <CustomExercise>[
      CustomExercise(
        id: 'custom-1',
        name: 'Plank am Stuhl',
        reps: S.customDefaultReps,
        minutes: S.customDefaultMinutes,
      ),
    ],
  ),
  taps: _toToday,
);

AppSeed _todayEmpty(ScenarioEnv env) => AppSeed(
  state: _todayState(env, removed: _allBaseIds()),
  taps: _toToday,
);

AppSeed _todayDone(ScenarioEnv env) =>
    AppSeed(state: _todayState(env, done: true), taps: _toToday);

/// Leer und erledigt: „Heute erledigt“ gewinnt beim Button (B-6).
AppSeed _todayEmptyDone(ScenarioEnv env) => AppSeed(
  state: _todayState(env, removed: _allBaseIds(), done: true),
  taps: _toToday,
);

/// Standard bis zum Listenende gescrollt (Reserve, Gruppe).
AppSeed _todayCluster(ScenarioEnv env) => AppSeed(
  state: _todayState(env),
  taps: const <String>[S.navToday, kPreviewScrollEnd],
);

AppSeed _todayDoneCluster(ScenarioEnv env) => AppSeed(
  state: _todayState(env, done: true),
  taps: const <String>[S.navToday, kPreviewScrollEnd],
);

/// „Entfernt. Rückgängig“ (echter Weg: Tipp auf „Entfernen“).
AppSeed _todaySnackbarRemoved(ScenarioEnv env) => AppSeed(
  state: _todayState(env),
  taps: <String>[S.navToday, _firstRemoveLabel()],
);

/// „Eingetragen. Rückgängig“ (echter Weg: Sheet, „Training eintragen“).
AppSeed _todaySnackbarLogged(ScenarioEnv env) => AppSeed(
  state: _todayState(env),
  taps: const <String>[S.navToday, S.trainingLog, S.trainingSheetConfirm],
);

/// Snackbar über der Gruppe bei bis ans Ende gescrollter Liste.
AppSeed _todaySnackbarCluster(ScenarioEnv env) => AppSeed(
  state: _todayState(env),
  taps: <String>[S.navToday, kPreviewScrollEnd, _lastRemoveLabel()],
);

AppSeed _todayModeSheet(ScenarioEnv env) => AppSeed(
  state: _todayState(env),
  taps: const <String>[S.navToday, S.trainingLog],
);

AppSeed _todayCustomDialog(ScenarioEnv env) => AppSeed(
  state: _todayState(env),
  taps: const <String>[S.navToday, S.customAddLabel],
);

AppSeed _todayCustomDialogKeyboard(ScenarioEnv env) => AppSeed(
  state: _todayState(env),
  taps: const <String>[S.navToday, S.customAddLabel],
  focusField: true,
);

/// Tageswechsel auf Heute: Zeitsprung um einen Tag nach dem Wechsel auf Heute;
/// Heute zeigt das neue Datum, das frische Programm und die Snackbar „Neuer
/// Tag, neues Programm.“.
AppSeed _todayNewDaySnackbar(ScenarioEnv env) => AppSeed(
  state: _todayState(env, removed: <String>[_allBaseIds().first]),
  taps: _toToday,
  daysAfterTaps: 1,
);

// ---------------------------------------------------------------------------
// App-Szenarien (U4): Deine Daten, Verwerfen, Löschen
// ---------------------------------------------------------------------------
// Sie öffnen das Sheet über den echten Weg (Icon „Deine Daten“ in der
// Pfad-Kopfzeile) und weiter über Tipps auf die echten Bausteine.

const List<String> _openData = <String>[S.dataSheetOpen];

/// Ein anderer Typ als der gespeicherte (ACL) ist gewählt: Entwurf geändert.
final String _otherTypeCard = S.choiceLabel(S.injuryMuscle, false);

AppSeed _dataSheet(ScenarioEnv env) =>
    AppSeed(state: _completedState(env), taps: _openData);

/// Sheet ans Ende gescrollt: der Abschnitt „Daten löschen“ ist sichtbar (F-8).
AppSeed _dataSheetBottom(ScenarioEnv env) => AppSeed(
  state: _completedState(env),
  taps: <String>[..._openData, kPreviewScrollSheetEnd],
);

/// Gruppe unter dem Scrim: Pfad im aktiven Zustand mit offenem Sheet.
AppSeed _pathSheetOpen(ScenarioEnv env) => AppSeed(
  state: _pathState(env, streak: _streakActive(env)),
  taps: _openData,
);

/// „Anderes“ mit gespeichertem Freitext (Feld „Was ist passiert?“).
AppSeed _dataSheetOther(ScenarioEnv env) => AppSeed(
  state: _completedState(env).copyWith(
    onboarding: _completedState(env).onboarding.copyWith(
      injuryType: InjuryType.other,
      injuryOther: PreviewTexts.injuryOtherValue,
    ),
  ),
  taps: _openData,
);

/// Gespeichert: Muskelfaserriss. Der Hinweis „noch keinen eigenen Pfad“ steht
/// unter den Karten, die Kopfzeile darunter zeigt den vollen Kurznamen (SK-1).
AppSeed _dataSheetMuscle(ScenarioEnv env) => AppSeed(
  state: _completedState(env).copyWith(
    onboarding: _completedState(env).onboarding
        .copyWith(injuryType: InjuryType.muscle),
  ),
  taps: <String>[..._openData, kPreviewScrollSheetEnd],
);

/// Link „Datenschutzerklärung“ ganz unten im Sheet: öffnet die
/// Platzhalterseite (SK-1).
AppSeed _dataPrivacy(ScenarioEnv env) => AppSeed(
  state: _completedState(env),
  taps: <String>[..._openData, kPreviewScrollSheetEnd, S.dataPrivacyEntry],
);

/// Pfad bei Muskelfaserriss ohne Sheet: Kopfzeile mit vollem Kurznamen.
AppSeed _pathMuscle(ScenarioEnv env) {
  final AppState base = _pathState(env, streak: _streakActive(env));
  return AppSeed(
    state: base.copyWith(
      onboarding: base.onboarding.copyWith(injuryType: InjuryType.muscle),
    ),
  );
}

/// Entwurf geändert: „Speichern“ ist aktiv.
AppSeed _dataSheetDirty(ScenarioEnv env) => AppSeed(
  state: _completedState(env),
  taps: <String>[...(_openData), _otherTypeCard],
);

/// Geändert, dann Schließen: „Änderungen verwerfen?“.
AppSeed _dataDiscardDialog(ScenarioEnv env) => AppSeed(
  state: _completedState(env),
  taps: <String>[..._openData, _otherTypeCard, S.close],
);

/// Löschdialog ans Ende gescrollt: die Buttons sind sichtbar (R-1; bei 2,0 ohne
/// Symbol und ohne Wortbruch).
AppSeed _dataDeleteDialogBottom(ScenarioEnv env) => AppSeed(
  state: _completedState(env),
  taps: <String>[..._openData, S.dataDeleteButton, kPreviewScrollDialogEnd],
);

AppSeed _dataDeleteDialog(ScenarioEnv env) => AppSeed(
  state: _completedState(env),
  taps: <String>[..._openData, S.dataDeleteButton],
);

/// Löschen läuft (der Speicher antwortet nie): nach 300 ms Fortschrittskreis.
AppSeed _dataDeleteBusy(ScenarioEnv env) => AppSeed(
  state: _completedState(env),
  taps: <String>[..._openData, S.dataDeleteButton, S.deleteConfirm],
  deleteMode: DeleteSeedMode.slow,
);

/// Löschen schlägt fehl: Fehlerhinweis und „Nochmal versuchen“.
AppSeed _dataDeleteError(ScenarioEnv env) => AppSeed(
  state: _completedState(env),
  taps: <String>[..._openData, S.dataDeleteButton, S.deleteConfirm],
  deleteMode: DeleteSeedMode.failing,
);

/// Tastatur im Sheet: das Namensfeld hat den Fokus.
AppSeed _dataSheetKeyboard(ScenarioEnv env) =>
    AppSeed(state: _completedState(env), taps: _openData, focusField: true);

/// Alle Szenarien, in der Reihenfolge der Kontaktbögen.
final List<Scenario> kScenarios = <Scenario>[
  Scenario(id: 'cmp-typo', builder: _typo),
  Scenario(id: 'cmp-buttons', builder: _buttons, expectsPrimary: true),
  Scenario(id: 'cmp-busy', builder: _busy, loops: true),
  Scenario(id: 'cmp-forms', builder: _forms, tablet: true),
  Scenario(id: 'cmp-controls', builder: _controls),
  Scenario(id: 'cmp-surfaces', builder: _surfaces, tablet: true),
  Scenario(id: 'cmp-manny', builder: _manny),
  Scenario(
    id: 'cmp-nav-manny',
    builder: _navManny,
    maxBackdrops: BlurTokens.maxPerScreen,
    expectsNav: true,
    expectsMannyButton: true,
    tablet: true,
  ),
  Scenario(
    id: 'cmp-snackbar',
    builder: _snackbar,
    maxBackdrops: BlurTokens.maxPerScreen,
    expectsNav: true,
  ),
  Scenario(id: 'cmp-pipette', builder: _pipette),
  Scenario(
    id: 'ob1-empty',
    app: _obEmpty,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob0-look',
    app: _obLook,
    expectsPrimary: true,
    expectsHeader: true,
    tablet: true,
  ),
  Scenario(
    id: 'ob0-look-ohne',
    app: _obLookWithout,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob1-name-ohne',
    app: _obNameWithout,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob1-name',
    app: _obName,
    expectsPrimary: true,
    expectsHeader: true,
    tablet: true,
  ),
  Scenario(
    id: 'ob1-keyboard',
    app: _obNameKeyboard,
    keyboard: true,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob2',
    app: _obConsent,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob3-none',
    app: _obInjuryNone,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob3-acl',
    app: _obInjuryAcl,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob3-other',
    app: _obInjuryOther,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob3-muscle',
    app: _obInjuryMuscle,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob3-other-keyboard',
    app: _obInjuryOtherKeyboard,
    keyboard: true,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob4-empty',
    app: _obDateEmpty,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob4-date',
    app: _obDate,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob1-deleted-snackbar',
    app: _obDeleted,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob1-corrupt-snackbar',
    app: _obCorrupt,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob-mic-hint',
    app: _obMicHint,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(id: 'ob2-privacy', app: _obPrivacy, expectsHeader: true),
  Scenario(id: 'start-error', app: _startError, expectsPrimary: true),
  Scenario(
    id: 'shell-tab-path',
    app: _shellPath,
    expectsNav: true,
    expectsMannyButton: true,
  ),
  Scenario(id: 'shell-tab-today', app: _shellToday, expectsNav: true),
  // Pfad (U3a): in Laden und Fehler steht keine Button-Gruppe (A-43).
  Scenario(
    id: 'path-loading',
    app: _pathLoading,
    maxBackdrops: BlurTokens.maxPerScreen,
    expectsNav: true,
  ),
  Scenario(
    id: 'path-error',
    app: _pathError,
    maxBackdrops: BlurTokens.maxPerScreen,
    expectsNav: true,
    expectsPrimary: true,
  ),
  _pathScenario('path-active', _pathActive, tablet: true),
  _pathScenario('path-frozen', _pathFrozen),
  _pathScenario('path-reset', _pathReset),
  _pathScenario('path-bubble-greeting', _pathBubbleGreeting),
  _pathScenario('path-bubble-danger', _pathBubbleDanger),
  _pathScenario('path-bubble-restart', _pathBubbleRestart),
  _pathScenario('path-celebration', _pathCelebration),
  _pathScenario('path-hint-locked', _pathHintLocked),
  _pathScenario('path-hint-done', _pathHintDone),
  _pathScenario('path-week1', _pathWeek1),
  _pathScenario('path-end', _pathEnd),
  _pathScenario('path-stat-hint-freeze', _pathStatHintFreeze),
  _pathScenario('path-stat-hint-streak', _pathStatHintStreak),
  _pathScenario('path-muscle', _pathMuscle),
  _pathScenario('path-outlook', _pathOutlook),
  _pathScenario('path-outlook-hint', _pathOutlookHint),
  _pathScenario('path-header-wrap', _pathActive, fixedTextScale: 1.2),
  _pathScenario('path-cluster-bubble', _pathClusterBubble),
  _pathScenario('path-cluster-hint', _pathClusterHint),
  _pathScenario('path-scrolled-bottom', _pathScrolledBottom),
  // Heute (U3b): in Laden und Fehler steht keine Button-Gruppe (A-43).
  Scenario(
    id: 'today-loading',
    app: _todayLoading,
    maxBackdrops: BlurTokens.maxPerScreen,
    expectsNav: true,
  ),
  Scenario(
    id: 'today-error',
    app: _todayError,
    maxBackdrops: BlurTokens.maxPerScreen,
    expectsNav: true,
    expectsPrimary: true,
  ),
  _todayScenario('today-standard', _todayStandard, tablet: true),
  _todayScenario('today-friday', _todayFriday),
  _todayScenario('today-weekend', _todayWeekend),
  _todayScenario('today-10', _today10),
  _todayScenario('today-30', _today30),
  _todayScenario('today-custom', _todayCustom),
  _todayScenario('today-empty', _todayEmpty),
  _todayScenario('today-done', _todayDone),
  _todayScenario('today-empty-done', _todayEmptyDone),
  _todayScenario('today-cluster', _todayCluster),
  _todayScenario('today-done-cluster', _todayDoneCluster),
  // Umbruchszustand: „Training eintragen“ bricht um (UI-71, UI-73).
  _todayScenario('today-wrap', _todayStandard, fixedTextScale: 1.5),
  _todayScenario('today-snackbar-removed', _todaySnackbarRemoved),
  _todayScenario('today-snackbar-logged', _todaySnackbarLogged),
  _todayScenario('today-snackbar-cluster', _todaySnackbarCluster),
  _todayScenario('today-newday-snackbar', _todayNewDaySnackbar),
  // Sheet und Dialog: Nav und Button-Gruppe von Home liegen unter dem Scrim
  // (abgedunkelt, nicht bedienbar) und zählen nicht als Overlay der oberen
  // Route. Höchstens zwei BackdropFilter (Nav und Sheet). Der Primärbutton des
  // Sheets ist „Training eintragen“; der Dialog hat keinen markierten.
  Scenario(id: 'today-mode-sheet', app: _todayModeSheet, expectsPrimary: true),
  Scenario(id: 'today-custom-dialog', app: _todayCustomDialog),
  Scenario(
    id: 'today-custom-dialog-keyboard',
    app: _todayCustomDialogKeyboard,
    keyboard: true,
  ),
  // Deine Daten (U4): Sheet über dem Pfad (Nav und Button-Gruppe liegen unter
  // dem Scrim). Der Primärbutton des Sheets ist „Speichern“. Die Dialoge haben
  // keinen markierten Primärbutton.
  Scenario(
    id: 'data-sheet',
    app: _dataSheet,
    expectsPrimary: true,
    tablet: true,
  ),
  Scenario(
    id: 'data-sheet-bottom',
    app: _dataSheetBottom,
    expectsPrimary: true,
  ),
  Scenario(id: 'path-sheet-open', app: _pathSheetOpen, expectsPrimary: true),
  Scenario(id: 'data-sheet-other', app: _dataSheetOther, expectsPrimary: true),
  Scenario(
    id: 'data-sheet-muscle',
    app: _dataSheetMuscle,
    expectsPrimary: true,
  ),
  Scenario(id: 'data-privacy', app: _dataPrivacy, expectsHeader: true),
  Scenario(id: 'data-sheet-dirty', app: _dataSheetDirty, expectsPrimary: true),
  Scenario(id: 'data-discard-dialog', app: _dataDiscardDialog),
  Scenario(id: 'data-delete-dialog', app: _dataDeleteDialog),
  Scenario(id: 'data-delete-dialog-bottom', app: _dataDeleteDialogBottom),
  Scenario(id: 'data-delete-busy', app: _dataDeleteBusy, loops: true),
  Scenario(id: 'data-delete-error', app: _dataDeleteError),
  Scenario(
    id: 'data-sheet-keyboard',
    app: _dataSheetKeyboard,
    keyboard: true,
    expectsPrimary: true,
  ),
  Scenario(
    id: 'chat-manny',
    app: _chatManny,
    maxBackdrops: 0,
    expectsHeader: true,
    expectsChatFooter: true,
    tablet: true,
  ),
  Scenario(
    id: 'chat-manny-scale15',
    app: _chatManny,
    maxBackdrops: 0,
    expectsHeader: true,
    expectsChatFooter: true,
    fixedTextScale: 1.5,
  ),
  // Ziele der Leiste (F2-R3): Kopf-Karte, Leiste, Blur ≤ 3.
  Scenario(
    id: 'chats',
    app: _chats,
    expectsNav: true,
    expectsHeader: true,
    tablet: true,
  ),
  Scenario(
    id: 'chats-scale15',
    app: _chats,
    expectsNav: true,
    expectsHeader: true,
    fixedTextScale: 1.5,
  ),
  Scenario(
    id: 'profile',
    app: _profile,
    expectsNav: true,
    expectsHeader: true,
    tablet: true,
  ),
  // Sheets über dem Profil: opak, ohne Blur; Leiste und Kopf-Karte liegen
  // unter dem Scrim. Primärbutton ist „Fertig“.
  Scenario(id: 'profile-look-sheet', app: _profileLook, expectsPrimary: true),
  Scenario(
    id: 'profile-display-sheet',
    app: _profileDisplay,
    expectsPrimary: true,
  ),
  Scenario(
    id: 'example-chat-physio',
    app: _exampleChatPhysio,
    maxBackdrops: 0,
    expectsHeader: true,
    expectsChatFooter: true,
  ),
  Scenario(
    id: 'example-chat-family',
    app: _exampleChatFamily,
    maxBackdrops: 0,
    expectsHeader: true,
    expectsChatFooter: true,
  ),
  Scenario(
    id: 'example-chat-doctor',
    app: _exampleChatDoctor,
    maxBackdrops: 0,
    expectsHeader: true,
    expectsChatFooter: true,
  ),
];

/// Pfad im Standard-Zustand: Nav, Button-Gruppe und Kopf sind Pflicht (die
/// Matrix meldet einen fehlenden Marker als harten Befund); höchstens zwei
/// `BackdropFilter` (Nav plus Blase).
Scenario _pathScenario(
  String id,
  AppSeedBuilder seed, {
  bool tablet = false,
  double? fixedTextScale,
}) => Scenario(
  id: id,
  app: seed,
  expectsNav: true,
  expectsMannyButton: true,
  expectsHeader: true,
  tablet: tablet,
  fixedTextScale: fixedTextScale,
);

/// Heute im Standard-Zustand: Nav und Button-Gruppe sind Pflicht (die Matrix
/// meldet einen fehlenden Marker als harten Befund), der Primärbutton ist
/// sichtbar und antippbar; höchstens zwei `BackdropFilter` (Nav plus Sheet).
/// Ein festes Kopfelement gibt es nicht: Datum und Titel laufen mit der Liste.
Scenario _todayScenario(
  String id,
  AppSeedBuilder seed, {
  bool tablet = false,
  double? fixedTextScale,
}) => Scenario(
  id: id,
  app: seed,
  expectsNav: true,
  expectsPrimary: true,
  tablet: tablet,
  fixedTextScale: fixedTextScale,
);

Scenario? scenarioById(String id) {
  for (final Scenario s in kScenarios) {
    if (s.id == id) return s;
  }
  return null;
}
