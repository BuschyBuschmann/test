// Textstile als `ThemeExtension` (Design-Brief v1 3.3, Plan 8.1). Jeder Stil
// setzt `fontFamily`, `fontSize`, `height`, `fontWeight` **und**
// `fontVariations` (`wght`, `opsz`, bei Bricolage zusätzlich `wdth`).
// Stile tragen keine Farbe, außer `segment`/`segmentSelected` (A-23); die Farbe
// setzt die Komponente aus `CuraColors`.
import 'package:flutter/material.dart';

import 'cura_colors.dart';
import 'tokens.dart';

/// Optische Größe: `opsz = fontSize`, begrenzt auf die Achse der Schrift
/// (entspricht `font-optical-sizing: auto` im Web).
double opticalSizeFor(TypeSpec spec) {
  final bool bricolage = spec.family == TypeScale.bricolage;
  final double min = bricolage
      ? TypeScale.bricolageOpszMin
      : TypeScale.dmSansOpszMin;
  final double max = bricolage
      ? TypeScale.bricolageOpszMax
      : TypeScale.dmSansOpszMax;
  return spec.size.clamp(min, max).toDouble();
}

TextStyle textStyleFromSpec(TypeSpec spec, {Color? color}) {
  final bool bricolage = spec.family == TypeScale.bricolage;
  return TextStyle(
    fontFamily: spec.family,
    fontSize: spec.size,
    height: spec.lineHeight / spec.size,
    fontWeight: FontWeight.values.firstWhere(
      (FontWeight w) => w.value == spec.weight,
    ),
    letterSpacing: spec.letterSpacingEm == 0
        ? null
        : spec.letterSpacingEm * spec.size,
    color: color,
    fontVariations: <FontVariation>[
      FontVariation('wght', spec.weight.toDouble()),
      FontVariation('opsz', opticalSizeFor(spec)),
      if (bricolage) const FontVariation('wdth', TypeScale.bricolageWidth),
    ],
  );
}

@immutable
class CuraTypography extends ThemeExtension<CuraTypography> {
  const CuraTypography({
    required this.display,
    required this.titleHeader,
    required this.title,
    required this.heading,
    required this.counter,
    required this.counterUnit,
    required this.numeral,
    required this.numeralSmall,
    required this.numeralLarge,
    required this.button,
    required this.body,
    required this.bodyStrong,
    required this.secondary,
    required this.label,
    required this.caption,
    required this.chip,
    required this.bubble,
    required this.segment,
    required this.segmentSelected,
  });

  factory CuraTypography.from(CuraColors colors) {
    return CuraTypography(
      display: textStyleFromSpec(TypeScale.display),
      titleHeader: textStyleFromSpec(TypeScale.titleHeader),
      title: textStyleFromSpec(TypeScale.title),
      heading: textStyleFromSpec(TypeScale.heading),
      counter: textStyleFromSpec(TypeScale.counter),
      counterUnit: textStyleFromSpec(TypeScale.counterUnit),
      numeral: textStyleFromSpec(TypeScale.numeral),
      numeralSmall: textStyleFromSpec(TypeScale.numeralSmall),
      numeralLarge: textStyleFromSpec(TypeScale.numeralLarge),
      button: textStyleFromSpec(TypeScale.button),
      body: textStyleFromSpec(TypeScale.body),
      bodyStrong: textStyleFromSpec(TypeScale.bodyStrong),
      secondary: textStyleFromSpec(TypeScale.secondary),
      label: textStyleFromSpec(TypeScale.label),
      caption: textStyleFromSpec(TypeScale.caption),
      chip: textStyleFromSpec(TypeScale.chip),
      bubble: textStyleFromSpec(TypeScale.bubble),
      segment: textStyleFromSpec(TypeScale.segment, color: colors.text2),
      segmentSelected: textStyleFromSpec(
        TypeScale.segmentSelected,
        color: colors.text1,
      ),
    );
  }

  final TextStyle display;

  /// Titel der Kopf-Karte 30/32 (`title` ist 24/28).
  final TextStyle titleHeader;
  final TextStyle title;
  final TextStyle heading;

  /// Zähler-Orb 52/52 und seine Einheit 30.
  final TextStyle counter;
  final TextStyle counterUnit;

  /// Zahl in Kacheln 28/30; [numeralSmall] 18/24.
  final TextStyle numeral;
  final TextStyle numeralSmall;

