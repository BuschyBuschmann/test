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
import '../logic/injury_type.dart';
import '../theme/cura_colors.dart';
import '../theme/cura_metrics.dart';
import '../theme/cura_typography.dart';
import '../ui/components/action_cluster.dart';
import '../ui/components/choice_card.dart';
import '../ui/components/content_frame.dart';
import '../ui/components/cura_dialog.dart';
import '../ui/components/cura_label.dart';
import '../ui/components/cura_snackbar.dart';
import '../ui/components/cura_text_field.dart';
import '../ui/components/date_card.dart';
import '../ui/components/floating_nav.dart';
import '../ui/components/glass_card.dart';
import '../ui/components/glow_background.dart';
import '../ui/components/header_icon_button.dart';
import '../ui/components/manny.dart';
import '../ui/components/manny_bubble.dart';
import '../ui/components/manny_chat_button.dart';
import '../ui/components/messages_button.dart';
import '../ui/components/mic_button.dart';
import '../ui/components/pill_button.dart';
import '../ui/components/probe_keys.dart';
import '../ui/components/step_progress.dart';
import 'preview_texts.dart';

/// Marker für die Prüfungen. Namen mit Präfix `overlay:` zählen als Overlay
/// (schwebt über dem Inhalt), `probe:` als Messpunkt für die Pipette.
abstract final class PreviewKeys {
  static const ValueKey<String> nav = ProbeKeys.nav;
  static const ValueKey<String> cluster = ProbeKeys.cluster;
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

/// Zustand einer **App-Szenarios** (Plan 12.4: `ob*`, `shell-*`): die echte
/// App (`CuraApp` mit StartGate, Routen und Speicher) startet mit diesem
/// Speicher. So laufen Matrix und Screenshots durch denselben Code wie die
/// Produktion.
class AppSeed {
  const AppSeed({
    this.state,
    this.unreadable = false,
    this.deleteFirst = false,
    this.taps = const <String>[],
  });

  /// Gespeicherter Zustand; `null` = Erststart (nichts gespeichert).
  final AppState? state;

  /// Der Speicher liefert unlesbaren Inhalt (N-12): Neustart mit Hinweis.
  final bool unreadable;

  /// Nach dem Laden läuft „Alles löschen“ (echter Löschweg): Onboarding
  /// Schritt 1 mit dem Hinweis „Alle Daten sind gelöscht.“.
  final bool deleteFirst;

