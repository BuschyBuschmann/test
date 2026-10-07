import 'package:curaone/logic/manny_occasions.dart';
import 'package:curaone/logic/undo.dart';
import 'package:curaone/state/transient_ui.dart';
import 'package:curaone/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';

RemovalUndo entry(String id) =>
    RemovalUndo(RemovalToken(day: kToday, exerciseId: id));

void main() {
  testWidgets('Fenster dauert 8 s (Snackbar-Token) und endet dann von selbst', (
    WidgetTester tester,
  ) async {
    final TransientUi t = TransientUi();
    int notified = 0;
    t.addListener(() => notified++);
    t.startUndoWindow(entry('a'));
    expect(t.undoWindowOpen, isTrue);
    expect(notified, 1);
    await tester.pump(SnackbarTokens.long - const Duration(milliseconds: 1));
    expect(t.undoWindowOpen, isTrue);
    await tester.pump(const Duration(milliseconds: 1));
    expect(t.undoWindowOpen, isFalse);
    expect(t.undo, isNull);
    expect(notified, 2);
    t.dispose();
  });

  test(
    'eine Methode beendet das Fenster; idempotent, benachrichtigt einmal',
    () {
      final TransientUi t = TransientUi();
      int notified = 0;
      t.addListener(() => notified++);
      t.endUndoWindow(); // nichts offen
      expect(notified, 0);
      t.startUndoWindow(entry('a'));
      t.endUndoWindow();
      t.endUndoWindow();
      expect(t.undoWindowOpen, isFalse);
      expect(notified, 2);
      t.dispose();
    },
  );

  testWidgets('neues Fenster ersetzt das alte (nur eine Snackbar), Timer neu', (
    WidgetTester tester,
  ) async {
    final TransientUi t = TransientUi();
    t.startUndoWindow(entry('a'));
    await tester.pump(const Duration(seconds: 5));
    t.startUndoWindow(entry('b'));
    expect((t.undo! as RemovalUndo).token.exerciseId, 'b');
    await tester.pump(const Duration(seconds: 5)); // 10 s seit a, 5 s seit b
    expect(t.undoWindowOpen, isTrue);
    await tester.pump(const Duration(seconds: 3));
    expect(t.undoWindowOpen, isFalse);
    t.dispose();
  });

  test('Blase und Hinweis: setzen, schließen, reset', () {
    final TransientUi t = TransientUi();
    const BubbleDecision d = BubbleDecision(
      occasion: MannyOccasion.fact,
      pose: MannyPose.neutral,
    );
    t.showBubble(d);
    t.showHint('w5-d1');
    t.startUndoWindow(entry('a'));
    expect(t.visibleBubble, d);
    expect(t.hintUnitId, 'w5-d1');
    t.dismissBubble();
    t.dismissHint();
    expect(t.visibleBubble, isNull);
    expect(t.hintUnitId, isNull);
    t.showBubble(d);
    t.showHint('x');
    t.reset();
    expect(t.visibleBubble, isNull);
    expect(t.hintUnitId, isNull);
    expect(t.undoWindowOpen, isFalse);
    t.dispose();
  });

  testWidgets('nach dispose feuert kein Timer mehr', (
    WidgetTester tester,
  ) async {
    final TransientUi t = TransientUi();
    t.startUndoWindow(entry('a'));
    t.dispose();
    await tester.pump(const Duration(seconds: 20)); // wirft nicht
  });
}
