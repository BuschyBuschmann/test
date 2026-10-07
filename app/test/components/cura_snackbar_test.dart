// CuraSnackbar + SnackbarHost (Ergänzung 1 Abschnitt 2 und 3.3, UI-37, UI-39,
// UI-41, UI-44, UI-64, UI-65; Brief B-8 Dauern 4/5/8 s).

import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/tokens.dart';
import 'package:curaone/ui/components/cura_snackbar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/component_support.dart';
import '../support/pump_app.dart';

Widget _host(SnackbarController c, {double bottom = 100}) => Stack(
  children: <Widget>[
    Positioned.fill(
      child: SnackbarHost(controller: c, bottomOffset: bottom),
    ),
  ],
);

class _Log {
  final List<String> events = <String>[];

  CuraSnackbarMessage message(
    String text, {
    Duration duration = SnackbarTokens.long,
    String? action,
    String? name,
  }) {
    final String n = name ?? text;
    return CuraSnackbarMessage(
      text: text,
      duration: duration,
      actionLabel: action,
      actionSemanticsLabel: action == null ? null : 'Eintrag rückgängig machen',
      onAction: action == null ? null : () => events.add('$n:onAction'),
      onClosed: (SnackbarCloseReason r) => events.add('$n:${r.name}'),
    );
  }
}