  /// Screenreader-Labels von Bausteinen, die nach dem Start „getippt“ werden.
  final List<String> taps;
}

typedef AppSeedBuilder = AppSeed Function(ScenarioEnv env);

class Scenario {
  const Scenario({
    required this.id,
    this.builder,
    this.app,
    this.maxBackdrops = 2,
    this.expectsPrimary = false,
    this.expectsNav = false,
    this.expectsCluster = false,
    this.expectsHeader = false,
    this.expectsChatFooter = false,
    this.tablet = false,
    this.keyboard = false,
    this.transientOverlay = false,
    this.loops = false,
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

  /// Das Szenario enthält Nav, Button-Gruppe, Kopf bzw. Chat-Fuß mit dem
  /// jeweiligen Marker (`overlay:nav`, `overlay:cluster`, `header`,
  /// `overlay:chat-footer`). Fehlt der Marker, ist das ein harter Befund der
  /// Matrix; ohne Flag würde die jeweilige Prüfung still entfallen.
  final bool expectsNav;
  final bool expectsCluster;
  final bool expectsHeader;
  final bool expectsChatFooter;

  /// Zusätzlich bei 768 × 1024 prüfen (ContentFrame, Plan 12.2).
  final bool tablet;

  /// Tastatur-Szenario (Plan 12.4, B-10): die Prüfumgebung blendet eine
  /// Tastatur von 300 dp ein (`viewInsets.bottom` plus Platzhalterfläche mit
  /// dem Marker `overlay:keyboard`). Die Matrix prüft es bei 320 × 568 nur
  /// mit Skalierung 1,0: bei 200 % bleibt über der Tastatur kein Scrollbereich.
  final bool keyboard;

  /// Zeigt ein zeitlich begrenztes Overlay (Snackbar von 4 s), das bei 320 × 568
  /// und 200 % fast die ganze Fläche zwischen Kopf und Mikrofon-Zeile deckt
  /// (Richtwert-Befund „Sichtfläche“). Die Matrix prüft diese Szenarien bei
  /// 568 dp Höhe nur mit Skalierung 1,0; nach Ablauf bzw. Wegwischen ist der
  /// Inhalt frei.
  final bool transientOverlay;
}

// ---------------------------------------------------------------------------
// Gerüst
// ---------------------------------------------------------------------------

/// Glow hinter dem Inhalt, Inhalt im `ContentFrame`, Overlays darüber.
Widget _screen({required Widget body, List<Widget> overlays = const []}) {
  return Stack(
    children: <Widget>[
      const Positioned.fill(child: GlowBackground()),
      Positioned.fill(child: ContentFrame(child: body)),
      ...overlays,
    ],
  );
}

Widget _gap() => const SizedBox(height: CuraSpace.s3);

/// Zeilenumbruch-sicherer Platz über Inhalten auf Glas: der obere linke
/// Lichtfleck liegt dort bei 24 %, Text auf Glas verträgt höchstens 16 %
/// (Errata E-1).
const double _glowClearance = CuraSpace.s10 * 5;

Widget _scrollBody(List<Widget> children, {double bottom = CuraSpace.s6}) {
  return SingleChildScrollView(
    key: PreviewKeys.scroll,
    padding: EdgeInsets.fromLTRB(
      CuraSpace.pageMargin,
      _glowClearance,
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
  return _screen(
    body: SingleChildScrollView(
      key: PreviewKeys.scroll,
      padding: const EdgeInsets.all(CuraSpace.pageMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final MapEntry<String, TextStyle> e
              in t.all.entries) ...<Widget>[
            Text(_styleCaption(e), style: t.caption.copyWith(color: c.text3)),
            Text(
              _sampleFor(e.key),
              style: e.value.copyWith(color: e.value.color ?? c.text1),
            ),
            const SizedBox(height: CuraSpace.s3),
          ],
        ],
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
          MessagesButton(onPressed: _noop),
          MannyChatButton(onPressed: _noop),
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
          const MannyPlaceholder(height: CuraSize.mannyPathHeight),
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
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: CuraSpace.s4,
        runSpacing: CuraSpace.s4,
        children: <Widget>[
          for (final MannyPose p in MannyPose.values)
            MannyPlaceholder(height: CuraSize.mannyPathHeight, pose: p),
          for (final MannyPose p in MannyPose.values)
            MannyPlaceholder(
              height: CuraSize.mannyHeadInButton,
              pose: p,
              crop: MannyCrop.head,
            ),
        ],
      ),
    ]),
  );
}

/// Nav und Button-Gruppe (Modus Pfad) über scrollenden Auswahlkarten: Reserve
/// am Listenende wie in Ergänzung 2, 3.1 (Nav + 16 + 56 + 8 + 48 + 16).
Widget _navCluster(BuildContext context, ScenarioEnv env) {
  final double nav = FloatingNav.occupiedHeight(context);
  const double reserve =
      CuraSpace.pageMargin +
      CuraSize.mannyChatButton +
      CuraSpace.clusterGap +
      CuraSize.messagesButton +
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
        right: CuraSpace.pageMargin,
        bottom: nav + CuraSpace.pageMargin,
        child: KeyedSubtree(
          key: PreviewKeys.cluster,
          child: ActionCluster(
            mode: ActionClusterMode.path,
            onOpenChat: _noop,
            onOpenMessages: _noop,
          ),
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
            _glowClearance,
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

AppState _onboardingState(
  ScenarioEnv env, {
  int step = 0,
  String name = '',
  InjuryType? type,
  String other = '',
  LocalDay? date,
  bool consent = false,
  bool completed = false,
}) {
  return AppState.initial(_today(env)).copyWith(
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
  step: 3,
  name: PreviewTexts.nameValue,
  type: InjuryType.acl,
  date: _today(env).addDays(-30),
  consent: true,
  completed: true,
);

AppSeed _obEmpty(ScenarioEnv env) => const AppSeed();

AppSeed _obName(ScenarioEnv env) =>
    AppSeed(state: _onboardingState(env, name: PreviewTexts.nameValue));

AppSeed _obNameKeyboard(ScenarioEnv env) =>
    AppSeed(state: _onboardingState(env, name: PreviewTexts.nameValue));

AppSeed _obConsent(ScenarioEnv env) => AppSeed(
  state: _onboardingState(env, step: 1, name: PreviewTexts.nameValue),
);

AppSeed _obInjuryNone(ScenarioEnv env) => AppSeed(
  state: _onboardingState(
    env,
    step: 2,
    name: PreviewTexts.nameValue,
    consent: true,
  ),
);

AppSeed _obInjuryAcl(ScenarioEnv env) => AppSeed(
  state: _onboardingState(
    env,
    step: 2,
    name: PreviewTexts.nameValue,
    type: InjuryType.acl,
    consent: true,
  ),
);

AppState _otherInjury(ScenarioEnv env) => _onboardingState(
  env,
  step: 2,
  name: PreviewTexts.nameValue,
  type: InjuryType.other,
  other: PreviewTexts.injuryOtherValue,
  consent: true,
);

AppSeed _obInjuryOther(ScenarioEnv env) => AppSeed(state: _otherInjury(env));

AppSeed _obInjuryOtherKeyboard(ScenarioEnv env) =>
    AppSeed(state: _otherInjury(env));

AppSeed _obDateEmpty(ScenarioEnv env) => AppSeed(
  state: _onboardingState(
    env,
    step: 3,
    name: PreviewTexts.nameValue,
    type: InjuryType.acl,
    consent: true,
  ),
);

AppSeed _obDate(ScenarioEnv env) => AppSeed(
  state: _onboardingState(
    env,
    step: 3,
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

/// Mikrofon-Hinweis: Tipp auf den Mikrofon-Button.
AppSeed _obMicHint(ScenarioEnv env) => AppSeed(
  state: _onboardingState(env, name: PreviewTexts.nameValue),
  taps: const <String>[S.micUnavailable],
);

AppSeed _shellPath(ScenarioEnv env) => AppSeed(state: _completedState(env));

AppSeed _shellToday(ScenarioEnv env) =>
    AppSeed(state: _completedState(env), taps: const <String>[S.navToday]);

/// Alle Szenarien, in der Reihenfolge der Kontaktbögen.
const List<Scenario> kScenarios = <Scenario>[
  Scenario(id: 'cmp-typo', builder: _typo),
  Scenario(id: 'cmp-buttons', builder: _buttons, expectsPrimary: true),
  Scenario(id: 'cmp-busy', builder: _busy, loops: true),
  Scenario(id: 'cmp-forms', builder: _forms, tablet: true),
  Scenario(id: 'cmp-controls', builder: _controls),
  Scenario(id: 'cmp-surfaces', builder: _surfaces, tablet: true),
  Scenario(id: 'cmp-manny', builder: _manny),
  Scenario(
    id: 'cmp-nav-cluster',
    builder: _navCluster,
    maxBackdrops: 1,
    expectsNav: true,
    expectsCluster: true,
    tablet: true,
  ),
  Scenario(
    id: 'cmp-snackbar',
    builder: _snackbar,
    maxBackdrops: 1,
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
    transientOverlay: true,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob1-corrupt-snackbar',
    app: _obCorrupt,
    transientOverlay: true,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(
    id: 'ob-mic-hint',
    app: _obMicHint,
    expectsPrimary: true,
    expectsHeader: true,
  ),
  Scenario(id: 'shell-tab-path', app: _shellPath, expectsNav: true),
  Scenario(id: 'shell-tab-today', app: _shellToday, expectsNav: true),
];

Scenario? scenarioById(String id) {
  for (final Scenario s in kScenarios) {
    if (s.id == id) return s;
  }
  return null;
}
