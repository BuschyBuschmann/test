// ThemeData-Aufbau aus den Tokens (Plan 8.1). Stellt `CuraColors` und
// `CuraTypography` als Erweiterungen bereit und stimmt die Material-
// Bausteine (Datumsauswahl) auf die Tokens ab. Die Locale `de` und die
// Material-Lokalisierung setzt die App (`app.dart`).
import 'package:flutter/material.dart';

import 'cura_colors.dart';
import 'cura_metrics.dart';
import 'cura_typography.dart';

abstract final class CuraTheme {
  /// Theme der Inhaltsflächen: [brightness] wählt Hell oder Dunkel (Brief 3.2,
  /// unabhängig von der Welt); [highContrast] den Token-Satz „Hoher Kontrast“
  /// (gilt auch für „Transparenz reduzieren“, Brief 3.5).
  static ThemeData build({
    Brightness brightness = Brightness.light,
    bool highContrast = false,
  }) {
    final CuraColors colors = CuraColors.variant(
      brightness,
      highContrast: highContrast,
    );
    final CuraTypography type = switch ((brightness, highContrast)) {
      (Brightness.dark, true) => CuraTypography.darkHighContrast,
      (Brightness.dark, false) => CuraTypography.dark,
      (Brightness.light, true) => CuraTypography.lightHighContrast,
      (Brightness.light, false) => CuraTypography.light,
    };

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      secondary: colors.accentText,
      onSecondary: colors.surfaceOpaque,
      surface: colors.surfaceOpaque,
      onSurface: colors.text1,
      error: colors.statusError,
      onError: colors.surfaceOpaque,
    );

    TextStyle withColor(TextStyle s, Color c) => s.copyWith(color: c);
    final TextTheme textTheme = TextTheme(
      displayLarge: withColor(type.display, colors.text1),
      displayMedium: withColor(type.display, colors.text1),
      displaySmall: withColor(type.display, colors.text1),
      headlineLarge: withColor(type.title, colors.text1),
      headlineMedium: withColor(type.title, colors.text1),
      headlineSmall: withColor(type.title, colors.text1),
      titleLarge: withColor(type.title, colors.text1),
      titleMedium: withColor(type.heading, colors.text1),
      titleSmall: withColor(type.heading, colors.text1),
      bodyLarge: withColor(type.body, colors.text1),
      bodyMedium: withColor(type.body, colors.text1),
      bodySmall: withColor(type.secondary, colors.text2),
      labelLarge: withColor(type.button, colors.text1),
      labelMedium: withColor(type.secondary, colors.text2),
      labelSmall: withColor(type.caption, colors.text2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.bg,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      extensions: <ThemeExtension<dynamic>>[colors, type],
      datePickerTheme: datePickerTheme(colors, type),
      // `primary` bleibt `accent` (Flächen, Ringe, Auswahl). Alles, was
      // Material daraus als **Text** färbt, wird auf `accentText` bzw. `text-1`
      // umgelenkt (Brief-E-2, V2-32): Textbuttons, Eingabefeld-Labels.
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(colors, type),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.text1,
          textStyle: type.bodyStrong,
        ),
      ),
      inputDecorationTheme: inputDecorationTheme(colors, type),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accentText,
        selectionHandleColor: colors.accentText,
      ),
    );
  }

  static ButtonStyle _textButtonStyle(CuraColors colors, CuraTypography type) =>
      TextButton.styleFrom(
        foregroundColor: colors.accentText,
        textStyle: type.bodyStrong,
        minimumSize: const Size(CuraSize.touchTarget, CuraSize.touchTarget),
      );

  /// Eingabefelder (auch im Eingabe-Modus der Datumsauswahl): Label `text-2`,
  /// fokussiert bzw. schwebend `accentText`, nie `accent` als Text.
  static InputDecorationTheme inputDecorationTheme(
    CuraColors colors,
    CuraTypography type,
  ) {
    return InputDecorationTheme(
      labelStyle: type.secondary.copyWith(color: colors.text2),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith((
        Set<WidgetState> states,
      ) {
        return type.secondary.copyWith(
          color: states.contains(WidgetState.error)
              ? colors.statusError
              : (states.contains(WidgetState.focused)
                    ? colors.accentText
                    : colors.text2),
        );
      }),
      hintStyle: type.body.copyWith(color: colors.text2),
      helperStyle: type.secondary.copyWith(color: colors.text2),
    );
  }

  /// Datumsauswahl im gewählten Thema. Textbuttons in `accent-text` (Brief-E-2:
  /// nie `accent` als Text auf `surface-opaque`); der gewählte Tag bleibt eine
  /// Fläche `accent` mit `on-accent`.
  static DatePickerThemeData datePickerTheme(
    CuraColors colors,
    CuraTypography type,
  ) {
    final ButtonStyle textButton = _textButtonStyle(colors, type);
    return DatePickerThemeData(
      backgroundColor: colors.surfaceOpaque,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CuraRadius.dialog),
        side: BorderSide(color: colors.cardBorder),
      ),
      headerForegroundColor: colors.text1,
      confirmButtonStyle: textButton,
      cancelButtonStyle: textButton,
      dayForegroundColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        return states.contains(WidgetState.selected)
            ? colors.onAccent
            : colors.text1;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        return states.contains(WidgetState.selected) ? colors.accent : null;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        return states.contains(WidgetState.selected)
            ? colors.onAccent
            : colors.accentText;
      }),
      todayBorder: BorderSide(color: colors.accentText),
      inputDecorationTheme: inputDecorationTheme(colors, type),
    );
  }
}
