import 'package:curaone/state/app_controller.dart';
import 'package:curaone/state/app_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/controller_harness.dart';

void main() {
  testWidgets(
    'AppScope stellt den Controller bereit und baut bei Änderung neu',
    (WidgetTester tester) async {
      final Harness h = await Harness.boot();
      int builds = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AppScope(
            controller: h.controller,
            child: Builder(
              builder: (BuildContext context) {
                builds++;
                final AppController c = AppScope.of(context);
                return Text(c.state.onboarding.name);
              },
            ),
          ),
        ),
      );
      expect(find.text(''), findsOneWidget);
      expect(builds, 1);
      h.controller.setName('Jakob');
      await tester.pump();
      expect(find.text('Jakob'), findsOneWidget);
      expect(builds, 2);
      h.dispose();
    },
  );

  testWidgets('maybeOf ohne AppScope liefert null', (
    WidgetTester tester,
  ) async {
    AppController? found;
    bool called = false;
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          found = AppScope.maybeOf(context);
          called = true;
          return const SizedBox.shrink();
        },
      ),
    );
    expect(called, isTrue);
    expect(found, isNull);
  });
}
