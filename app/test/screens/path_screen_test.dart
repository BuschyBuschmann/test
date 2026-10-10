// Pfad-Tab im Ablauf der echten App (U3a, Brief 6.2, Ergänzung 1 3.1/3.5,
// Ergänzung 2 3.1): Layout und Mittenlage (UI-20, UI-21), Kopfzeile (UI-22,
// UI-25), Manny, Blasen und Feier (UI-23, UI-40, UI-45), Unit-Tipps und
// `NodeHint` (UI-59 bis UI-63), Manny-Tipp (UI-59 neu, UI-74), Kollisionen mit
// der Button-Gruppe (UI-24, UI-75), Laden und Fehler (A-43, E-4), Zurück und
// Escape (Plan 4.3), Fokus (A-38), Hoher Kontrast und Bewegung reduzieren.
import 'dart:async';

import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/logic/app_state.dart';
import 'package:curaone/logic/clock.dart';
import 'package:curaone/logic/manny_context.dart';
import 'package:curaone/logic/manny_occasions.dart';
import 'package:curaone/logic/manny_text_source.dart';
import 'package:curaone/logic/placeholder_pools.dart' show FactRef;
import 'package:curaone/logic/manny_state.dart';
import 'package:curaone/logic/path_generator.dart';
import 'package:curaone/logic/path_model.dart';
import 'package:curaone/logic/profile.dart';
import 'package:curaone/logic/streak.dart';
import 'package:curaone/state/app_controller.dart'
    show ProfileUpdateResult, TrainingResult;
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:curaone/ui/chat/manny_chat_screen.dart';
import 'package:curaone/ui/components/action_cluster.dart';
import 'package:curaone/ui/components/cura_snackbar.dart';
import 'package:curaone/ui/components/floating_nav.dart';
import 'package:curaone/ui/components/manny.dart';
import 'package:curaone/ui/components/manny_bubble.dart';
import 'package:curaone/ui/components/manny_chat_button.dart';
import 'package:curaone/ui/components/node_hint.dart';
import 'package:curaone/ui/components/path_header.dart';
import 'package:curaone/ui/components/path_node.dart';
import 'package:curaone/ui/components/path_outlook.dart';
import 'package:curaone/ui/components/probe_keys.dart';
import 'package:curaone/ui/home/home_shell.dart';
import 'package:curaone/ui/path/overlay_placement.dart' show kOverlayTopLimit;
import 'package:curaone/ui/path/path_source.dart';
import 'package:curaone/ui/path/path_view.dart' show MannyPerch;
import 'package:curaone/ui/start/start_loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/app_harness.dart';
import '../support/builders.dart';
import '../support/component_support.dart';
import '../support/controller_harness.dart';
import '../support/pump_app.dart';

// ---------------------------------------------------------------------------
// Helfer
// ---------------------------------------------------------------------------

/// Beispielfakt des Tages als gezeigt: kein Anlass, Ruhelage ohne Blase.
AppState _noBubble(AppState s) => s.copyWith(
  manny: MannyState(
    lastShown: <MannyOccasion, LocalDay>{MannyOccasion.fact: kToday},
  ),
);

AppState Function(AppState) _tweak(AppState Function(AppState) f) =>
    (AppState s) => f(_noBubble(s));

Future<Harness> _pump(
  WidgetTester tester, {
  AppState Function(AppState)? tweak,
  DateTime? now,
  Size size = Viewports.phone,
  double scale = 1,
  bool rm = false,
  bool screenReader = false,
  bool hc = false,
  PathSource? source,
  bool bubble = false,
}) async {
  final Harness h = await Harness.onboarded(
    now: now,
    tweak: tweak ?? (bubble ? null : _noBubble),
  );
  addTearDown(h.dispose);
  await pumpCura(
    tester,
    h.controller,
    size: size,
    textScale: scale,
    disableAnimations: rm,
    accessibleNavigation: screenReader,
    highContrast: hc,
    pathSource: source,
  );
  return h;
}

HomeShellState _shell(WidgetTester tester) =>
    tester.state<HomeShellState>(find.byType(HomeShell, skipOffstage: false));

Finder _unit(String id) =>
    find.byKey(ValueKey<String>('unit:$id'), skipOffstage: false);

Finder get _manny => find.byKey(const ValueKey<String>('path-manny'));
Finder get _bubble => find.byType(MannyBubble);
Finder get _hint => find.byType(NodeHint);
Finder get _navEntryHeute => find.descendant(
  of: find.byType(FloatingNav),
  matching: find.text(S.navToday),
);
Finder get _navEntryPfad => find.descendant(
  of: find.byType(FloatingNav),
  matching: find.text(S.navPath),
);

Rect _viewport(WidgetTester tester) =>
    tester.getRect(find.byKey(ProbeKeys.scroll));

/// Scrollt die Unit in die Mitte der Sichtfläche (programmatisch, wie ein
/// Sprung; schließt keine Overlays).
Future<void> _reveal(WidgetTester tester, String id) async {
  await Scrollable.ensureVisible(tester.element(_unit(id)), alignment: 0.5);
  await tester.pump();
}

Finder get _outlook => find.byType(PathOutlook, skipOffstage: false);

Future<void> _revealOutlook(WidgetTester tester) async {
  await Scrollable.ensureVisible(tester.element(_outlook), alignment: 0.5);
  await tester.pump();
}

/// Endfall: alles bis vor den Boss erledigt.
AppState _allDone(AppState s) => s.copyWith(
  path: s.path.copyWith(
    completedUnitIds: <String>[
      for (final PathUnit u in kSamplePath)
        if (u.kind != UnitKind.boss) u.id,
    ],
  ),
);

Future<void> _tapOutlook(WidgetTester tester) async {
  await _revealOutlook(tester);
  await tester.tap(_outlook);
  await tester.pumpAndSettle();
}

Future<void> _tapUnit(WidgetTester tester, String id) async {
  await _reveal(tester, id);
  await tester.tap(_unit(id));
  await tester.pumpAndSettle();
}

/// Mitte der gezeichneten Manny-Form (Widget ohne Trefferrand).
Rect _mannyDraw(WidgetTester tester) {
  final Rect box = tester.getRect(_manny);
  final Size draw = MannyPlaceholder.sizeFor(
    MannyCrop.full,
    CuraSize.mannyPathHeight,
  );
  final EdgeInsets insets = MannyPlaceholder.tapInsets(draw);
  return Rect.fromLTWH(
    box.left + insets.left,
    box.top + insets.top,
    draw.width,
    draw.height,
  );
}

double _baseline(WidgetTester tester) {
  final Rect draw = _mannyDraw(tester);
  return draw.top + MannyPerch.feetFromTop(draw.height);
}

Future<void> _close(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 10));
  await disposeApp(tester);
}

AppState _week(AppState s, int daysAgo) => s.copyWith(
  onboarding: s.onboarding.copyWith(injuryDate: kToday.addDays(-daysAgo)),
);

class _Pending implements PathSource {
  @override
  Future<void>? prepare() => Completer<void>().future;
}

/// Scheitert beim ersten Aufruf, danach bereit.
class _FailsOnce implements PathSource {
  int calls = 0;

  @override
  Future<void>? prepare() {
    calls++;
    if (calls == 1) throw StateError('Test: Pfad nicht ladbar');
    return null;
  }
}

class _AlwaysFails implements PathSource {
  int calls = 0;

  @override
  Future<void>? prepare() {
    calls++;
    throw StateError('Test: Pfad nicht ladbar');
  }
}

