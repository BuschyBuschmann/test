// Routen (U2b, Plan 4.4): `CuraSheetRoute` (Wischgeste nur auf dem Kopf,
// Scrim, PopScope, Fokusrückgabe, reduzierte Bewegung) und `CuraDialogRoute`
// (Scrim, Escape, PopScope, Routenname, Fokus).
import 'package:curaone/l10n/strings_de.dart';
import 'package:curaone/theme/cura_metrics.dart';
import 'package:curaone/ui/components/cura_dialog.dart';
import 'package:curaone/ui/components/pill_button.dart';
import 'package:curaone/ui/routes/cura_dialog_route.dart';
import 'package:curaone/ui/routes/cura_sheet_route.dart';
import 'package:curaone/ui/routes/route_focus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

const String _kSheetName = 'Test-Sheet';

/// Gerüst mit einem Knopf, der [open] ausführt.
Future<void> _pumpHost(
  WidgetTester tester,
  void Function(BuildContext context) open, {
  bool reduceMotion = false,
}) async {
  await pumpApp(
    tester,
    Builder(
      builder: (BuildContext context) => Center(
        child: ElevatedButton(
          onPressed: () => open(context),
          child: const Text('Öffnen'),
        ),
      ),
    ),
  );
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pump();
  }
}

Widget _sheet({bool canPop = true, VoidCallback? onBlocked, int rows = 30}) {
  return PopScope(
    canPop: canPop,
    onPopInvokedWithResult: (bool didPop, Object? result) {
      if (!didPop) onBlocked?.call();
    },
    child: CuraSheetFrame(
      header: const SizedBox(
        height: 64,
        child: Center(child: Text('Kopf', key: ValueKey<String>('sheet-head'))),
      ),
      body: Column(
        children: <Widget>[
          for (int i = 0; i < rows; i++)
            SizedBox(height: 48, child: Text('Zeile $i')),
        ],
      ),
      footer: PillButton(label: 'Speichern', onPressed: () {}),
    ),
  );
}

Future<void> _openSheet(
  WidgetTester tester, {
  bool canPop = true,
  VoidCallback? onBlocked,
  bool reduceMotion = false,
}) async {
  await _pumpHost(tester, (BuildContext context) {
    Navigator.of(context).push<void>(
      CuraSheetRoute<void>(
        context: context,
        routeLabel: _kSheetName,
        builder: (BuildContext context) =>
            _sheet(canPop: canPop, onBlocked: onBlocked),
      ),
    );
  }, reduceMotion: reduceMotion);
  await tester.tap(find.text('Öffnen'));
  await tester.pumpAndSettle();
}

bool _sheetOpen(WidgetTester tester) =>
    find.byKey(const ValueKey<String>('sheet-head')).evaluate().isNotEmpty;

/// Lage des Sheets: der Kopf wandert mit (Ziehen verschiebt das Innere des
/// `CuraSheetFrame`, nicht sein Rechteck).
double _sheetTop(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(const ValueKey<String>('sheet-head'))).dy;

