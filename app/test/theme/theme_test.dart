// Theme-Aufbau: Erweiterungen, Farbschema, DatePicker (Brief-E-2, UI-4).
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_theme.dart';
import 'package:curaone/theme/cura_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Normal und hoher Kontrast liefern die passenden Erweiterungen', () {
    final ThemeData normal = CuraTheme.build();
    final ThemeData hc = CuraTheme.build(highContrast: true);
    expect(normal.brightness, Brightness.dark);
    expect(normal.extension<CuraColors>(), same(CuraColors.dark));
    expect(hc.extension<CuraColors>(), same(CuraColors.darkHighContrast));
    expect(normal.extension<CuraTypography>(), isNotNull);
    expect(normal.scaffoldBackgroundColor, CuraColors.dark.bg);
    expect(normal.colorScheme.primary, CuraColors.dark.accent);
    expect(normal.colorScheme.onPrimary, CuraColors.dark.onAccent);
    expect(normal.colorScheme.surface, CuraColors.dark.surfaceOpaque);
  });

  test('DatePicker: Textbuttons accent-hi, gewählter Tag accent/on-accent', () {
    final CuraColors c = CuraColors.dark;
    final DatePickerThemeData d = CuraTheme.build().datePickerTheme;
    expect(d.backgroundColor, c.surfaceOpaque);
    for (final ButtonStyle? style in <ButtonStyle?>[
      d.confirmButtonStyle,
      d.cancelButtonStyle,
    ]) {
      expect(style!.foregroundColor!.resolve(<WidgetState>{}), c.accentHi);
    }
    final Set<WidgetState> selected = <WidgetState>{WidgetState.selected};
    expect(d.dayBackgroundColor!.resolve(selected), c.accent);
    expect(d.dayForegroundColor!.resolve(selected), c.onAccent);
    expect(d.dayForegroundColor!.resolve(<WidgetState>{}), c.text1);
  });

  testWidgets('CuraColors.of und CuraTypography.of lesen aus dem Theme', (
    WidgetTester tester,
  ) async {
    late CuraColors colors;
    late CuraTypography type;
    await tester.pumpWidget(
      MaterialApp(
        theme: CuraTheme.build(),
        home: Builder(
          builder: (BuildContext context) {
            colors = CuraColors.of(context);
            type = CuraTypography.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(colors, same(CuraColors.dark));
    expect(type.body.fontFamily, 'DMSans');
  });
}
