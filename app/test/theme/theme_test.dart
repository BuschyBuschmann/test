// Theme-Aufbau: Erweiterungen, Farbschema, DatePicker (Brief-E-2, UI-4).
import 'package:curaone/theme/cura_colors.dart';
import 'package:curaone/theme/cura_theme.dart';
import 'package:curaone/theme/cura_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Hell/Dunkel, normal und hoher Kontrast: passende Erweiterungen', () {
    final ThemeData normal = CuraTheme.build();
    final ThemeData hc = CuraTheme.build(highContrast: true);
    final ThemeData dark = CuraTheme.build(brightness: Brightness.dark);
    final ThemeData darkHc = CuraTheme.build(
      brightness: Brightness.dark,
      highContrast: true,
    );
    // Standard ist Hell (Brief 3.2); die App wählt das Thema aus System/Profil.
    expect(normal.brightness, Brightness.light);
    expect(normal.extension<CuraColors>(), same(CuraColors.light));
    expect(hc.extension<CuraColors>(), same(CuraColors.lightHighContrast));
    expect(dark.brightness, Brightness.dark);
    expect(dark.extension<CuraColors>(), same(CuraColors.dark));
    expect(darkHc.extension<CuraColors>(), same(CuraColors.darkHighContrast));
    expect(normal.extension<CuraTypography>(), isNotNull);
    expect(normal.scaffoldBackgroundColor, CuraColors.light.bg);
    expect(normal.colorScheme.primary, CuraColors.light.accent);
    expect(normal.colorScheme.onPrimary, CuraColors.light.onAccent);
    expect(normal.colorScheme.surface, CuraColors.light.surfaceOpaque);
    expect(dark.scaffoldBackgroundColor, CuraColors.dark.bg);
    expect(dark.colorScheme.surface, CuraColors.dark.surfaceOpaque);
  });

  test(
    'DatePicker: Textbuttons accent-text, gewählter Tag accent/on-accent',
    () {
      final CuraColors c = CuraColors.light;
      final DatePickerThemeData d = CuraTheme.build().datePickerTheme;
      expect(d.backgroundColor, c.surfaceOpaque);
      for (final ButtonStyle? style in <ButtonStyle?>[
        d.confirmButtonStyle,
        d.cancelButtonStyle,
      ]) {
        expect(style!.foregroundColor!.resolve(<WidgetState>{}), c.accentText);
      }
      final Set<WidgetState> selected = <WidgetState>{WidgetState.selected};
      expect(d.dayBackgroundColor!.resolve(selected), c.accent);
      expect(d.dayForegroundColor!.resolve(selected), c.onAccent);
      expect(d.dayForegroundColor!.resolve(<WidgetState>{}), c.text1);
    },
  );

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
    expect(colors, same(CuraColors.light));
    expect(type.body.fontFamily, 'DMSans');
  });
}
