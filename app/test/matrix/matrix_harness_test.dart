// Selbsttest des Matrix-Harness (R-AB-1, R-AB-6): `tapEveryTarget` und
// `settle`. Ohne sie könnte der Durchlauf „jedes Ziel antippen“ still den
// größten Teil der Ziele überspringen, und niemand merkte es.
import 'package:curaone/dev/scenarios.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';
import 'matrix_checks.dart';
import 'matrix_harness.dart';

/// Seite, deren Zustand sich beim Tippen verändert: „A“ öffnet einen Dialog
/// über dem Rest (danach sind B und C begraben, ihr Label wäre ein anderes),
/// „B“ benennt „C“ um. Zählt, wie oft jedes Ziel getippt wurde.
class _Page extends StatefulWidget {
  const _Page(this.taps, {this.dropC = false});

  final Map<String, int> taps;

  /// Simuliert einen Neuaufbau, der ein Ziel verliert.
  final bool dropC;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  String _c = 'C';
  bool _dialog = false;

  Widget _button(String label, VoidCallback onTap) => Semantics(
    button: true,
    label: label,
    onTap: onTap,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(width: 120, height: 48, child: Text(label)),
    ),
  );

  void _count(String label) =>
      widget.taps.update(label, (int n) => n + 1, ifAbsent: () => 1);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            const SizedBox(height: 60),
            _button('A', () {
              _count('A');
              setState(() => _dialog = true);
            }),
            const SizedBox(height: 8),
            _button('B', () {
              _count('B');
              setState(() => _c = 'C neu');
            }),
            const SizedBox(height: 8),
            if (!widget.dropC) _button(_c, () => _count(_c)),
          ],
        ),
        if (_dialog)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xCC000000),
              child: Center(
                child: _button('Schließen', () {
                  _count('Schließen');
                  setState(() => _dialog = false);
                }),
              ),
            ),
          ),
      ],
    );
  }
}

void main() {
  Future<void> build(
    WidgetTester tester,
    Map<String, int> taps, {
    bool dropC = false,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpRm(tester, _Page(taps, dropC: dropC));
    await tester.pumpAndSettle();
  }

  testWidgets('R-AB-1: jedes Ziel wird angetippt, auch nach einem Tipp, der '
      'die Seite verändert', (WidgetTester tester) async {
    final SemanticsHandle h = tester.ensureSemantics();
    final Map<String, int> taps = <String, int>{};
    await build(tester, taps);
    final TapSweep sweep = await tapEveryTarget(
      tester,
      rebuild: () => build(tester, taps),
      allowProgress: false,
    );
    // Ausgangszustand: A, B, C. Der alte Durchlauf hätte nach dem Tipp auf „A“
    // (Dialog über allem) B und C nicht mehr gefunden bzw. „C“ nach „B“ nicht
    // mehr unter diesem Label.
    expect(sweep.candidates, 3);
    expect(sweep.tapped, 3);
    expect(sweep.findings, isEmpty);
    expect(taps, <String, int>{'A': 1, 'B': 1, 'C': 1});
    await tester.pumpWidget(const SizedBox.shrink());
    h.dispose();
  });

  testWidgets('R-AB-1: ein Ziel, das nach dem Neuaufbau fehlt, ist ein harter '
      'Befund (nicht übersprungen)', (WidgetTester tester) async {
    final SemanticsHandle h = tester.ensureSemantics();
    final Map<String, int> taps = <String, int>{};
    await build(tester, taps);
    int builds = 0;
    final TapSweep sweep = await tapEveryTarget(
      tester,
      rebuild: () => build(tester, taps, dropC: ++builds >= 1),
      allowProgress: false,
    );
    expect(sweep.candidates, 3);
    expect(sweep.tapped, 2);
    expect(sweep.findings, hasLength(1));
    expect(sweep.findings.single.check, 'Tap-Ziel angetippt');
    expect(sweep.findings.single.message, contains('"C"'));
    expect(sweep.findings.single.advisory, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    h.dispose();
  });

  testWidgets('R-AB-1: eine Animation über 120 ms nach dem Tipp wird erkannt', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle h = tester.ensureSemantics();
    Future<void> slow() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpRm(tester, const _SlowTap());
      await tester.pumpAndSettle();
    }

    await slow();
    final TapSweep sweep = await tapEveryTarget(
      tester,
      rebuild: slow,
      allowProgress: false,
    );
    expect(sweep.tapped, 1);
    expect(
      sweep.findings.map((Finding f) => f.check),
      contains('RM ohne laufende Animation'),
    );
    expect(sweep.findings.single.message, contains('"Los"'));
    await tester.pumpWidget(const SizedBox.shrink());
    h.dispose();
  });

  testWidgets('settle: Szenario mit Dauer-Animation läuft 60 Frames, sonst '
      'pumpAndSettle', (WidgetTester tester) async {
    int frames = 0;
    Widget counter() => _FrameCounter(onFrame: () => frames++);
    const Scenario loops = Scenario(
      id: 'x',
      app: null,
      builder: _nop,
      loops: true,
    );
    await tester.pumpWidget(counter());
    frames = 0;
    await settle(tester, loops);
    // 1 + 60 Frames; weniger hieße: Skripte von App-Szenarien (ein Frame je
    // Schritt) blieben unfertig.
    expect(frames, greaterThanOrEqualTo(60));

    const Scenario rest = Scenario(id: 'y', builder: _nop);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const _Finite());
    await settle(tester, rest);
    expect(tester.binding.transientCallbackCount, 0);
  });
}

/// „Bewegung reduzieren“ an, wie im RM-Durchlauf der Matrix (das `Scaffold`
/// liegt unter der `MediaQuery`, die `checkReducedMotion` befragt).
Future<void> _pumpRm(WidgetTester tester, Widget child) async {
  setViewport(tester, Viewports.phone);
  await tester.pumpWidget(
    MaterialApp(
      builder: (BuildContext context, Widget? app) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: app!,
      ),
      home: Scaffold(body: child),
    ),
  );
}

Widget _nop(BuildContext c, ScenarioEnv e) => const SizedBox();

/// Tippen startet eine 400-ms-Animation (länger als erlaubt).
class _SlowTap extends StatefulWidget {
  const _SlowTap();

  @override
  State<_SlowTap> createState() => _SlowTapState();
}

class _SlowTapState extends State<_SlowTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      button: true,
      label: 'Los',
      onTap: () => _c.forward(from: 0),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _c.forward(from: 0),
        child: const SizedBox(width: 120, height: 48),
      ),
    ),
  );
}

/// Zählt Frames einer Dauer-Animation.
class _FrameCounter extends StatefulWidget {
  const _FrameCounter({required this.onFrame});

  final VoidCallback onFrame;

  @override
  State<_FrameCounter> createState() => _FrameCounterState();
}

class _FrameCounterState extends State<_FrameCounter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _c.addListener(widget.onFrame);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _Finite extends StatefulWidget {
  const _Finite();

  @override
  State<_Finite> createState() => _FiniteState();
}

class _FiniteState extends State<_Finite> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
