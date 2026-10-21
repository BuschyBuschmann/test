// Abgeleitete Farbrollen der Bausteine (Brief 3.5, 5, Ergänzung 1/2).
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_roles.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final CuraColors c in <CuraColors>[
    CuraColors.light,
    CuraColors.dark,
    CuraColors.lightHighContrast,
    CuraColors.darkHighContrast,
  ]) {
    test('Rollen (${c.isDark ? 'Dunkel' : 'Hell'}, '
        '${c.highContrast ? 'Hoher Kontrast' : 'Normal'})', () {
      const Color white = Color(0xFFFFFFFF);
      expect(c.pressedOverlay, c.text1.withValues(alpha: 0.10));
      expect(c.lightEdge, white.withValues(alpha: c.isDark ? 0.10 : 0.60));
      expect(c.disabledFill, c.text1.withValues(alpha: 0.10));
      // Spur von Balken und Reglern: ink-1 14 % (Brief 3.2).
      expect(c.progressOff, c.text1.withValues(alpha: 0.14));
      expect(c.pureWhite, white);
      expect(c.chipFill, c.chipNeutralFill);
      expect(c.disabledContent, c.text1.withValues(alpha: 0.38));
      expect(c.navActiveBorder, c.accent.withValues(alpha: 0.60));
      expect(c.unitPulse(0.25), c.accent.withValues(alpha: 0.75));
    });
  }

  test('Maße der Bausteine (Ablage der Brief-Werte)', () {
    expect(CuraComponent.iconSize, 24);
    expect(CuraComponent.dialogIconSize, 28);
    expect(CuraComponent.bubbleMaxWidth, 280);
    expect(CuraComponent.bubbleMinSideSpace, 140);
    expect(CuraComponent.bubbleArrow, 8);
    expect(CuraComponent.stepSegments, 5);
    expect(CuraComponent.snackbarPadding, 16);
    expect(CuraComponent.choiceInnerMinHeight, 64 - 24);
  });
}
