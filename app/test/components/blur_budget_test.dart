// Blur-Budget (Design-Brief v2, 3.5, V2-10): höchstens 3 gleichzeitig gebaute
// `BackdropFilter` je Scope; ein vierter bekommt keinen Platz und bleibt
// unscharf, wird ein Platz frei, rückt er nach. Hoher Kontrast belegt keinen
// Platz.
import 'package:curaone/theme/tokens.dart';
import 'package:curaone/ui/components/cura_blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import '../support/backdrops.dart';

Widget _blur(int i) => CuraBlur(
  key: ValueKey<int>(i),
  child: SizedBox(width: 40, height: 20, child: Text('B$i')),
);

BlurBudget _budget(WidgetTester tester) =>
    BlurBudgetScope.maybeOf(tester.element(find.byType(Column).first))!;

void main() {
  test('Budget: Obergrenze 3 ist das Token', () {
    expect(BlurTokens.maxPerScreen, 3);
    expect(BlurBudget().capacity, 3);
    final BlurBudget b = BlurBudget();
    expect(
      <bool>[b.tryAcquire(), b.tryAcquire(), b.tryAcquire(), b.tryAcquire()],
      <bool>[true, true, true, false],
    );
    expect(b.used, 3);
    b.release();
    expect(b.used, 2);
    expect(b.tryAcquire(), isTrue);
  });

  testWidgets('vier CuraBlur: genau 3 BackdropFilter, vierter ohne Blur', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      BlurBudgetScope(
        child: Column(children: <Widget>[for (int i = 0; i < 4; i++) _blur(i)]),
      ),
    );
    expect(activeBackdrops(), findsNWidgets(3));
    expect(_budget(tester).used, 3);
    // Der Inhalt des vierten steht trotzdem da.
    expect(find.text('B3'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<int>(3)),
        matching: activeBackdrops(),
      ),
      findsNothing,
    );
  });

  testWidgets('wird ein Platz frei, rückt der wartende Blur nach', (
    WidgetTester tester,
  ) async {
    Widget tree(int count) => BlurBudgetScope(
      child: Column(
        children: <Widget>[for (int i = 0; i < count; i++) _blur(i)],
      ),
    );
    await pumpApp(tester, tree(4));
    expect(activeBackdrops(), findsNWidgets(3));
    // Der erste Blur verschwindet.
    await pumpApp(
      tester,
      BlurBudgetScope(
        child: Column(children: <Widget>[for (int i = 1; i < 4; i++) _blur(i)]),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(activeBackdrops(), findsNWidgets(3));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<int>(3)),
        matching: activeBackdrops(),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'L1K: der Baum bleibt stabil, ein Platz ändert weder Zustand noch '
    'Element des Kindes',
    (WidgetTester tester) async {
      int inits = 0;
      final Widget probe = _InitCounter(onInit: () => inits++);
      Widget tree(int from) => BlurBudgetScope(
        child: Column(
          children: <Widget>[
            for (int i = from; i < 4; i++)
              if (i == 3)
                CuraBlur(key: const ValueKey<int>(3), child: probe)
              else
                _blur(i),
          ],
        ),
      );
      await pumpApp(tester, tree(0));
      expect(inits, 1);
      final Element before = tester.element(find.byType(_InitCounter));
      // Der vierte hat noch keinen Platz: Filter aus, Baum wie mit Platz.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<int>(3)),
          matching: find.byWidgetPredicate((Widget w) => w is BackdropFilter),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<int>(3)),
          matching: activeBackdrops(),
        ),
        findsNothing,
      );
      await pumpApp(tester, tree(1));
      await tester.pump();
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const ValueKey<int>(3)),
          matching: activeBackdrops(),
        ),
        findsOneWidget,
      );
      expect(inits, 1, reason: 'kein Neuaufbau des Kindes');
      expect(tester.element(find.byType(_InitCounter)), same(before));
    },
  );

  testWidgets('Hoher Kontrast: kein Blur, kein Platz belegt', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      BlurBudgetScope(
        child: Column(children: <Widget>[for (int i = 0; i < 4; i++) _blur(i)]),
      ),
      highContrast: true,
    );
    expect(activeBackdrops(), findsNothing);
    expect(_budget(tester).used, 0);
    expect(find.text('B0'), findsOneWidget);
  });

  testWidgets('ohne Scope: kein Limit (Einzelbausteine)', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      Column(children: <Widget>[for (int i = 0; i < 5; i++) _blur(i)]),
    );
    expect(activeBackdrops(), findsNWidgets(5));
  });

  testWidgets('getrennte Scopes haben getrennte Budgets (je Screen)', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      Column(
        children: <Widget>[
          BlurBudgetScope(
            child: Column(
              children: <Widget>[for (int i = 0; i < 3; i++) _blur(i)],
            ),
          ),
          BlurBudgetScope(
            child: Column(
              children: <Widget>[for (int i = 10; i < 13; i++) _blur(i)],
            ),
          ),
        ],
      ),
    );
    expect(activeBackdrops(), findsNWidgets(6));
  });

  testWidgets('Stärke der Weichzeichnung ist wählbar (Leiste σ 30)', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      BlurBudgetScope(
        child: CuraBlur(
          sigma: BlurTokens.navSigma,
          child: const SizedBox(width: 40, height: 20),
        ),
      ),
    );
    final BackdropFilter f = tester.widget(activeBackdrops());
    expect(f.filter.toString(), contains('30'));
  });

  testWidgets('ein CuraBlur in TickerMode(enabled: false) belegt keinen Platz '
      '(inaktives Ziel der Leiste)', (WidgetTester tester) async {
    Widget tree({required bool firstEnabled}) => BlurBudgetScope(
      child: Column(
        children: <Widget>[
          TickerMode(enabled: firstEnabled, child: _blur(0)),
          for (int i = 1; i < 4; i++) _blur(i),
        ],
      ),
    );
    // Das erste ist inaktiv und belegt nichts; die drei sichtbaren bekommen
    // ihren Platz (ohne diese Regel hielte das inaktive den ersten Platz).
    await pumpApp(tester, tree(firstEnabled: false));
    expect(_budget(tester).used, 3);
    expect(activeBackdrops(), findsNWidgets(3));
  });

  testWidgets('L1K2: deaktivierter Filter erzwingt kein Compositing, aktiver '
      'schon', (WidgetTester tester) async {
    Widget tree() =>
        Column(children: <Widget>[for (int i = 0; i < 4; i++) _blur(i)]);
    await pumpApp(tester, BlurBudgetScope(child: tree()));
    RenderBackdropFilter render(int i) => tester.renderObject(
      find.descendant(
        of: find.byKey(ValueKey<int>(i)),
        matching: find.byWidgetPredicate((Widget w) => w is BackdropFilter),
      ),
    );
    expect(render(0).enabled, isTrue);
    expect(render(0).alwaysNeedsCompositing, isTrue);
    // Der vierte hat keinen Platz: Filter aus, kein erzwungenes Compositing.
    expect(render(3).enabled, isFalse);
    expect(render(3).alwaysNeedsCompositing, isFalse);
  });

  testWidgets('L1K3: aktiver Blur wird inaktiv und wieder aktiv, am selben '
      'RenderObject und ohne Neuaufbau des Kindes', (
    WidgetTester tester,
  ) async {
    int inits = 0;
    final Widget probe = _InitCounter(onInit: () => inits++);
    Widget tree({required bool active}) => BlurBudgetScope(
      child: TickerMode(
        enabled: active,
        child: CuraBlur(key: const ValueKey<int>(0), child: probe),
      ),
    );
    RenderBackdropFilter render() => tester.renderObject(
      find.descendant(
        of: find.byKey(const ValueKey<int>(0)),
        matching: find.byWidgetPredicate((Widget w) => w is BackdropFilter),
      ),
    );

    await pumpApp(tester, tree(active: true));
    final RenderBackdropFilter before = render();
    expect(before.enabled, isTrue);
    expect(before.debugLayer, isA<BackdropFilterLayer>());
    expect(before.needsCompositing, isTrue);
    final Element childBefore = tester.element(find.byType(_InitCounter));
    expect(inits, 1);

    // Aktiv -> inaktiv am bestehenden RenderObject: kein Layer, kein Compositing.
    await pumpApp(tester, tree(active: false));
    await tester.pump();
    expect(render(), same(before));
    expect(render().enabled, isFalse);
    expect(render().debugLayer, isNull);
    expect(render().needsCompositing, isFalse);
    expect(activeBackdrops(), findsNothing);
    expect(inits, 1, reason: 'kein Neuaufbau des Kindes');
    expect(tester.element(find.byType(_InitCounter)), same(childBefore));

    // Inaktiv -> aktiv: genau ein Layer, Compositing wieder erzwungen.
    await pumpApp(tester, tree(active: true));
    await tester.pump();
    expect(render(), same(before));
    expect(render().enabled, isTrue);
    expect(render().debugLayer, isA<BackdropFilterLayer>());
    expect(render().needsCompositing, isTrue);
    expect(activeBackdrops(), findsOneWidget);
    expect(inits, 1, reason: 'kein Neuaufbau des Kindes');
    expect(tester.element(find.byType(_InitCounter)), same(childBefore));
  });
}

class _InitCounter extends StatefulWidget {
  const _InitCounter({required this.onInit});

  final VoidCallback onInit;

  @override
  State<_InitCounter> createState() => _InitCounterState();
}

class _InitCounterState extends State<_InitCounter> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 40, height: 20);
}
