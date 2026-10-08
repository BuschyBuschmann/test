// UI-8 (W-Teil): `CuraMotion.of` erkennt „Bewegung reduzieren“ auf beiden
// Wegen (Systemsignal `disableAnimations` bzw. `reduceMotion` über den
// `platformDispatcher`, Plan 8.1) und über den Preview-Override.

import 'package:curaone/theme/cura_motion.dart';
import 'package:curaone/theme/tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<CuraMotion> _motion(WidgetTester tester, {bool? preview}) async {
  late CuraMotion result;
  Widget probe = Builder(
    builder: (BuildContext context) {
      result = CuraMotion.of(context);
      return const SizedBox.shrink();
    },
  );
  if (preview != null) {
    probe = PreviewMotionOverride(reduceMotion: preview, child: probe);
  }
  await tester.pumpWidget(MediaQuery.fromView(view: tester.view, child: probe));
  return result;
}

void main() {
  testWidgets('Ohne Signal: nicht reduziert, Dauern unverändert', (
    WidgetTester tester,
  ) async {
    final CuraMotion m = await _motion(tester);
    expect(m.reduced, isFalse);
    expect(m.fast, const Duration(milliseconds: 120));
    expect(m.base, const Duration(milliseconds: 200));
    expect(m.slow, const Duration(milliseconds: 320));
    expect(m.curve, MotionTokens.curve);
    expect(m.duration(m.base), m.base);
    expect(m.slide(8), 8);
  });

  testWidgets('Systemsignal disableAnimations (Android, Web)', (
    WidgetTester tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final CuraMotion m = await _motion(tester);
    expect(m.reduced, isTrue);
  });

  testWidgets('Systemsignal reduceMotion (iOS)', (WidgetTester tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final CuraMotion m = await _motion(tester);
    expect(m.reduced, isTrue);
    // Reduziert: Ein-/Überblenden höchstens `fast`, keine Schiebung.
    expect(m.duration(m.base), m.fast);
    expect(m.duration(m.slow), m.fast);
    expect(
      m.duration(const Duration(milliseconds: 50)),
      const Duration(milliseconds: 50),
    );
    expect(m.slide(24), 0);
  });

  testWidgets('Preview-Override erzwingt an und aus', (
    WidgetTester tester,
  ) async {
    expect((await _motion(tester, preview: true)).reduced, isTrue);
    expect((await _motion(tester, preview: false)).reduced, isFalse);
  });
}