void main() {
  // -------------------------------------------------------------------------
  group('Layout und Mittenlage (UI-20, UI-21)', () {
    testWidgets('Größen 48 / 60 / 72 / 92, Kreise nach Art, Hit-Area ≥ 48 dp', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      for (final (String, double) c in <(String, double)>[
        ('w5-d1', 48),
        ('w5-goal', 60),
        ('p2-end', 72),
        ('boss', 92),
      ]) {
        await _reveal(tester, c.$1);
        expect(tester.getSize(_unit(c.$1)), Size(c.$2, c.$2), reason: c.$1);
      }
      await _close(tester);
    });

    testWidgets('geschwungen: nicht alle Units auf einer Bahn; Zukunft oben, '
        'Vergangenheit unten', (WidgetTester tester) async {
      await _pump(tester);
      final List<double> xs = <double>[];
      final List<double> ys = <double>[];
      for (final PathUnit u in kSamplePath) {
        final Rect r = tester.getRect(_unit(u.id));
        xs.add(r.center.dx.roundToDouble());
        ys.add(r.center.dy);
      }
      expect(xs.toSet().length, greaterThan(4), reason: 'geschwungen (UI-20)');
      for (int i = 1; i < ys.length; i++) {
        expect(
          ys[i],
          lessThan(ys[i - 1]),
          reason: 'Zukunft oben: ${kSamplePath[i].id}',
        );
      }
      expect(
        xs.reduce((double a, double b) => a < b ? a : b),
        greaterThanOrEqualTo(16),
      );
      expect(
        xs.reduce((double a, double b) => a > b ? a : b),
        lessThanOrEqualTo(390 - 16),
      );
      await _close(tester);
    });

    testWidgets('Beschriftungen unter Wochenzielen, Phasen-Abschlüssen und '
        'Boss; nicht für Trainingstage', (WidgetTester tester) async {
      await _pump(tester);
      expect(find.text('Wochenziel', skipOffstage: false), findsNWidgets(12));
      expect(
        find.text('Phasen-Abschluss', skipOffstage: false),
        findsNWidgets(3),
      );
      expect(find.text('Return to Sport', skipOffstage: false), findsOneWidget);
      // Dekoration: nicht doppelt zum Unit-Label im Screenreader.
      final SemanticsHandle h = tester.ensureSemantics();
      await tester.pump();
      expect(find.bySemanticsLabel('Wochenziel'), findsNothing);
      h.dispose();
      await _close(tester);
    });

    for (final Size size in Viewports.matrix) {
      for (final (String, AppState Function(AppState)) c
          in <(String, AppState Function(AppState))>[
            ('Woche 5', (AppState s) => s),
            ('Woche 1', (AppState s) => _week(s, 0)),
            ('Endfall', (AppState s) => _week(s, 200)),
          ]) {
        testWidgets('aktuelle Unit bei 40 bis 65 % der Sichtfläche, Manny auf '
            'ihr (${c.$1}, ${size.width.toInt()}×${size.height.toInt()})', (
          WidgetTester tester,
        ) async {
          await _pump(tester, size: size, tweak: _tweak(c.$2));
          final PathNode current = tester.widget<PathNode>(
            find
                .byWidgetPredicate(
                  (Widget w) => w is PathNode && w.status != UnitStatus.locked,
                  skipOffstage: false,
                )
                .first,
          );
          // Die Unit, auf der Manny sitzt: Manny-Mitte über der Unit-Mitte.
          final Rect draw = _mannyDraw(tester);
          Finder? seat;
          for (final PathUnit u in kSamplePath) {
            final Rect r = tester.getRect(_unit(u.id));
            if ((r.center.dx - draw.center.dx).abs() < 0.5 &&
                r.top >= _baseline(tester) - CuraSize.mannyPerchOverlap - 0.5 &&
                r.top <= _baseline(tester) - CuraSize.mannyPerchOverlap + 0.5) {
              seat = _unit(u.id);
            }
          }
          expect(
            seat,
            isNotNull,
            reason: 'Manny steht mit den Füßen auf einer Unit',
          );
          final Rect view = _viewport(tester);
          final double fraction =
              (tester.getRect(seat!).center.dy - view.top) / view.height;
          expect(fraction, inInclusiveRange(0.40, 0.65), reason: '$fraction');
          expect(fraction, closeTo(0.55, 0.01));
          expect(current.status, isNot(UnitStatus.locked));
          await _close(tester);
        });
      }
    }

    testWidgets('jede Unit lässt sich auf 55 % scrollen: erste, mittlere, '
        'letzte (Polster oben und unten)', (WidgetTester tester) async {
      await _pump(tester);
      final Rect view = _viewport(tester);
      for (final String id in <String>['w1-d1', 'w6-goal', 'boss']) {
        await _reveal(tester, id);
        final double f =
            (tester.getRect(_unit(id)).center.dy - view.top) / view.height;
        // Mitte (0,5) bzw. 55 % am Ende des Scrollwegs: jede Unit steht im
        // Fenster von UI-21 (40 bis 65 %).
        expect(f, inInclusiveRange(0.40, 0.65), reason: id);
      }
      await _close(tester);
    });

    testWidgets('Pfad scrollt unter der Kopfzeile; die Kopfzeile bleibt fest', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      final Rect head = tester.getRect(find.byType(PathHeader));
      await tester.drag(find.byKey(ProbeKeys.scroll), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(PathHeader)), head);
      await _close(tester);
    });
  });

  // -------------------------------------------------------------------------
  group('Kopfzeile im Pfad (UI-22, UI-25)', () {
    testWidgets(
      'Woche, Phase, Beispielpfad, Streak und Freezes aus dem Zustand',
      (WidgetTester tester) async {
        final SemanticsHandle h = tester.ensureSemantics();
        await _pump(
          tester,
          tweak: _tweak(
            (AppState s) => s.copyWith(
              streak: const StreakState(
                count: 12,
                freezes: 1,
                lastTrainingDay: LocalDay(2026, 10, 6),
                evaluatedThrough: LocalDay(2026, 10, 6),
              ),
            ),
          ),
        );
        expect(find.text('Woche 5'), findsOneWidget);
        expect(find.text('Phase 2 · Kreuzband'), findsOneWidget);
        expect(find.text('BEISPIELPFAD'), findsOneWidget);
        expect(find.bySemanticsLabel('Streak: 12 Tage'), findsOneWidget);
        expect(find.bySemanticsLabel('Streak-Freezes: 1'), findsOneWidget);
        h.dispose();
        await _close(tester);
      },
    );

    testWidgets('eingefroren: das Wort steht in der Kopfzeile (UI-18, UI-22)', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _pump(
        tester,
        tweak: _tweak(
          (AppState s) => s.copyWith(
            streak: const StreakState(
              count: 12,
              freezes: 1,
              lastTrainingDay: LocalDay(2026, 10, 5),
              evaluatedThrough: LocalDay(2026, 10, 6),
              coveredInGap: 1,
            ),
          ),
        ),
      );
      expect(find.text(S.streakFrozenWord), findsOneWidget);
      expect(
        find.bySemanticsLabel('Streak: 12 Tage, eingefroren'),
        findsOneWidget,
      );
      h.dispose();
      await _close(tester);
    });

    testWidgets('Kopfzeile steht im festen Kopf (Marker header); ab 1,5 läuft '
        'sie in der Scrollfläche mit (Marker scroll-header)', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      expect(find.byKey(ProbeKeys.header), findsOneWidget);
      expect(find.byKey(ProbeKeys.scrollHeader), findsNothing);
      await _close(tester);
      await _pump(tester, scale: 2, size: Viewports.small);
      expect(find.byKey(ProbeKeys.header), findsNothing);
      expect(find.byKey(ProbeKeys.scrollHeader), findsOneWidget);
      // Sie ist per Scrollen erreichbar: ganz nach oben.
      final ScrollableState st = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(ProbeKeys.scroll),
          matching: find.byType(Scrollable),
        ),
      );
      st.position.jumpTo(0);
      await tester.pump();
      final Rect head = tester.getRect(find.byType(PathHeader));
      expect(head.top, greaterThanOrEqualTo(0));
      expect(head.bottom, lessThan(568));
      await _close(tester);
    });

    testWidgets('„Deine Daten“ ist der Einstieg und tut bis U4 nichts', (
      WidgetTester tester,
    ) async {
      final Harness h = await _pump(tester);
      final AppState before = h.state;
      await tester.tap(find.byTooltip(S.dataSheetOpen));
      await tester.pumpAndSettle();
      expect(h.state, before);
      expect(find.byType(HomeShell), findsOneWidget);
      await _close(tester);
    });
  });

  // -------------------------------------------------------------------------
  group('Manny-Blase und Anlässe (UI-23, UI-40, UI-45)', () {
    testWidgets('Beispielfakt beim ersten Besuch; Text aus der Textquelle', (
      WidgetTester tester,
    ) async {
      final Harness h = await Harness.onboarded();
      addTearDown(h.dispose);
      await pumpCura(tester, h.controller);
      expect(_bubble, findsOneWidget);
      expect(
        find.text('Dein Gewebe baut sich gerade aktiv um. Heute zählt.'),
        findsOneWidget,
      );
      expect(
        h.controller.transient.visibleBubble?.occasion,
        MannyOccasion.fact,
      );
      await _close(tester);
    });

    testWidgets('der Text kommt aus der MannyTextSource (Fake)', (
      WidgetTester tester,
    ) async {
      final Harness h = await Harness.onboarded(text: FakeMannyTextSource());
      addTearDown(h.dispose);
      await pumpCura(tester, h.controller);
      expect(find.text('FAKE fact Jakob'), findsOneWidget);
      await _close(tester);
    });

    testWidgets('X ≥ 48 dp, Label „Nachricht schließen“; schließt, zählt als '
        'gezeigt und erscheint am selben Tag nicht erneut', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle sem = tester.ensureSemantics();
      final Harness h = await _pump(tester, bubble: true);
      expect(find.bySemanticsLabel(S.bubbleClose), findsOneWidget);
      final Size x = tester.getSize(find.byTooltip(S.bubbleClose));
      expect(x.width, greaterThanOrEqualTo(48));
      expect(x.height, greaterThanOrEqualTo(48));
      await tester.tap(find.byTooltip(S.bubbleClose));
      await tester.pumpAndSettle();
      expect(_bubble, findsNothing);
      expect(
        h.state.manny.shownOn(MannyOccasion.fact, h.controller.today),
        isTrue,
      );
      // Tab hin und zurück: kein neuer Besuch zeigt dieselbe Blase.
      await tester.tap(_navEntryHeute);
      await tester.pumpAndSettle();
      await tester.tap(_navEntryPfad);
      await tester.pumpAndSettle();
      expect(_bubble, findsNothing);
      sem.dispose();
      await _close(tester);
    });

    testWidgets('Tipp irgendwo schließt die Blase; darunterliegende Elemente '
        'bleiben bedienbar', (WidgetTester tester) async {
      final Harness h = await _pump(tester, bubble: true);
      expect(_bubble, findsOneWidget);
      // Tipp auf „Heute“ in der Nav: Blase zu und Tab wechselt.
      await tester.tap(_navEntryHeute);
      await tester.pumpAndSettle();
      expect(h.controller.transient.visibleBubble, isNull);
      expect(_shell(tester).activeTab, HomeTab.today);
      await _close(tester);
    });

    testWidgets('Tipp auf die Kopfzeile schließt die Blase', (
      WidgetTester tester,
    ) async {
      final Harness h = await _pump(tester, bubble: true);
      await tester.tapAt(tester.getRect(find.byType(PathHeader)).center);
      await tester.pumpAndSettle();
      expect(h.controller.transient.visibleBubble, isNull);
      expect(
        h.state.manny.shownOn(MannyOccasion.fact, h.controller.today),
        isTrue,
      );
      await _close(tester);
    });

    testWidgets(
      'X und „Tipp irgendwo“ rufen zweimal: Schließen ist idempotent',
      (WidgetTester tester) async {
        final Harness h = await _pump(tester, bubble: true);
        int writes = 0;
        h.controller.addListener(() => writes++);
        await tester.tap(find.byTooltip(S.bubbleClose));
        await tester.pumpAndSettle();
        expect(_bubble, findsNothing);
        expect(
          h.state.manny.lastShown.entries
              .where(
                (MapEntry<MannyOccasion, LocalDay> e) =>
                    e.key == MannyOccasion.fact,
              )
              .length,
          1,
        );
        expect(
          writes,
          lessThanOrEqualTo(2),
          reason: 'ein Schließen, kein Doppelschreiben',
        );
        await _close(tester);
      },
    );

    testWidgets('Begrüßung einmal nach dem Onboarding, Pose neutral', (
      WidgetTester tester,
    ) async {
      final Harness h = await _pump(
        tester,
        tweak: (AppState s) => _week(
          s.copyWith(manny: const MannyState(greetingPending: true)),
          0,
        ),
      );
      expect(
        find.text("Moin Jakob, los geht's. Dein Weg beginnt hier."),
        findsOneWidget,
      );
      expect(tester.widget<MannyPlaceholder>(_manny).pose, MannyPose.neutral);
      await tester.tap(find.byTooltip(S.bubbleClose));
      await tester.pumpAndSettle();
      expect(h.state.manny.greetingPending, isFalse);
      expect(tester.widget<MannyPlaceholder>(_manny).pose, MannyPose.neutral);
      await _close(tester);
    });

    testWidgets('Streak-Gefahr ab 18:00, nicht um 17:59; Pose motiviert', (
      WidgetTester tester,
    ) async {
      AppState streak12(AppState s) => s.copyWith(
        manny: const MannyState(),
        streak: const StreakState(
          count: 12,
          lastTrainingDay: LocalDay(2026, 10, 6),
          evaluatedThrough: LocalDay(2026, 10, 6),
        ),
      );
      await _pump(tester, tweak: streak12, now: DateTime(2026, 10, 7, 17, 59));
      expect(find.textContaining('wartet auf dich'), findsNothing);
      await _close(tester);
      await _pump(tester, tweak: streak12, now: DateTime(2026, 10, 7, 18));
      expect(
        find.text(
          'Dein Streak von 12 Tagen wartet auf dich. Heute noch eine Runde?',
        ),
        findsOneWidget,
      );
      expect(tester.widget<MannyPlaceholder>(_manny).pose, MannyPose.motiviert);
      await _close(tester);
    });

    testWidgets('Neustart nach Reset: Nachricht und Pose motiviert', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        tweak: (AppState s) => s.copyWith(
          manny: const MannyState(),
          streak: const StreakState(
            freezes: 0,
            uncoveredInGap: 2,
            resetNoticePending: true,
          ),
        ),
      );
      expect(
        find.text(
          'Neuer Anlauf, Jakob. Dein Pfad bleibt, der Streak startet heute neu.',
        ),
        findsOneWidget,
      );
      expect(tester.widget<MannyPlaceholder>(_manny).pose, MannyPose.motiviert);
      await _close(tester);
    });

    testWidgets('Feier erst beim nächsten Pfad-Besuch nach dem Rückgängig-'
        'Fenster: Text, Pose feiernd, einmaliger Ring-Puls (UI-40)', (
      WidgetTester tester,
    ) async {
      final Harness h = await _pump(tester);
      await tester.tap(_navEntryHeute);
      await tester.pumpAndSettle();
      final TrainingResult r = h.controller.logTraining(
        forDay: h.controller.today,
      );
      expect(r.applied, isTrue);
      await tester.pump();
      expect(h.controller.transient.undoWindowOpen, isTrue);
      expect(_bubble, findsNothing, reason: 'Heute zeigt keine Feier');

      await tester.tap(_navEntryPfad);
      await tester.pump(); // Wechsel
      await tester.pump(); // Besuch (nach dem Frame)
      await tester.pump();
      expect(h.controller.transient.undoWindowOpen, isFalse);
      expect(find.text('Stark, Jakob. Das war Tag 1.'), findsOneWidget);
      expect(tester.widget<MannyPlaceholder>(_manny).pose, MannyPose.feiernd);
      // Ring-Puls auf der erledigten Unit.
      expect(tester.widget<PathNode>(_unit('w5-d1')).pulse, isTrue);
      // Feier und Puls sind verbraucht.
      expect(h.state.celebration, isNull);
      expect(h.state.path.pulsePending, isNull);
      await tester.pumpAndSettle();
      expect(
        tester.widget<PathNode>(_unit('w5-d1')).pulse,
        isFalse,
        reason: 'einmalig',
      );
      // Manny sitzt jetzt auf der nächsten Unit.
      expect(
        tester.widget<PathNode>(_unit('w5-d2')).status,
        UnitStatus.current,
      );
      await tester.tap(find.byTooltip(S.bubbleClose));
      await tester.pumpAndSettle();
      expect(
        h.state.manny.shownOn(MannyOccasion.celebration, h.controller.today),
        isTrue,
      );
      expect(tester.widget<MannyPlaceholder>(_manny).pose, MannyPose.neutral);
      await _close(tester);
    });

    testWidgets('Rückgängig vor dem Pfad-Besuch: keine Feier', (
      WidgetTester tester,
    ) async {
      final Harness h = await _pump(tester);
      await tester.tap(_navEntryHeute);
      await tester.pumpAndSettle();
      final TrainingResult r = h.controller.logTraining(
        forDay: h.controller.today,
      );
      h.controller.undoTraining(r.snapshot!);
      await tester.tap(_navEntryPfad);
      await tester.pumpAndSettle();
      expect(_bubble, findsNothing);
      expect(h.state.celebration, isNull);
      await _close(tester);
    });

    testWidgets(
      'Feier bei reduzierter Bewegung: Blase ja, Ring-Puls nein (UI-8)',
      (WidgetTester tester) async {
        final Harness h = await _pump(tester, rm: true);
        await tester.tap(_navEntryHeute);
        await tester.pumpAndSettle();
        h.controller.logTraining(forDay: h.controller.today);
        await tester.tap(_navEntryPfad);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        expect(find.text('Stark, Jakob. Das war Tag 1.'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 121));
        expect(tester.binding.transientCallbackCount, 0);
        expect(tester.widget<PathNode>(_unit('w5-d1')).pulse, isFalse);
        await _close(tester);
      },
    );

    testWidgets('Priorität: Feier vor Neustart und Begrüßung', (
      WidgetTester tester,
    ) async {
      final Harness h = await _pump(
        tester,
        tweak: (AppState s) => s.copyWith(
          manny: const MannyState(greetingPending: true),
          celebration: CelebrationState(day: kToday, unitId: 'w5-d1'),
          path: const PathState(
            completedUnitIds: <String>['w5-d1'],
            pulsePending: 'w5-d1',
          ),
        ),
      );
      expect(
        h.controller.transient.visibleBubble?.occasion,
        MannyOccasion.celebration,
      );
      await _close(tester);
    });

    testWidgets('scrollt der Nutzer, schließt die Blase (zählt als gezeigt); '
        'programmatisches Scrollen lässt sie stehen', (
      WidgetTester tester,
    ) async {
      final Harness h = await _pump(tester, bubble: true);
      expect(_bubble, findsOneWidget);
      await _reveal(tester, 'w1-d1');
      expect(_bubble, findsOneWidget, reason: 'Sprung schließt nicht');
      await tester.drag(find.byKey(ProbeKeys.scroll), const Offset(0, -120));
      await tester.pumpAndSettle();
      expect(_bubble, findsNothing);
      expect(
        h.state.manny.shownOn(MannyOccasion.fact, h.controller.today),
        isTrue,
      );
      await _close(tester);
    });

    testWidgets('Blase ist nicht modal: Unit, Nav und Chat-Button bedienbar, '
        'kein Blur über dem Budget (Nav plus Blase)', (
      WidgetTester tester,
    ) async {
      await _pump(tester, bubble: true);
      expect(backdropCount(tester), lessThanOrEqualTo(2));
      expect(
        find
            .byType(ModalBarrier)
            .evaluate()
            .where((Element e) => (e.widget as ModalBarrier).dismissible)
            .length,
        0,
      );
      await _close(tester);
    });
  });

  // -------------------------------------------------------------------------
  group('Unit-Tipps (UI-59, UI-60 bis UI-63)', () {
    testWidgets('Tipp auf die aktuelle Unit wechselt auf Heute; die Blase '
        'schließt (UI-59)', (WidgetTester tester) async {
      final Harness h = await _pump(tester, bubble: true);
      expect(_bubble, findsOneWidget);
      await _tapUnit(tester, 'w5-d1');
      expect(_shell(tester).activeTab, HomeTab.today);
      expect(
        tester.widget<FloatingNav>(find.byType(FloatingNav)).currentIndex,
        HomeTab.today,
      );
      expect(h.controller.transient.visibleBubble, isNull);
      expect(
        h.state.manny.shownOn(MannyOccasion.fact, h.controller.today),
        isTrue,
      );
      await _close(tester);
    });

    testWidgets(
      'aktuelle Unit öffnet Heute auch, wenn heute schon erledigt ist',
      (WidgetTester tester) async {
        await _pump(
          tester,
          tweak: _tweak(
            (AppState s) => s.copyWith(day: s.day.copyWith(done: true)),
          ),
        );
        await _tapUnit(tester, 'w5-d1');
        expect(_shell(tester).activeTab, HomeTab.today);
        await _close(tester);
      },
    );

    for (final (String, String, String) c in <(String, String, String)>[
      ('Trainingstag, laufende Woche', 'w5-d2', 'Kommt noch diese Woche'),
      ('Wochenziel, laufende Woche', 'w5-goal', 'Kommt noch diese Woche'),
      ('Trainingstag, spätere Woche', 'w7-d1', 'Kommt in Woche 7'),
      ('Wochenziel, spätere Woche', 'w6-goal', 'Kommt in Woche 6'),
      ('Phasen-Abschluss', 'p2-end', 'Phasen-Abschluss kommt in Woche 8'),
      ('Boss', 'boss', 'Return to Sport kommt in Woche 12'),
    ]) {
      testWidgets('gesperrt: ${c.$1} → „${c.$3}“, kein Tabwechsel (UI-60)', (
        WidgetTester tester,
      ) async {
        await _pump(tester);
        await _tapUnit(tester, c.$2);
        expect(find.text(c.$3), findsOneWidget);
        expect(_hint, findsOneWidget);
        expect(_shell(tester).activeTab, HomeTab.path);
        await _close(tester);
      });
    }

    testWidgets('Boss in der laufenden Woche 12: „Dein Ziel: zurück in deinen '
        'Sport.“', (WidgetTester tester) async {
      await _pump(tester, tweak: _tweak((AppState s) => _week(s, 200)));
      await _tapUnit(tester, 'boss');
      expect(find.text('Dein Ziel: zurück in deinen Sport.'), findsOneWidget);
      await _close(tester);
    });

    testWidgets(
      'erledigt → „Erledigt. Das hast du geschafft.“, kein Tabwechsel '
      '(UI-61)',
      (WidgetTester tester) async {
        await _pump(tester);
        await _tapUnit(tester, 'w3-d2');
        expect(find.text('Erledigt. Das hast du geschafft.'), findsOneWidget);
        expect(_shell(tester).activeTab, HomeTab.path);
        await _close(tester);
      },
    );

    testWidgets('Hinweis: opak, ohne Blur, höchstens einer; ein neuer ersetzt '
        'den alten; vollständig im Bild mit ≥ 16 dp Rand (UI-62)', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      await _tapUnit(tester, 'w3-d2');
      final CuraColors c = colorsAt(tester, _hint);
      final BoxDecoration d = decorationsUnder(
        tester,
        _hint,
      ).firstWhere((BoxDecoration x) => x.borderRadius != null);
      expect(d.color, c.surfaceOpaque);
      expect(backdropCount(tester), 1, reason: 'nur die Nav');
      await _tapUnit(tester, 'w7-d1');
      expect(_hint, findsOneWidget);
      expect(find.text('Kommt in Woche 7'), findsOneWidget);
      expect(find.text('Erledigt. Das hast du geschafft.'), findsNothing);
      final Rect r = tester.getRect(_hint);
      expect(r.left, greaterThanOrEqualTo(16));
      expect(r.right, lessThanOrEqualTo(390 - 16));
      expect(r.top, greaterThanOrEqualTo(_viewport(tester).top));
      expect(r.width, lessThanOrEqualTo(240));
      await _close(tester);
    });

    testWidgets('Pfeil zeigt auf die getippte Unit', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      await _tapUnit(tester, 'w3-d2');
      final Rect hint = tester.getRect(_hint);
      final Rect unit = tester.getRect(_unit('w3-d2'));
      final NodeHint w = tester.widget<NodeHint>(_hint);
      if (w.arrow == HintArrow.down) {
        expect(hint.bottom, closeTo(unit.top, 0.5));
        expect(hint.left + w.arrowCenter, closeTo(unit.center.dx, 0.5));
      } else if (w.arrow == HintArrow.up) {
        expect(hint.top, closeTo(unit.bottom, 0.5));
        expect(hint.left + w.arrowCenter, closeTo(unit.center.dx, 0.5));
      } else {
        expect(hint.top + w.arrowCenter, closeTo(unit.center.dy, 0.5));
      }
      await _close(tester);
    });

    testWidgets('Hinweis schließt: Tipp irgendwo, Escape, Zurück, Tabwechsel, '
        'Scrollen durch den Nutzer, Chat öffnen (UI-62)', (
      WidgetTester tester,
    ) async {
      final Harness h = await _pump(tester);
      Future<void> show() => _tapUnit(tester, 'w3-d2');

      await show();
      await tester.tapAt(tester.getRect(find.byType(PathHeader)).center);
      await tester.pumpAndSettle();
      expect(_hint, findsNothing, reason: 'Tipp irgendwo');

      await show();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_hint, findsNothing, reason: 'Escape');

      await show();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_hint, findsNothing, reason: 'Zurück');
      expect(find.byType(HomeShell), findsOneWidget);

      await show();
      await tester.tap(_navEntryHeute);
      await tester.pumpAndSettle();
      expect(h.controller.transient.hintUnitId, isNull, reason: 'Tabwechsel');
      await tester.tap(_navEntryPfad);
      await tester.pumpAndSettle();
      expect(_hint, findsNothing);

      await show();
      await tester.drag(find.byKey(ProbeKeys.scroll), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(_hint, findsNothing, reason: 'Scrollen');

      await show();
      await tester.tap(find.byType(MannyChatButton));
      await tester.pumpAndSettle();
      expect(h.controller.transient.hintUnitId, isNull, reason: 'Chat öffnen');
      await _close(tester);
    });

    testWidgets('Hinweis schließt nach 5 s', (WidgetTester tester) async {
      await _pump(tester);
      await _tapUnit(tester, 'w3-d2');
      await tester.pump(const Duration(milliseconds: 4600));
      expect(_hint, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
      expect(_hint, findsNothing);
      await _close(tester);
    });

    testWidgets(
      'bei aktivem Screenreader schließt der Hinweis nicht von selbst',
      (WidgetTester tester) async {
        final SemanticsHandle h = tester.ensureSemantics();
        await _pump(tester, screenReader: true);
        await _tapUnit(tester, 'w3-d2');
        await tester.pump(const Duration(seconds: 12));
        expect(_hint, findsOneWidget);
        expect(
          find.bySemanticsLabel('Erledigt. Das hast du geschafft.'),
          findsOneWidget,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(_hint, findsNothing);
        h.dispose();
        await _close(tester);
      },
    );

    testWidgets('Hinweis mit Textskalierung 2,0: bricht um, bleibt im Bild und '
        'über der Gruppe (320 × 568)', (WidgetTester tester) async {
      await _pump(tester, size: Viewports.small, scale: 2);
      await _tapUnit(tester, 'w7-d1');
      final Rect hint = tester.getRect(_hint);
      final Rect cluster = tester.getRect(find.byType(ActionCluster));
      expect(hint.left, greaterThanOrEqualTo(16));
      expect(hint.right, lessThanOrEqualTo(320 - 16));
      expect(hint.bottom, lessThanOrEqualTo(cluster.top - 8 + 0.5));
      expect(hint.overlaps(cluster), isFalse);
      await _close(tester);
    });

    testWidgets(
      'Units: sichtbarer Fokus, Enter und Leertaste lösen aus (UI-63)',
      (WidgetTester tester) async {
        await _pump(tester);
        // Zum ersten Unit-Fokus tabben (Kopf: „Deine Daten“, dann Units).
        for (int i = 0; i < 3; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }
        final BuildContext ctx = FocusManager.instance.primaryFocus!.context!;
        PathNode? node;
        ctx.visitAncestorElements((Element e) {
          if (e.widget is PathNode) node = e.widget as PathNode;
          return node == null;
        });
        expect(node, isNotNull, reason: 'Fokus liegt auf einer Unit');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        final bool acted =
            _hint.evaluate().isNotEmpty ||
            _shell(tester).activeTab == HomeTab.today;
        expect(acted, isTrue);
        await _close(tester);
      },
    );

    testWidgets('Labels: „Woche 5, Trainingstag 1, aktuell. Öffnet Heute.“, '
        '„… gesperrt.“, „… erledigt.“, Boss (A-14)', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _pump(tester);
      for (final PathUnit u in <PathUnit>[
        kSamplePath.firstWhere((PathUnit x) => x.id == 'w5-d1'),
        kSamplePath.firstWhere((PathUnit x) => x.id == 'w5-d2'),
        kSamplePath.firstWhere((PathUnit x) => x.id == 'w3-d2'),
      ]) {
        await _reveal(tester, u.id);
        final PathNode n = tester.widget<PathNode>(_unit(u.id));
        expect(
          find.bySemanticsLabel(n.semanticLabel),
          findsOneWidget,
          reason: u.id,
        );
      }
      expect(
        tester.widget<PathNode>(_unit('w5-d1')).semanticLabel,
        'Woche 5, Trainingstag 1, aktuell. Öffnet Heute.',
      );
      expect(
        tester.widget<PathNode>(_unit('boss')).semanticLabel,
        'Return to Sport, gesperrt.',
      );
      expect(
        tester.widget<PathNode>(_unit('w5-goal')).semanticLabel,
        'Woche 5, Wochenziel, gesperrt.',
      );
      expect(
        tester.widget<PathNode>(_unit('p1-end')).semanticLabel,
        'Woche 4, Phasen-Abschluss, erledigt.',
      );
      h.dispose();
      await _close(tester);
    });
  });

  // -------------------------------------------------------------------------
  group('Manny-Tipp (UI-59 neu, UI-74, A-38)', () {
    testWidgets('Tipp auf Manny öffnet den Chat, der Tab bleibt, die Blase '
        'schließt und kommt nicht wieder', (WidgetTester tester) async {
      final Harness h = await _pump(tester, bubble: true);
      expect(_bubble, findsOneWidget);
      await tester.tapAt(_mannyDraw(tester).center);
      await tester.pumpAndSettle();
      expect(find.byType(MannyChatScreen), findsOneWidget);
      expect(_shell(tester).activeTab, HomeTab.path);
      expect(h.controller.transient.visibleBubble, isNull);
      expect(
        h.state.manny.shownOn(MannyOccasion.fact, h.controller.today),
        isTrue,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MannyChatScreen), findsNothing);
      expect(_bubble, findsNothing, reason: 'am selben Tag nicht erneut');
      await _close(tester);
    });

    testWidgets('Fokus kehrt nach dem Chat an den Manny-Button zurück (A-38)', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      await tester.tapAt(_mannyDraw(tester).center);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final BuildContext? ctx = FocusManager.instance.primaryFocus?.context;
      bool onButton = false;
      ctx?.visitAncestorElements((Element e) {
        if (e.widget is MannyChatButton) onButton = true;
        return !onButton;
      });
      expect(onButton, isTrue);
      await _close(tester);
    });

    testWidgets(
      'Trefferfläche: Form und 8-dp-Rand ja, außerhalb nein; unter der '
      'Standlinie gilt die Unit (UI-74)',
      (WidgetTester tester) async {
        await _pump(tester);
        final Rect draw = _mannyDraw(tester);
        final double base = _baseline(tester);

        Future<bool> opensChat(Offset p) async {
          await tester.tapAt(p);
          await tester.pumpAndSettle();
          final bool open = find.byType(MannyChatScreen).evaluate().isNotEmpty;
          if (open) {
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
          }
          return open;
        }

        final Path hit = MannyPlaceholder.hitPath(
          size: draw.size,
          pose: MannyPose.neutral,
        );
        Offset at(Offset o) => draw.topLeft + o;
        // Punkte relativ zur gezeichneten Form (Ursprung oben links).
        final Offset body = Offset(draw.width / 2, 40);
        const Offset margin = Offset(6, 40); // knapp außerhalb des Körpers
        const Offset outside = Offset(-14, 40);
        expect(hit.contains(body), isTrue);
        expect(hit.contains(margin), isTrue, reason: 'im 8-dp-Rand');
        expect(hit.contains(outside), isFalse);
        expect(await opensChat(at(body)), isTrue, reason: 'Körper');
        expect(await opensChat(at(margin)), isTrue, reason: 'Rand');
        expect(await opensChat(at(outside)), isFalse, reason: '14 dp daneben');
        // Unterhalb der Standlinie: die Unit, nicht Manny (aktuell → Heute).
        await tester.tapAt(Offset(draw.center.dx, base + 4));
        await tester.pumpAndSettle();
        expect(find.byType(MannyChatScreen), findsNothing);
        expect(_shell(tester).activeTab, HomeTab.today);
        await _close(tester);
      },
    );

    testWidgets('Manny hat keine Fokusstation und keine Button-Semantik, das '
        'Bild-Label bleibt (UI-74)', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await _pump(tester);
      expect(find.bySemanticsLabel(S.mannyImageLabel), findsOneWidget);
      final SemanticsData d = tester
          .getSemantics(find.bySemanticsLabel(S.mannyImageLabel))
          .getSemanticsData();
      expect(d.flagsCollection.isButton, isFalse);
      expect(d.hasAction(SemanticsAction.tap), isFalse);
      expect(d.flagsCollection.isImage, isTrue);
      // Tab-Traversal: keine Station in Manny.
      for (int i = 0; i < 70; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final BuildContext? ctx = FocusManager.instance.primaryFocus?.context;
        bool inManny = false;
        ctx?.visitAncestorElements((Element e) {
          if (e.widget is MannyPlaceholder &&
              (e.widget as MannyPlaceholder).onTap != null) {
            inManny = true;
          }
          return !inManny;
        });
        expect(inManny, isFalse, reason: 'Tab $i');
      }
      h.dispose();
      await _close(tester);
    });

    testWidgets(
      'nur auf dem Pfad tippbar: Manny im Button ist kein Chat-Einstieg '
      'zusätzlich (ein Chat, nicht zwei)',
      (WidgetTester tester) async {
        await _pump(tester);
        await tester.tap(find.byType(MannyChatButton));
        await tester.pumpAndSettle();
        expect(find.byType(MannyChatScreen), findsOneWidget);
        await _close(tester);
      },
    );
  });

  // -------------------------------------------------------------------------
  group(
    'Ausblick „Prävention & Gesundheitssport“ (Ergänzung 3, UI-90 bis UI-99)',
    () {
      for (final Size size in Viewports.matrix) {
        testWidgets('UI-90, UI-91, UI-94: Marke mittig, ≤ 300 dp und ≤ Breite '
            '− 32, ≥ 72 dp hoch, Boss darunter mit ≥ 84 dp Abstand '
            '(${size.width.toInt()} × ${size.height.toInt()})', (
          WidgetTester tester,
        ) async {
          await _pump(tester, size: size);
          expect(find.text(S.outlookTitle), findsOneWidget);
          expect(find.text(S.outlookSubtitle), findsOneWidget);
          final Rect o = tester.getRect(_outlook);
          final Rect boss = tester.getRect(_unit('boss'));
          expect(o.width, lessThanOrEqualTo(300 + 0.01));
          expect(o.width, lessThanOrEqualTo(size.width - 32 + 0.01));
          expect(
            o.width,
            closeTo(size.width - 32 < 300 ? size.width - 32 : 300, 0.01),
          );
          expect(o.center.dx, closeTo(size.width / 2, 0.5));
          expect(o.height, greaterThanOrEqualTo(72));
          expect(boss.width, 92);
          expect(o.bottom, lessThanOrEqualTo(boss.top - 84 + 0.01));
          // Darüber steht keine weitere Unit.
          for (final Element e
              in find.byType(PathNode, skipOffstage: false).evaluate()) {
            final RenderBox box = e.renderObject! as RenderBox;
            final double top = box.localToGlobal(Offset.zero).dy;
            expect(top, greaterThanOrEqualTo(boss.top - 0.01));
          }
          await _close(tester);
        });
      }

      testWidgets('UI-90, UI-95: genau 52 Units, die Marke ist keine Unit und '
          'trägt weder Ring noch Manny', (WidgetTester tester) async {
        await _pump(tester, tweak: _tweak(_allDone));
        expect(find.byType(PathNode, skipOffstage: false), findsNWidgets(52));
        expect(
          find.descendant(
            of: _outlook,
            matching: find.byType(PathNode, skipOffstage: false),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: _outlook,
            matching: find.byType(MannyPlaceholder, skipOffstage: false),
          ),
          findsNothing,
        );
        final Rect o = tester.getRect(_outlook);
        expect(tester.getRect(_manny).overlaps(o), isFalse);
        expect(kPathOutlookShown, isTrue);
        await _close(tester);
      });

      testWidgets('UI-91: Glas ohne Blur, gestrichelter Rand lockedBorder 6/4, '
          'Schloss-Kreis 36 dp, Titel text-1, Untertitel text-2, keine '
          'Animation', (WidgetTester tester) async {
        await _pump(tester);
        await _revealOutlook(tester);
        final CuraColors c = colorsAt(tester, _outlook);
        expect(backdropCount(tester), 1, reason: 'nur die Nav');
        final DashedRRectPainter dashed = tester
            .widgetList<CustomPaint>(
              find.descendant(of: _outlook, matching: find.byType(CustomPaint)),
            )
            .map((CustomPaint p) => p.foregroundPainter)
            .whereType<DashedRRectPainter>()
            .single;
        expect(dashed.color, c.lockedBorder);
        expect(dashed.dash, 6);
        expect(dashed.gap, 4);
        expect(dashed.width, 1.5);
        expect(dashed.radius, 24);
        final BoxDecoration glass = decorationsUnder(
          tester,
          _outlook,
        ).firstWhere((BoxDecoration x) => x.gradient != null);
        expect(glass.gradient, c.cardFill);
        final Finder lock = find.descendant(
          of: _outlook,
          matching: find.byIcon(Icons.lock_rounded),
        );
        expect(lock, findsOneWidget);
        expect(tester.widget<Icon>(lock).color, c.lockedIcon);
        final Finder circle = find.ancestor(
          of: lock,
          matching: find.byWidgetPredicate(
            (Widget w) => w is SizedBox && w.width == 36 && w.height == 36,
          ),
        );
        expect(circle, findsOneWidget);
        expect(
          tester.widget<Text>(find.text(S.outlookTitle)).style!.color,
          c.text1,
        );
        expect(
          tester.widget<Text>(find.text(S.outlookSubtitle)).style!.color,
          c.text2,
        );
        expect(
          find.descendant(
            of: _outlook,
            matching: find.byIcon(Icons.star_rounded),
          ),
          findsNothing,
        );
        expect(tester.hasRunningAnimations, isFalse);
        await _close(tester);
      });

      testWidgets(
        'UI-91: Hoher Kontrast opak mit border-control-hc, kein Blur',
        (WidgetTester tester) async {
          await _pump(tester, hc: true);
          await _revealOutlook(tester);
          final CuraColors c = colorsAt(tester, _outlook);
          expect(c.highContrast, isTrue);
          final DashedRRectPainter dashed = tester
              .widgetList<CustomPaint>(
                find.descendant(
                  of: _outlook,
                  matching: find.byType(CustomPaint),
                ),
              )
              .map((CustomPaint p) => p.foregroundPainter)
              .whereType<DashedRRectPainter>()
              .single;
          expect(dashed.color, c.controlBorder);
          final BoxDecoration glass = decorationsUnder(
            tester,
            _outlook,
          ).firstWhere((BoxDecoration x) => x.gradient != null);
          expect(glass.gradient!.colors, <Color>[
            c.surfaceOpaque,
            c.surfaceOpaque,
          ]);
          expect(backdropCount(tester), 0, reason: 'HC: kein Blur');
          await _close(tester);
        },
      );

      testWidgets('UI-92: Tipp zeigt den NodeHint, kein Tabwechsel, schließt '
          'die Manny-Blase, höchstens einer, Pfeil auf die Mitte der Marke', (
        WidgetTester tester,
      ) async {
        final Harness h = await _pump(tester, bubble: true);
        expect(_bubble, findsOneWidget);
        await _tapOutlook(tester);
        expect(find.text(S.outlookHint), findsOneWidget);
        expect(_hint, findsOneWidget);
        expect(_bubble, findsNothing);
        expect(h.controller.transient.visibleBubble, isNull);
        expect(_shell(tester).activeTab, HomeTab.path);
        final CuraColors c = colorsAt(tester, _hint);
        final BoxDecoration d = decorationsUnder(
          tester,
          _hint,
        ).firstWhere((BoxDecoration x) => x.borderRadius != null);
        expect(d.color, c.surfaceOpaque);
        final Rect hint = tester.getRect(_hint);
        final Rect o = tester.getRect(_outlook);
        final NodeHint w = tester.widget<NodeHint>(_hint);
        expect(w.arrow, HintArrow.down, reason: 'über der Marke');
        expect(hint.bottom, closeTo(o.top, 0.5));
        expect(hint.left + w.arrowCenter, closeTo(o.center.dx, 0.5));
        expect(hint.left, greaterThanOrEqualTo(16));
        expect(hint.right, lessThanOrEqualTo(390 - 16));
        // Ein neuer Hinweis an einer Unit ersetzt ihn (höchstens einer).
        await _tapUnit(tester, 'w3-d2');
        expect(_hint, findsOneWidget);
        expect(find.text(S.outlookHint), findsNothing);
        await _close(tester);
      });

      testWidgets('UI-92: Hinweis schließt durch Tipp, Escape, Scrollen und '
          'nach 5 s', (WidgetTester tester) async {
        await _pump(tester);
        await _tapOutlook(tester);
        await tester.tapAt(tester.getRect(find.byType(PathHeader)).center);
        await tester.pumpAndSettle();
        expect(_hint, findsNothing, reason: 'Tipp');
        await _tapOutlook(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(_hint, findsNothing, reason: 'Escape');
        await _tapOutlook(tester);
        await tester.drag(find.byKey(ProbeKeys.scroll), const Offset(0, 100));
        await tester.pumpAndSettle();
        expect(_hint, findsNothing, reason: 'Scrollen');
        await _tapOutlook(tester);
        await tester.pump(const Duration(milliseconds: 4600));
        expect(_hint, findsOneWidget);
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump();
        expect(_hint, findsNothing, reason: '5 s');
        await _close(tester);
      });

      testWidgets('UI-92, UI-93: bei aktivem Screenreader schließt der Hinweis '
          'nicht von selbst und wird angesagt (Live-Region)', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle sem = tester.ensureSemantics();
        await _pump(tester, screenReader: true);
        await _tapOutlook(tester);
        await tester.pump(const Duration(seconds: 12));
        expect(_hint, findsOneWidget);
        expect(find.bySemanticsLabel(S.outlookHint), findsOneWidget);
        expect(
          tester
              .getSemantics(find.bySemanticsLabel(S.outlookHint))
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(_hint, findsNothing);
        sem.dispose();
        await _close(tester);
      });

      testWidgets('UI-93: Schaltfläche mit Label, Hit-Area ≥ 48 dp', (
        WidgetTester tester,
      ) async {
        final SemanticsHandle sem = tester.ensureSemantics();
        await _pump(tester);
        await _revealOutlook(tester);
        final Finder label = find.bySemanticsLabel(S.outlookLabel);
        expect(label, findsOneWidget);
        expect(S.outlookLabel, 'Prävention und Gesundheitssport, gesperrt.');
        final SemanticsNode node = tester.getSemantics(label);
        expect(node.flagsCollection.isButton, isTrue);
        expect(node.rect.width, greaterThanOrEqualTo(48));
        expect(node.rect.height, greaterThanOrEqualTo(48));
        sem.dispose();
        await _close(tester);
      });

      testWidgets(
        'UI-93: Fokus Marke vor Boss vor den übrigen Units, Enter und '
        'Leertaste lösen aus, Fokusring sichtbar',
        (WidgetTester tester) async {
          await _pump(tester);
          final List<String> order = <String>[];
          for (int i = 0; i < 4; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
            await tester.pump();
            final BuildContext ctx =
                FocusManager.instance.primaryFocus!.context!;
            String kind = '?';
            ctx.visitAncestorElements((Element e) {
              final Widget w = e.widget;
              if (w is PathOutlook) {
                kind = 'outlook';
                return false;
              }
              if (w is PathNode) {
                kind = w.unit.id;
                return false;
              }
              return true;
            });
            order.add(kind);
            if (kind == 'outlook') {
              await tester.sendKeyEvent(LogicalKeyboardKey.enter);
              await tester.pumpAndSettle();
              expect(_hint, findsOneWidget, reason: 'Enter');
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
              await tester.pumpAndSettle();
              expect(_hint, findsNothing);
              await tester.sendKeyEvent(LogicalKeyboardKey.space);
              await tester.pumpAndSettle();
              expect(
                find.text(S.outlookHint),
                findsOneWidget,
                reason: 'Leertaste',
              );
            }
          }
          final int o = order.indexOf('outlook');
          expect(o, greaterThanOrEqualTo(0), reason: '$order');
          expect(order[o + 1], 'boss', reason: '$order');
          expect(order[o + 2], 'p3-end', reason: '$order');
          await _close(tester);
        },
      );

      for (final Size size in <Size>[Viewports.small, Viewports.large]) {
        testWidgets('UI-97: Marke, Boss und jede Unit lassen sich auf 55 % '
            'scrollen (${size.width.toInt()} dp)', (WidgetTester tester) async {
          await _pump(tester, size: size);
          final Rect view = _viewport(tester);
          final ScrollPosition pos = tester
              .state<ScrollableState>(
                find.descendant(
                  of: find.byKey(ProbeKeys.scroll),
                  matching: find.byType(Scrollable),
                ),
              )
              .position;
          Future<void> expect55(Finder f, String reason) async {
            final double dy = tester.getRect(f).center.dy;
            final double target = view.top + 0.55 * view.height;
            final double want = (pos.pixels + dy - target).clamp(
              pos.minScrollExtent,
              pos.maxScrollExtent,
            );
            pos.jumpTo(want);
            await tester.pump();
            expect(
              tester.getRect(f).center.dy,
              closeTo(target, 1),
              reason: reason,
            );
          }

          await expect55(_outlook, 'Marke');
          await expect55(_unit('boss'), 'Boss');
          await expect55(_unit('p3-end'), 'p3-end');
          await expect55(_unit('w6-goal'), 'mittlere Unit');
          await expect55(_unit('w1-d1'), 'erste Unit');
          // In der Endlage oben liegt die Marke nicht hinter der Kopfzeile.
          pos.jumpTo(pos.minScrollExtent);
          await tester.pump();
          expect(tester.getRect(_outlook).top, greaterThanOrEqualTo(view.top));
          await _close(tester);
        });
      }

      for (final Size size in <Size>[Viewports.small, Viewports.phone]) {
        testWidgets('UI-99: 200 % Schrift bei ${size.width.toInt()} dp: Titel '
            'bricht um, nichts überlappt, kein Abschneiden', (
          WidgetTester tester,
        ) async {
          await _pump(tester, size: size, scale: 2);
          await _revealOutlook(tester);
          final Rect o = tester.getRect(_outlook);
          final Rect title = tester.getRect(find.text(S.outlookTitle));
          final Rect sub = tester.getRect(find.text(S.outlookSubtitle));
          expect(o.height, greaterThan(72), reason: 'wächst mit der Schrift');
          expect(title.bottom, lessThanOrEqualTo(sub.top + 0.5));
          expect(title.left, greaterThanOrEqualTo(o.left));
          expect(title.right, lessThanOrEqualTo(o.right));
          expect(sub.bottom, lessThanOrEqualTo(o.bottom));
          expect(title.top, greaterThanOrEqualTo(o.top));
          expect(o.left, greaterThanOrEqualTo(16 - 0.01));
          expect(o.right, lessThanOrEqualTo(size.width - 16 + 0.01));
          expect(
            tester.getRect(_unit('boss')).top - o.bottom,
            greaterThanOrEqualTo(84 - 0.01),
          );
          await _close(tester);
        });
      }

      testWidgets('UI-99: Hinweis bei 320 × 568 und 200 % bleibt im Bild und '
          'über der Gruppe', (WidgetTester tester) async {
        await _pump(tester, size: Viewports.small, scale: 2);
        await _tapOutlook(tester);
        final Rect hint = tester.getRect(_hint);
        final Rect cluster = tester.getRect(find.byType(ActionCluster));
        expect(hint.left, greaterThanOrEqualTo(16));
        expect(hint.right, lessThanOrEqualTo(320 - 16));
        expect(hint.overlaps(cluster), isFalse);
        expect(hint.top, greaterThanOrEqualTo(_viewport(tester).top));
        await _close(tester);
      });

      testWidgets('UI-98: Kopfzeile unverändert (Woche, Phase, Beispielpfad), '
          'keine Phase 4; Texte der Marke ohne Zahl', (
        WidgetTester tester,
      ) async {
        await _pump(
          tester,
          tweak: _tweak((AppState s) => _allDone(_week(s, 200))),
        );
        expect(find.text('Woche 12'), findsOneWidget);
        expect(find.text('Phase 3 · Kreuzband'), findsOneWidget);
        expect(find.textContaining('Phase 4'), findsNothing);
        final RegExp digit = RegExp(r'\d');
        for (final String t in <String>[
          S.outlookTitle,
          S.outlookSubtitle,
          S.outlookHint,
          S.outlookLabel,
        ]) {
          expect(digit.hasMatch(t), isFalse, reason: t);
        }
        await _close(tester);
      });
    },
  );

  group('Zurück und Escape (Plan 4.3, N-6)', () {
    testWidgets('Pfad: erst Blase, dann Hinweis, dann App schließen', (
      WidgetTester tester,
    ) async {
      final SystemPopRecorder pop = SystemPopRecorder(tester);
      final Harness h = await _pump(tester, bubble: true);
      expect(_bubble, findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_bubble, findsNothing);
      expect(pop.count, 0);
      await _tapUnit(tester, 'w3-d2');
      expect(_hint, findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_hint, findsNothing);
      expect(pop.count, 0);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(pop.count, 1);
      expect(h.controller.transient.visibleBubble, isNull);
      await disposeApp(tester);
    });

    testWidgets('Escape schließt Blase und Hinweis nacheinander', (
      WidgetTester tester,
    ) async {
      final Harness h = await _pump(tester, bubble: true);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(h.controller.transient.visibleBubble, isNull);
      await _tapUnit(tester, 'w3-d2');
      expect(_hint, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_hint, findsNothing);
      await _close(tester);
    });
  });

  // -------------------------------------------------------------------------
  group('Button-Gruppe, Kollisionen und Rückfälle (UI-24, UI-75)', () {
    testWidgets('Gruppe: rechts 16 dp, über der Nav, Nachrichten-Button 8 dp '
        'über dem Manny-Button; unten links nichts', (
      WidgetTester tester,
    ) async {
      await _pump(tester);
      final Rect cluster = tester.getRect(find.byType(ActionCluster));
      final Rect nav = tester.getRect(find.byType(FloatingNav));
      expect(cluster.right, 390 - 16);
      expect(cluster.bottom, lessThanOrEqualTo(nav.top - 16 + 0.5 + 22));
      expect(cluster.bottom, closeTo(844 - (64 + 22) - 16, 0.5));
      await _close(tester);
    });

    for (final (Size, double) c in <(Size, double)>[
      (Viewports.small, 1),
      (Viewports.small, 2),
      (Viewports.phone, 1),
      (Viewports.phone, 2),
      (Viewports.large, 2),
    ]) {
      testWidgets('Blase überdeckt die Gruppe nie, mindestens 8 dp darüber '
          '(${c.$1.width.toInt()}×${c.$1.height.toInt()}, ×${c.$2})', (
        WidgetTester tester,
      ) async {
        await _pump(
          tester,
          size: c.$1,
          scale: c.$2,
          tweak: (AppState s) => _week(
            s.copyWith(
              manny: const MannyState(),
              streak: const StreakState(
                freezes: 0,
                uncoveredInGap: 2,
                resetNoticePending: true,
              ),
            ),
            0,
          ),
        );
        expect(_bubble, findsOneWidget);
        final Rect b = tester.getRect(_bubble);
        final Rect g = tester.getRect(find.byType(ActionCluster));
        expect(b.overlaps(g), isFalse);
        expect(b.bottom, lessThanOrEqualTo(g.top - 8 + 0.5));
        expect(b.left, greaterThanOrEqualTo(16 - 0.5));
        expect(b.right, lessThanOrEqualTo(c.$1.width - 16 + 0.5));
        if (c.$2 >= 1.5) {
          expect(tester.widget<MannyBubble>(_bubble).arrow, BubbleArrow.down);
        }
        // Die Blase überdeckt Manny nicht.
        expect(b.overlaps(_mannyDraw(tester).deflate(2)), isFalse);
        await tester.pumpAndSettle();
        await _close(tester);
      });
    }

    testWidgets(
      '320 × 568, ×1,0: nahe der Gruppe wechselt die Blase über Manny',
      (WidgetTester tester) async {
        await _pump(
          tester,
          size: Viewports.small,
          tweak: (AppState s) => _week(
            s.copyWith(
              manny: const MannyState(),
              streak: const StreakState(
                freezes: 0,
                uncoveredInGap: 2,
                resetNoticePending: true,
              ),
            ),
            0,
          ),
        );
        final Rect b = tester.getRect(_bubble);
        final Rect g = tester.getRect(find.byType(ActionCluster));
        expect(b.bottom, lessThanOrEqualTo(g.top - 8 + 0.5));
        expect(tester.widget<MannyBubble>(_bubble).arrow, BubbleArrow.down);
        await _close(tester);
      },
    );

    testWidgets('lange Blase bei 320 × 568 und ×2,0: begrenzt, Text scrollt '
        'innen, überdeckt die Gruppe nie', (WidgetTester tester) async {
      await _pump(
        tester,
        size: Viewports.small,
        scale: 2,
        tweak: (AppState s) => s.copyWith(
          manny: const MannyState(),
          streak: const StreakState(
            freezes: 0,
            uncoveredInGap: 2,
            resetNoticePending: true,
          ),
        ),
      );
      final MannyBubble w = tester.widget<MannyBubble>(_bubble);
      final Rect b = tester.getRect(_bubble);
      final Rect g = tester.getRect(find.byType(ActionCluster));
      expect(w.maxBodyHeight, isNotNull, reason: 'begrenzt');
      expect(
        find.descendant(
          of: _bubble,
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      expect(b.bottom, lessThanOrEqualTo(g.top - 8 + 0.5));
      expect(b.top, greaterThanOrEqualTo(0));
      // X bleibt bedienbar.
      await tester.tap(find.byTooltip(S.bubbleClose));
      await tester.pumpAndSettle();
      expect(_bubble, findsNothing);
      await _close(tester);
    });

    testWidgets('Pfad scrollt nach unten, wenn über Manny kein Platz ist und '
        'darunter Raum bleibt; die Blase gilt erst danach als erschienen', (
      WidgetTester tester,
    ) async {
      // 390 × 844, ×2,0, eine lange Nachricht: über Manny fehlen etwa 60 dp,
      // bis zur Gruppe bleiben etwa 130 dp.
      final Harness h = await Harness.onboarded(text: _LongText());
      addTearDown(h.dispose);
      await pumpCura(tester, h.controller, textScale: 2);
      expect(_bubble, findsOneWidget);
      final MannyBubble w = tester.widget<MannyBubble>(_bubble);
      expect(w.arrow, BubbleArrow.down);
      expect(
        w.maxBodyHeight,
        isNull,
        reason: 'nicht begrenzt: das Scrollen genügt',
      );
      final Rect b = tester.getRect(_bubble);
      final Rect g = tester.getRect(find.byType(ActionCluster));
      expect(b.top, greaterThanOrEqualTo(kOverlayTopLimit - 0.5));
      expect(b.overlaps(_mannyDraw(tester).deflate(2)), isFalse);
      expect(g.top, greaterThan(_mannyDraw(tester).bottom));
      // Manny steht jetzt tiefer als auf 55 %.
      final Rect view = _viewport(tester);
      final double f =
          (tester.getRect(_unit('w5-d1')).center.dy - view.top) / view.height;
      expect(
        f,
        greaterThan(0.56),
        reason: 'der Pfad wurde nach unten gescrollt',
      );
      expect(h.controller.transient.visibleBubble, isNotNull);
      await _close(tester);
    });

    testWidgets('unterste Unit lässt sich über die Gruppe schieben (UI-75)', (
      WidgetTester tester,
    ) async {
      for (final Size size in Viewports.matrix) {
        await _pump(tester, size: size, scale: 2);
        final ScrollableState st = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(ProbeKeys.scroll),
            matching: find.byType(Scrollable),
          ),
        );
        st.position.jumpTo(st.position.maxScrollExtent);
        await tester.pump();
        final Rect unit = tester.getRect(_unit('w1-d1'));
        final Rect g = tester.getRect(find.byType(ActionCluster));
        final Rect nav = tester.getRect(find.byType(FloatingNav));
        expect(unit.bottom, lessThanOrEqualTo(g.top + 0.5), reason: '$size');
        expect(unit.bottom, lessThanOrEqualTo(nav.top + 0.5));
        await _close(tester);
      }
    });

    testWidgets('Auf dem Pfad erscheint keine Snackbar (UI-63): auch nicht bei '
        'Blase, Hinweis, Chat und Rückkehr', (WidgetTester tester) async {
      await _pump(tester, bubble: true);
      expect(find.byType(CuraSnackbar), findsNothing);
      await _tapUnit(tester, 'w3-d2');
      expect(find.byType(CuraSnackbar), findsNothing);
      await tester.tapAt(_mannyDraw(tester).center);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(CuraSnackbar), findsNothing);
      await _close(tester);
    });

    testWidgets('Zone unten links frei, unten rechts nur die Gruppe (UI-24)', (
      WidgetTester tester,
    ) async {
      await _pump(tester, bubble: true);
      final Rect g = tester.getRect(find.byType(ActionCluster));
      final Rect nav = tester.getRect(find.byType(FloatingNav));
      final Rect left = Rect.fromLTRB(
        0,
        nav.top - (g.height + 16),
        195,
        nav.top,
      );
      final Rect right = Rect.fromLTRB(
        195,
        nav.top - (g.height + 16),
        390,
        nav.top,
      );
      for (final Finder f in <Finder>[_bubble]) {
        for (final Element e in f.evaluate()) {
          final RenderBox rb = e.renderObject! as RenderBox;
          final Rect r = rb.localToGlobal(Offset.zero) & rb.size;
          expect(r.overlaps(left), isFalse);
          expect(r.overlaps(right), isFalse);
        }
      }
      await _close(tester);
    });
  });

  // -------------------------------------------------------------------------
  group('Laden und Fehler (Brief 6.2, E-4, A-43)', () {
    testWidgets(
      'Laden: statische Glas-Kreise, keine Button-Gruppe, Nav bleibt',
      (WidgetTester tester) async {
        final SemanticsHandle h = tester.ensureSemantics();
        await _pump(tester, source: _Pending());
        expect(find.byType(StartLoadingView), findsOneWidget);
        expect(find.bySemanticsLabel(S.loading), findsOneWidget);
        expect(find.byType(ActionCluster), findsNothing);
        expect(find.byType(MannyChatButton), findsNothing);
        expect(find.byType(FloatingNav), findsOneWidget);
        expect(find.byType(PathHeader), findsNothing);
        expect(
          tester.binding.transientCallbackCount,
          0,
          reason: 'kein Shimmer',
        );
        h.dispose();
        await _close(tester);
      },
    );

    testWidgets('Fehler: „Dein Pfad konnte nicht geladen werden.“ (E-4), Icon, '
        '„Nochmal versuchen“, keine Button-Gruppe', (
      WidgetTester tester,
    ) async {
      await _pump(tester, source: _AlwaysFails());
      expect(
        find.text('Dein Pfad konnte nicht geladen werden.'),
        findsOneWidget,
      );
      expect(
        find.text('Deine Daten konnten nicht geladen werden.'),
        findsNothing,
      );
      expect(find.text(S.retry), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.byType(ActionCluster), findsNothing);
      expect(find.byType(FloatingNav), findsOneWidget);
      final CuraColors c = colorsAt(tester, find.byType(FloatingNav));
      expect(
        tester.widget<Icon>(find.byIcon(Icons.error_outline_rounded)).color,
        c.statusError,
      );
      await _close(tester);
    });

    testWidgets(
      '„Nochmal versuchen“ bereitet den Pfad erneut vor; danach Pfad, '
      'Gruppe und Besuch (Blase)',
      (WidgetTester tester) async {
        final _FailsOnce source = _FailsOnce();
        final Harness h = await _pump(tester, source: source, bubble: true);
        expect(
          find.text('Dein Pfad konnte nicht geladen werden.'),
          findsOneWidget,
        );
        await tester.tap(find.text(S.retry));
        await tester.pumpAndSettle();
        expect(source.calls, 2);
        expect(find.byType(PathHeader), findsOneWidget);
        expect(find.byType(ActionCluster), findsOneWidget);
        expect(h.controller.transient.visibleBubble, isNotNull);
        await _close(tester);
      },
    );

    testWidgets('Laden endet: ein Future schaltet auf bereit', (
      WidgetTester tester,
    ) async {
      final Completer<void> done = Completer<void>();
      await _pump(tester, source: _FutureSource(done.future));
      expect(find.byType(StartLoadingView), findsOneWidget);
      done.complete();
      await tester.pumpAndSettle();
      expect(find.byType(PathHeader), findsOneWidget);
      expect(find.byType(ActionCluster), findsOneWidget);
      await _close(tester);
    });

    testWidgets('Fehler im Future: Fehlerzustand', (WidgetTester tester) async {
      final Completer<void> done = Completer<void>();
      await _pump(tester, source: _FutureSource(done.future));
      done.completeError(StateError('Test'));
      await tester.pumpAndSettle();
      expect(
        find.text('Dein Pfad konnte nicht geladen werden.'),
        findsOneWidget,
      );
      await _close(tester);
    });
  });

  // -------------------------------------------------------------------------
  group('Neuberechnung und Mittenlage (UI-55-Grundlage)', () {
    testWidgets(
      'nach dem Eintragen steht die neue aktuelle Unit wieder auf 55 %',
      (WidgetTester tester) async {
        final Harness h = await _pump(tester);
        await tester.tap(_navEntryHeute);
        await tester.pumpAndSettle();
        h.controller.logTraining(forDay: h.controller.today);
        await tester.tap(_navEntryPfad);
        await tester.pumpAndSettle();
        final Rect view = _viewport(tester);
        final double f =
            (tester.getRect(_unit('w5-d2')).center.dy - view.top) / view.height;
        expect(f, closeTo(0.55, 0.01));
        await _close(tester);
      },
    );

    testWidgets('nach einer Profiländerung (Datum) springt der Pfad ohne '
        'Animation auf die neue aktuelle Unit', (WidgetTester tester) async {
      final Harness h = await _pump(tester);
      final ProfileDraft draft = ProfileDraft.fromState(h.state)
          .copyWith(injuryDate: kToday.addDays(-80));
      final ProfileUpdateResult r = h.controller.updateProfile(draft);
      expect(r.pathRecomputed, isTrue);
      await tester.pump();
      await tester.pump();
      final Rect view = _viewport(tester);
      final PathProgress p = computePathProgress(
        injuryDate: kToday.addDays(-80),
        today: kToday,
        completedUnitIds: const <String>[],
      );
      final String id = p.units[p.mannyIndex].id;
      final double f =
          (tester.getRect(_unit(id)).center.dy - view.top) / view.height;
      expect(f, closeTo(0.55, 0.01));
      expect(find.text('Woche ${p.week}'), findsOneWidget);
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'keine Scroll-Animation',
      );
      await _close(tester);
    });
  });

  // -------------------------------------------------------------------------
  group('Hoher Kontrast und Bewegung reduzieren (UI-8, UI-9, UI-65)', () {
    testWidgets('Hoher Kontrast: Blase, Hinweis und Pillen opak, kein Blur, '
        'kein Glow, gesperrte Units mit border-control-hc', (
      WidgetTester tester,
    ) async {
      await _pump(tester, hc: true, bubble: true);
      final CuraColors c = colorsAt(tester, find.byType(PathHeader));
      expect(c.highContrast, isTrue);
      expect(backdropCount(tester), 0);
      await tester.tap(find.byTooltip(S.bubbleClose));
      await tester.pumpAndSettle();
      await _tapUnit(tester, 'w3-d2');
      final BoxDecoration d = decorationsUnder(
        tester,
        _hint,
      ).firstWhere((BoxDecoration x) => x.borderRadius != null);
      expect(d.color, c.surfaceOpaque);
      expect((d.border! as Border).top.color, c.cardBorder);
      expect(c.cardBorder, c.borderControlHc);
      await _close(tester);
    });

    testWidgets('Bewegung reduzieren: Blase ohne Schiebung, nach 121 ms keine '
        'laufende Animation', (WidgetTester tester) async {
      await _pump(tester, rm: true, bubble: true);
      await tester.pump(const Duration(milliseconds: 121));
      await tester.pump(const Duration(milliseconds: 1));
      expect(_bubble, findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
      await _tapUnit(tester, 'w3-d2');
      await tester.pump(const Duration(milliseconds: 121));
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
      await _close(tester);
    });

    testWidgets(
      'inaktiver Tab (Heute): keine laufende Animation vom Pfad (TickerMode)',
      (WidgetTester tester) async {
        await _pump(tester);
        await tester.tap(_navEntryHeute);
        await tester.pumpAndSettle();
        expect(tester.binding.transientCallbackCount, 0);
        await _close(tester);
      },
    );
  });
}

/// Eine lange (aber höchstens zweisätzige) Nachricht für die Rückfälle.
class _LongText implements MannyTextSource {
  @override
  String bubbleText(MannyOccasion occasion, MannyContext ctx) =>
      'Starker Start in deine Woche, ${ctx.firstName}. Jede Einheit zählt '
      'für dein Ziel und für dich. Mach heute weiter so und bleib dran.';

  @override
  FactRef fact(MannyContext ctx) => const FactRef(id: 'long', text: 'x');
}

class _FutureSource implements PathSource {
  _FutureSource(this.future);

  final Future<void> future;

  @override
  Future<void>? prepare() => future;
}