  /// Zahl 24/28 (z. B. Uhrzeit auf Karten).
  final TextStyle numeralLarge;
  final TextStyle button;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle secondary;

  /// Abschnittstitel; Großbuchstaben nur in der Darstellung (`CuraLabel`).
  final TextStyle label;
  final TextStyle caption;

  /// Chip 13/16, 700.
  final TextStyle chip;

  /// Sprechblase, 14,5 sp.
  final TextStyle bubble;
  final TextStyle segment;
  final TextStyle segmentSelected;

  /// Alle Stile mit Namen (für Typo-Tafel und Tests).
  Map<String, TextStyle> get all => <String, TextStyle>{
    'display': display,
    'titleHeader': titleHeader,
    'title': title,
    'heading': heading,
    'counter': counter,
    'counterUnit': counterUnit,
    'numeral': numeral,
    'numeralSmall': numeralSmall,
    'numeralLarge': numeralLarge,
    'button': button,
    'body': body,
    'bodyStrong': bodyStrong,
    'secondary': secondary,
    'label': label,
    'caption': caption,
    'chip': chip,
    'bubble': bubble,
    'segment': segment,
    'segmentSelected': segmentSelected,
  };

  static final CuraTypography light = CuraTypography.from(CuraColors.light);
  static final CuraTypography dark = CuraTypography.from(CuraColors.dark);
  static final CuraTypography lightHighContrast = CuraTypography.from(
    CuraColors.lightHighContrast,
  );
  static final CuraTypography darkHighContrast = CuraTypography.from(
    CuraColors.darkHighContrast,
  );

  static CuraTypography of(BuildContext context) {
    final CuraTypography? t = Theme.of(context).extension<CuraTypography>();
    assert(
      t != null,
      'CuraTypography fehlt im Theme (CuraTheme.build nutzen).',
    );
    return t!;
  }

  @override
  CuraTypography copyWith({
    TextStyle? display,
    TextStyle? titleHeader,
    TextStyle? title,
    TextStyle? heading,
    TextStyle? counter,
    TextStyle? counterUnit,
    TextStyle? numeral,
    TextStyle? numeralSmall,
    TextStyle? numeralLarge,
    TextStyle? button,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? secondary,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? chip,
    TextStyle? bubble,
    TextStyle? segment,
    TextStyle? segmentSelected,
  }) {
    return CuraTypography(
      display: display ?? this.display,
      titleHeader: titleHeader ?? this.titleHeader,
      title: title ?? this.title,
      heading: heading ?? this.heading,
      counter: counter ?? this.counter,
      counterUnit: counterUnit ?? this.counterUnit,
      numeral: numeral ?? this.numeral,
      numeralSmall: numeralSmall ?? this.numeralSmall,
      numeralLarge: numeralLarge ?? this.numeralLarge,
      button: button ?? this.button,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      secondary: secondary ?? this.secondary,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      chip: chip ?? this.chip,
      bubble: bubble ?? this.bubble,
      segment: segment ?? this.segment,
      segmentSelected: segmentSelected ?? this.segmentSelected,
    );
  }

  @override
  CuraTypography lerp(ThemeExtension<CuraTypography>? other, double t) {
    if (other is! CuraTypography) return this;
    return CuraTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      titleHeader: TextStyle.lerp(titleHeader, other.titleHeader, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      heading: TextStyle.lerp(heading, other.heading, t)!,
      counter: TextStyle.lerp(counter, other.counter, t)!,
      counterUnit: TextStyle.lerp(counterUnit, other.counterUnit, t)!,
      numeral: TextStyle.lerp(numeral, other.numeral, t)!,
      numeralSmall: TextStyle.lerp(numeralSmall, other.numeralSmall, t)!,
      numeralLarge: TextStyle.lerp(numeralLarge, other.numeralLarge, t)!,
      button: TextStyle.lerp(button, other.button, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyStrong: TextStyle.lerp(bodyStrong, other.bodyStrong, t)!,
      secondary: TextStyle.lerp(secondary, other.secondary, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      chip: TextStyle.lerp(chip, other.chip, t)!,
      bubble: TextStyle.lerp(bubble, other.bubble, t)!,
      segment: TextStyle.lerp(segment, other.segment, t)!,
      segmentSelected: TextStyle.lerp(
        segmentSelected,
        other.segmentSelected,
        t,
      )!,
    );
  }
}