void main() {
  group('CuraSheetRoute', () {
    testWidgets('öffnet unten, höchstens 90 % hoch, Kopf und Fuß bleiben', (
      WidgetTester tester,
    ) async {
      await _openSheet(tester);
      final Rect sheet = tester.getRect(find.byType(CuraSheetFrame));
      expect(sheet.bottom, closeTo(Viewports.phone.height, 0.5));
      expect(
        sheet.height,
        lessThanOrEqualTo(
          Viewports.phone.height * CuraSize.sheetMaxHeightFraction + 0.5,
        ),
      );
      expect(find.text('Speichern'), findsOneWidget);
      // Inhalt scrollt, Kopf und Fußleiste nicht.
      final double head = tester.getTopLeft(find.text('Kopf')).dy;
      final double foot = tester.getTopLeft(find.text('Speichern')).dy;
      await tester.drag(find.text('Zeile 3'), const Offset(0, -300));
      await tester.pump();
      expect(tester.getTopLeft(find.text('Kopf')).dy, head);
      expect(tester.getTopLeft(find.text('Speichern')).dy, foot);
    });

    testWidgets('Routenname für den Screenreader', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _openSheet(tester);
      expect(find.bySemanticsLabel(_kSheetName), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Blur nur im Normalmodus; Hoher Kontrast opak mit Scrim 72 %', (
      WidgetTester tester,
    ) async {
      Future<void> open({required bool hc}) async {
        await pumpApp(
          tester,
          Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                CuraSheetRoute<void>(
                  context: context,
                  routeLabel: _kSheetName,
                  builder: (BuildContext context) => _sheet(rows: 2),
                ),
              ),
              child: const Text('Öffnen'),
            ),
          ),
          highContrast: hc,
        );
        // Theme-Wechsel (200 ms) abwarten, sonst sind die Farben gemischt.
        await tester.pumpAndSettle();
        await tester.tap(find.text('Öffnen'));
        await tester.pumpAndSettle();
      }

      await open(hc: false);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(
        tester
            .widget<AnimatedModalBarrier>(
              find.byType(AnimatedModalBarrier).last,
            )
            .color
            .value!
            .a,
        closeTo(0.60, 0.01),
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await open(hc: true);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(
        tester
            .widget<AnimatedModalBarrier>(
              find.byType(AnimatedModalBarrier).last,
            )
            .color
            .value!
            .a,
        closeTo(0.72, 0.01),
      );
    });

    testWidgets('Tipp auf den Scrim schließt', (WidgetTester tester) async {
      await _openSheet(tester);
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();
      expect(_sheetOpen(tester), isFalse);
    });

    testWidgets('Zurück und Escape schließen', (WidgetTester tester) async {
      await _openSheet(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_sheetOpen(tester), isFalse);

      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();
      expect(_sheetOpen(tester), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_sheetOpen(tester), isFalse);
    });

    testWidgets('PopScope blockiert: Scrim, Zurück, Escape lassen es offen', (
      WidgetTester tester,
    ) async {
      int blocked = 0;
      await _openSheet(tester, canPop: false, onBlocked: () => blocked++);
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();
      expect(_sheetOpen(tester), isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_sheetOpen(tester), isTrue);
      expect(blocked, 3);
    });

    testWidgets('Fling auf dem Kopf schließt', (WidgetTester tester) async {
      await _openSheet(tester);
      await tester.fling(
        find.byKey(const ValueKey<String>('sheet-head')),
        const Offset(0, 300),
        1500,
      );
      await tester.pumpAndSettle();
      expect(_sheetOpen(tester), isFalse);
    });

    testWidgets('Ziehen über 30 % der Höhe schließt, darunter federt zurück', (
      WidgetTester tester,
    ) async {
      await _openSheet(tester);
      final double rest = _sheetTop(tester);
      final double height = tester.getSize(find.byType(CuraSheetFrame)).height;

      // Unter der Schwelle: langsam ziehen, loslassen, zurück an den Platz.
      final TestGesture slow = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<String>('sheet-head'))),
      );
      await slow.moveBy(Offset(0, height * 0.2));
      await tester.pump();
      expect(_sheetTop(tester), greaterThan(rest + height * 0.15));
      await slow.up();
      await tester.pumpAndSettle();
      expect(_sheetOpen(tester), isTrue);
      expect(_sheetTop(tester), closeTo(rest, 0.5));

      // Über der Schwelle: schließt.
      final TestGesture far = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey<String>('sheet-head'))),
      );
      await far.moveBy(Offset(0, height * 0.4));
      await tester.pump();
      await far.up();
      await tester.pumpAndSettle();
      expect(_sheetOpen(tester), isFalse);
    });

    testWidgets(
      'Wischen mit PopScope: Verwerfen-Weg statt Schließen, Sheet federt zurück',
      (WidgetTester tester) async {
        int blocked = 0;
        await _openSheet(tester, canPop: false, onBlocked: () => blocked++);
        final double rest = _sheetTop(tester);
        await tester.fling(
          find.byKey(const ValueKey<String>('sheet-head')),
          const Offset(0, 300),
          1500,
        );
        await tester.pumpAndSettle();
        expect(_sheetOpen(tester), isTrue);
        expect(blocked, 1, reason: 'PopScope wurde gefragt');
        expect(_sheetTop(tester), closeTo(rest, 0.5));
      },
    );

    testWidgets('Fling im Scrollbereich scrollt nur den Inhalt', (
      WidgetTester tester,
    ) async {
      await _openSheet(tester);
      final double rest = _sheetTop(tester);
      final Finder body = find.descendant(
        of: find.byType(CuraSheetFrame),
        matching: find.byType(SingleChildScrollView),
      );
      final ScrollableState scrollable = tester.state(
        find.descendant(of: body, matching: find.byType(Scrollable)),
      );
      await tester.fling(body, const Offset(0, -400), 1500);
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(0));
      expect(_sheetOpen(tester), isTrue);
      expect(_sheetTop(tester), closeTo(rest, 0.5));
      // Nach unten schieben: der Inhalt scrollt zurück, das Sheet bleibt.
      await tester.fling(body, const Offset(0, 3000), 3000);
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, 0);
      expect(_sheetOpen(tester), isTrue);
      expect(_sheetTop(tester), closeTo(rest, 0.5));
    });

    testWidgets('Bewegung reduzieren: nur Einblenden, keine Schiebung', (
      WidgetTester tester,
    ) async {
      await _openSheet(tester, reduceMotion: true);
      // Schon im Ruhezustand angekommen; während des Übergangs gab es keine
      // Schiebung: neu öffnen und mittendrin prüfen.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Öffnen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        find.ancestor(
          of: find.byType(CuraSheetFrame),
          matching: find.byType(SlideTransition),
        ),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.byType(CuraSheetFrame),
          matching: find.byType(FadeTransition),
        ),
        findsWidgets,
      );
      expect(
        tester.getBottomLeft(find.byType(CuraSheetFrame)).dy,
        closeTo(Viewports.phone.height, 0.5),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 121));
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('normale Bewegung schiebt von unten ein', (
      WidgetTester tester,
    ) async {
      await _pumpHost(tester, (BuildContext context) {
        Navigator.of(context).push<void>(
          CuraSheetRoute<void>(
            context: context,
            routeLabel: _kSheetName,
            builder: (BuildContext context) => _sheet(),
          ),
        );
      });
      await tester.tap(find.text('Öffnen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      expect(
        tester.getTopLeft(find.byType(CuraSheetFrame)).dy,
        greaterThan(Viewports.phone.height * 0.4),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('Fokusrückgabe an den Auslöser, nur wenn er noch existiert', (
      WidgetTester tester,
    ) async {
      final FocusNode trigger = FocusNode(debugLabel: 'trigger');
      addTearDown(trigger.dispose);
      final ValueNotifier<bool> present = ValueNotifier<bool>(true);
      addTearDown(present.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: present,
          builder: (BuildContext context, bool visible, Widget? child) {
            return Center(
              child: visible
                  ? Focus(
                      focusNode: trigger,
                      child: Builder(
                        builder: (BuildContext context) => TextButton(
                          onPressed: () => pushReturningFocus<void>(
                            Navigator.of(context),
                            CuraSheetRoute<void>(
                              context: context,
                              routeLabel: _kSheetName,
                              builder: (BuildContext context) => _sheet(),
                            ),
                            trigger: trigger,
                          ),
                          child: const Text('Auslöser'),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),
      );
      await tester.tap(find.text('Auslöser'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(trigger.hasFocus, isTrue);

      // Der Auslöser verschwindet, während das Sheet offen ist (Tageswechsel,
      // Löschen): kein Fehler, kein Fokus.
      trigger.unfocus();
      await tester.tap(find.text('Auslöser'));
      await tester.pumpAndSettle();
      present.value = false;
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(trigger.hasFocus, isFalse);
    });
  });

  group('CuraDialogRoute', () {
    Future<void> openDialog(
      WidgetTester tester, {
      bool canPop = true,
      VoidCallback? onBlocked,
    }) async {
      await _pumpHost(tester, (BuildContext context) {
        Navigator.of(context).push<void>(
          CuraDialogRoute<void>(
            context: context,
            builder: (BuildContext context) => PopScope(
              canPop: canPop,
              onPopInvokedWithResult: (bool didPop, Object? result) {
                if (!didPop) onBlocked?.call();
              },
              child: CuraDialog(
                icon: Icons.delete_outline_rounded,
                title: 'Alles löschen?',
                message: 'Text',
                actions: <Widget>[
                  PillButton(
                    label: 'Abbrechen',
                    variant: PillButtonVariant.neutral,
                    autofocus: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      });
      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();
    }

    testWidgets('zentriert, Routenname, Anfangsfokus auf der sicheren Aktion', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await openDialog(tester);
      expect(find.byType(CuraDialog), findsOneWidget);
      expect(
        tester.getCenter(find.byType(CuraDialog)).dx,
        closeTo(Viewports.phone.width / 2, 0.5),
      );
      expect(find.bySemanticsLabel('Alles löschen?'), findsWidgets);
      final PillButton cancel = tester.widget(find.byType(PillButton));
      expect(cancel.autofocus, isTrue);
      handle.dispose();
    });

    testWidgets('Tipp auf den Scrim, Zurück und Escape schließen', (
      WidgetTester tester,
    ) async {
      await openDialog(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(CuraDialog), findsNothing);

      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(CuraDialog), findsNothing);

      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(CuraDialog), findsNothing);
    });

    testWidgets('PopScope sperrt Scrim, Zurück und Escape (Löschen läuft)', (
      WidgetTester tester,
    ) async {
      int blocked = 0;
      await openDialog(tester, canPop: false, onBlocked: () => blocked++);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(CuraDialog), findsOneWidget);
      expect(blocked, 3);
    });

    testWidgets('Einblenden ohne Skalieren oder Schieben', (
      WidgetTester tester,
    ) async {
      await _pumpHost(tester, (BuildContext context) {
        Navigator.of(context).push<void>(
          CuraDialogRoute<void>(
            context: context,
            builder: (BuildContext context) => const CuraDialog(
              title: 'Alles löschen?',
              message: 'Text',
              actions: <Widget>[],
            ),
          ),
        );
      });
      await tester.tap(find.text('Öffnen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final Rect early = tester.getRect(find.byType(CuraDialog));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(CuraDialog)), early);
      expect(
        find.ancestor(
          of: find.byType(CuraDialog),
          matching: find.byType(ScaleTransition),
        ),
        findsNothing,
      );
    });

    testWidgets('Bewegung reduzieren: höchstens dur-fast', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _pumpHost(tester, (BuildContext context) {
        Navigator.of(context).push<void>(
          CuraDialogRoute<void>(
            context: context,
            builder: (BuildContext context) => const CuraDialog(
              title: 'Alles löschen?',
              message: 'Text',
              actions: <Widget>[],
            ),
          ),
        );
      });
      await tester.tap(find.text('Öffnen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 121));
      expect(tester.binding.transientCallbackCount, 0);
      expect(find.text(S.close), findsNothing);
    });
  });
}