void main() {
  group('Aussehen (CuraSnackbar)', () {
    Widget bar({String? action, String text = 'Eingetragen.'}) => Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CuraSnackbar(
          text: text,
          actionLabel: action,
          onAction: action == null ? null : () {},
        ),
      ),
    );

    testWidgets('opak surface-opaque, Rand hair, Radius 20, Innenabstand 16, '
        'Text body text-1, Aktion accent-hi, kein Blur', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, bar(action: 'Rückgängig'));
      final Finder f = find.byType(CuraSnackbar);
      final CuraColors c = colorsAt(tester, f);
      final BoxDecoration d = decorationsUnder(tester, f).first;
      expect(d.color, c.surfaceOpaque);
      expect(d.color, const Color(0xFF1B2129));
      expect(d.borderRadius, BorderRadius.circular(20));
      expect(d.border, Border.all(color: c.borderHair, width: 1));
      expect(d.boxShadow, isNull);
      expect(backdropCount(tester), 0);
      final Rect r = tester.getRect(f);
      // Höhe: 16 + Aktion (48) + 16 bei Aktion; ohne Aktion 16 + 24 + 16.
      expect(r.height, 80);
      expect(tester.getRect(find.text('Eingetragen.')).left - r.left, 16);
      final TextStyle t = tester.widget<Text>(find.text('Eingetragen.')).style!;
      expect(t.fontSize, 16);
      expect(t.color, c.text1);
      final TextStyle a = tester.widget<Text>(find.text('Rückgängig')).style!;
      expect(a.color, c.accentHi);
      expect(a.fontWeight, FontWeight.w600);
    });

    testWidgets('Hoher Kontrast: Rand border-control-hc, weiterhin opak', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, bar(action: 'Rückgängig'), highContrast: true);
      final CuraColors c = colorsAt(tester, find.byType(CuraSnackbar));
      final BoxDecoration d = decorationsUnder(
        tester,
        find.byType(CuraSnackbar),
      ).first;
      expect(d.color, const Color(0xFF1B2129));
      expect(d.border, Border.all(color: c.borderControlHc, width: 1));
    });

    testWidgets('Aktion rechts neben dem Text, Hit-Area ≥ 48 dp', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, bar(action: 'Rückgängig'));
      final Rect text = tester.getRect(find.text('Eingetragen.'));
      final Rect action = tester.getRect(find.text('Rückgängig'));
      expect(action.left, greaterThan(text.right));
      final Finder target = find.ancestor(
        of: find.text('Rückgängig'),
        matching: find.byType(ConstrainedBox),
      );
      final Size s = tester.getSize(target.first);
      expect(s.height, greaterThanOrEqualTo(48));
      expect(s.width, greaterThanOrEqualTo(48));
    });

    testWidgets('Aktion unter dem Text, rechtsbündig: ab Skalierung 1,3', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, bar(action: 'Rückgängig'), textScale: 1.3);
      final Rect text = tester.getRect(find.text('Eingetragen.'));
      final Rect action = tester.getRect(find.text('Rückgängig'));
      expect(action.top, greaterThanOrEqualTo(text.bottom));
      final Rect bar0 = tester.getRect(find.byType(CuraSnackbar));
      expect(bar0.right - 16 - action.right, lessThan(20));
    });

    testWidgets(
      'Aktion unter dem Text, wenn sie nicht daneben passt (320 dp)',
      (WidgetTester tester) async {
        await pumpApp(
          tester,
          bar(action: 'Rückgängig', text: 'Alle Daten sind gelöscht und neu.'),
          size: Viewports.small,
        );
        final Rect text = tester.getRect(find.textContaining('Alle Daten'));
        final Rect action = tester.getRect(find.text('Rückgängig'));
        expect(action.top, greaterThanOrEqualTo(text.bottom));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('200 %: bricht um, nichts abgeschnitten', (
      WidgetTester tester,
    ) async {
      await pumpApp(
        tester,
        bar(action: 'Rückgängig', text: 'Neuer Tag, neues Programm.'),
        size: Viewports.small,
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('ohne Aktion: nur Text', (WidgetTester tester) async {
      await pumpApp(tester, bar());
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Eingetragen.'), findsOneWidget);
      expect(tester.getSize(find.byType(CuraSnackbar)).height, 56);
    });
  });

  group('Host: Position, Ersetzen, Dauer', () {
    testWidgets('steht mit 16 dp Seitenrand und bottomOffset über dem Rand, '
        'bei 560 dp Rahmen mittig', (WidgetTester tester) async {
      final SnackbarController c = SnackbarController();
      addTearDown(c.dispose);
      await pumpApp(tester, _host(c, bottom: 112));
      c.show(_Log().message('Eingetragen.', action: 'Rückgängig'));
      await tester.pumpAndSettle();
      final Rect r = tester.getRect(find.byType(CuraSnackbar));
      expect(r.left, 16);
      expect(r.right, 390 - 16);
      expect(844 - r.bottom, 112);
      await pumpApp(tester, _host(c, bottom: 112), size: Viewports.tablet);
      await tester.pumpAndSettle();
      final Rect t = tester.getRect(find.byType(CuraSnackbar));
      expect(t.center.dx, closeTo(768 / 2, 0.5));
      expect(t.width, lessThanOrEqualTo(560));
    });

    testWidgets('Dauer 8 s: bei 7,9 s da, danach weg (timeout)', (
      WidgetTester tester,
    ) async {
      final _Log log = _Log();
      final SnackbarController c = SnackbarController();
      addTearDown(c.dispose);
      await pumpApp(tester, _host(c));
      c.show(log.message('Eingetragen.', action: 'Rückgängig'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 7900));
      expect(find.byType(CuraSnackbar), findsOneWidget);
      expect(log.events, isEmpty);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CuraSnackbar), findsNothing);
      expect(log.events, <String>['Eingetragen.:timeout']);
    });

    testWidgets('Dauern 4 s und 5 s (B-8)', (WidgetTester tester) async {
      final _Log log = _Log();
      final SnackbarController c = SnackbarController();
      addTearDown(c.dispose);
      await pumpApp(tester, _host(c));
      c.show(
        log.message(
          'Alle Daten sind gelöscht.',
          duration: SnackbarTokens.short,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 3900));
      expect(find.byType(CuraSnackbar), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CuraSnackbar), findsNothing);
      c.show(
        log.message(
          'Neuer Tag, neues Programm.',
          duration: SnackbarTokens.medium,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 4900));
      expect(find.byType(CuraSnackbar), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CuraSnackbar), findsNothing);
      expect(SnackbarTokens.short.inSeconds, 4);
      expect(SnackbarTokens.medium.inSeconds, 5);
      expect(SnackbarTokens.long.inSeconds, 8);
    });

    testWidgets('immer nur eine: neue ersetzt die alte, alte Aktion verfällt', (
      WidgetTester tester,
    ) async {
      final _Log log = _Log();
      final SnackbarController c = SnackbarController();
      addTearDown(c.dispose);
      await pumpApp(tester, _host(c));
      c.show(log.message('Eingetragen.', action: 'Rückgängig'));
      await tester.pump();
      c.show(log.message('Entfernt.', action: 'Rückgängig'));
      await tester.pump();
      expect(find.byType(CuraSnackbar), findsOneWidget);
      expect(find.text('Eingetragen.'), findsNothing);
      expect(find.text('Entfernt.'), findsOneWidget);
      expect(log.events, <String>['Eingetragen.:replaced']);
      // Neue Dauer beginnt neu (8 s ab der zweiten Snackbar).
      await tester.pump(const Duration(milliseconds: 7900));
      expect(find.byType(CuraSnackbar), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CuraSnackbar), findsNothing);
      expect(log.events.last, 'Entfernt.:timeout');
    });

    testWidgets('Aktion: erst schließen, dann ausführen; Aktion darf eine '
        'neue Snackbar zeigen', (WidgetTester tester) async {
      final _Log log = _Log();
      final SnackbarController c = SnackbarController();
      addTearDown(c.dispose);
      await pumpApp(tester, _host(c));
      c.show(
        CuraSnackbarMessage(
          text: 'Entfernt.',
          actionLabel: 'Rückgängig',
          onAction: () {
            log.events.add('onAction');
            c.show(log.message('Zurückgenommen.'));
          },
          onClosed: (SnackbarCloseReason r) =>
              log.events.add('closed:${r.name}'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rückgängig'));
      await tester.pump();
      expect(log.events, <String>['closed:action', 'onAction']);
      expect(find.text('Zurückgenommen.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 9));
    });

    testWidgets('hide() meldet hidden, ist ohne Snackbar wirkungslos', (
      WidgetTester tester,
    ) async {
      final _Log log = _Log();
      final SnackbarController c = SnackbarController();
      addTearDown(c.dispose);
      await pumpApp(tester, _host(c));
      c.close();
      expect(log.events, isEmpty);
      c.show(log.message('Eingetragen.'));
      await tester.pump();
      c.close();
      await tester.pump();
      c.close();
      expect(log.events, <String>['Eingetragen.:hidden']);
      expect(find.byType(CuraSnackbar), findsNothing);
    });
  });

  group('Timer: Pause und Screenreader', () {
    testWidgets('pausiert, solange der Zeiger darüber liegt (Hover), läuft '
        'danach mit der Restzeit weiter', (WidgetTester tester) async {
      final _Log log = _Log();
      final SnackbarController c = SnackbarController();
      addTearDown(c.dispose);
      await pumpApp(tester, _host(c));
      c.show(log.message('Eingetragen.', action: 'Rückgängig'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(mouse.removePointer);
      await mouse.addPointer(location: Offset.zero);
      await tester.pump(const Duration(seconds: 3)); // 3 s vergangen
      await mouse.moveTo(tester.getCenter(find.byType(CuraSnackbar)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      expect(find.byType(CuraSnackbar), findsOneWidget);
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(find.byType(CuraSnackbar), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(CuraSnackbar), findsNothing);
      expect(log.events, <String>['Eingetragen.:timeout']);
    });

    testWidgets('pausiert bei Fokus auf der Aktion; Escape schließt', (
      WidgetTester tester,
    ) async {
      final _Log log = _Log();
      final SnackbarController c = SnackbarController();
      addTearDown(c.dispose);
      await pumpApp(tester, _host(c));
      c.show(log.message('Eingetragen.', action: 'Rückgängig'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));
      expect(find.byType(CuraSnackbar), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byType(CuraSnackbar), findsNothing);
      expect(log.events, <String>['Eingetragen.:dismissed']);
    });

    testWidgets('Tastatur: Enter auf der Aktion löst sie aus', (
      WidgetTester tester,
    ) async {
      final _Log log = _Log();
      final SnackbarController c = SnackbarController();
      addTearDown(c.dispose);
      await pumpApp(tester, _host(c));
      c.show(log.message('Eingetragen.', action: 'Rückgängig'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(log.events, <String>[
        'Eingetragen.:action',
        'Eingetragen.:onAction',
      ]);
    });

    testWidgets('Wegwischen schließt (dismissed)', (WidgetTester tester) async {
      final _Log log = _Log();
      final SnackbarController c = SnackbarController();
      addTearDown(c.dispose);
      await pumpApp(tester, _host(c));
      c.show(log.message('Eingetragen.'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.fling(find.byType(CuraSnackbar), const Offset(300, 0), 800);
      await tester.pump();
      expect(find.byType(CuraSnackbar), findsNothing);
      expect(log.events, <String>['Eingetragen.:dismissed']);
    });

    testWidgets('bei accessibleNavigation läuft kein Timer', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final _Log log = _Log();
      final SnackbarController c = SnackbarController();
      addTearDown(c.dispose);
      await pumpApp(tester, _host(c));
      c.show(log.message('Eingetragen.', action: 'Rückgängig'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 60));
      expect(find.byType(CuraSnackbar), findsOneWidget);
      expect(log.events, isEmpty);
      c.close(); // Tabwechsel o. Ä. beendet sie
      await tester.pump();
      expect(find.byType(CuraSnackbar), findsNothing);
    });
  });

  group('Semantik und Bewegung', () {
    testWidgets('Live-Region „Eingetragen. Rückgängig, Schaltfläche“, Aktion '
        '„Eintrag rückgängig machen“', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      final _Log log = _Log();
      final SnackbarController c = SnackbarController();
      addTearDown(c.dispose);
      await pumpApp(tester, _host(c));
      c.show(log.message('Eingetragen.', action: 'Rückgängig'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(
        find.semantics.byLabel('Eingetragen. Rückgängig, Schaltfläche'),
        findsOneWidget,
      );
      final SemanticsNode live = tester.getSemantics(
        find.bySemanticsLabel('Eingetragen. Rückgängig, Schaltfläche'),
      );
      expect(live, isSemantics(isLiveRegion: true));
      expect(
        find.bySemanticsLabel('Eintrag rückgängig machen'),
        findsOneWidget,
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      c.close();
      await tester.pump();
      h.dispose();
    });

    testWidgets('Erscheinen: Einblenden plus 8 dp Schiebung in dur-base', (
      WidgetTester tester,
    ) async {
      final SnackbarController c = SnackbarController();
      addTearDown(c.dispose);
      await pumpApp(tester, _host(c));
      c.show(_Log().message('Eingetragen.'));
      await tester.pump();
      final Finder move = find.descendant(
        of: find.byType(SnackbarHost),
        matching: find.byType(Transform),
      );
      final Finder fade = find.descendant(
        of: find.byType(SnackbarHost),
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(fade.first).opacity, 0);
      expect(
        tester.widget<Transform>(move.first).transform.getTranslation().y,
        8,
      );
      await tester.pump(const Duration(milliseconds: 201));
      expect(tester.widget<Opacity>(fade.first).opacity, 1);
      expect(
        tester.widget<Transform>(move.first).transform.getTranslation().y,
        0,
      );
      c.close();
      await tester.pump();
    });

    testWidgets('reduzierte Bewegung: keine Schiebung, nach 121 ms keine '
        'laufende Animation', (WidgetTester tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final SnackbarController c = SnackbarController();
      addTearDown(c.dispose);
      await pumpApp(tester, _host(c));
      c.show(_Log().message('Eingetragen.'));
      await tester.pump();
      final Finder move = find.descendant(
        of: find.byType(SnackbarHost),
        matching: find.byType(Transform),
      );
      expect(
        tester.widget<Transform>(move.first).transform.getTranslation().y,
        0,
      );
      await tester.pump(const Duration(milliseconds: 121));
      // Die Snackbar hat keine Animation mehr (nur den Timer).
      final Finder fade = find.descendant(
        of: find.byType(SnackbarHost),
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(fade.first).opacity, 1);
      c.close();
      await tester.pump();
    });
  });
}
